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
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Bug Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'bug-creation-test', name: 'Bug Creation Test') }
  let!(:user) { setup_admin_user(login: 'bug_creator') }

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

  describe 'Bug Creation Flow' do
    it 'creates a new Bug via Add Bug button' do
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

      # Step 5: "Add Bug" ボタンを見つける（明示的待機）
      @playwright_page.wait_for_selector('.bug-container button[data-add-button="bug"]', timeout: 10000)
      add_bug_button = @playwright_page.query_selector('.bug-container button[data-add-button="bug"]')
      expect(add_bug_button).not_to be_nil, 'Add Bug button not found'

      # Step 6: ボタンをクリック（プロンプト対応）
      @playwright_page.once('dialog', ->(dialog) {
        expect(dialog.message).to include('Bug名を入力してください')
        dialog.accept('New Bug Report')
      })

      add_bug_button.click

      # Step 7: 新しいBugが表示されることを確認
      @playwright_page.wait_for_selector('.bug-item >> text="New Bug Report"', timeout: 10000)
      expect_text_visible('New Bug Report')

      puts "\n✅ Bug Creation E2E Test Passed"
    end

    it 'cancels Bug creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      user_story_card = @playwright_page.query_selector('.user-story-card >> text="Test UserStory"')
      expand_button = user_story_card&.query_selector('.expand-button')
      expand_button&.click
      sleep 0.5

      @playwright_page.wait_for_selector('.bug-container button[data-add-button="bug"]', timeout: 10000)
      add_bug_button = @playwright_page.query_selector('.bug-container button[data-add-button="bug"]')
      expect(add_bug_button).not_to be_nil

      # プロンプトをキャンセル
      @playwright_page.once('dialog', ->(dialog) {
        dialog.dismiss
      })

      add_bug_button.click

      # Bugが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Bug Report')

      puts "\n✅ Bug Creation Cancel Test Passed"
    end
  end
end
