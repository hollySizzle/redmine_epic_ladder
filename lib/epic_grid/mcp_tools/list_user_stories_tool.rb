# frozen_string_literal: true

require_relative 'base_helper'

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
      extend BaseHelper

      description "プロジェクト内のUserStory一覧を取得します。Version、担当者でフィルタリング可能です。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）" },
          version_id: { type: "string", description: "Version IDでフィルタ（省略可）" },
          assigned_to_id: { type: "string", description: "担当者IDでフィルタ（省略可）" },
          status: { type: "string", description: "ステータスでフィルタ（open/closed、省略可）" },
          limit: { type: "number", description: "取得件数上限（デフォルト: 50）" }
        },
        required: []
      )

      def self.call(project_id: nil, version_id: nil, assigned_to_id: nil, status: nil, limit: 50, server_context:)
        Rails.logger.info "ListUserStoriesTool#call started: project_id=#{project_id || 'DEFAULT'}"

        begin
          # プロジェクト取得と権限チェック（server_contextからX-Default-Projectヘッダー値を参照）
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("チケット閲覧権限がありません", { project: project.identifier })
          end

          # UserStoryトラッカー取得
          user_story_tracker = find_tracker(:user_story)
          return error_response("UserStoryトラッカーが設定されていません") unless user_story_tracker

          # UserStory一覧取得
          user_stories = project.issues.where(tracker: user_story_tracker)
          user_stories = user_stories.where(fixed_version_id: version_id) if version_id.present?
          user_stories = user_stories.where(assigned_to_id: assigned_to_id) if assigned_to_id.present?

          # ステータスフィルタ
          if status.present?
            if status.downcase == 'open'
              user_stories = user_stories.where(status: IssueStatus.where(is_closed: false))
            elsif status.downcase == 'closed'
              user_stories = user_stories.where(status: IssueStatus.where(is_closed: true))
            end
          end

          # 件数制限
          user_stories = user_stories.limit(limit) if limit

          # UserStory情報構築
          story_list = user_stories.map do |story|
            {
              id: story.id.to_s,
              subject: story.subject,
              description: story.description,
              status: {
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
              done_ratio: story.done_ratio,
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
            user_stories: story_list,
            total_count: story_list.size
          )
        rescue StandardError => e
          Rails.logger.error "ListUserStoriesTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
      end
    end
  end
end
