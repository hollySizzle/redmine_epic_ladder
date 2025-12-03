# plugins/redmine_epic_ladder/config/routes.rb
RedmineApp::Application.routes.draw do
  # MSW準拠のEpic Ladder API設計
  # エンドポイント: /api/epic_ladder/projects/:projectId/...
  scope 'api/epic_ladder/projects/:project_id', defaults: { format: 'json' } do
    # ===== Grid Data API (MSW handlers.ts準拠) =====
    # GET /api/epic_ladder/projects/:projectId/grid
    get 'grid', to: 'epic_ladder/grid#show'

    # POST /api/epic_ladder/projects/:projectId/grid/move_feature
    post 'grid/move_feature', to: 'epic_ladder/grid#move_feature'

    # POST /api/epic_ladder/projects/:projectId/grid/move_user_story
    post 'grid/move_user_story', to: 'epic_ladder/grid#move_user_story'

    # POST /api/epic_ladder/projects/:projectId/grid/batch_update
    post 'grid/batch_update', to: 'epic_ladder/grid#batch_update'

    # GET /api/epic_ladder/projects/:projectId/grid/updates
    get 'grid/updates', to: 'epic_ladder/grid#real_time_updates'

    # POST /api/epic_ladder/projects/:projectId/grid/reset (テスト用)
    post 'grid/reset', to: 'epic_ladder/grid#reset'

    # ===== Epic CRUD API =====
    # POST /api/epic_ladder/projects/:projectId/epics
    post 'epics', to: 'epic_ladder/grid#create_epic'

    # ===== Version CRUD API =====
    # POST /api/epic_ladder/projects/:projectId/versions
    post 'versions', to: 'epic_ladder/grid#create_version'

    # ===== Feature Cards API =====
    # POST /api/epic_ladder/projects/:projectId/cards
    post 'cards', to: 'epic_ladder/cards#create'

    # POST /api/epic_ladder/projects/:projectId/cards/:featureId/user_stories
    post 'cards/:feature_id/user_stories', to: 'epic_ladder/cards#create_user_story'

    # ===== UserStory子要素 CRUD API =====
    # POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/tasks
    post 'cards/user_stories/:user_story_id/tasks', to: 'epic_ladder/cards#create_task'

    # POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/tests
    post 'cards/user_stories/:user_story_id/tests', to: 'epic_ladder/cards#create_test'

    # POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/bugs
    post 'cards/user_stories/:user_story_id/bugs', to: 'epic_ladder/cards#create_bug'
  end

  # メインEpic Ladder画面
  get 'projects/:project_id/epic_ladder', to: 'epic_ladder#index', as: 'project_epic_ladder'

  # プロジェクト設定タブ用（Epic Ladderタブからのフォーム送信）
  patch 'projects/:project_id/epic_ladder/settings', to: 'epic_ladder/project_settings#update', as: 'project_epic_ladder_settings'

  # MCPツールヒント設定用
  patch 'projects/:project_id/epic_ladder/mcp_tool_hints', to: 'epic_ladder/mcp_tool_hints#update', as: 'project_epic_ladder_mcp_tool_hints'

  # Version変更クイックアクション
  patch 'epic_ladder/issues/:id/update_version', to: 'epic_ladder/version#update', as: 'epic_ladder_update_version'

  # ===== MCP Server (Streamable HTTP) =====
  # POST /mcp/rpc - JSON-RPC 2.0エンドポイント
  # OPTIONS /mcp/rpc - CORSプリフライト対応
  # OAuth Discovery: config/initializers/mcp_oauth_rejection.rb で処理
  namespace :mcp do
    post '/rpc', to: 'server#handle'
    options '/rpc', to: 'server#options'
  end
end
