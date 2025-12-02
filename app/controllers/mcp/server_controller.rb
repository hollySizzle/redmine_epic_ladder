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
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Redmine-API-Key, X-Default-Project'
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
      @mcp_server ||= begin
        server = MCP::Server.new(
          name: "redmine_epic_ladder",
          version: "1.0.0",
          tools: all_mcp_tools,
          server_context: {
            user: User.current,
            default_project: extract_default_project_from_header
          }
        )

        # tools/list ハンドラをカスタマイズしてプロジェクト固有ヒントを注入
        project = default_project_for_hints
        server.tools_list_handler do |_request|
          all_mcp_tools.map do |tool_class|
            tool_hash = tool_class.to_h
            tool_hash[:description] = build_description_with_hint(tool_class, project)
            tool_hash
          end
        end

        server
      end
    end

    # 全MCPツールクラス一覧
    def all_mcp_tools
      [
        # カテゴリ1: チケット作成ツール
        EpicLadder::McpTools::CreateEpicTool,
        EpicLadder::McpTools::CreateFeatureTool,
        EpicLadder::McpTools::CreateUserStoryTool,
        EpicLadder::McpTools::CreateTaskTool,
        EpicLadder::McpTools::CreateBugTool,
        EpicLadder::McpTools::CreateTestTool,
        # カテゴリ2: Version管理ツール
        EpicLadder::McpTools::CreateVersionTool,
        EpicLadder::McpTools::AssignToVersionTool,
        EpicLadder::McpTools::MoveToNextVersionTool,
        EpicLadder::McpTools::ListVersionsTool,
        # カテゴリ3: チケット操作ツール
        EpicLadder::McpTools::UpdateIssueStatusTool,
        EpicLadder::McpTools::AddIssueCommentTool,
        EpicLadder::McpTools::UpdateIssueProgressTool,
        EpicLadder::McpTools::UpdateIssueAssigneeTool,
        # カテゴリ4: 検索・参照ツール
        EpicLadder::McpTools::ListUserStoriesTool,
        EpicLadder::McpTools::ListEpicsTool,
        EpicLadder::McpTools::GetProjectStructureTool,
        EpicLadder::McpTools::GetIssueDetailTool
      ]
    end

    # X-Default-Projectヘッダーからプロジェクトを取得（ヒント用）
    def default_project_for_hints
      project_identifier = extract_default_project_from_header
      return nil if project_identifier.blank?

      Project.find_by(identifier: project_identifier) || Project.find_by(id: project_identifier)
    end

    # ツールのdescriptionにプロジェクト固有ヒントを付与
    def build_description_with_hint(tool_class, project)
      base_description = tool_class.description_value || ''
      return base_description if project.nil?

      # ツールクラス名からtool_keyを抽出（例: CreateTaskTool → create_task）
      tool_key = tool_class.name.demodulize.underscore.sub(/_tool$/, '')

      EpicLadder::McpToolHint.build_description(project, tool_key, base_description)
    end

    # X-Default-Projectヘッダーからデフォルトプロジェクトを取得
    # .mcp.jsonのheadersセクションで指定された値をサーバー側で利用可能にする
    def extract_default_project_from_header
      request.headers['X-Default-Project'].presence
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
