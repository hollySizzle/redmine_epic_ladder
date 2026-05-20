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
# 参考: spec/system/epic_ladder/simple_e2e_spec.rb
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
    @allowed_parent_project = create(:project, name: 'Allowed MCP Parent', identifier: 'allowed-mcp-parent')

    # プラグイン設定を初期化
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:epic],
      'feature_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:feature],
      'user_story_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:user_story],
      'task_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:task],
      'test_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:test],
      'bug_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:bug],
      'mcp_enabled' => '1',
      'mcp_project_creation_enabled' => '0',
      'mcp_project_creation_scope' => 'disabled',
      'mcp_project_creation_allowed_parent_ids' => [],
      'mcp_project_creation_allow_root' => '0'
    }
  end

  describe 'Plugin Settings Page Display' do
    it 'should display plugin settings page with tracker configuration' do
      # Step 1: ログイン（ヘルパー使用）
      login_as(user)

      # Step 2: プラグイン設定画面に移動
      @playwright_page.goto('/settings/plugin/redmine_epic_ladder', timeout: 30000)
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

      # MCPプロジェクト作成設定
      mcp_project_creation_enabled = @playwright_page.query_selector('input[name="settings[mcp_project_creation_enabled]"][type="checkbox"]')
      expect(mcp_project_creation_enabled).not_to be_nil

      mcp_project_creation_scope = @playwright_page.query_selector('select[name="settings[mcp_project_creation_scope]"]')
      expect(mcp_project_creation_scope).not_to be_nil

      allowed_parent_select = @playwright_page.query_selector('select[name="settings[mcp_project_creation_allowed_parent_ids][]"]')
      expect(allowed_parent_select).not_to be_nil

      allow_root_checkbox = @playwright_page.query_selector('input[name="settings[mcp_project_creation_allow_root]"][type="checkbox"]')
      expect(allow_root_checkbox).not_to be_nil

      expect(@playwright_page.text_content('body')).to include('プロジェクト作成は影響範囲が大きいため')

      # Step 5: 階層構造プレビュー確認
      hierarchy_preview = @playwright_page.query_selector('.hierarchy-preview')
      expect(hierarchy_preview).not_to be_nil

      # プレビュー内容確認（テスト設定名を使用）
      epic_preview = @playwright_page.query_selector('#epic-preview')
      expect(epic_preview).not_to be_nil
      expect(epic_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:epic])

      feature_preview = @playwright_page.query_selector('#feature-preview')
      expect(feature_preview).not_to be_nil
      expect(feature_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:feature])

      user_story_preview = @playwright_page.query_selector('#user-story-preview')
      expect(user_story_preview).not_to be_nil
      expect(user_story_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:user_story])

      task_preview = @playwright_page.query_selector('#task-preview')
      expect(task_preview).not_to be_nil
      expect(task_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:task])

      test_preview = @playwright_page.query_selector('#test-preview')
      expect(test_preview).not_to be_nil
      expect(test_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:test])

      bug_preview = @playwright_page.query_selector('#bug-preview')
      expect(bug_preview).not_to be_nil
      expect(bug_preview.text_content).to eq(EpicLadderTestConfig::TRACKER_NAMES[:bug])

      puts "\n✅ Plugin Settings E2E Test Passed: All tracker settings displayed correctly"
    end

    it 'should persist MCP project creation settings from plugin settings page' do
      login_as(user)

      @playwright_page.goto('/settings/plugin/redmine_epic_ladder', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      @playwright_page.check('input[name="settings[mcp_project_creation_enabled]"][type="checkbox"]')
      @playwright_page.select_option('select[name="settings[mcp_project_creation_scope]"]', value: 'allowed_parents_only')
      @playwright_page.evaluate(<<~JS)
        (() => {
          const projectId = #{@allowed_parent_project.id.to_s.to_json};
          const select = document.querySelector('select[name="settings[mcp_project_creation_allowed_parent_ids][]"]');
          for (const option of select.options) {
            option.selected = option.value === projectId;
          }
          select.dispatchEvent(new Event('change', { bubbles: true }));
        })()
      JS
      @playwright_page.uncheck('input[name="settings[mcp_project_creation_allow_root]"][type="checkbox"]')

      submit_button = @playwright_page.query_selector('input[type="submit"]')
      expect(submit_button).not_to be_nil
      submit_button.click
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      settings = Setting.plugin_redmine_epic_ladder
      expect(settings['mcp_project_creation_enabled']).to eq('1')
      expect(settings['mcp_project_creation_scope']).to eq('allowed_parents_only')
      expect(settings['mcp_project_creation_allowed_parent_ids']).to include(@allowed_parent_project.id.to_s)
      expect(settings['mcp_project_creation_allow_root']).to eq('0')

      expect(EpicLadder::McpTools::ProjectValidator.project_creation_allowed_parent_ids).to include(@allowed_parent_project.id)
    end

    it 'should display tracker options in select elements' do
      # Step 1: ログイン（ヘルパー使用）
      login_as(user)

      # Step 2: プラグイン設定画面に移動
      @playwright_page.goto('/settings/plugin/redmine_epic_ladder', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: Epic トラッカーの select 要素にオプションが存在するか確認
      epic_select = @playwright_page.query_selector('select[name="settings[epic_tracker]"]')
      expect(epic_select).not_to be_nil

      # オプション要素を取得
      epic_options = @playwright_page.query_selector_all('select[name="settings[epic_tracker]"] option')
      expect(epic_options.length).to be > 1 # 最低でも「選択してください」+ トラッカー

      # トラッカーオプションが存在するか確認（テスト設定名を使用）
      epic_option_texts = epic_options.map(&:text_content)
      expect(epic_option_texts).to include(EpicLadderTestConfig::TRACKER_NAMES[:epic])
      expect(epic_option_texts).to include(EpicLadderTestConfig::TRACKER_NAMES[:feature])
      expect(epic_option_texts).to include(EpicLadderTestConfig::TRACKER_NAMES[:user_story])

      puts "\n✅ Tracker Options Test Passed: Select elements contain tracker options"
    end
  end
end
