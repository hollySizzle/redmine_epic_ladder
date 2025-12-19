# frozen_string_literal: true

require_relative 'issue_creation_service'

module EpicLadder
  module McpTools
    # Feature作成MCPツール
    # Feature（分類を行うための中間層）チケットを作成する
    #
    # @example
    #   ユーザー: 「CTAのFeatureを作って」
    #   AI: CreateFeatureToolを呼び出し
    #   結果: Feature #1001が作成される
    class CreateFeatureTool < MCP::Tool
      description "Creates a Feature (intermediate category) issue under an Epic. Example: 'CTA Button'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          subject: { type: "string", description: "Feature subject/title" },
          parent_epic_id: { type: "string", description: "Parent Epic issue ID" },
          description: { type: "string", description: "Feature description (optional)" },
          assigned_to_id: { type: "string", description: "Assignee user ID (defaults to current user)" }
        },
        required: ["subject", "parent_epic_id"]
      )

      def self.call(project_id: nil, subject:, parent_epic_id:, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateFeatureTool#call started: project_id=#{project_id}, subject=#{subject}, parent_epic_id=#{parent_epic_id}"

        begin
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :feature,
            project_id: project_id,
            subject: subject,
            description: description || subject,
            parent_issue_id: parent_epic_id,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          # Map result to expected response format
          success_response(
            feature_id: result[:issue_id],
            feature_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            parent_epic: result[:parent_issue],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateFeatureTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # エラーレスポンス生成
        def error_response(message, details = {})
          MCP::Tool::Response.new([{
            type: "text",
            text: JSON.generate({
              success: false,
              error: message,
              details: details
            })
          }])
        end

        # 成功レスポンス生成
        def success_response(data = {})
          MCP::Tool::Response.new([{
            type: "text",
            text: JSON.generate({
              success: true
            }.merge(data))
          }])
        end
      end
    end
  end
end
