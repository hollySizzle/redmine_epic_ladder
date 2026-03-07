# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット間関連付け解除MCPツール
    # チケット間の関連（relates, blocks, precedes 等）を削除する
    #
    # @example
    #   ユーザー: 「Bug #1234 と Feature #5678 の関連を解除して」
    #   AI: RemoveRelatedIssueToolを呼び出し
    #   結果: Bug #1234 と Feature #5678 の関連が削除される
    class RemoveRelatedIssueTool < MCP::Tool
      extend BaseHelper
      description "Removes a relation between two issues."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          related_issue_id: { type: "string", description: "Related issue ID" }
        },
        required: %w[issue_id related_issue_id]
      )

      def self.call(issue_id:, related_issue_id:, server_context:)
        Rails.logger.info "RemoveRelatedIssueTool#call started: issue_id=#{issue_id}, related_issue_id=#{related_issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          related_issue = Issue.find_by(id: related_issue_id)
          return error_response("チケットが見つかりません: #{related_issue_id}") unless related_issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, issue.project)
            return error_response("チケット閲覧権限がありません", { project: issue.project.identifier })
          end
          unless user.allowed_to?(:view_issues, related_issue.project)
            return error_response("チケット閲覧権限がありません", { project: related_issue.project.identifier })
          end
          unless user.allowed_to?(:manage_issue_relations, issue.project)
            return error_response("関連チケット管理権限がありません", { project: issue.project.identifier })
          end

          # 双方向検索（handle_issue_orderによりfrom/toが入れ替わるため）
          relation = IssueRelation.where(issue_from_id: issue.id, issue_to_id: related_issue.id).first ||
                     IssueRelation.where(issue_from_id: related_issue.id, issue_to_id: issue.id).first

          unless relation
            return error_response(
              "関連が見つかりません",
              { issue_id: issue_id.to_s, related_issue_id: related_issue_id.to_s }
            )
          end

          # 削除前に情報を保持
          relation_id = relation.id.to_s
          relation_type = relation.relation_type

          # 関連の削除
          unless relation.destroy
            return error_response("関連の削除に失敗しました")
          end

          # 成功レスポンス
          success_response(
            relation_id: relation_id,
            issue_id: issue_id.to_s,
            related_issue_id: related_issue_id.to_s,
            relation_type: relation_type,
            issue_url: issue_url(issue.id)
          )
        rescue StandardError => e
          Rails.logger.error "RemoveRelatedIssueTool error: #{e.class.name}: #{e.message}"
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
