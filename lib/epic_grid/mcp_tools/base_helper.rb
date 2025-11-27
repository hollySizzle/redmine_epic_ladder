# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCP Tools共通ヘルパーモジュール
    # すべてのMCPツールで使用される共通ヘルパーメソッドを提供
    module BaseHelper
      # プロジェクトIDを解決する
      # @param project_id [String, nil] プロジェクトID（省略可能）
      # @param server_context [Hash, nil] サーバーコンテキスト（X-Default-Projectヘッダー値を含む）
      # @return [String, nil] 解決されたプロジェクトID
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

      # プロジェクト取得（識別子 or ID）with DEFAULT_PROJECT フォールバック
      # @param project_id [String, nil] プロジェクトID（省略時はDEFAULT_PROJECT）
      # @return [Project, nil] Projectオブジェクト
      def find_project(project_id)
        resolved_id = resolve_project_id(project_id)
        return nil unless resolved_id

        if resolved_id.to_i.to_s == resolved_id.to_s
          Project.find_by(id: resolved_id.to_i)
        else
          Project.find_by(identifier: resolved_id) || Project.find_by(id: resolved_id.to_i)
        end
      end

      # プロジェクトでMCPが許可されているかチェック
      # プロジェクト設定のmcp_enabledを参照
      # @param project [Project] Projectオブジェクト
      # @return [Boolean] 許可されている場合true
      def project_allowed?(project)
        EpicGrid::ProjectSetting.mcp_enabled?(project)
      end

      # プロジェクト取得と権限チェックを一括で行う
      # @param project_id [String, nil] プロジェクトID（省略時はDEFAULT_PROJECT）
      # @param server_context [Hash, nil] サーバーコンテキスト（X-Default-Projectヘッダー値を含む）
      # @return [Hash] { project: Project, error: String/nil }
      def resolve_and_validate_project(project_id, server_context: nil)
        resolved_id = resolve_project_id(project_id, server_context: server_context)

        unless resolved_id
          return {
            project: nil,
            error: "プロジェクトIDが指定されていません。DEFAULT_PROJECTを設定するか、project_idを指定してください"
          }
        end

        project = find_project(resolved_id)
        unless project
          return {
            project: nil,
            error: "プロジェクトが見つかりません: #{resolved_id}"
          }
        end

        unless project_allowed?(project)
          return {
            project: nil,
            error: "プロジェクト '#{project.identifier}' でMCP APIが許可されていません",
            details: { hint: "プロジェクト設定 → Epic Grid タブでMCP APIを有効にしてください" }
          }
        end

        { project: project, error: nil }
      end

      # トラッカー取得ヘルパー（projectなし版）
      def find_tracker(tracker_type)
        tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
        Tracker.find_by(name: tracker_name)
      end

      # トラッカー取得ヘルパー（project検証あり版）
      def find_tracker_for_project(tracker_type, project)
        tracker = find_tracker(tracker_type)
        return nil unless tracker
        return nil unless project.trackers.include?(tracker)
        tracker
      end

      # エラーレスポンス生成
      def error_response(message, details = {})
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: message,
            details: details
          })
        }])
      end

      # 成功レスポンス生成
      def success_response(data = {})
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: true
          }.merge(data))
        }])
      end
    end
  end
end
