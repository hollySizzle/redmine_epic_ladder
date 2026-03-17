# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # 複数チケットステータス一括更新MCPツール
    # 複数チケットのステータスを一括更新する
    #
    # @example
    #   ユーザー: 「Task #101, #102, #103をクローズして」
    #   AI: BulkUpdateIssueStatusToolを呼び出し
    #   結果: 3チケットが一括クローズされる
    class BulkUpdateIssueStatusTool < MCP::Tool
      extend BaseHelper
      description "Updates status of multiple issues at once. Partial failures are reported individually without rollback."

      input_schema(
        properties: {
          issue_ids: {
            type: "array",
            items: { type: "string" },
            description: "Array of Issue IDs (max 50)"
          },
          status_name: { type: "string", description: "Status name (e.g., 'Closed', 'In Progress')" },
          comment: { type: "string", description: "Optional comment to add to each issue" }
        },
        required: ["issue_ids", "status_name"]
      )

      def self.call(issue_ids:, status_name:, comment: nil, server_context:)
        Rails.logger.info "BulkUpdateIssueStatusTool#call started: issue_ids=#{issue_ids.inspect}, status_name=#{status_name}"

        begin
          # バリデーション
          if issue_ids.blank?
            return error_response("issue_idsが空です")
          end

          if issue_ids.size > 50
            return error_response("issue_idsは50件以下にしてください（指定: #{issue_ids.size}件）")
          end

          # ステータス取得（曖昧検索対応）
          status = find_status(status_name)
          return error_response("ステータスが見つかりません: #{status_name}") unless status

          user = server_context[:user] || User.current
          results = []
          succeeded = 0
          failed = 0

          issue_ids.each do |issue_id|
            begin
              issue = Issue.find_by(id: issue_id)
              unless issue
                results << { issue_id: issue_id, success: false, error: "チケットが見つかりません" }
                failed += 1
                next
              end

              # 権限チェック
              unless user.allowed_to?(:edit_issues, issue.project)
                results << { issue_id: issue_id, success: false, error: "チケット編集権限がありません" }
                failed += 1
                next
              end

              # closable?チェック
              if status.is_closed && !issue.closable?
                results << { issue_id: issue_id, success: false, error: "未完了の子チケットがあるためクローズできません" }
                failed += 1
                next
              end

              # reopenable?チェック
              if !status.is_closed && issue.status.is_closed && !issue.reopenable?
                results << { issue_id: issue_id, success: false, error: "親チケットがクローズ済みのため再オープンできません" }
                failed += 1
                next
              end

              # ステータス更新
              old_status_name = issue.status.name
              issue.status = status

              # コメント追加（任意）
              if comment.present?
                issue.init_journal(user, comment)
              end

              if issue.save
                results << { issue_id: issue_id, success: true, old_status: old_status_name, new_status: status.name }
                succeeded += 1
              else
                results << { issue_id: issue_id, success: false, error: issue.errors.full_messages.join(', ') }
                failed += 1
              end
            rescue StandardError => e
              results << { issue_id: issue_id, success: false, error: e.message }
              failed += 1
            end
          end

          success_response(
            succeeded: succeeded,
            failed: failed,
            total: issue_ids.size,
            results: results
          )
        rescue StandardError => e
          Rails.logger.error "BulkUpdateIssueStatusTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # ステータスを曖昧検索
        def find_status(status_name)
          status = IssueStatus.find_by(name: status_name)
          return status if status

          status = IssueStatus.where('LOWER(name) = ?', status_name.downcase).first
          return status if status

          IssueStatus.where('LOWER(name) LIKE ?', "%#{status_name.downcase}%").first
        end
      end
    end
  end
end
