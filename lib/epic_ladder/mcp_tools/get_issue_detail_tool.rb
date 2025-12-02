# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット詳細取得MCPツール
    # チケットの詳細情報、コメント（Journal）、子チケットを取得する
    #
    # @example
    #   ユーザー: 「UserStory #123の詳細とコメントを見せて」
    #   AI: GetIssueDetailToolを呼び出し
    #   結果: チケット詳細+コメント+子チケット情報が返却される
    class GetIssueDetailTool < MCP::Tool
      extend BaseHelper
      description "チケットの詳細情報、コメント（更新履歴）、子チケットを取得します。"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "チケットID" }
        },
        required: ["issue_id"]
      )

      def self.call(issue_id:, server_context:)
        Rails.logger.info "GetIssueDetailTool#call started: issue_id=#{issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, issue.project)
            return error_response("チケット閲覧権限がありません", { project: issue.project.identifier })
          end

          # チケット詳細情報を構築
          issue_data = build_issue_data(issue)

          # Journals（コメント・更新履歴）を取得
          journals_data = build_journals_data(issue)

          # 子チケットを取得
          children_data = build_children_data(issue)

          # 成功レスポンス
          success_response(
            issue: issue_data,
            journals: journals_data,
            journals_count: journals_data.size,
            children: children_data,
            children_count: children_data.size
          )
        rescue StandardError => e
          Rails.logger.error "GetIssueDetailTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # チケット詳細データを構築
        def build_issue_data(issue)
          {
            id: issue.id.to_s,
            subject: issue.subject,
            description: issue.description,
            tracker: {
              id: issue.tracker.id.to_s,
              name: issue.tracker.name
            },
            status: {
              id: issue.status.id.to_s,
              name: issue.status.name,
              is_closed: issue.status.is_closed
            },
            priority: {
              id: issue.priority.id.to_s,
              name: issue.priority.name
            },
            author: {
              id: issue.author.id.to_s,
              name: issue.author.name
            },
            assigned_to: issue.assigned_to ? {
              id: issue.assigned_to.id.to_s,
              name: issue.assigned_to.name
            } : nil,
            fixed_version: issue.fixed_version ? {
              id: issue.fixed_version.id.to_s,
              name: issue.fixed_version.name,
              status: issue.fixed_version.status,
              effective_date: issue.fixed_version.effective_date&.to_s
            } : nil,
            parent: issue.parent ? {
              id: issue.parent.id.to_s,
              subject: issue.parent.subject
            } : nil,
            created_on: issue.created_on.iso8601,
            updated_on: issue.updated_on.iso8601,
            start_date: issue.start_date&.to_s,
            due_date: issue.due_date&.to_s,
            estimated_hours: issue.estimated_hours,
            done_ratio: issue.done_ratio,
            url: issue_url(issue.id)
          }.compact
        end

        # Journals（コメント・更新履歴）データを構築
        def build_journals_data(issue)
          issue.journals.order(created_on: :asc).map do |journal|
            {
              id: journal.id.to_s,
              user: {
                id: journal.user.id.to_s,
                name: journal.user.name
              },
              created_on: journal.created_on.iso8601,
              notes: journal.notes,
              details: journal.details.map do |detail|
                {
                  property: detail.property,
                  name: detail.prop_key,
                  old_value: detail.old_value,
                  new_value: detail.value
                }
              end
            }
          end
        end

        # 子チケットデータを構築
        def build_children_data(issue)
          issue.children.map do |child|
            {
              id: child.id.to_s,
              subject: child.subject,
              tracker: child.tracker.name,
              status: child.status.name,
              assigned_to: child.assigned_to&.name,
              done_ratio: child.done_ratio,
              url: issue_url(child.id)
            }
          end
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end      end
    end
  end
end
