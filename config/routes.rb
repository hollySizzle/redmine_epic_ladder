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
  resources :projects do
    get 'epic_grid', to: 'epic_grid#index'
  end
end
