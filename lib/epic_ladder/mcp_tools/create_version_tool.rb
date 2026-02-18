# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # Version作成MCPツール
    # Version（リリース予定）を作成する
    #
    # @example
    #   ユーザー: 「Sprint 2025-02のVersionを作って」
    #   AI: CreateVersionToolを呼び出し
    #   結果: Version「Sprint 2025-02」が作成される
    class CreateVersionTool < MCP::Tool
      extend BaseHelper

      description "Creates a Version (release milestone). Example: 'Sprint 2025-02 (due 2025-02-28)'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          name: { type: "string", description: "Version name" },
          effective_date: { type: "string", description: "Release date (YYYY-MM-DD format)" },
          description: { type: "string", description: "Version description (optional)" },
          status: { type: "string", description: "Status (open/locked/closed, default: open)" }
        },
        required: ["name", "effective_date"]
      )

      def self.call(project_id: nil, name:, effective_date:, description: nil, status: "open", server_context:)
        Rails.logger.info "CreateVersionTool#call started: project_id=#{project_id || 'DEFAULT'}, name=#{name}, effective_date=#{effective_date}"

        begin
          # プロジェクト取得と権限チェック（server_contextからX-Default-Projectヘッダー値を参照）
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:manage_versions, project)
            return error_response("Version作成権限がありません", { project: project.identifier })
          end

          # effective_dateをパース
          parsed_date = parse_date(effective_date)
          return error_response("無効な日付形式です: #{effective_date}（YYYY-MM-DD形式で指定してください）") unless parsed_date

          # Version作成
          version = project.versions.build(
            name: name,
            description: description,
            effective_date: parsed_date,
            status: status
          )

          unless version.save
            return error_response("Version作成に失敗しました", { errors: version.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            version_id: version.id.to_s,
            version_url: version_url(project, version),
            name: version.name,
            effective_date: version.effective_date.to_s,
            status: version.status
          )
        rescue StandardError => e
          Rails.logger.error "CreateVersionTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # 日付パース
        def parse_date(date_string)
          Date.parse(date_string)
        rescue ArgumentError
          nil
        end

        # RedmineのVersion URLを生成
        def version_url(project, version)
          "#{Setting.protocol}://#{Setting.host_name}/projects/#{project.identifier}/versions/#{version.id}"
        end

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
