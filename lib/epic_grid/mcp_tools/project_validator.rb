# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCPツール用のプロジェクトバリデーションヘルパー
    # グローバルMCP有効/無効 + プロジェクト単位のMCP許可設定をチェック
    module ProjectValidator
      module_function

      # プロジェクトIDを解決する
      # @param project_id [String, nil] プロジェクトID（省略可能）
      # @param server_context [Hash, nil] サーバーコンテキスト（X-Default-Projectヘッダー値を含む）
      # @return [String] 解決されたプロジェクトID
      #
      # 優先順位:
      #   1. 明示的に指定されたproject_id
      #   2. server_context[:default_project] (X-Default-Projectヘッダーから)
      def resolve_project_id(project_id, server_context: nil)
        return project_id if project_id.present?

        # X-Default-Projectヘッダーから取得（.mcp.jsonで設定可能）
        if server_context.is_a?(Hash) && server_context[:default_project].present?
          return server_context[:default_project]
        end

        nil
      end

      # MCP APIがグローバルで有効かどうかチェック
      # @return [Boolean] MCP APIが有効な場合true
      def mcp_enabled?
        settings = Setting.plugin_redmine_epic_grid || {}
        settings['mcp_enabled'] == '1'
      end

      # プロジェクトでMCPが許可されているかチェック
      # @param project [Project] Projectオブジェクト
      # @return [Boolean] 許可されている場合true
      def project_allowed?(project)
        EpicGrid::ProjectSetting.mcp_enabled?(project)
      end

      # プロジェクトバリデーションエラーレスポンス生成
      # @param project [Project] プロジェクト
      # @return [MCP::Tool::Response] エラーレスポンス
      def project_not_allowed_response(project)
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: "プロジェクト '#{project.identifier}' でMCP APIが許可されていません",
            details: {
              project_id: project.identifier,
              hint: "プロジェクト設定 → Epic Grid タブでMCP APIを有効にしてください"
            }
          })
        }])
      end

      # MCP無効エラーレスポンス生成
      # @return [MCP::Tool::Response] エラーレスポンス
      def mcp_disabled_response
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: "MCP APIが無効になっています。管理画面でMCP APIを有効にしてください。"
          })
        }])
      end
    end
  end
end
