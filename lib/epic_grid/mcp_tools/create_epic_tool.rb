# frozen_string_literal: true

require_relative 'issue_creation_service'

module EpicGrid
  module McpTools
    # Epic作成MCPツール
    # Epic（大分類）チケットを作成する
    #
    # @example
    #   ユーザー: 「ユーザー動線のEpicを作って」
    #   AI: CreateEpicToolを呼び出し
    #   結果: Epic #1000が作成される
    class CreateEpicTool < MCP::Tool
      description "Epic（大分類）チケットを作成します。例: 'ユーザー動線'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）" },
          subject: { type: "string", description: "Epicの件名" },
          description: { type: "string", description: "Epicの説明（省略可）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["subject"]
      )

      def self.call(project_id: nil, subject:, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateEpicTool#call started: project_id=#{project_id}, subject=#{subject}"

        begin
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :epic,
            project_id: project_id,
            subject: subject,
            description: description || subject,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          # Map result to expected response format
          success_response(
            epic_id: result[:issue_id],
            epic_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateEpicTool error: #{e.class.name}: #{e.message}"
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
