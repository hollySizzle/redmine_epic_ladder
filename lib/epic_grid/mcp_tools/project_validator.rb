# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCPツール用のプロジェクトバリデーションヘルパー
    # ALLOWED_PROJECTS と DEFAULT_PROJECT の機能を提供
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
      #   3. ENV['DEFAULT_PROJECT'] (サーバー側環境変数)
      def resolve_project_id(project_id, server_context: nil)
        return project_id if project_id.present?

        # X-Default-Projectヘッダーから取得（.mcp.jsonで設定可能）
        if server_context.is_a?(Hash) && server_context[:default_project].present?
          return server_context[:default_project]
        end

        # フォールバック: サーバー側環境変数
        default_project = ENV.fetch('DEFAULT_PROJECT', nil)
        return default_project if default_project.present?

        nil
      end

      # プロジェクトがALLOWED_PROJECTSに含まれているかチェック
      # @param project_id [String] プロジェクトID（識別子または数値ID）
      # @param project [Project] Projectオブジェクト
      # @return [Boolean] 許可されている場合true
      def project_allowed?(project_id, project)
        allowed_projects_str = ENV.fetch('ALLOWED_PROJECTS', '')

        # ALLOWED_PROJECTSが空の場合はすべて許可
        return true if allowed_projects_str.blank?

        allowed_projects = allowed_projects_str.split(',').map(&:strip)

        # プロジェクトIDまたは識別子で照合
        allowed_projects.include?(project_id.to_s) ||
          allowed_projects.include?(project.id.to_s) ||
          allowed_projects.include?(project.identifier)
      end

      # プロジェクトバリデーションエラーレスポンス生成
      # @param project_id [String] プロジェクトID
      # @param allowed_projects [String] 許可されているプロジェクトリスト
      # @return [MCP::Tool::Response] エラーレスポンス
      def project_not_allowed_response(project_id, allowed_projects)
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: "プロジェクト '#{project_id}' へのアクセスが許可されていません",
            details: {
              project_id: project_id,
              allowed_projects: allowed_projects.split(',').map(&:strip)
            }
          })
        }])
      end
    end
  end
end
