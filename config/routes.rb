# plugins/redmine_epic_grid/config/routes.rb
RedmineApp::Application.routes.draw do
  # MSW準拠のEpic Grid API設計
  # エンドポイント: /api/epic_grid/projects/:projectId/...
  scope 'api/epic_grid/projects/:project_id', defaults: { format: 'json' } do
    # ===== Grid Data API (MSW handlers.ts準拠) =====
    # GET /api/epic_grid/projects/:projectId/grid
    get 'grid', to: 'epic_grid/grid#show'

    # POST /api/epic_grid/projects/:projectId/grid/move_feature
    post 'grid/move_feature', to: 'epic_grid/grid#move_feature'

    # POST /api/epic_grid/projects/:projectId/grid/move_user_story
    post 'grid/move_user_story', to: 'epic_grid/grid#move_user_story'

    # POST /api/epic_grid/projects/:projectId/grid/batch_update
    post 'grid/batch_update', to: 'epic_grid/grid#batch_update'

    # GET /api/epic_grid/projects/:projectId/grid/updates
    get 'grid/updates', to: 'epic_grid/grid#real_time_updates'

    # POST /api/epic_grid/projects/:projectId/grid/reset (テスト用)
    post 'grid/reset', to: 'epic_grid/grid#reset'

    # ===== Epic CRUD API =====
    # POST /api/epic_grid/projects/:projectId/epics
    post 'epics', to: 'epic_grid/grid#create_epic'

    # ===== Version CRUD API =====
    # POST /api/epic_grid/projects/:projectId/versions
    post 'versions', to: 'epic_grid/grid#create_version'

    # ===== Feature Cards API =====
    # POST /api/epic_grid/projects/:projectId/cards
    post 'cards', to: 'epic_grid/cards#create'

    # POST /api/epic_grid/projects/:projectId/cards/:featureId/user_stories
    post 'cards/:feature_id/user_stories', to: 'epic_grid/cards#create_user_story'

    # ===== UserStory子要素 CRUD API =====
    # POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tasks
    post 'cards/user_stories/:user_story_id/tasks', to: 'epic_grid/cards#create_task'

    # POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tests
    post 'cards/user_stories/:user_story_id/tests', to: 'epic_grid/cards#create_test'

    # POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/bugs
    post 'cards/user_stories/:user_story_id/bugs', to: 'epic_grid/cards#create_bug'
  end

  # メインEpic Grid画面
  get 'projects/:project_id/epic_grid', to: 'epic_grid#index', as: 'project_epic_grid'

  # プロジェクト設定タブ用（Epic Gridタブからのフォーム送信）
  patch 'projects/:project_id/epic_grid/settings', to: 'epic_grid/project_settings#update', as: 'project_epic_grid_settings'

  # MCPツールヒント設定用
  patch 'projects/:project_id/epic_grid/mcp_tool_hints', to: 'epic_grid/mcp_tool_hints#update', as: 'project_epic_grid_mcp_tool_hints'

  # Version変更クイックアクション
  patch 'epic_grid/issues/:id/update_version', to: 'epic_grid/version#update', as: 'epic_grid_update_version'

  # ===== MCP Server (Streamable HTTP) =====
  # POST /mcp/rpc - JSON-RPC 2.0エンドポイント
  # OPTIONS /mcp/rpc - CORSプリフライト対応
  # OAuth Discovery: config/initializers/mcp_oauth_rejection.rb で処理
  namespace :mcp do
    post '/rpc', to: 'server#handle'
    options '/rpc', to: 'server#options'
  end
end
