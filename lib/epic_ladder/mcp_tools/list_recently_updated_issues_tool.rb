# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # 最近更新されたチケット一覧取得MCPツール
    # プロジェクト内のチケットを更新日時降順で取得する
    #
    # @example
    #   ユーザー: 「最近更新されたチケットを見せて」
    #   AI: ListRecentlyUpdatedIssuesTool を呼び出し
    #   結果: 更新日時降順でチケット一覧が返却される
    class ListRecentlyUpdatedIssuesTool < MCP::Tool
      extend BaseHelper

      description "Lists recently updated issues in a project, sorted by update time (newest first). Useful for tracking recent activity."

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          limit: { type: "number", description: "Max results (default: 20, max: 50)" }
        },
        required: []
      )

      def self.call(project_id: nil, limit: 20, server_context:)
        Rails.logger.info "ListRecentlyUpdatedIssuesTool#call started: project_id=#{project_id || 'DEFAULT'}"

        begin
          # プロジェクト取得と権限チェック
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("チケット閲覧権限がありません", { project: project.identifier })
          end

          # limit制限（1〜50）
          limit = [[limit.to_i, 1].max, 50].min

          # 更新日時降順でチケット取得
          issues = project.issues.order(updated_on: :desc).limit(limit)

          # レスポンス構築（軽量）
          issues_list = issues.map do |issue|
            {
              id: issue.id.to_s,
              subject: issue.subject,
              tracker: issue.tracker.name,
              status: issue.status.name,
              updated_on: issue.updated_on.iso8601,
              assigned_to: issue.assigned_to&.name
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            issues: issues_list,
            total_count: issues_list.size
          )
        rescue StandardError => e
          Rails.logger.error "ListRecentlyUpdatedIssuesTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end
    end
  end
end
