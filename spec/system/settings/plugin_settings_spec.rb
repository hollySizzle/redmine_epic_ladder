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

RSpec.describe 'Plugin Settings E2E', type: :system do
  let(:user) { create(:user, login: 'admin_user', admin: true) }

  # テストデータ: トラッカー作成
  let(:epic_tracker) { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
  let(:feature_tracker) { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
  let(:user_story_tracker) { Tracker.find_or_create_by!(name: 'UserStory') { |t| t.default_status = IssueStatus.first } }
  let(:task_tracker) { Tracker.find_or_create_by!(name: 'Task') { |t| t.default_status = IssueStatus.first } }
  let(:test_tracker) { Tracker.find_or_create_by!(name: 'Test') { |t| t.default_status = IssueStatus.first } }
  let(:bug_tracker) { Tracker.find_or_create_by!(name: 'Bug') { |t| t.default_status = IssueStatus.first } }

  before(:each) do
    # トラッカーを事前作成
    epic_tracker
    feature_tracker
    user_story_tracker
    task_tracker
    test_tracker
    bug_tracker

    # プラグイン設定を初期化
    Setting.plugin_redmine_epic_grid = {
      'epic_tracker' => 'Epic',
      'feature_tracker' => 'Feature',
      'user_story_tracker' => 'UserStory',
      'task_tracker' => 'Task',
      'test_tracker' => 'Test',
      'bug_tracker' => 'Bug'
    }
  end

  describe 'Plugin Settings Page Display' do
    it 'should display plugin settings page with tracker configuration' do
      # Step 1: ログイン
      @playwright_page.goto('/login', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      @playwright_page.fill('input[name="username"]', user.login)
      @playwright_page.fill('input[name="password"]', 'password123')
      @playwright_page.click('input#login-submit')

      # ログイン成功確認
      @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

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

      # プレビュー内容確認
      epic_preview = @playwright_page.query_selector('#epic-preview')
      expect(epic_preview).not_to be_nil
      expect(epic_preview.text_content).to eq('Epic')

      feature_preview = @playwright_page.query_selector('#feature-preview')
      expect(feature_preview).not_to be_nil
      expect(feature_preview.text_content).to eq('Feature')

      user_story_preview = @playwright_page.query_selector('#user-story-preview')
      expect(user_story_preview).not_to be_nil
      expect(user_story_preview.text_content).to eq('UserStory')

      task_preview = @playwright_page.query_selector('#task-preview')
      expect(task_preview).not_to be_nil
      expect(task_preview.text_content).to eq('Task')

      test_preview = @playwright_page.query_selector('#test-preview')
      expect(test_preview).not_to be_nil
      expect(test_preview.text_content).to eq('Test')

      bug_preview = @playwright_page.query_selector('#bug-preview')
      expect(bug_preview).not_to be_nil
      expect(bug_preview.text_content).to eq('Bug')

      puts "\n✅ Plugin Settings E2E Test Passed: All tracker settings displayed correctly"
    end

    it 'should display tracker options in select elements' do
      # Step 1: ログイン
      @playwright_page.goto('/login', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      @playwright_page.fill('input[name="username"]', user.login)
      @playwright_page.fill('input[name="password"]', 'password123')
      @playwright_page.click('input#login-submit')
      @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

      # Step 2: プラグイン設定画面に移動
      @playwright_page.goto('/settings/plugin/redmine_epic_grid', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: Epic トラッカーの select 要素にオプションが存在するか確認
      epic_select = @playwright_page.query_selector('select[name="settings[epic_tracker]"]')
      expect(epic_select).not_to be_nil

      # オプション要素を取得
      epic_options = @playwright_page.query_selector_all('select[name="settings[epic_tracker]"] option')
      expect(epic_options.length).to be > 1 # 最低でも「選択してください」+ トラッカー

      # Epic オプションが存在するか確認
      epic_option_texts = epic_options.map(&:text_content)
      expect(epic_option_texts).to include('Epic')
      expect(epic_option_texts).to include('Feature')
      expect(epic_option_texts).to include('UserStory')

      puts "\n✅ Tracker Options Test Passed: Select elements contain tracker options"
    end
  end
end
