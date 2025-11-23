# frozen_string_literal: true

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
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          subject: { type: "string", description: "Epicの件名" },
          description: { type: "string", description: "Epicの説明（省略可）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["project_id", "subject"]
      )

      def self.call(project_id:, subject:, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateEpicTool#call started: project_id=#{project_id}, subject=#{subject}"

        begin
          # プロジェクト取得
          project = find_project(project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{project_id}")
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:add_issues, project)
            return error_response("Epic作成権限がありません", { project: project.identifier })
          end

          # Epicトラッカー取得
          epic_tracker = find_tracker(:epic, project)
          return error_response("Epicトラッカーが設定されていません") unless epic_tracker

          # 担当者解決
          assigned_to = resolve_assigned_to(project, assigned_to_id, user)

          # Epic作成
          epic = Issue.new(
            project: project,
            tracker: epic_tracker,
            subject: subject,
            description: description || subject,
            assigned_to: assigned_to,
            author: user,
            status: IssueStatus.first
          )

          unless epic.save
            return error_response("Epic作成に失敗しました", { errors: epic.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            epic_id: epic.id.to_s,
            epic_url: issue_url(epic.id),
            subject: epic.subject,
            assigned_to: assigned_to ? {
              id: assigned_to.id.to_s,
              name: assigned_to.name
            } : nil
          )
        rescue StandardError => e
          Rails.logger.error "CreateEpicTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # プロジェクト取得（識別子 or ID）
        def find_project(project_id)
          if project_id.to_i.to_s == project_id
            Project.find_by(id: project_id.to_i)
          else
            Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
          end
        end

        # 担当者を解決
        def resolve_assigned_to(project, assigned_to_id, current_user)
          if assigned_to_id.present?
            User.find_by(id: assigned_to_id)
          else
            current_user
          end
        end

        # トラッカー取得ヘルパー
        def find_tracker(tracker_type, project)
          tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
          tracker = Tracker.find_by(name: tracker_name)
          return nil unless tracker
          return nil unless project.trackers.include?(tracker)
          tracker
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
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
