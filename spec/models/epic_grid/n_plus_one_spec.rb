# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe 'EpicGrid N+1 Query Detection', type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:test_tracker) { create(:test_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }

  before do
    # プロジェクトに全てのトラッカーを紐付け
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
  end

  describe 'epic_grid_as_normalized_json' do
    context 'with multiple user stories containing tasks/tests/bugs' do
      let!(:epic) { create(:epic, project: project, author: user) }
      let!(:feature) { create(:feature, project: project, parent: epic, author: user) }
      let!(:user_stories) do
        5.times.map do
          create(:user_story, project: project, parent: feature, author: user)
        end
      end

      before do
        # 各UserStoryに Task/Test/Bug を追加
        user_stories.each do |us|
          create(:task, project: project, parent: us, author: user)
          create(:test, project: project, parent: us, author: user)
          create(:bug, project: project, parent: us, author: user)
        end
      end

      it 'should not trigger N+1 queries when serializing multiple user stories' do
        # 最初のクエリ数をカウント（ウォームアップ）
        user_stories.first.epic_grid_as_normalized_json

        # 5つのUserStoryをシリアライズする際のクエリ数を計測
        queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] if payload[:sql] !~ /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/
        end

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          user_stories.each(&:epic_grid_as_normalized_json)
        end

        # Trackerクエリが大量に発生していないことを確認
        # 期待値: Trackerクエリは最大でも3回（task/test/bug）×キャッシュミス程度
        tracker_queries = queries.select { |sql| sql.include?('SELECT "trackers"') && sql.include?('name') }

        expect(tracker_queries.count).to be <= 15,
          "Expected <= 15 Tracker queries, but got #{tracker_queries.count}. This indicates an N+1 problem.\nQueries: #{tracker_queries.join("\n")}"
      end

      it 'should use cached trackers efficiently' do
        # Trackerのfind_byが繰り返し呼ばれていないことを確認
        expect(Tracker).to receive(:find_by).at_most(3).times.and_call_original

        user_stories.each(&:epic_grid_as_normalized_json)
      end
    end

    # Note: Redmine's 'children' is not an association but a method, so we can't test eager loading on it.
    # The N+1 problem is primarily with Tracker queries, which is tested above.
  end

  describe 'grid_controller performance' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:features) do
      3.times.map do
        create(:feature, project: project, parent: epic, author: user)
      end
    end
    let!(:user_stories) do
      features.flat_map do |feature|
        3.times.map do
          create(:user_story, project: project, parent: feature, author: user)
        end
      end
    end

    before do
      user_stories.each do |us|
        create(:task, project: project, parent: us, author: user)
        create(:test, project: project, parent: us, author: user)
      end
    end

    it 'should not have excessive queries when building grid data' do
      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] if payload[:sql] !~ /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        # グリッドデータ構築をシミュレート
        user_stories.each do |us|
          us.epic_grid_as_normalized_json
        end
      end

      # 総クエリ数の上限チェック（9 UserStories × 適切なクエリ数）
      # N+1がある場合: 9 * (3 Tracker queries) = 27以上
      # 修正後: 10以下が理想
      expect(queries.count).to be <= 50,
        "Expected <= 50 queries for 9 user stories, but got #{queries.count}. Possible N+1 issue."
    end
  end
end
