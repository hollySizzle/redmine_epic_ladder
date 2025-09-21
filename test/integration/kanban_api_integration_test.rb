# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class KanbanApiIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :trackers

  def setup
    @project = projects(:projects_001)
    @user = users(:users_002)  # Normal user with permissions
    @admin = users(:users_001)  # Admin user
  end

  def test_kanban_data_endpoint_returns_200_for_authorized_user
    # ログイン
    log_user(@user.login, 'admin')

    # カンバンデータ取得API呼び出し
    get "/kanban/projects/#{@project.id}/cards"

    # レスポンス確認（404ではなく200が返ることを確認）
    assert_response :success, "Expected 200 OK but got #{response.status}"

    # JSONレスポンス確認
    json = JSON.parse(response.body)
    assert json.key?('project'), 'Response should contain project data'
    assert json.key?('columns'), 'Response should contain columns data'
    assert json.key?('issues'), 'Response should contain issues data'

    # プロジェクト情報確認
    assert_equal @project.id, json['project']['id']
    assert_equal @project.name, json['project']['name']
  end

  def test_kanban_data_endpoint_requires_authentication
    # 未ログイン状態でAPIアクセス
    get "/kanban/projects/#{@project.id}/cards"

    # 認証エラーまたはリダイレクトが発生することを確認
    assert_response :unauthorized, "Unauthenticated access should be rejected"
  end

  def test_test_connection_endpoint_works
    # ログイン
    log_user(@admin.login, 'admin')

    # 接続テストAPI呼び出し
    get "/kanban/projects/#{@project.id}/test_connection"

    # レスポンス確認
    assert_response :success

    # JSONレスポンス確認
    json = JSON.parse(response.body)
    assert_equal 'ok', json['status']
    assert json.key?('timestamp')
  end

  def test_transition_issue_endpoint_exists_but_not_implemented
    # ログイン
    log_user(@admin.login, 'admin')

    # イシュー状態遷移API呼び出し
    post "/kanban/projects/#{@project.id}/transition_issue",
         params: { issue_id: 1, target_column: 'in_progress' },
         headers: { 'Content-Type' => 'application/json' }

    # エンドポイントは存在するがまだ未実装として501 Not Implementedかエラーが返る
    assert_response :unprocessable_entity

    # または実装されている場合は :success または :not_found
    # assert_includes [:success, :not_found, :unprocessable_entity], response.status
  end

  def test_generate_test_endpoint_exists_but_not_implemented
    # ログイン
    log_user(@admin.login, 'admin')

    # Test自動生成API呼び出し
    post "/kanban/projects/#{@project.id}/generate_test",
         params: { user_story_id: 1 },
         headers: { 'Content-Type' => 'application/json' }

    # エンドポイントは存在することを確認（404でないこと）
    assert_not_equal 404, response.status, 'Generate test endpoint should exist'

    # 未実装または正常実装のいずれかを許可
    assert_includes [200, 422, 501], response.status,
                    "Expected success, unprocessable_entity, or not_implemented but got #{response.status}"
  end

  def test_validate_release_endpoint_exists
    # ログイン
    log_user(@admin.login, 'admin')

    # リリース検証API呼び出し
    get "/kanban/projects/#{@project.id}/validate_release?user_story_id=1"

    # エンドポイントは存在することを確認（404でないこと）
    assert_not_equal 404, response.status, 'Validate release endpoint should exist'
  end

  def test_api_endpoints_return_json_content_type
    # ログイン
    log_user(@admin.login, 'admin')

    # カンバンデータAPI
    get "/kanban/projects/#{@project.id}/cards"
    assert_equal 'application/json', response.content_type.split(';').first

    # 接続テストAPI
    get "/kanban/projects/#{@project.id}/test_connection"
    assert_equal 'application/json', response.content_type.split(';').first
  end

  private

  def log_user(login, password)
    User.current = nil
    post '/login', params: { username: login, password: password }
    assert_equal login, User.find(session[:user_id]).login
  end
end