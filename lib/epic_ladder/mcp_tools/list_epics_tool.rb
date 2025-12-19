# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # Epic一覧取得MCPツール
    # プロジェクト内のEpicを一覧取得する
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトのEpic一覧を見せて」
    #   AI: ListEpicsToolを呼び出し
    #   結果: Epic一覧が返却される
    class ListEpicsTool < MCP::Tool
      extend BaseHelper

      description "Lists Epic issues in a project. Can filter by assignee and status."

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          assigned_to_id: { type: "string", description: "Filter by assignee ID (optional)" },
          status: { type: "string", description: "Filter by status (open/closed, optional)" },
          limit: { type: "number", description: "Max results (default: 50)" }
        },
        required: []
      )

      def self.call(project_id: nil, assigned_to_id: nil, status: nil, limit: 50, server_context:)
        Rails.logger.info "ListEpicsTool#call started: project_id=#{project_id || 'DEFAULT'}"

        begin
          # プロジェクト取得と権限チェック（server_contextからX-Default-Projectヘッダー値を参照）
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("チケット閲覧権限がありません", { project: project.identifier })
          end

          # Epicトラッカー取得
          epic_tracker = find_tracker(:epic)
          return error_response("Epicトラッカーが設定されていません") unless epic_tracker

          # Epic一覧取得
          epics = project.issues.where(tracker: epic_tracker)
          epics = epics.where(assigned_to_id: assigned_to_id) if assigned_to_id.present?

          # ステータスフィルタ
          if status.present?
            if status.downcase == 'open'
              epics = epics.where(status: IssueStatus.where(is_closed: false))
            elsif status.downcase == 'closed'
              epics = epics.where(status: IssueStatus.where(is_closed: true))
            end
          end

          # 件数制限
          epics = epics.limit(limit) if limit

          # Epic情報構築
          epic_list = epics.map do |epic|
            {
              id: epic.id.to_s,
              subject: epic.subject,
              description: epic.description,
              status: {
                name: epic.status.name,
                is_closed: epic.status.is_closed
              },
              assigned_to: epic.assigned_to ? {
                id: epic.assigned_to.id.to_s,
                name: epic.assigned_to.name
              } : nil,
              url: issue_url(epic.id)
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            epics: epic_list,
            total_count: epic_list.size
          )
        rescue StandardError => e
          Rails.logger.error "ListEpicsTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
      end
    end
  end
end
