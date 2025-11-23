# frozen_string_literal: true

module EpicGrid
  module McpTools
    # UserStory一覧取得MCPツール
    # プロジェクト内のUserStoryを一覧取得する
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトのUserStory一覧を見せて」
    #   AI: ListUserStoriesToolを呼び出し
    #   結果: UserStory一覧が返却される
    class ListUserStoriesTool < MCP::Tool
      description "プロジェクト内のUserStory一覧を取得します。Version、担当者でフィルタリング可能です。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          version_id: { type: "string", description: "Version IDでフィルタ（省略可）" },
          assigned_to_id: { type: "string", description: "担当者IDでフィルタ（省略可）" },
          status: { type: "string", description: "ステータスでフィルタ（open/closed、省略可）" },
          limit: { type: "number", description: "取得件数上限（デフォルト: 50）" }
        },
        required: ["project_id"]
      )

      def self.call(project_id:, version_id: nil, assigned_to_id: nil, status: nil, limit: 50, server_context:)
        Rails.logger.info "ListUserStoriesTool#call started: project_id=#{project_id}"

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

          # UserStoryトラッカー取得
          user_story_tracker = find_tracker(:user_story)
          return error_response("UserStoryトラッカーが設定されていません") unless user_story_tracker

          # UserStory検索
          user_stories = project.issues.where(tracker: user_story_tracker)

          # フィルタ適用
          user_stories = user_stories.where(fixed_version_id: version_id) if version_id.present?
          user_stories = user_stories.where(assigned_to_id: assigned_to_id) if assigned_to_id.present?

          if status.present?
            if status.downcase == 'open'
              user_stories = user_stories.where(status: IssueStatus.where(is_closed: false))
            elsif status.downcase == 'closed'
              user_stories = user_stories.where(status: IssueStatus.where(is_closed: true))
            end
          end

          # 件数制限
          user_stories = user_stories.limit(limit.to_i)

          # レスポンス構築
          stories_data = user_stories.map do |story|
            {
              id: story.id.to_s,
              subject: story.subject,
              description: story.description&.truncate(200),
              status: {
                id: story.status.id.to_s,
                name: story.status.name,
                is_closed: story.status.is_closed
              },
              version: story.fixed_version ? {
                id: story.fixed_version.id.to_s,
                name: story.fixed_version.name
              } : nil,
              assigned_to: story.assigned_to ? {
                id: story.assigned_to.id.to_s,
                name: story.assigned_to.name
              } : nil,
              children_count: story.children.count,
              url: issue_url(story.id)
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            user_stories: stories_data,
            total_count: stories_data.size
          )
        rescue StandardError => e
          Rails.logger.error "ListUserStoriesTool error: #{e.class.name}: #{e.message}"
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
