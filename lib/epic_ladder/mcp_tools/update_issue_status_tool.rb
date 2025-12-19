# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケットステータス更新MCPツール
    # チケットのステータスを更新する（Open→InProgress→Closed）
    #
    # @example
    #   ユーザー: 「Task #9999をClosedにして」
    #   AI: UpdateIssueStatusToolを呼び出し
    #   結果: Task #9999がClosedになる
    class UpdateIssueStatusTool < MCP::Tool
      extend BaseHelper
      description "Updates issue status. Example: 'Open', 'In Progress', 'Closed'"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          status_name: { type: "string", description: "Status name (e.g., 'Open', 'In Progress', 'Closed')" },
          confirmed: { type: "boolean", description: "Confirmation flag (required for dangerous operations)", default: false }
        },
        required: ["issue_id", "status_name"]
      )

      def self.call(issue_id:, status_name:, confirmed: false, server_context:)
        Rails.logger.info "UpdateIssueStatusTool#call started: issue_id=#{issue_id}, status_name=#{status_name}, confirmed=#{confirmed}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # ステータス取得（曖昧検索対応）
          status = find_status(status_name)
          return error_response("ステータスが見つかりません: #{status_name}") unless status

          # 環境変数チェック: close操作で確認が必要か
          if status.is_closed && check_confirmation_required('close') && !confirmed
            # Epic/Featureの場合は配下のチケット数を取得
            children_count = issue.children.count

            return confirmation_required_response(
              operation: 'close',
              issue_id: issue.id.to_s,
              subject: issue.subject,
              tracker: issue.tracker.name,
              old_status: {
                id: issue.status.id.to_s,
                name: issue.status.name
              },
              new_status: {
                id: status.id.to_s,
                name: status.name,
                is_closed: status.is_closed
              },
              children_count: children_count,
              confirmation_message: "チケット ##{issue.id} 「#{issue.subject}」を#{status.name}にします。" +
                                  (children_count > 0 ? " 配下に#{children_count}件のチケットがあります。" : "") +
                                  " 実行しますか？"
            )
          end

          # ステータス更新
          old_status = issue.status
          issue.status = status

          unless issue.save
            return error_response("ステータス更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            old_status: {
              id: old_status.id.to_s,
              name: old_status.name
            },
            new_status: {
              id: status.id.to_s,
              name: status.name,
              is_closed: status.is_closed
            }
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueStatusTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # ステータスを曖昧検索
        # 例: "closed" → "Closed", "in progress" → "In Progress"
        def find_status(status_name)
          # 完全一致
          status = IssueStatus.find_by(name: status_name)
          return status if status

          # 大文字小文字を無視して検索
          status = IssueStatus.where('LOWER(name) = ?', status_name.downcase).first
          return status if status

          # 部分一致
          IssueStatus.where('LOWER(name) LIKE ?', "%#{status_name.downcase}%").first
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
        # 確認が必要かチェック
        # @param operation [String] 操作名（例: 'move_version', 'delete', 'close'）
        # @return [Boolean] 確認が必要ならtrue
        def check_confirmation_required(operation)
          require_confirmation_for = ENV.fetch('REQUIRE_CONFIRMATION_FOR', '')
          operations = require_confirmation_for.split(',').map(&:strip)
          operations.include?(operation)
        end

        # 確認要求レスポンス生成
        def confirmation_required_response(data = {})
          MCP::Tool::Response.new([{
            type: "text",
            text: JSON.generate({
              success: false,
              confirmation_required: true,
              error: "この操作には確認が必要です。確認後、confirmed=trueを追加して再実行してください。"
            }.merge(data))
          }])
        end
      end
    end
  end
end
