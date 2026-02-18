# frozen_string_literal: true

require_relative 'issue_creation_service'

module EpicLadder
  module McpTools
    # UserStory作成MCPツール
    # UserStory（ユーザの要求など､ざっくりとした目標）チケットを作成する
    #
    # @example
    #   ユーザー: 「申込画面を作るUserStoryを作って」
    #   AI: CreateUserStoryToolを呼び出し
    #   結果: UserStory #1002が作成される
    class CreateUserStoryTool < MCP::Tool
      description "Creates a UserStory (user requirement/goal) issue under a Feature. Example: 'Build registration form'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          subject: { type: "string", description: "UserStory subject/title" },
          parent_feature_id: { type: "string", description: "Parent Feature issue ID" },
          version_id: { type: "string", description: "Target Version ID (release milestone)" },
          description: { type: "string", description: "UserStory description (optional)" },
          assigned_to_id: { type: "string", description: "Assignee user ID (defaults to current user)" }
        },
        required: ["subject", "parent_feature_id"]
      )

      def self.call(project_id: nil, subject:, parent_feature_id:, version_id: nil, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateUserStoryTool#call started: project_id=#{project_id}, subject=#{subject}, parent_feature_id=#{parent_feature_id}"

        begin
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :user_story,
            project_id: project_id,
            subject: subject,
            description: description || subject,
            parent_issue_id: parent_feature_id,
            version_id: version_id,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          # Map result to expected response format
          success_response(
            user_story_id: result[:issue_id],
            user_story_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            parent_feature: result[:parent_issue],
            version: result[:version],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateUserStoryTool error: #{e.class.name}: #{e.message}"
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
