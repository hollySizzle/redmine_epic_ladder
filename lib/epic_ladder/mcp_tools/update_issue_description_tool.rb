# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット説明更新MCPツール
    # チケットのdescriptionを更新する
    #
    # @example
    #   ユーザー: 「Task #9999の説明を更新して」
    #   AI: UpdateIssueDescriptionToolを呼び出し
    #   結果: Task #9999の説明が更新される
    class UpdateIssueDescriptionTool < MCP::Tool
      extend BaseHelper
      description "Updates the description of an issue."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          description: { type: "string", description: "New description text" }
        },
        required: %w[issue_id description]
      )

      def self.call(issue_id:, description:, server_context:)
        Rails.logger.info "UpdateIssueDescriptionTool#call started: issue_id=#{issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 説明更新
          old_description = issue.description
          issue.description = description

          unless issue.save
            return error_response("説明の更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            old_description: old_description,
            new_description: description
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueDescriptionTool error: #{e.class.name}: #{e.message}"
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
