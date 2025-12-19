# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット進捗率更新MCPツール
    # チケットの進捗率を更新する（0%→50%→100%）
    #
    # @example
    #   ユーザー: 「Task #9999の進捗率を50%にして」
    #   AI: UpdateIssueProgressToolを呼び出し
    #   結果: Task #9999の進捗率が50%になる
    class UpdateIssueProgressTool < MCP::Tool
      extend BaseHelper
      description "Updates issue progress (done ratio). Specify an integer from 0 to 100."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          progress: { type: "number", description: "Progress percentage (0-100 integer)" }
        },
        required: ["issue_id", "progress"]
      )

      def self.call(issue_id:, progress:, server_context:)
        Rails.logger.info "UpdateIssueProgressTool#call started: issue_id=#{issue_id}, progress=#{progress}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 進捗率バリデーション
          progress_int = progress.to_i
          unless (0..100).include?(progress_int)
            return error_response("進捗率は0〜100の範囲で指定してください", { progress: progress })
          end

          # 進捗率更新
          old_progress = issue.done_ratio
          issue.done_ratio = progress_int

          unless issue.save
            return error_response("進捗率更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            old_progress: old_progress,
            new_progress: issue.done_ratio
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueProgressTool error: #{e.class.name}: #{e.message}"
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
