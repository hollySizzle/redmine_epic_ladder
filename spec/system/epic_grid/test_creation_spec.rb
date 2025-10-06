# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Test作成E2Eテスト
# ============================================================
#
# テスト対象:
# - 各UserStory内の「+ Add Test」ボタンをクリック
# - プロンプトにTest名を入力
# - 新しいTestが作成され、グリッドに表示される
#
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Test Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'test-creation-test', name: 'Test Creation Test') }
  let!(:user) { setup_admin_user(login: 'test_creator') }

  before(:each) do
    # Epic, Feature, Version, UserStoryを作成
    epic_tracker = project.trackers.find { |t| t.name == EpicGridTestConfig::TRACKER_NAMES[:epic] }
    feature_tracker = project.trackers.find { |t| t.name == EpicGridTestConfig::TRACKER_NAMES[:feature] }
    user_story_tracker = project.trackers.find { |t| t.name == EpicGridTestConfig::TRACKER_NAMES[:user_story] }

    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic')
    @version1 = create(:version, project: project, name: 'v1.0.0')
    @feature1 = create(:issue, project: project, tracker: feature_tracker, parent: @epic1, fixed_version: @version1, subject: 'Test Feature')
    @user_story1 = create(:issue, project: project, tracker: user_story_tracker, parent: @feature1, subject: 'Test UserStory')
  end

  describe 'Test Creation Flow' do
    it 'creates a new Test via Add Test button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: UserStoryが表示されることを確認
      expect_text_visible('Test UserStory')

      # Step 4: create_test_via_uiヘルパーを使用
      create_test_via_ui('Test UserStory', 'New Test Case')

      # Step 5: 新しいTestが表示されることを確認
      expect_text_visible('New Test Case')

      puts "\n✅ Test Creation E2E Test Passed"
    end

    it 'cancels Test creation when modal is dismissed' do
      login_as(user)
      goto_kanban(project)

      # UserStoryを展開
      expand_user_story('Test UserStory')

      # キャンセル操作を実行
      cancel_item_creation_via_ui('test', parent_info: { user_story_subject: 'Test UserStory' })

      # Testが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Test Case')

      puts "\n✅ Test Creation Cancel Test Passed"
    end
  end
end
