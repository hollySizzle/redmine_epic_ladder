# plugins/redmine_release_kanban/config/routes.rb
RedmineApp::Application.routes.draw do
  resources :projects do
    # メインカンバンルート
    get 'kanban', to: 'kanban#index'

    # 統合API ルート
    scope 'kanban', module: 'kanban' do
      # ===== APIIntegration（API連携） =====
      get 'api/kanban_data', to: 'api#kanban_data'
      post 'api/transition_issue', to: 'api#transition_issue'
      post 'api/assign_version', to: 'api#assign_version'
      post 'api/generate_test', to: 'api#generate_test'
      get 'api/validate_release', to: 'api#validate_release'
      get 'api/test_connection', to: 'api#test_connection'

      # ===== TrackerHierarchy（トラッカー階層管理） =====
      get 'hierarchy/tree', to: 'hierarchy#hierarchy_tree'
      get 'hierarchy/validate', to: 'hierarchy#validate_hierarchy'
      get 'hierarchy/allowed_children', to: 'hierarchy#allowed_children'

      # ===== StateTransition（状態遷移管理） =====
      post 'transitions/move_card', to: 'state_transitions#move_card'
      post 'transitions/bulk_move', to: 'state_transitions#bulk_move_cards'
      get 'transitions/preview', to: 'state_transitions#transition_preview'
      get 'transitions/validate_move', to: 'state_transitions#validate_move'

      # ===== VersionManagement（バージョン管理・伝播） =====
      post 'versions/assign', to: 'versions#assign_version'
      post 'versions/bulk_assign', to: 'versions#bulk_assign_version'
      post 'versions/create', to: 'versions#create_version'
      get 'versions/preview', to: 'versions#version_assignment_preview'
      post 'versions/propagate', to: 'versions#propagate_version'

      # ===== AutoGeneration（自動生成・リレーション） =====
      post 'auto_generation/generate_test', to: 'auto_generation#generate_test'
      post 'auto_generation/batch_generate_tests', to: 'auto_generation#batch_generate_tests'
      get 'auto_generation/status', to: 'auto_generation#auto_generation_status'
      post 'auto_generation/ensure_test', to: 'auto_generation#ensure_test_exists'

      # ===== ValidationGuard（ガード・検証） =====
      get 'validations/release_readiness', to: 'validations#release_readiness'
      post 'validations/bulk_validate', to: 'validations#bulk_validation'
      get 'validations/rules', to: 'validations#validation_rules'
      post 'validations/attempt_bypass', to: 'validations#attempt_bypass'

      # ===== 既存互換性ルート =====
      get 'cards', to: 'api#kanban_data' # 下位互換
      get 'hierarchy_tree', to: 'hierarchy#hierarchy_tree' # 下位互換
    end
  end

  # グローバルテスト用ルート
  get 'kanban/test', to: 'kanban/api#test_connection'
end
