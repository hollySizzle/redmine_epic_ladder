# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Bug作成E2Eテスト
# ============================================================
#
# テスト対象:
# - 各UserStory内の「+ Add Bug」ボタンをクリック
# - プロンプトにBug名を入力
# - 新しいBugが作成され、グリッドに表示される
#
# 参考: spec/system/epic_ladder/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Bug Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_ladder_project(identifier: 'bug-creation-test', name: 'Bug Creation Test') }
  let!(:user) { setup_admin_user(login: 'bug_creator') }

  before(:each) do
    # Epic, Feature, Version, UserStoryを作成
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
    feature_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:feature] }
    user_story_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:user_story] }

    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic')
    @version1 = create(:version, project: project, name: 'v1.0.0')
    @feature1 = create(:issue, project: project, tracker: feature_tracker, parent: @epic1, fixed_version: @version1, subject: 'Test Feature')
    @user_story1 = create(:issue, project: project, tracker: user_story_tracker, parent: @feature1, subject: 'Test UserStory')
  end

  describe 'Bug Creation Flow' do
    it 'creates a new Bug via Add Bug button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: UserStoryが表示されることを確認
      expect_text_visible('Test UserStory')

      # Step 4: create_bug_via_uiヘルパーを使用
      create_bug_via_ui('Test UserStory', 'New Bug Report')

      # Step 5: 新しいBugが表示されることを確認
      expect_text_visible('New Bug Report')

      puts "\n✅ Bug Creation E2E Test Passed"
    end

    it 'cancels Bug creation when modal is dismissed' do
      login_as(user)
      goto_kanban(project)

      # UserStoryを展開
      expand_user_story('Test UserStory')

      # キャンセル操作を実行
      cancel_item_creation_via_ui('bug', parent_info: { user_story_subject: 'Test UserStory' })

      # Bugが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Bug Report')

      puts "\n✅ Bug Creation Cancel Test Passed"
    end
  end
end
