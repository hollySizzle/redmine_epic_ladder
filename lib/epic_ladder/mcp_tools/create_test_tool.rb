# frozen_string_literal: true

require_relative 'issue_creation_service'

module EpicLadder
  module McpTools
    # Test作成MCPツール
    # Test（やるべきテストや検証）チケットを作成する
    #
    # @example
    #   ユーザー: 「申込完了までのE2Eテストを作るTestチケットを作って」
    #   AI: CreateTestToolを呼び出し
    #   結果: Test #1004が作成される
    class CreateTestTool < MCP::Tool
      description "Test（やるべきテストや検証）チケットを作成します。例: '申込完了までのE2Eテスト'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）" },
          description: { type: "string", description: "Testの説明（自然言語OK）" },
          parent_user_story_id: { type: "string", description: "親UserStory ID（階層構造維持のため必須）" },
          version_id: { type: "string", description: "Version ID（省略時は親から継承）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["description", "parent_user_story_id"]
      )

      def self.call(project_id: nil, description:, parent_user_story_id: nil, version_id: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateTestTool#call started: project_id=#{project_id}, description=#{description}"

        begin
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :test,
            project_id: project_id,
            description: description,
            parent_issue_id: parent_user_story_id,
            version_id: version_id,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          # Map result to expected response format
          success_response(
            test_id: result[:issue_id],
            test_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            parent_user_story: result[:parent_issue],
            version: result[:version],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateTestTool error: #{e.class.name}: #{e.message}"
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
