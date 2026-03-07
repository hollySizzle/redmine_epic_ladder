# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット間関連付け設定MCPツール
    # チケット間の関連（relates, blocks, precedes 等）を追加する
    #
    # @example
    #   ユーザー: 「Bug #1234 は Feature #5678 をブロックしている」
    #   AI: AddRelatedIssueToolを呼び出し（relation_type: "blocks"）
    #   結果: Bug #1234 → Feature #5678 の blocks 関連が作成される
    class AddRelatedIssueTool < MCP::Tool
      extend BaseHelper
      description "Adds a relation between two issues. Supported relation types: relates, duplicates, duplicated, blocks, blocked, precedes, follows, copied_to, copied_from."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Source issue ID" },
          related_issue_id: { type: "string", description: "Target issue ID" },
          relation_type: {
            type: "string",
            description: "Relation type (default: relates). One of: relates, duplicates, duplicated, blocks, blocked, precedes, follows, copied_to, copied_from"
          }
        },
        required: %w[issue_id related_issue_id]
      )

      def self.call(issue_id:, related_issue_id:, relation_type: "relates", server_context:)
        Rails.logger.info "AddRelatedIssueTool#call started: issue_id=#{issue_id}, related_issue_id=#{related_issue_id}, relation_type=#{relation_type}"

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

          # relation_typeバリデーション
          unless IssueRelation::TYPES.keys.include?(relation_type)
            return error_response(
              "無効な関連タイプです: #{relation_type}",
              { valid_types: IssueRelation::TYPES.keys }
            )
          end

          # 関連の作成
          relation = IssueRelation.new(
            issue_from: issue,
            issue_to: related_issue,
            relation_type: relation_type
          )

          unless relation.save
            return error_response("関連の作成に失敗しました", { errors: relation.errors.full_messages })
          end

          # 成功レスポンス（handle_issue_orderによりfrom/toが入れ替わる可能性があるため、ユーザ指定の元IDを返す）
          success_response(
            relation_id: relation.id.to_s,
            issue_id: issue_id.to_s,
            related_issue_id: related_issue_id.to_s,
            relation_type: relation_type,
            actual_relation_type: relation.relation_type,
            actual_issue_from_id: relation.issue_from_id.to_s,
            actual_issue_to_id: relation.issue_to_id.to_s,
            issue_url: issue_url(issue.id)
          )
        rescue StandardError => e
          Rails.logger.error "AddRelatedIssueTool error: #{e.class.name}: #{e.message}"
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
