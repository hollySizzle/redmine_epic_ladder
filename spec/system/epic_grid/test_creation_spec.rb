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

      # Step 4: UserStoryカードを展開（Task/Test/Bugコンテナを表示）
      user_story_card = @playwright_page.query_selector('.user-story-card >> text="Test UserStory"')
      expect(user_story_card).not_to be_nil

      # 展開ボタンをクリック（実装に応じて調整）
      expand_button = user_story_card.query_selector('.expand-button')
      expand_button&.click

      sleep 0.5 # 展開アニメーション待機

      # Step 5: "Add Test" ボタンを見つける（明示的待機）
      add_test_button = @playwright_page.wait_for_selector('.test-container button[data-add-button="test"]', state: 'visible', timeout: 10000)
      expect(add_test_button).not_to be_nil, 'Add Test button not found'

      # Step 6: Dialogリスナーを設定（クリック前に設定）
      @playwright_page.on('dialog', ->(dialog) {
        expect(dialog.message).to include('Test名を入力してください')
        dialog.accept('New Test Case')
      })

      # Step 7: ボタンをクリック
      add_test_button.click

      # Step 8: 新しいTestが表示されることを確認
      @playwright_page.wait_for_selector('.test-item >> text="New Test Case"', timeout: 10000)
      expect_text_visible('New Test Case')

      puts "\n✅ Test Creation E2E Test Passed"
    end

    it 'cancels Test creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      user_story_card = @playwright_page.query_selector('.user-story-card >> text="Test UserStory"')
      expand_button = user_story_card&.query_selector('.expand-button')
      expand_button&.click
      sleep 0.5

      add_test_button = @playwright_page.wait_for_selector('.test-container button[data-add-button="test"]', state: 'visible', timeout: 10000)
      expect(add_test_button).not_to be_nil

      # Dialogリスナーを設定（キャンセル）
      @playwright_page.on('dialog', ->(dialog) {
        dialog.dismiss
      })

      add_test_button.click

      # Testが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Test Case')

      puts "\n✅ Test Creation Cancel Test Passed"
    end
  end
end
