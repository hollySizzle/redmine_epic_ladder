# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCPツール用のプロジェクトバリデーションヘルパー
    # ALLOWED_PROJECTS と DEFAULT_PROJECT の機能を提供
    module ProjectValidator
      module_function

      # プロジェクトIDを解決する
      # @param project_id [String, nil] プロジェクトID（省略可能）
      # @return [String] 解決されたプロジェクトID
      def resolve_project_id(project_id)
        return project_id if project_id.present?

        # DEFAULT_PROJECTを使用
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
