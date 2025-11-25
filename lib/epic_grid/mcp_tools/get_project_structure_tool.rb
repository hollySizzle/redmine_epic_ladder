# frozen_string_literal: true

require_relative 'base_helper'

module EpicGrid
  module McpTools
    # プロジェクト構造取得MCPツール
    # プロジェクトのEpic階層構造を可視化する
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトの構造を見せて」
    #   AI: GetProjectStructureToolを呼び出し
    #   結果: Epic→Feature→UserStoryの階層構造が返却される
    class GetProjectStructureTool < MCP::Tool
      extend BaseHelper
      description "プロジェクトのEpic階層構造（Epic→Feature→UserStory）を可視化します。PMがプロジェクト全体を把握するのに便利です。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）" },
          version_id: { type: "string", description: "Version IDでフィルタ（省略可）" },
          status: { type: "string", description: "ステータスでフィルタ（open/closed、省略可）" }
        },
        required: []
      )

      def self.call(project_id: nil, version_id: nil, status: nil, server_context:)
        Rails.logger.info "GetProjectStructureTool#call started: project_id=#{project_id || 'DEFAULT'}"

        begin
          # プロジェクト取得と権限チェック
          result = resolve_and_validate_project(project_id)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("チケット閲覧権限がありません", { project: project.identifier })
          end

          # トラッカー取得
          epic_tracker = find_tracker(:epic)
          feature_tracker = find_tracker(:feature)
          user_story_tracker = find_tracker(:user_story)
          task_tracker = find_tracker(:task)
          bug_tracker = find_tracker(:bug)
          test_tracker = find_tracker(:test)

          return error_response("Epic階層のトラッカーが設定されていません") unless epic_tracker && feature_tracker && user_story_tracker

          # Epic取得
          epics = project.issues.where(tracker: epic_tracker)
          epics = apply_filters(epics, status)

          # 構造構築
          trackers = { task: task_tracker, bug: bug_tracker, test: test_tracker }
          structure = epics.map do |epic|
            {
              id: epic.id.to_s,
              subject: epic.subject,
              type: "Epic",
              status: {
                name: epic.status.name,
                is_closed: epic.status.is_closed
              },
              features: build_features(epic, feature_tracker, user_story_tracker, trackers, version_id, status)
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            structure: structure,
            summary: build_summary(structure)
          )
        rescue StandardError => e
          Rails.logger.error "GetProjectStructureTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # Feature構造構築
        def build_features(epic, feature_tracker, user_story_tracker, trackers, version_id, status)
          features = epic.children.where(tracker: feature_tracker)
          features = apply_filters(features, status)

          features.map do |feature|
            {
              id: feature.id.to_s,
              subject: feature.subject,
              type: "Feature",
              status: {
                name: feature.status.name,
                is_closed: feature.status.is_closed
              },
              user_stories: build_user_stories(feature, user_story_tracker, trackers, version_id, status)
            }
          end
        end

        # UserStory構造構築
        def build_user_stories(feature, user_story_tracker, trackers, version_id, status)
          user_stories = feature.children.where(tracker: user_story_tracker)
          user_stories = user_stories.where(fixed_version_id: version_id) if version_id.present?
          user_stories = apply_filters(user_stories, status)

          user_stories.map do |story|
            {
              id: story.id.to_s,
              subject: story.subject,
              type: "UserStory",
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
              children: build_children(story, trackers)
            }
          end
        end

        # UserStoryの子チケット（Task/Bug/Test）構築
        def build_children(user_story, trackers)
          children = {
            tasks: [],
            bugs: [],
            tests: []
          }

          user_story.children.each do |child|
            child_data = {
              id: child.id.to_s,
              subject: child.subject,
              status: {
                name: child.status.name,
                is_closed: child.status.is_closed
              },
              assigned_to: child.assigned_to ? {
                id: child.assigned_to.id.to_s,
                name: child.assigned_to.name
              } : nil,
              done_ratio: child.done_ratio
            }

            if child.tracker_id == trackers[:task]&.id
              children[:tasks] << child_data
            elsif child.tracker_id == trackers[:bug]&.id
              children[:bugs] << child_data
            elsif child.tracker_id == trackers[:test]&.id
              children[:tests] << child_data
            end
          end

          children
        end

        # フィルタ適用
        def apply_filters(issues, status)
          if status.present?
            if status.downcase == 'open'
              issues = issues.where(status: IssueStatus.where(is_closed: false))
            elsif status.downcase == 'closed'
              issues = issues.where(status: IssueStatus.where(is_closed: true))
            end
          end
          issues
        end

        # サマリー構築
        def build_summary(structure)
          total_features = structure.sum { |e| e[:features].size }
          total_user_stories = structure.sum { |e| e[:features].sum { |f| f[:user_stories].size } }

          total_tasks = 0
          total_bugs = 0
          total_tests = 0

          structure.each do |epic|
            epic[:features].each do |feature|
              feature[:user_stories].each do |story|
                total_tasks += story[:children][:tasks].size
                total_bugs += story[:children][:bugs].size
                total_tests += story[:children][:tests].size
              end
            end
          end

          {
            total_epics: structure.size,
            total_features: total_features,
            total_user_stories: total_user_stories,
            total_tasks: total_tasks,
            total_bugs: total_bugs,
            total_tests: total_tests
          }
        end

      end
    end
  end
end
