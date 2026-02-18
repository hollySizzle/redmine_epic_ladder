# frozen_string_literal: true

require_relative 'issue_creation_service'

module EpicLadder
  module McpTools
    # タスク作成MCPツール
    # 自然言語からTaskチケットを作成する
    #
    # @example
    #   ユーザー: 「カートのリファクタリングタスクを作って」
    #   AI: CreateTaskToolを呼び出し
    #   結果: Task #9999が作成される
    class CreateTaskTool < MCP::Tool
      description "Creates a Task issue from natural language. Example: 'Refactor shopping cart'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          description: { type: "string", description: "Task description (natural language OK)" },
          parent_user_story_id: { type: "string", description: "Parent UserStory ID (required for hierarchy)" },
          version_id: { type: "string", description: "Version ID (inherits from parent if omitted)" },
          assigned_to_id: { type: "string", description: "Assignee user ID (defaults to current user)" }
        },
        required: ["description", "parent_user_story_id"]
      )

      def self.call(project_id: nil, description:, parent_user_story_id: nil, version_id: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateTaskTool#call started: project_id=#{project_id}, description=#{description}"

        begin
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :task,
            project_id: project_id,
            description: description,
            parent_issue_id: parent_user_story_id,
            version_id: version_id,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          # Map result to expected response format
          success_response(
            task_id: result[:issue_id],
            task_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            parent_user_story: result[:parent_issue],
            version: result[:version],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateTaskTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # エラーレスポンス生成（MCP::Tool::Response形式）
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

        # 成功レスポンス生成（MCP::Tool::Response形式）
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
