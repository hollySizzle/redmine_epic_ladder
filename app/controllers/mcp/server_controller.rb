# frozen_string_literal: true

module Mcp
  # MCP Server Controller (Streamable HTTP Transport)
  # Claude Desktop等からJSON-RPC 2.0リクエストを受信し、MCP::Serverに委譲する
  #
  # 認証方式: Redmine APIキー認証（X-Redmine-API-Keyヘッダー）
  # エンドポイント:
  #   POST /mcp/rpc - JSON-RPC 2.0リクエスト処理
  #   OPTIONS /mcp/rpc - CORSプリフライト対応
  class ServerController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :check_if_login_required
    before_action :set_cors_headers
    before_action :authenticate_api_user, except: [:options]

    # OPTIONS /mcp/rpc - CORSプリフライトリクエスト対応
    def options
      head :ok
    end

    # POST /mcp/rpc - JSON-RPC 2.0リクエスト処理
    def handle
      # JSON-RPC 2.0リクエストを受信
      rpc_request = request.body.read
      Rails.logger.info "MCP RPC Request: #{rpc_request}"

      # リクエストIDを事前にパース（エラーハンドリング用）
      @request_id = parse_request_id(rpc_request)

      # MCP::Serverでリクエスト処理
      response_json = mcp_server.handle_json(rpc_request)
      Rails.logger.info "MCP RPC Response: #{response_json}"

      # Notificationリクエスト（idがnil）の場合はレスポンスを返さない（MCP仕様）
      if @request_id.nil?
        head :no_content
        return
      end

      # レスポンス返却（既にJSON文字列なのでそのまま返す）
      render json: JSON.parse(response_json), status: :ok
    rescue StandardError => e
      # JSON-RPC 2.0エラーレスポンス形式
      Rails.logger.error "MCP RPC Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32603, # Internal error
          message: e.message,
          data: {
            error_id: request.uuid,
            timestamp: Time.current.iso8601
          }
        },
        id: @request_id
      }, status: :internal_server_error
    end

    private

    # CORS ヘッダー設定
    def set_cors_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Redmine-API-Key'
      response.headers['Access-Control-Max-Age'] = '86400' # 24時間
    end

    # Redmine APIキー認証
    def authenticate_api_user
      api_key = request.headers['X-Redmine-API-Key'] || params[:key]

      if api_key.blank?
        render_auth_error('APIキーが必要です')
        return false
      end

      user = User.find_by_api_key(api_key)

      unless user&.active?
        render_auth_error('無効なAPIキーです')
        return false
      end

      User.current = user
      Rails.logger.info "MCP authenticated: user=#{user.login} (id=#{user.id})"
      true
    rescue StandardError => e
      Rails.logger.error "MCP authentication error: #{e.message}"
      render_auth_error('認証エラー')
      false
    end

    # 認証エラーレスポンス
    def render_auth_error(message)
      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32001, # カスタムエラーコード: Unauthorized
          message: message
        },
        id: nil
      }, status: :unauthorized
    end

    # MCP::Serverインスタンス生成（Statelessモード）
    def mcp_server
      @mcp_server ||= MCP::Server.new(
        name: "redmine_epic_grid",
        version: "1.0.0",
        tools: [
          # カテゴリ1: チケット作成ツール
          EpicGrid::McpTools::CreateEpicTool,
          EpicGrid::McpTools::CreateFeatureTool,
          EpicGrid::McpTools::CreateUserStoryTool,
          EpicGrid::McpTools::CreateTaskTool,
          EpicGrid::McpTools::CreateBugTool,
          EpicGrid::McpTools::CreateTestTool,
          # カテゴリ2: Version管理ツール
          EpicGrid::McpTools::CreateVersionTool,
          EpicGrid::McpTools::AssignToVersionTool,
          EpicGrid::McpTools::MoveToNextVersionTool,
          # カテゴリ3: チケット操作ツール
          EpicGrid::McpTools::UpdateIssueStatusTool,
          EpicGrid::McpTools::AddIssueCommentTool,
          EpicGrid::McpTools::UpdateIssueProgressTool,
          EpicGrid::McpTools::UpdateIssueAssigneeTool,
          # カテゴリ4: 検索・参照ツール
          EpicGrid::McpTools::ListUserStoriesTool,
          EpicGrid::McpTools::ListEpicsTool,
          EpicGrid::McpTools::GetProjectStructureTool
        ],
        server_context: {
          user: User.current
        }
      )
    end

    # リクエストIDをパース（エラーレスポンス用）
    def parse_request_id(rpc_request)
      return nil if rpc_request.blank?

      parsed = JSON.parse(rpc_request)
      parsed["id"]
    rescue StandardError
      nil
    end
  end
end
