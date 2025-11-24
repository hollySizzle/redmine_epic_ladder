# frozen_string_literal: true
require_relative 'base_helper'

module EpicGrid
  module McpTools
    # チケットコメント追加MCPツール
    # チケットにコメント（ノート）を追加する
    #
    # @example
    #   ユーザー: 「Task #9999にコメント追加: 実装完了、レビュー待ち」
    #   AI: AddIssueCommentToolを呼び出し
    #   結果: Task #9999にコメントが追加される
    class AddIssueCommentTool < MCP::Tool
      extend BaseHelper
      description "チケットにコメント（ノート）を追加します。"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "チケットID" },
          comment: { type: "string", description: "コメント内容" }
        },
        required: ["issue_id", "comment"]
      )

      def self.call(issue_id:, comment:, server_context:)
        Rails.logger.info "AddIssueCommentTool#call started: issue_id=#{issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:add_issue_notes, issue.project)
            return error_response("コメント追加権限がありません", { project: issue.project.identifier })
          end

          # コメント追加（Journalとして記録）
          issue.init_journal(user, comment)

          unless issue.save
            return error_response("コメント追加に失敗しました", { errors: issue.errors.full_messages })
          end

          # 最新のJournalを取得
          latest_journal = issue.journals.order(created_on: :desc).first

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            comment: comment,
            journal_id: latest_journal&.id&.to_s,
            created_at: latest_journal&.created_on&.iso8601
          )
        rescue StandardError => e
          Rails.logger.error "AddIssueCommentTool error: #{e.class.name}: #{e.message}"
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
