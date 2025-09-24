# plugins/redmine_release_kanban/init.rb
Redmine::Plugin.register :redmine_release_kanban do
  name 'Redmine Release Kanban Plugin'
  author 'holly'
  description 'Epic→Feature→UserStory→Task/Test階層制約とバージョン管理を統合したRelease Kanbanシステム'
  version '1.0.0'
  url 'https://github.com/your-repo/redmine_release_kanban'
  author_url 'https://github.com/your-team'

  # プロジェクトモジュール定義
  project_module :release_kanban do
    permission :view_kanban, {
      kanban: [:index],
      'kanban/cards' => [:index],
      'kanban/hierarchy' => [:hierarchy_tree],
      'kanban/validations' => [:release_validation, :bulk_validation]
    }, require: :member

    permission :manage_kanban, {
      'kanban/state_transitions' => [:move_card, :bulk_move_cards],
      'kanban/versions' => [:assign_version, :bulk_assign_version, :create_version],
      'kanban/auto_generation' => [:generate_test, :batch_generate_tests]
    }, require: :member
  end

  # プロジェクトメニューに追加
  menu :project_menu,
       :release_kanban,
       { controller: 'kanban', action: 'index' },
       caption: 'Release Kanban',
       param: :project_id,
       if: Proc.new { |p| User.current.allowed_to?(:view_kanban, p) }

  # プラグイン設定画面
  settings default: {
    'epic_tracker' => 'Epic',
    'feature_tracker' => 'Feature',
    'user_story_tracker' => 'UserStory',
    'task_tracker' => 'Task',
    'test_tracker' => 'Test',
    'bug_tracker' => 'Bug'
  }, partial: 'settings/kanban_tracker_settings'
end
