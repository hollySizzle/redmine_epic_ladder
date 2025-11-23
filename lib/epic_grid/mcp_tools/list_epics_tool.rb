# frozen_string_literal: true

module EpicGrid
  module McpTools
    # Epic一覧取得MCPツール
    # プロジェクト内のEpicを一覧取得する
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトのEpic一覧を見せて」
    #   AI: ListEpicsToolを呼び出し
    #   結果: Epic一覧が返却される
    class ListEpicsTool < MCP::Tool
      description "プロジェクト内のEpic一覧を取得します。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          assigned_to_id: { type: "string", description: "担当者IDでフィルタ（省略可）" },
          status: { type: "string", description: "ステータスでフィルタ（open/closed、省略可）" },
          limit: { type: "number", description: "取得件数上限（デフォルト: 50）" }
        },
        required: ["project_id"]
      )

      def self.call(project_id:, assigned_to_id: nil, status: nil, limit: 50, server_context:)
        Rails.logger.info "ListEpicsTool#call started: project_id=#{project_id}"

        begin
          # プロジェクト取得
          project = find_project(project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{project_id}")
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("チケット閲覧権限がありません", { project: project.identifier })
          end

          # Epicトラッカー取得
          epic_tracker = find_tracker(:epic)
          return error_response("Epicトラッカーが設定されていません") unless epic_tracker

          # Epic検索
          epics = project.issues.where(tracker: epic_tracker)

          # フィルタ適用
          epics = epics.where(assigned_to_id: assigned_to_id) if assigned_to_id.present?

          if status.present?
            if status.downcase == 'open'
              epics = epics.where(status: IssueStatus.where(is_closed: false))
            elsif status.downcase == 'closed'
              epics = epics.where(status: IssueStatus.where(is_closed: true))
            end
          end

          # 件数制限
          epics = epics.limit(limit.to_i)

          # レスポンス構築
          epics_data = epics.map do |epic|
            {
              id: epic.id.to_s,
              subject: epic.subject,
              description: epic.description&.truncate(200),
              status: {
                id: epic.status.id.to_s,
                name: epic.status.name,
                is_closed: epic.status.is_closed
              },
              assigned_to: epic.assigned_to ? {
                id: epic.assigned_to.id.to_s,
                name: epic.assigned_to.name
              } : nil,
              children_count: epic.children.count,
              url: issue_url(epic.id)
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            epics: epics_data,
            total_count: epics_data.size
          )
        rescue StandardError => e
          Rails.logger.error "ListEpicsTool error: #{e.class.name}: #{e.message}"
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

        # トラッカー取得ヘルパー
        def find_tracker(tracker_type)
          tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
          Tracker.find_by(name: tracker_name)
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
