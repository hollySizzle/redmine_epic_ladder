# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット担当者変更MCPツール
    # チケットの担当者を変更する
    #
    # @example
    #   ユーザー: 「Task #9999の担当者を田中さん（ID:5）にして」
    #   AI: UpdateIssueAssigneeToolを呼び出し
    #   結果: Task #9999の担当者が田中さんになる
    class UpdateIssueAssigneeTool < MCP::Tool
      extend BaseHelper
      description "Changes the assignee of an issue."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          assigned_to_id: { type: "string", description: "Assignee user ID (null to unassign)" }
        },
        required: ["issue_id", "assigned_to_id"]
      )

      def self.call(issue_id:, assigned_to_id:, server_context:)
        Rails.logger.info "UpdateIssueAssigneeTool#call started: issue_id=#{issue_id}, assigned_to_id=#{assigned_to_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 担当者取得
          old_assignee = issue.assigned_to
          new_assignee = nil

          if assigned_to_id.present? && assigned_to_id != "null"
            new_assignee = User.find_by(id: assigned_to_id)
            return error_response("担当者が見つかりません: #{assigned_to_id}") unless new_assignee

            # プロジェクトメンバーチェック
            unless new_assignee.allowed_to?(:view_issues, issue.project)
              return error_response("指定されたユーザーはプロジェクトメンバーではありません", { user_id: assigned_to_id })
            end
          end

          # 担当者更新
          issue.assigned_to = new_assignee

          unless issue.save
            return error_response("担当者変更に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            old_assignee: old_assignee ? {
              id: old_assignee.id.to_s,
              name: old_assignee.name,
              login: old_assignee.login
            } : nil,
            new_assignee: new_assignee ? {
              id: new_assignee.id.to_s,
              name: new_assignee.name,
              login: new_assignee.login
            } : nil
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueAssigneeTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end      end
    end
  end
end
