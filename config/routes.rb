# plugins/redmine_release_kanban/config/routes.rb
RedmineApp::Application.routes.draw do
  resources :projects do
    # メインカンバンルート
    get 'kanban', to: 'kanban#index'

    # API ルート
    scope 'kanban' do
      # カードデータ取得
      get 'cards', to: 'kanban/cards#index'

      # 階層構造データ
      get 'hierarchy_tree', to: 'kanban/hierarchy#hierarchy_tree'

      # 状態遷移
      post 'move_card', to: 'kanban/state_transitions#move_card'
      post 'bulk_move_cards', to: 'kanban/state_transitions#bulk_move_cards'
      get 'transition_preview', to: 'kanban/state_transitions#transition_preview'

      # バージョン管理
      post 'assign_version', to: 'kanban/versions#assign_version'
      post 'bulk_assign_version', to: 'kanban/versions#bulk_assign_version'
      post 'versions', to: 'kanban/versions#create_version'
      get 'version_assignment_preview', to: 'kanban/versions#version_assignment_preview'

      # 自動生成
      post 'generate_test', to: 'kanban/auto_generation#generate_test'
      post 'batch_generate_tests', to: 'kanban/auto_generation#batch_generate_tests'
      get 'auto_generation_status', to: 'kanban/auto_generation#auto_generation_status'

      # 検証・ガード
      get 'release_validation', to: 'kanban/validations#release_validation'
      post 'bulk_validation', to: 'kanban/validations#bulk_validation'
      get 'validation_rules', to: 'kanban/validations#validation_rules'

      # 階層検証
      get 'validate_hierarchy', to: 'kanban/hierarchy#validate_hierarchy'
    end
  end
end
