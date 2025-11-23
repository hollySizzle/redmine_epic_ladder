# frozen_string_literal: true

module EpicGrid
  module McpTools
    # UserStory作成MCPツール
    # UserStory（ユーザの要求など､ざっくりとした目標）チケットを作成する
    #
    # @example
    #   ユーザー: 「申込画面を作るUserStoryを作って」
    #   AI: CreateUserStoryToolを呼び出し
    #   結果: UserStory #1002が作成される
    class CreateUserStoryTool < MCP::Tool
      description "UserStory（ユーザの要求など､ざっくりとした目標）チケットを作成します。例: '申込画面を作る'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          subject: { type: "string", description: "UserStoryの件名" },
          parent_feature_id: { type: "string", description: "親Feature ID" },
          version_id: { type: "string", description: "Version ID（リリース予定）" },
          description: { type: "string", description: "UserStoryの説明（省略可）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["project_id", "subject", "parent_feature_id"]
      )

      def self.call(project_id:, subject:, parent_feature_id:, version_id: nil, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateUserStoryTool#call started: project_id=#{project_id}, subject=#{subject}, parent_feature_id=#{parent_feature_id}"

        begin
          # プロジェクト取得
          project = find_project(project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{project_id}")
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:add_issues, project)
            return error_response("UserStory作成権限がありません", { project: project.identifier })
          end

          # UserStoryトラッカー取得
          user_story_tracker = find_tracker(:user_story)
          return error_response("UserStoryトラッカーが設定されていません") unless user_story_tracker

          # 親Feature取得
          parent_feature = Issue.find_by(id: parent_feature_id)
          return error_response("親Featureが見つかりません: #{parent_feature_id}") unless parent_feature

          # Version解決
          version = resolve_version(project, version_id)

          # 担当者解決
          assigned_to = resolve_assigned_to(project, assigned_to_id, user)

          # UserStory作成
          user_story = Issue.new(
            project: project,
            tracker: user_story_tracker,
            subject: subject,
            description: description || subject,
            parent_issue_id: parent_feature.id,
            fixed_version_id: version&.id,
            assigned_to: assigned_to,
            author: user,
            status: IssueStatus.first
          )

          unless user_story.save
            return error_response("UserStory作成に失敗しました", { errors: user_story.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            user_story_id: user_story.id.to_s,
            user_story_url: issue_url(user_story.id),
            subject: user_story.subject,
            parent_feature: {
              id: parent_feature.id.to_s,
              subject: parent_feature.subject
            },
            version: version ? {
              id: version.id.to_s,
              name: version.name
            } : nil,
            assigned_to: assigned_to ? {
              id: assigned_to.id.to_s,
              name: assigned_to.name
            } : nil
          )
        rescue StandardError => e
          Rails.logger.error "CreateUserStoryTool error: #{e.class.name}: #{e.message}"
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

        # Versionを解決
        def resolve_version(project, version_id)
          if version_id.present?
            Version.find_by(id: version_id)
          else
            # 最新の未完了Versionを選択
            project.versions.where(status: 'open').order(:effective_date).first
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
