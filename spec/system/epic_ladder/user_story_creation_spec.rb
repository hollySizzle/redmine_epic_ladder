# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# UserStory作成E2Eテスト
# ============================================================
#
# テスト対象:
# - 各Feature×Versionセル内の「+ Add User Story」ボタンをクリック
# - プロンプトにUserStory名を入力
# - 新しいUserStoryが作成され、グリッドに表示される
#
# 参考: spec/system/epic_ladder/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'UserStory Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_ladder_project(identifier: 'userstory-creation-test', name: 'UserStory Creation Test') }
  let!(:user) { setup_admin_user(login: 'userstory_creator') }

  before(:each) do
    # Epic, Feature, Versionを作成
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
    feature_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:feature] }

    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic for UserStory')
    @version1 = create(:version, project: project, name: 'v1.0.0')
    @feature1 = create(:issue, project: project, tracker: feature_tracker, parent: @epic1, fixed_version: @version1, subject: 'Test Feature')
  end

  describe 'UserStory Creation Flow' do
    it 'creates a new UserStory via Add User Story button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: Epic, Feature, Versionが表示されることを確認
      expect_text_visible('Test Epic for UserStory')
      expect_text_visible('Test Feature')
      expect_text_visible('v1.0.0')

      # Step 4: create_user_story_via_uiヘルパーを使用
      create_user_story_via_ui(@feature1.id, 'New Test UserStory')

      # Step 5: 新しいUserStoryが表示されることを確認
      expect_text_visible('New Test UserStory')

      puts "\n✅ UserStory Creation E2E Test Passed"
    end

    it 'cancels UserStory creation when modal is dismissed' do
      login_as(user)
      goto_kanban(project)

      # キャンセル操作を実行
      cancel_item_creation_via_ui('user-story', parent_info: { feature_id: @feature1.id })

      # UserStoryが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Test UserStory')

      puts "\n✅ UserStory Creation Cancel Test Passed"
    end
  end
end
