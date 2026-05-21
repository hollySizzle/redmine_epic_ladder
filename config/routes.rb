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

  # 管理者向け Claude Web MCP OAuth application 設定
  get 'admin/epic_ladder/claude_mcp', to: 'epic_ladder/claude_mcp_settings#show', as: 'epic_ladder_claude_mcp_settings'
  post 'admin/epic_ladder/claude_mcp', to: 'epic_ladder/claude_mcp_settings#create'
  patch 'admin/epic_ladder/claude_mcp', to: 'epic_ladder/claude_mcp_settings#update'
  post 'admin/epic_ladder/claude_mcp/recreate', to: 'epic_ladder/claude_mcp_settings#recreate', as: 'epic_ladder_claude_mcp_settings_recreate'
  delete 'admin/epic_ladder/claude_mcp', to: 'epic_ladder/claude_mcp_settings#destroy'
  post 'admin/epic_ladder/claude_mcp/check', to: 'epic_ladder/claude_mcp_settings#check', as: 'epic_ladder_claude_mcp_settings_check'

  # MCPツールヒント設定用
  patch 'projects/:project_id/epic_ladder/mcp_tool_hints', to: 'epic_ladder/mcp_tool_hints#update', as: 'project_epic_ladder_mcp_tool_hints'

  # Version変更クイックアクション
  patch 'epic_ladder/issues/:id/update_version', to: 'epic_ladder/version#update', as: 'epic_ladder_update_version'

  # UserStoryへの昇格クイックアクション
  patch 'epic_ladder/issues/:id/promote_to_user_story', to: 'epic_ladder/promotion#promote_to_user_story', as: 'epic_ladder_promote_to_user_story'

  # ===== MCP Server (Streamable HTTP) =====
  # POST /mcp/rpc - JSON-RPC 2.0エンドポイント
  # OPTIONS /mcp/rpc - CORSプリフライト対応
  # OAuth Discovery: config/initializers/mcp_oauth_rejection.rb で処理
  get '/.well-known/oauth-protected-resource', to: 'mcp/oauth#protected_resource', format: false
  get '/.well-known/oauth-protected-resource/mcp/rpc', to: 'mcp/oauth#protected_resource', format: false
  get '/.well-known/oauth-authorization-server', to: 'mcp/oauth#authorization_server', format: false

  namespace :mcp do
    post '/rpc', to: 'server#handle'
    options '/rpc', to: 'server#options'
  end

  # Claude Web Custom Connector互換:
  # 一部のClaude Web実装がmetadata内の /oauth/* ではなくroot直下を叩くため、
  # Redmine本体のDoorkeeper endpointに収束させる。
  get '/authorize', to: redirect { |_params, request|
    query_params = request.query_parameters.dup
    query_params['scope'] = Mcp::OauthController::MCP_SCOPES.join(' ') if query_params['scope'].blank?
    query = query_params.to_query
    query.present? ? "/oauth/authorize?#{query}" : '/oauth/authorize'
  }
  post '/token', to: 'doorkeeper/tokens#create'
end
