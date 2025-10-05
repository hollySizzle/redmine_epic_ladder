# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# 📚 Plugin Settings E2E Test
# ============================================================
#
# このテストは以下を検証します:
#
# 1. プラグイン設定画面へのアクセス
# 2. トラッカー設定フォームの表示
# 3. 階層構造プレビューの表示
#
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Plugin Settings E2E', type: :system, js: true do
  let!(:user) { setup_admin_user(login: 'settings_admin') }

  before(:each) do
    @epic_tracker = create(:epic_tracker)
    @feature_tracker = create(:feature_tracker)
    @user_story_tracker = create(:user_story_tracker)
    @task_tracker = create(:task_tracker)
    @test_tracker = create(:test_tracker)
    @bug_tracker = create(:bug_tracker)

    # プラグイン設定を初期化
    Setting.plugin_redmine_epic_grid = {
      'epic_tracker' => EpicGridTestConfig::TRACKER_NAMES[:epic],
      'feature_tracker' => EpicGridTestConfig::TRACKER_NAMES[:feature],
      'user_story_tracker' => EpicGridTestConfig::TRACKER_NAMES[:user_story],
      'task_tracker' => EpicGridTestConfig::TRACKER_NAMES[:task],
      'test_tracker' => EpicGridTestConfig::TRACKER_NAMES[:test],
      'bug_tracker' => EpicGridTestConfig::TRACKER_NAMES[:bug]
    }
  end

  describe 'Plugin Settings Page Display' do
    it 'should display plugin settings page with tracker configuration' do
      # Step 1: ログイン（ヘルパー使用）
      login_as(user)

      # Step 2: プラグイン設定画面に移動
      @playwright_page.goto('/settings/plugin/redmine_epic_grid', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: 設定画面ボックス表示確認
      settings_box = @playwright_page.query_selector('.box.tabular.settings')
      expect(settings_box).not_to be_nil

      # Step 4: 各トラッカー設定フォーム確認
      # Epic トラッカー
      epic_select = @playwright_page.query_selector('select[name="settings[epic_tracker]"]')
      expect(epic_select).not_to be_nil

      # Feature トラッカー
      feature_select = @playwright_page.query_selector('select[name="settings[feature_tracker]"]')
      expect(feature_select).not_to be_nil

      # UserStory トラッカー
      user_story_select = @playwright_page.query_selector('select[name="settings[user_story_tracker]"]')
      expect(user_story_select).not_to be_nil

      # Task トラッカー
      task_select = @playwright_page.query_selector('select[name="settings[task_tracker]"]')
      expect(task_select).not_to be_nil

      # Test トラッカー
      test_select = @playwright_page.query_selector('select[name="settings[test_tracker]"]')
      expect(test_select).not_to be_nil

      # Bug トラッカー
      bug_select = @playwright_page.query_selector('select[name="settings[bug_tracker]"]')
      expect(bug_select).not_to be_nil

      # Step 5: 階層構造プレビュー確認
      hierarchy_preview = @playwright_page.query_selector('.hierarchy-preview')
      expect(hierarchy_preview).not_to be_nil

      # プレビュー内容確認（テスト設定名を使用）
      epic_preview = @playwright_page.query_selector('#epic-preview')
      expect(epic_preview).not_to be_nil
      expect(epic_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:epic])

      feature_preview = @playwright_page.query_selector('#feature-preview')
      expect(feature_preview).not_to be_nil
      expect(feature_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:feature])

      user_story_preview = @playwright_page.query_selector('#user-story-preview')
      expect(user_story_preview).not_to be_nil
      expect(user_story_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:user_story])

      task_preview = @playwright_page.query_selector('#task-preview')
      expect(task_preview).not_to be_nil
      expect(task_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:task])

      test_preview = @playwright_page.query_selector('#test-preview')
      expect(test_preview).not_to be_nil
      expect(test_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:test])

      bug_preview = @playwright_page.query_selector('#bug-preview')
      expect(bug_preview).not_to be_nil
      expect(bug_preview.text_content).to eq(EpicGridTestConfig::TRACKER_NAMES[:bug])

      puts "\n✅ Plugin Settings E2E Test Passed: All tracker settings displayed correctly"
    end

    it 'should display tracker options in select elements' do
      # Step 1: ログイン（ヘルパー使用）
      login_as(user)

      # Step 2: プラグイン設定画面に移動
      @playwright_page.goto('/settings/plugin/redmine_epic_grid', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: Epic トラッカーの select 要素にオプションが存在するか確認
      epic_select = @playwright_page.query_selector('select[name="settings[epic_tracker]"]')
      expect(epic_select).not_to be_nil

      # オプション要素を取得
      epic_options = @playwright_page.query_selector_all('select[name="settings[epic_tracker]"] option')
      expect(epic_options.length).to be > 1 # 最低でも「選択してください」+ トラッカー

      # トラッカーオプションが存在するか確認（テスト設定名を使用）
      epic_option_texts = epic_options.map(&:text_content)
      expect(epic_option_texts).to include(EpicGridTestConfig::TRACKER_NAMES[:epic])
      expect(epic_option_texts).to include(EpicGridTestConfig::TRACKER_NAMES[:feature])
      expect(epic_option_texts).to include(EpicGridTestConfig::TRACKER_NAMES[:user_story])

      puts "\n✅ Tracker Options Test Passed: Select elements contain tracker options"
    end
  end
end
