# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # Bug/Test/TaskをUserStoryに昇格させるMCPツール
    # 新しいUserStoryをFeature配下に作成し、元issueをその子に、元親USとrelates関連で紐づける
    #
    # @example
    #   ユーザー: 「Bug #123 をUSに昇格させて」
    #   AI: PromoteToUsToolを呼び出し
    #   結果: 新USが作成され、Bug #123はその子チケットに、元親USとrelates関連で紐づく
    class PromoteToUsTool < MCP::Tool
      extend BaseHelper
      description "Promotes a Bug/Test/Task to UserStory by creating a new US under the Feature, moving the original issue as its child, and linking to the original parent US."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID of the Bug/Test/Task to promote" },
          target_feature_id: { type: "string", description: "Feature ID for the new US (default: parent US's parent Feature)" },
          us_subject: { type: "string", description: "Subject for the new US (default: original issue's subject)" }
        },
        required: ["issue_id"]
      )

      def self.call(issue_id:, target_feature_id: nil, us_subject: nil, server_context:)
        Rails.logger.info "PromoteToUsTool#call started: issue_id=#{issue_id}"

        begin
          # MCP有効チェック
          unless ProjectValidator.mcp_enabled?
            return ProjectValidator.mcp_disabled_response
          end

          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # プロジェクトMCP許可チェック
          unless ProjectValidator.project_allowed?(issue.project)
            return ProjectValidator.project_not_allowed_response(issue.project)
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # バリデーション
          validation = EpicLadder::IssuePromoter.validate_promotable(issue)
          unless validation[:valid]
            return error_response(validation[:error])
          end

          # target_feature解決
          target_feature = nil
          if target_feature_id.present?
            target_feature = Issue.find_by(id: target_feature_id)
            return error_response("指定されたFeatureが見つかりません: #{target_feature_id}") unless target_feature
          end

          # IssuePromoterに委譲
          result = EpicLadder::IssuePromoter.promote_to_user_story(
            issue,
            user: user,
            target_feature: target_feature,
            us_subject: us_subject
          )

          # 成功レスポンス
          success_response(
            new_user_story: {
              id: result[:new_user_story].id.to_s,
              subject: result[:new_user_story].subject,
              url: issue_url(result[:new_user_story].id)
            },
            original_issue: {
              id: issue.id.to_s,
              subject: issue.subject
            },
            original_parent_us: {
              id: result[:original_parent_us].id.to_s,
              subject: result[:original_parent_us].subject
            },
            relation_id: result[:relation].id.to_s
          )
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "PromoteToUsTool validation error: #{e.message}"
          error_response("昇格に失敗しました: #{e.message}")
        rescue StandardError => e
          Rails.logger.error "PromoteToUsTool error: #{e.class.name}: #{e.message}"
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
