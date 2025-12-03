# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::Hooks::IssueDetailHooks, type: :view do
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
    it 'epic_ladderモジュールが有効化されていない場合、ボタンを表示しない' do
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

    it 'epic_ladderモジュールが有効化されている場合、Task/Test/Bugトラッカーにボタンを表示する' do
      project.enable_module!(:epic_ladder)

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

    it 'UserStoryトラッカーの場合、クイックアクションを表示する' do
      project.enable_module!(:epic_ladder)
      user_story = FactoryBot.create(:user_story, project: project)

      context = {
        issue: user_story,
        project: project,
        controller: controller
      }

      allow(controller).to receive(:render_to_string).and_return('<div class="epic-grid-quick-actions">UserStory Actions</div>')

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to include('UserStory Actions')
    end

    it 'Featureトラッカーの場合、クイックアクションを表示する' do
      project.enable_module!(:epic_ladder)
      feature = FactoryBot.create(:feature, project: project)

      context = {
        issue: feature,
        project: project,
        controller: controller
      }

      allow(controller).to receive(:render_to_string).and_return('<div class="epic-grid-quick-actions">Feature Actions</div>')

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to include('Feature Actions')
    end

    it 'Epicトラッカーの場合、クイックアクションを表示する' do
      project.enable_module!(:epic_ladder)
      epic = FactoryBot.create(:epic, project: project)

      context = {
        issue: epic,
        project: project,
        controller: controller
      }

      allow(controller).to receive(:render_to_string).and_return('<div class="epic-grid-quick-actions">Epic Actions</div>')

      hook = described_class.send(:new)
      result = hook.view_issues_show_details_bottom(context)

      expect(result).to include('Epic Actions')
    end

    it 'UserStoryが見つからない場合（Task/Test/Bug）、ボタンを表示しない' do
      project.enable_module!(:epic_ladder)
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

    describe '#get_tracker_type' do
      it 'Taskトラッカーの場合は:task_levelを返す' do
        issue = FactoryBot.create(:task, project: project)
        result = hook.send(:get_tracker_type, issue)

        expect(result).to eq(:task_level)
      end

      it 'UserStoryトラッカーの場合は:user_storyを返す' do
        issue = FactoryBot.create(:user_story, project: project)
        result = hook.send(:get_tracker_type, issue)

        expect(result).to eq(:user_story)
      end

      it 'Featureトラッカーの場合は:featureを返す' do
        issue = FactoryBot.create(:feature, project: project)
        result = hook.send(:get_tracker_type, issue)

        expect(result).to eq(:feature)
      end

      it 'Epicトラッカーの場合は:epicを返す' do
        issue = FactoryBot.create(:epic, project: project)
        result = hook.send(:get_tracker_type, issue)

        expect(result).to eq(:epic)
      end
    end

    describe '#build_partial_context' do
      it 'task_levelの場合、正しいパーシャルとlocalsを返す' do
        user_story = FactoryBot.create(:user_story, project: project)
        task = FactoryBot.create(:task, project: project, parent: user_story)

        partial_name, locals = hook.send(:build_partial_context, task, project, :task_level)

        expect(partial_name).to eq('hooks/issue_quick_actions')
        expect(locals[:issue]).to eq(task)
        expect(locals[:user_story]).to eq(user_story)
        expect(locals[:project]).to eq(project)
      end

      it 'user_storyの場合、正しいパーシャルとlocalsを返す' do
        user_story = FactoryBot.create(:user_story, project: project)

        partial_name, locals = hook.send(:build_partial_context, user_story, project, :user_story)

        expect(partial_name).to eq('hooks/issue_quick_actions_user_story')
        expect(locals[:issue]).to eq(user_story)
        expect(locals[:project]).to eq(project)
      end

      it 'featureの場合、正しいパーシャルとlocalsを返す' do
        feature = FactoryBot.create(:feature, project: project)

        partial_name, locals = hook.send(:build_partial_context, feature, project, :feature)

        expect(partial_name).to eq('hooks/issue_quick_actions_feature')
        expect(locals[:issue]).to eq(feature)
        expect(locals[:project]).to eq(project)
      end

      it 'epicの場合、正しいパーシャルとlocalsを返す' do
        epic = FactoryBot.create(:epic, project: project)

        partial_name, locals = hook.send(:build_partial_context, epic, project, :epic)

        expect(partial_name).to eq('hooks/issue_quick_actions_epic')
        expect(locals[:issue]).to eq(epic)
        expect(locals[:project]).to eq(project)
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

  describe 'Version期日継承 - View Context' do
    let(:hook) { described_class.send(:new) }

    before do
      project.enable_module!(:epic_ladder)
    end

    context 'Versionの期日が設定されている場合' do
      it 'UserStoryトラッカーから作成する場合、Version期日が継承される' do
        version = FactoryBot.create(:version, project: project, effective_date: '2025-12-31')
        user_story = FactoryBot.create(:user_story, project: project, fixed_version: version)

        partial_name, locals = hook.send(:build_partial_context, user_story, project, :user_story)

        expect(partial_name).to eq('hooks/issue_quick_actions_user_story')
        expect(locals[:issue].fixed_version.effective_date.to_s).to eq('2025-12-31')
      end

      it 'Featureトラッカーから作成する場合、Version期日が継承される' do
        version = FactoryBot.create(:version, project: project, effective_date: '2025-12-31')
        feature = FactoryBot.create(:feature, project: project, fixed_version: version)

        partial_name, locals = hook.send(:build_partial_context, feature, project, :feature)

        expect(partial_name).to eq('hooks/issue_quick_actions_feature')
        expect(locals[:issue].fixed_version.effective_date.to_s).to eq('2025-12-31')
      end

      it 'Epicトラッカーから作成する場合、Version期日が継承される' do
        version = FactoryBot.create(:version, project: project, effective_date: '2025-12-31')
        epic = FactoryBot.create(:epic, project: project, fixed_version: version)

        partial_name, locals = hook.send(:build_partial_context, epic, project, :epic)

        expect(partial_name).to eq('hooks/issue_quick_actions_epic')
        expect(locals[:issue].fixed_version.effective_date.to_s).to eq('2025-12-31')
      end
    end

    context 'Versionが未設定の場合' do
      it 'UserStoryからTask作成時、期日はnilになる' do
        user_story = FactoryBot.create(:user_story, project: project, fixed_version: nil)

        partial_name, locals = hook.send(:build_partial_context, user_story, project, :user_story)

        expect(partial_name).to eq('hooks/issue_quick_actions_user_story')
        expect(locals[:issue].fixed_version).to be_nil
      end
    end
  end

  describe '階層ガイド機能' do
    let(:hook) { described_class.send(:new) }

    describe '#hierarchy_guide_enabled?' do
      context '設定が有効で、epic_ladderモジュールが有効な場合' do
        before do
          project.enable_module!(:epic_ladder)
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '1'
          )
        end

        it 'trueを返す' do
          result = hook.send(:hierarchy_guide_enabled?, project)
          expect(result).to be true
        end
      end

      context '設定が無効な場合' do
        before do
          project.enable_module!(:epic_ladder)
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '0'
          )
        end

        it 'falseを返す' do
          result = hook.send(:hierarchy_guide_enabled?, project)
          expect(result).to be false
        end
      end

      context 'epic_ladderモジュールが無効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '1'
          )
        end

        it 'falseを返す' do
          result = hook.send(:hierarchy_guide_enabled?, project)
          expect(result).to be false
        end
      end

      context 'プロジェクトがnilの場合' do
        it 'falseを返す' do
          result = hook.send(:hierarchy_guide_enabled?, nil)
          expect(result).to be false
        end
      end
    end

    describe '#view_issues_show_description_bottom' do
      before do
        project.enable_module!(:epic_ladder)
      end

      context '階層ガイドが有効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '1'
          )
        end

        it 'パーシャルをレンダリングする' do
          issue = FactoryBot.create(:user_story, project: project)
          context = {
            issue: issue,
            project: project,
            controller: controller
          }

          allow(controller).to receive(:render_to_string).and_return('<div class="hierarchy-guide">Guide</div>')

          result = hook.view_issues_show_description_bottom(context)

          expect(result).to include('hierarchy-guide')
        end
      end

      context '階層ガイドが無効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '0'
          )
        end

        it '空文字列を返す' do
          issue = FactoryBot.create(:user_story, project: project)
          context = {
            issue: issue,
            project: project
          }

          result = hook.view_issues_show_description_bottom(context)

          expect(result).to eq('')
        end
      end
    end

    describe '#view_issues_new_top' do
      before do
        project.enable_module!(:epic_ladder)
      end

      context '階層ガイドが有効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '1'
          )
        end

        it 'パーシャルをレンダリングする' do
          issue = FactoryBot.build(:user_story, project: project)
          context = {
            issue: issue,
            controller: controller
          }

          allow(controller).to receive(:render_to_string).and_return('<div class="hierarchy-notice">Notice</div>')

          result = hook.view_issues_new_top(context)

          expect(result).to include('hierarchy-notice')
        end
      end

      context '階層ガイドが無効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '0'
          )
        end

        it '空文字列を返す' do
          issue = FactoryBot.build(:user_story, project: project)
          context = {
            issue: issue
          }

          result = hook.view_issues_new_top(context)

          expect(result).to eq('')
        end
      end

      context 'プロジェクトがnilの場合' do
        it '空文字列を返す' do
          issue = double('Issue', project: nil)
          context = {
            issue: issue
          }

          result = hook.view_issues_new_top(context)

          expect(result).to eq('')
        end
      end
    end

    describe '#view_issues_form_details_bottom' do
      before do
        project.enable_module!(:epic_ladder)
      end

      context '階層ガイドが有効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '1'
          )
        end

        it 'パーシャルをレンダリングする' do
          issue = FactoryBot.create(:user_story, project: project)
          context = {
            issue: issue,
            project: project,
            controller: controller
          }

          allow(controller).to receive(:render_to_string).and_return('<script>version warning</script>')

          result = hook.view_issues_form_details_bottom(context)

          expect(result).to include('version warning')
        end
      end

      context '階層ガイドが無効な場合' do
        before do
          allow(Setting).to receive(:plugin_redmine_epic_ladder).and_return(
            'hierarchy_guide_enabled' => '0'
          )
        end

        it '空文字列を返す' do
          issue = FactoryBot.create(:user_story, project: project)
          context = {
            issue: issue,
            project: project
          }

          result = hook.view_issues_form_details_bottom(context)

          expect(result).to eq('')
        end
      end
    end
  end
end
