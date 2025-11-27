# plugins/redmine_epic_grid/init.rb

# Concern ファイルを先にrequire
require_relative 'app/models/concerns/epic_grid/issue_extensions'
require_relative 'app/models/concerns/epic_grid/project_extensions'
require_relative 'app/models/concerns/epic_grid/ransackable_config'
require_relative 'app/models/concerns/epic_grid/version_extensions'

# View Hooks
require_relative 'lib/epic_grid/hooks/issue_detail_hooks'

# Helper Patches (プロジェクト設定タブ追加用)
require_relative 'lib/epic_grid/projects_helper_patch'

# Project Setting Model
require_relative 'app/models/epic_grid/project_setting'

# Asset Deployer (npm不要環境対応)
require_relative 'lib/epic_grid/asset_deployer'

# Redmine コアモデルに即座にinclude
ActiveSupport.on_load(:active_record) do
  Issue.include(EpicGrid::IssueExtensions) unless Issue.included_modules.include?(EpicGrid::IssueExtensions)
  Issue.include(EpicGrid::RansackableConfig) unless Issue.included_modules.include?(EpicGrid::RansackableConfig)
  Project.include(EpicGrid::ProjectExtensions) unless Project.included_modules.include?(EpicGrid::ProjectExtensions)
  Version.include(EpicGrid::VersionExtensions) unless Version.included_modules.include?(EpicGrid::VersionExtensions)
  Rails.logger.info '[EpicGrid] ✅ Model extensions loaded in init.rb'
end

# 念のためto_prepareでも実行（リロード対策）
Rails.application.config.to_prepare do
  Issue.include(EpicGrid::IssueExtensions) unless Issue.included_modules.include?(EpicGrid::IssueExtensions)
  Issue.include(EpicGrid::RansackableConfig) unless Issue.included_modules.include?(EpicGrid::RansackableConfig)
  Project.include(EpicGrid::ProjectExtensions) unless Project.included_modules.include?(EpicGrid::ProjectExtensions)
  Version.include(EpicGrid::VersionExtensions) unless Version.included_modules.include?(EpicGrid::VersionExtensions)
  Rails.logger.info '[EpicGrid] ✅ Model extensions reloaded in to_prepare'
end

# アセット自動デプロイ (npm不要環境対応)
# after_initializeで実行 (to_prepareは開発環境で何度も実行されるため)
Rails.application.config.after_initialize do
  EpicGrid::AssetDeployer.deploy_if_needed
end

Redmine::Plugin.register :redmine_epic_grid do
  name 'Redmine Epic Grid Plugin'
  author 'holly'
  description 'Epic→Feature→UserStory→Task/Test階層制約とVersion管理を統合したEpic Gridシステム'
  version '1.0.0'
  url 'https://github.com/your-repo/redmine_epic_grid'
  author_url 'https://github.com/your-team'

  # プロジェクトモジュール定義
  project_module :epic_grid do
    permission :view_epic_grid, {
      epic_grid: [:index],
      'epic_grid/cards' => [:index],
      'epic_grid/hierarchy' => [:hierarchy_tree],
      'epic_grid/validations' => [:release_validation, :bulk_validation]
    }, require: :member

    permission :manage_epic_grid, {
      'epic_grid/state_transitions' => [:move_card, :bulk_move_cards],
      'epic_grid/versions' => [:assign_version, :bulk_assign_version, :create_version],
      'epic_grid/auto_generation' => [:generate_test, :batch_generate_tests],
      'epic_grid/project_settings' => [:show, :update]
    }, require: :member
  end

  # プロジェクトメニューに追加
  menu :project_menu,
       :epic_grid,
       { controller: 'epic_grid', action: 'index' },
       caption: 'Epic Grid',
       param: :project_id,
       if: Proc.new { |p| User.current.allowed_to?(:view_epic_grid, p) }

  # プラグイン設定画面
  settings default: {
    'epic_tracker' => 'Epic',
    'feature_tracker' => 'Feature',
    'user_story_tracker' => 'UserStory',
    'task_tracker' => 'Task',
    'test_tracker' => 'Test',
    'bug_tracker' => 'Bug',
    # MCP API設定（グローバル有効/無効のみ）
    'mcp_enabled' => '1'
  }, partial: 'settings/kanban_tracker_settings'
end
