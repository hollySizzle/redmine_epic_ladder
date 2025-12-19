# plugins/redmine_epic_ladder/init.rb

# Concern ファイルを先にrequire
require_relative 'app/models/concerns/epic_ladder/issue_extensions'
require_relative 'app/models/concerns/epic_ladder/project_extensions'
require_relative 'app/models/concerns/epic_ladder/ransackable_config'
require_relative 'app/models/concerns/epic_ladder/version_extensions'

# View Hooks
require_relative 'lib/epic_ladder/hooks/issue_detail_hooks'

# Helper Patches (プロジェクト設定タブ追加用)
require_relative 'lib/epic_ladder/projects_helper_patch'

# Project Setting Model
require_relative 'app/models/epic_ladder/project_setting'

# Asset Deployer (npm不要環境対応)
require_relative 'lib/epic_ladder/asset_deployer'

# Redmine コアモデルに即座にinclude
ActiveSupport.on_load(:active_record) do
  Issue.include(EpicLadder::IssueExtensions) unless Issue.included_modules.include?(EpicLadder::IssueExtensions)
  Issue.include(EpicLadder::RansackableConfig) unless Issue.included_modules.include?(EpicLadder::RansackableConfig)
  Project.include(EpicLadder::ProjectExtensions) unless Project.included_modules.include?(EpicLadder::ProjectExtensions)
  Version.include(EpicLadder::VersionExtensions) unless Version.included_modules.include?(EpicLadder::VersionExtensions)
  Rails.logger.info '[EpicLadder] ✅ Model extensions loaded in init.rb'
end

# 念のためto_prepareでも実行（リロード対策）
Rails.application.config.to_prepare do
  Issue.include(EpicLadder::IssueExtensions) unless Issue.included_modules.include?(EpicLadder::IssueExtensions)
  Issue.include(EpicLadder::RansackableConfig) unless Issue.included_modules.include?(EpicLadder::RansackableConfig)
  Project.include(EpicLadder::ProjectExtensions) unless Project.included_modules.include?(EpicLadder::ProjectExtensions)
  Version.include(EpicLadder::VersionExtensions) unless Version.included_modules.include?(EpicLadder::VersionExtensions)
  Rails.logger.info '[EpicLadder] ✅ Model extensions reloaded in to_prepare'
end

# アセット自動デプロイ (npm不要環境対応)
# after_initializeで実行 (to_prepareは開発環境で何度も実行されるため)
Rails.application.config.after_initialize do
  EpicLadder::AssetDeployer.deploy_if_needed
end

Redmine::Plugin.register :redmine_epic_ladder do
  name 'Redmine Epic Ladder Plugin'
  author 'holly'
  description 'Epic→Feature→UserStory→Task/Test階層制約とVersion管理を統合したEpic Ladderシステム'
  version '1.0.0'
  url 'https://github.com/your-repo/redmine_epic_ladder'
  author_url 'https://github.com/your-team'

  # プロジェクトモジュール定義
  project_module :epic_ladder do
    permission :view_epic_ladder, {
      epic_ladder: [:index],
      'epic_ladder/cards' => [:index],
      'epic_ladder/hierarchy' => [:hierarchy_tree],
      'epic_ladder/validations' => [:release_validation, :bulk_validation]
    }, require: :member

    permission :manage_epic_ladder, {
      'epic_ladder/state_transitions' => [:move_card, :bulk_move_cards],
      'epic_ladder/versions' => [:assign_version, :bulk_assign_version, :create_version],
      'epic_ladder/auto_generation' => [:generate_test, :batch_generate_tests],
      'epic_ladder/project_settings' => [:show, :update],
      'epic_ladder/mcp_tool_hints' => [:update]
    }, require: :member
  end

  # プロジェクトメニューに追加
  menu :project_menu,
       :epic_ladder,
       { controller: 'epic_ladder', action: 'index' },
       caption: 'Epic Ladder',
       param: :project_id,
       if: Proc.new { |p| User.current.allowed_to?(:view_epic_ladder, p) }

  # プラグイン設定画面
  settings default: {
    'epic_tracker' => 'Epic',
    'feature_tracker' => 'Feature',
    'user_story_tracker' => 'UserStory',
    'task_tracker' => 'Task',
    'test_tracker' => 'Test',
    'bug_tracker' => 'Bug',
    # MCP API設定（グローバル有効/無効のみ）
    'mcp_enabled' => '1',
    # MCPツールヒント（グローバルデフォルト）
    # 例: { 'create_task' => { 'enabled' => true, 'hint_text' => 'PR必須' } }
    'mcp_tool_hints' => {},
    # 階層ガイド設定
    'hierarchy_guide_enabled' => '1',
    # Dynamic Editプラグイン統合
    'dynamic_edit_integration_enabled' => '1'
  }, partial: 'settings/kanban_tracker_settings'
end
