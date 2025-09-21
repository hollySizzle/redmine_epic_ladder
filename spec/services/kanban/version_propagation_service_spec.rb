# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::VersionPropagationService, type: :service do
  include KanbanTestHelpers

  let!(:project) { Project.create!(name: 'Test Project', identifier: 'test-version-prop') }
  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }
  let!(:status) { IssueStatus.create!(name: 'New', is_closed: false) }
  let!(:priority) { IssuePriority.create!(name: 'Normal', is_default: true) }

  # トラッカー作成
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 1, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 2, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 3, is_in_chlog: false) }
  let!(:bug_tracker) { Tracker.create!(name: 'Bug', position: 4, is_in_chlog: false) }

  # バージョン作成
  let!(:version_v1) { Version.create!(project: project, name: 'v1.0', effective_date: 1.month.from_now) }
  let!(:version_v2) { Version.create!(project: project, name: 'v2.0', effective_date: 2.months.from_now) }

  # UserStory作成
  let!(:user_story) do
    Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status,
      subject: 'Test UserStory',
      author: user,
      priority: priority
    )
  end

  # Task作成
  let!(:task1) do
    Issue.create!(
      project: project,
      tracker: task_tracker,
      status: status,
      subject: 'Task 1',
      author: user,
      parent: user_story,
      priority: priority
    )
  end

  let!(:task2) do
    Issue.create!(
      project: project,
      tracker: task_tracker,
      status: status,
      subject: 'Task 2',
      author: user,
      parent: user_story,
      priority: priority,
      fixed_version: version_v1 # 既存バージョンあり
    )
  end

  # Test作成
  let!(:test_issue) do
    Issue.create!(
      project: project,
      tracker: test_tracker,
      status: status,
      subject: 'Test: Test UserStory',
      author: user,
      parent: user_story,
      priority: priority
    )
  end

  # Bug作成
  let!(:bug_issue) do
    Issue.create!(
      project: project,
      tracker: bug_tracker,
      status: status,
      subject: 'Bug Fix',
      author: user,
      parent: user_story,
      priority: priority
    )
  end

  describe '.propagate_to_children' do
    context '正常ケース' do
      it 'UserStoryのバージョンが全子要素（Task/Test/Bug）に伝播する' do
        result = described_class.propagate_to_children(user_story, version_v2)

        expect(result[:error]).to be_nil
        expect(result[:propagated_count]).to eq(4) # task1, task2, test, bug
        expect(result[:affected_issues]).to contain_exactly(task1.id, task2.id, test_issue.id, bug_issue.id)

        # 各子要素のバージョンを確認
        [task1, task2, test_issue, bug_issue].each do |child|
          child.reload
          expect(child.fixed_version).to eq(version_v2)
        end
      end

      it 'バージョンにnilを指定した場合、全子要素のバージョンをクリアする' do
        # まずバージョンを設定
        described_class.propagate_to_children(user_story, version_v1)

        # nilで上書き
        result = described_class.propagate_to_children(user_story, nil)

        expect(result[:error]).to be_nil
        expect(result[:propagated_count]).to eq(4)

        [task1, task2, test_issue, bug_issue].each do |child|
          child.reload
          expect(child.fixed_version).to be_nil
        end
      end

      it '子要素のupdated_onが更新される' do
        original_time = 1.day.ago
        task1.update_column(:updated_on, original_time)

        described_class.propagate_to_children(user_story, version_v2)

        task1.reload
        expect(task1.updated_on).to be > original_time
      end
    end

    context '伝播モードオプション' do
      it ':force_overwrite モード（デフォルト）は既存バージョンを上書きする' do
        result = described_class.propagate_to_children(user_story, version_v2, mode: :force_overwrite)

        expect(result[:propagated_count]).to eq(4)
        task2.reload
        expect(task2.fixed_version).to eq(version_v2) # v1.0からv2.0に上書き
      end

      it ':preserve_existing モードは既存バージョンを保持する' do
        result = described_class.propagate_to_children(user_story, version_v2, mode: :preserve_existing)

        expect(result[:propagated_count]).to eq(3) # task2は除外される
        expect(result[:affected_issues]).to contain_exactly(task1.id, test_issue.id, bug_issue.id)

        task2.reload
        expect(task2.fixed_version).to eq(version_v1) # 既存バージョンを保持
      end
    end

    context '異常ケース' do
      it 'UserStory以外のトラッカーではエラーを返す' do
        result = described_class.propagate_to_children(task1, version_v2)

        expect(result[:error]).to eq('UserStoryではありません')
        expect(result[:propagated_count]).to be_nil
      end

      it 'データベースエラーが発生した場合はロールバックされる' do
        # 無効なバージョンIDでエラーを発生させる
        allow(Issue).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(task1))

        result = described_class.propagate_to_children(user_story, version_v2)

        expect(result[:error]).to include('Validation failed')

        # ロールバックされていることを確認
        task1.reload
        expect(task1.fixed_version).to be_nil
      end
    end

    context '子要素の種類による制限' do
      let!(:feature_issue) do
        Issue.create!(
          project: project,
          tracker: Tracker.create!(name: 'Feature', position: 5),
          status: status,
          subject: 'Feature',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it 'Task/Test/Bug以外の子要素は対象外' do
        result = described_class.propagate_to_children(user_story, version_v2)

        expect(result[:propagated_count]).to eq(4) # Featureは含まれない
        expect(result[:affected_issues]).not_to include(feature_issue.id)

        feature_issue.reload
        expect(feature_issue.fixed_version).to be_nil
      end
    end
  end

  describe '.remove_version_from_children' do
    before do
      # 事前に全子要素にバージョンを設定
      [task1, task2, test_issue, bug_issue].each do |child|
        child.update!(fixed_version: version_v1)
      end
    end

    it 'UserStoryの全子要素からバージョンを削除する' do
      result = described_class.remove_version_from_children(user_story)

      expect(result[:error]).to be_nil
      expect(result[:removed_count]).to eq(4)

      [task1, task2, test_issue, bug_issue].each do |child|
        child.reload
        expect(child.fixed_version).to be_nil
      end
    end

    it 'updated_onが更新される' do
      original_time = 1.day.ago
      task1.update_column(:updated_on, original_time)

      described_class.remove_version_from_children(user_story)

      task1.reload
      expect(task1.updated_on).to be > original_time
    end

    it 'データベースエラーが発生した場合はエラーを返す' do
      allow(Issue).to receive(:update_all).and_raise(ActiveRecord::StatementInvalid.new('DB Error'))

      result = described_class.remove_version_from_children(user_story)

      expect(result[:error]).to include('DB Error')
    end
  end

  describe 'ログ出力の確認' do
    it '伝播時に適切なログが出力される' do
      expect(Rails.logger).to receive(:info).with(
        "Version propagated: UserStory##{user_story.id} -> Task##{task1.id}, Version: #{version_v2.name}"
      )
      expect(Rails.logger).to receive(:info).with(
        "Version propagated: UserStory##{user_story.id} -> Task##{task2.id}, Version: #{version_v2.name}"
      )
      expect(Rails.logger).to receive(:info).with(
        "Version propagated: UserStory##{user_story.id} -> Test##{test_issue.id}, Version: #{version_v2.name}"
      )
      expect(Rails.logger).to receive(:info).with(
        "Version propagated: UserStory##{user_story.id} -> Bug##{bug_issue.id}, Version: #{version_v2.name}"
      )

      described_class.propagate_to_children(user_story, version_v2)
    end

    it 'バージョンnilの場合のログ' do
      expect(Rails.logger).to receive(:info).with(
        "Version propagated: UserStory##{user_story.id} -> Task##{task1.id}, Version: None"
      )

      described_class.propagate_to_children(user_story, nil)
    end
  end

  describe 'パフォーマンステスト', :performance do
    it '大量の子要素でも高速に処理できる' do
      # 100個の子Taskを作成
      children = (1..100).map do |i|
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status,
          subject: "Task #{i}",
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      expect do
        described_class.propagate_to_children(user_story, version_v2)
      end.to perform_under(500).ms

      # 全て正しく更新されていることを確認
      children.each do |child|
        child.reload
        expect(child.fixed_version).to eq(version_v2)
      end
    end
  end

  describe 'トランザクション制御' do
    it '途中でエラーが発生した場合、全ての変更がロールバックされる' do
      # 2番目のタスクでエラーを発生させる
      allow(task2).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(task2))
      allow(Issue).to receive(:find).with(task2.id).and_return(task2)

      expect do
        described_class.propagate_to_children(user_story, version_v2)
      end.not_to change { task1.reload.fixed_version }
    end
  end
end