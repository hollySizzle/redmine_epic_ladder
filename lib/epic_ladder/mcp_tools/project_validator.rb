# frozen_string_literal: true

module EpicLadder
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
        settings = Setting.plugin_redmine_epic_ladder || {}
        settings['mcp_enabled'] == '1'
      end

      def project_creation_enabled?
        settings = Setting.plugin_redmine_epic_ladder || {}
        settings['mcp_project_creation_enabled'] == '1'
      end

      def project_creation_scope
        settings = Setting.plugin_redmine_epic_ladder || {}
        scope = settings['mcp_project_creation_scope'].presence || 'disabled'
        %w[disabled allowed_parents_only redmine_permissions].include?(scope) ? scope : 'disabled'
      end

      def project_creation_allowed_parent_ids
        settings = Setting.plugin_redmine_epic_ladder || {}
        raw_value = settings['mcp_project_creation_allowed_parent_ids']
        Array(raw_value).flat_map { |value| value.to_s.split(',') }.map(&:strip).reject(&:blank?).map(&:to_i).uniq
      end

      def project_creation_allow_root?
        settings = Setting.plugin_redmine_epic_ladder || {}
        settings['mcp_project_creation_allow_root'] == '1'
      end

      def project_creation_allowed_parent?(parent_project, user)
        return false unless mcp_enabled?
        return false unless project_creation_enabled?

        scope = project_creation_scope
        return false if scope == 'disabled'

        if parent_project.nil?
          return false unless project_creation_allow_root?

          return user.allowed_to?(:add_project, nil, global: true)
        end

        return false unless user.allowed_to?(:add_subprojects, parent_project)

        case scope
        when 'allowed_parents_only'
          project_creation_allowed_parent_ids.include?(parent_project.id)
        when 'redmine_permissions'
          true
        else
          false
        end
      end

      def project_creation_disabled_response
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: "MCP経由のプロジェクト作成が無効です。管理画面で許可範囲を設定してください。"
          })
        }])
      end

      # プロジェクトでMCPが許可されているかチェック
      # @param project [Project] Projectオブジェクト
      # @return [Boolean] 許可されている場合true
      def project_allowed?(project)
        EpicLadder::ProjectSetting.mcp_enabled?(project)
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
              hint: "プロジェクト設定 → Epic Ladder タブでMCP APIを有効にしてください"
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
