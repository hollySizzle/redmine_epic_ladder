# frozen_string_literal: true

module EpicGrid
  module McpTools
    # Feature作成MCPツール
    # Feature（分類を行うための中間層）チケットを作成する
    #
    # @example
    #   ユーザー: 「CTAのFeatureを作って」
    #   AI: CreateFeatureToolを呼び出し
    #   結果: Feature #1001が作成される
    class CreateFeatureTool < MCP::Tool
      description "Feature（分類を行うための中間層）チケットを作成します。例: 'CTA'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          subject: { type: "string", description: "Featureの件名" },
          parent_epic_id: { type: "string", description: "親Epic ID" },
          description: { type: "string", description: "Featureの説明（省略可）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["project_id", "subject", "parent_epic_id"]
      )

      def self.call(project_id:, subject:, parent_epic_id:, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateFeatureTool#call started: project_id=#{project_id}, subject=#{subject}, parent_epic_id=#{parent_epic_id}"

        begin
          # プロジェクト取得
          project = find_project(project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{project_id}")
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:add_issues, project)
            return error_response("Feature作成権限がありません", { project: project.identifier })
          end

          # Featureトラッカー取得
          feature_tracker = find_tracker(:feature)
          return error_response("Featureトラッカーが設定されていません") unless feature_tracker

          # 親Epic取得
          parent_epic = Issue.find_by(id: parent_epic_id)
          return error_response("親Epicが見つかりません: #{parent_epic_id}") unless parent_epic

          # 担当者解決
          assigned_to = resolve_assigned_to(project, assigned_to_id, user)

          # Feature作成
          feature = Issue.new(
            project: project,
            tracker: feature_tracker,
            subject: subject,
            description: description || subject,
            parent_issue_id: parent_epic.id,
            assigned_to: assigned_to,
            author: user,
            status: IssueStatus.first
          )

          unless feature.save
            return error_response("Feature作成に失敗しました", { errors: feature.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            feature_id: feature.id.to_s,
            feature_url: issue_url(feature.id),
            subject: feature.subject,
            parent_epic: {
              id: parent_epic.id.to_s,
              subject: parent_epic.subject
            },
            assigned_to: assigned_to ? {
              id: assigned_to.id.to_s,
              name: assigned_to.name
            } : nil
          )
        rescue StandardError => e
          Rails.logger.error "CreateFeatureTool error: #{e.class.name}: #{e.message}"
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
