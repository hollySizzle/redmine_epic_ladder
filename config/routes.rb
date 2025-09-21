# plugins/redmine_release_kanban/config/routes.rb
RedmineApp::Application.routes.draw do
  # 技術仕様書準拠のカンバンAPI設計
  scope 'kanban/projects/:project_id' do
    # ===== APIIntegration（API連携） =====
    get 'cards', to: 'kanban/api#kanban_data'
    post 'transition_issue', to: 'kanban/api#transition_issue'
    post 'assign_version', to: 'kanban/api#assign_version'
    post 'generate_test', to: 'kanban/api#generate_test'
    get 'validate_release', to: 'kanban/api#validate_release'
    get 'test_connection', to: 'kanban/api#test_connection'

    # ===== TrackerHierarchy（トラッカー階層管理） =====
    get 'hierarchy_tree', to: 'kanban/hierarchy#hierarchy_tree'
    get 'validate_hierarchy', to: 'kanban/hierarchy#validate_hierarchy'
    get 'allowed_children', to: 'kanban/hierarchy#allowed_children'

    # ===== StateTransition（状態遷移管理） =====
    post 'move_card', to: 'kanban/state_transitions#move_card'
    post 'bulk_move', to: 'kanban/state_transitions#bulk_move_cards'
    get 'transition_preview', to: 'kanban/state_transitions#transition_preview'
    get 'validate_move', to: 'kanban/state_transitions#validate_move'

    # ===== VersionManagement（バージョン管理・伝播） =====
    post 'versions/assign', to: 'kanban/versions#assign_version'
    post 'versions/bulk_assign', to: 'kanban/versions#bulk_assign_version'
    post 'versions/create', to: 'kanban/versions#create_version'
    get 'versions/preview', to: 'kanban/versions#version_assignment_preview'
    post 'versions/propagate', to: 'kanban/versions#propagate_version'

    # ===== AutoGeneration（自動生成・リレーション） =====
    post 'auto_generation/generate_test', to: 'kanban/auto_generation#generate_test'
    post 'auto_generation/batch_generate_tests', to: 'kanban/auto_generation#batch_generate_tests'
    get 'auto_generation/status', to: 'kanban/auto_generation#auto_generation_status'
    post 'auto_generation/ensure_test', to: 'kanban/auto_generation#ensure_test_exists'

    # ===== ValidationGuard（ガード・検証） =====
    get 'validations/release_readiness', to: 'kanban/validations#release_readiness'
    post 'validations/bulk_validate', to: 'kanban/validations#bulk_validation'
    get 'validations/rules', to: 'kanban/validations#validation_rules'
    post 'validations/attempt_bypass', to: 'kanban/validations#attempt_bypass'

    # ===== 既存互換性ルート =====
    get 'release_validation', to: 'kanban/api#validate_release' # 下位互換
  end

  # メインカンバン画面（従来のRedmineプロジェクト構造を維持）
  resources :projects do
    get 'kanban', to: 'kanban#index'
  end

  # グローバルテスト用ルート
  get 'kanban/test', to: 'kanban/api#test_connection'
end
