# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット件名更新MCPツール
    # チケットのsubjectを更新する
    #
    # @example
    #   ユーザー: 「Task #9999の件名を変更して」
    #   AI: UpdateIssueSubjectToolを呼び出し
    #   結果: Task #9999の件名が更新される
    class UpdateIssueSubjectTool < MCP::Tool
      extend BaseHelper
      description "チケットの件名（subject）を更新します。"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "チケットID" },
          subject: { type: "string", description: "新しい件名" }
        },
        required: %w[issue_id subject]
      )

      def self.call(issue_id:, subject:, server_context:)
        Rails.logger.info "UpdateIssueSubjectTool#call started: issue_id=#{issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 件名のバリデーション
          if subject.blank?
            return error_response("件名は必須です")
          end

          # 件名更新
          old_subject = issue.subject
          issue.subject = subject

          unless issue.save
            return error_response("件名の更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            old_subject: old_subject,
            new_subject: subject
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueSubjectTool error: #{e.class.name}: #{e.message}"
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
