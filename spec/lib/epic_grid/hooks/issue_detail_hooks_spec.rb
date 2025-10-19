# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::Hooks::IssueDetailHooks, type: :view do
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }

  # Trackerをプロジェクトに関連付け
  let(:task_tracker) { FactoryBot.create(:task_tracker) }
  let(:epic_tracker) { FactoryBot.create(:epic_tracker) }
  let(:user_story_tracker) { FactoryBot.create(:user_story_tracker) }
  let(:feature_tracker) { FactoryBot.create(:feature_tracker) }

  before do
    User.current = user
    # プロジェクトに全てのTrackerを関連付け
    project.trackers << [task_tracker, epic_tracker, user_story_tracker, feature_tracker]
    project.save!
  end

  describe 'Integration Test - View Hook' do
    it 'epic_gridモジュールが有効化されていない場合、ボタンを表示しない' do
      task = FactoryBot.create(:task, project: project)

      # Redmine Hook を手動で呼び出す
      context = {
        issue: task,
        project: project
      }

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to eq('')
    end

    it 'epic_gridモジュールが有効化されている場合、Task/Test/Bugトラッカーにボタンを表示する' do
      project.enable_module!(:epic_grid)

      user_story = FactoryBot.create(:user_story, project: project)
      task = FactoryBot.create(:task, project: project, parent: user_story)

      context = {
        issue: task,
        project: project,
        controller: controller
      }

      # モックコントローラーにrender_to_stringメソッドを追加
      allow(controller).to receive(:render_to_string).and_return('<div class="epic-grid-quick-actions">Quick Actions</div>')

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to include('Quick Actions')
    end

    it 'Epic/Featureトラッカーの場合、ボタンを表示しない' do
      project.enable_module!(:epic_grid)
      epic = FactoryBot.create(:epic, project: project)

      context = {
        issue: epic,
        project: project
      }

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to eq('')
    end

    it 'UserStoryが見つからない場合、ボタンを表示しない' do
      project.enable_module!(:epic_grid)
      task = FactoryBot.create(:task, project: project, parent: nil)

      context = {
        issue: task,
        project: project
      }

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to eq('')
    end
  end

  describe 'Private Methods (via send)' do
    let(:hook) { described_class.send(:new) }

    describe '#should_show_buttons?' do
      it 'Taskトラッカーの場合はtrueを返す' do
        issue = FactoryBot.create(:task, project: project)
        result = hook.send(:should_show_buttons?, issue)

        expect(result).to be true
      end

      it 'Epicトラッカーの場合はfalseを返す' do
        issue = FactoryBot.create(:epic, project: project)
        result = hook.send(:should_show_buttons?, issue)

        expect(result).to be false
      end
    end

    describe '#find_user_story' do
      it '親のUserStoryを見つける' do
        user_story = FactoryBot.create(:user_story, project: project)
        task = FactoryBot.create(:task, project: project, parent: user_story)

        result = hook.send(:find_user_story, task)

        expect(result).to eq(user_story)
      end

      it 'UserStory自身を渡した場合はそのまま返す' do
        user_story = FactoryBot.create(:user_story, project: project)

        result = hook.send(:find_user_story, user_story)

        expect(result).to eq(user_story)
      end

      it '親が存在しない場合はnilを返す' do
        orphan_task = FactoryBot.create(:task, project: project, parent: nil)

        result = hook.send(:find_user_story, orphan_task)

        expect(result).to be_nil
      end

      it '階層が深い場合でもUserStoryを見つける' do
        feature = FactoryBot.create(:feature, project: project)
        user_story = FactoryBot.create(:user_story, project: project, parent: feature)
        task = FactoryBot.create(:task, project: project, parent: user_story)

        result = hook.send(:find_user_story, task)

        expect(result).to eq(user_story)
      end
    end
  end
end
