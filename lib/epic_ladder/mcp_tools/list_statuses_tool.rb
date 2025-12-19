# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # ステータス一覧取得MCPツール
    # プロジェクトのワークフローで使用可能なステータスを一覧取得する
    #
    # @example
    #   ユーザー: 「ステータス一覧を見せて」
    #   AI: ListStatusesToolを呼び出し
    #   結果: ステータス一覧が返却される
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトで使えるステータスは？」
    #   AI: ListStatusesToolをproject_id指定で呼び出し
    #   結果: プロジェクトのワークフローで使用可能なステータスが返却される
    class ListStatusesTool < MCP::Tool
      extend BaseHelper

      description "ステータス一覧を取得します。プロジェクトIDを指定すると、そのプロジェクトのワークフローで使用可能なステータスに絞り込みます（未設定時は全ステータス）。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時は全ステータス）" },
          include_closed: { type: "boolean", description: "クローズ済みステータスを含むか（デフォルト: true）" }
        },
        required: []
      )

      def self.call(project_id: nil, include_closed: true, server_context:)
        Rails.logger.info "ListStatusesTool#call started: project_id=#{project_id || 'ALL'}, include_closed=#{include_closed}"

        begin
          if project_id.present?
            fetch_project_statuses(project_id, include_closed, server_context)
          else
            fetch_all_statuses(include_closed)
          end
        rescue StandardError => e
          Rails.logger.error "ListStatusesTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # 全ステータスを取得
        def fetch_all_statuses(include_closed)
          statuses = IssueStatus.sorted
          statuses = statuses.where(is_closed: false) unless include_closed

          status_list = build_status_list(statuses)

          success_response(
            statuses: status_list,
            total_count: status_list.size,
            source: "all"
          )
        end

        # プロジェクト固有のステータスを取得
        def fetch_project_statuses(project_id, include_closed, server_context)
          # プロジェクト取得と権限チェック
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("プロジェクト閲覧権限がありません", { project: project.identifier })
          end

          # プロジェクトのトラッカーからワークフローで使用されるステータスを取得
          tracker_ids = project.tracker_ids
          workflow_status_ids = WorkflowTransition
            .where(tracker_id: tracker_ids)
            .pluck(:old_status_id, :new_status_id)
            .flatten
            .uniq
            .compact

          # ワークフロー未設定の場合は全ステータスをフォールバック
          if workflow_status_ids.empty?
            statuses = IssueStatus.sorted
            source = "all (workflow not configured)"
          else
            statuses = IssueStatus.where(id: workflow_status_ids).sorted
            source = "workflow"
          end

          statuses = statuses.where(is_closed: false) unless include_closed

          status_list = build_status_list(statuses)

          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            statuses: status_list,
            total_count: status_list.size,
            source: source
          )
        end

        # ステータスリストを構築
        def build_status_list(statuses)
          statuses.map do |status|
            {
              id: status.id.to_s,
              name: status.name,
              is_closed: status.is_closed,
              position: status.position,
              description: status.description
            }
          end
        end
      end
    end
  end
end
