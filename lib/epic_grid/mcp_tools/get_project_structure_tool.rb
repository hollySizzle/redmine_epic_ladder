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
          status: { type: "string", description: "ステータスでフィルタ（open/closed、省略可）※include_closed推奨" },
          max_depth: { type: "integer", description: "取得階層の深さ: 1=Epic, 2=+Feature, 3=+UserStory, 4=+Task/Bug/Test（デフォルト3）" },
          include_closed: { type: "boolean", description: "クローズ済みチケットを含むか（デフォルトfalse=openのみ）" }
        },
        required: []
      )

      def self.call(project_id: nil, version_id: nil, status: nil, max_depth: 3, include_closed: false, server_context:)
        Rails.logger.info "GetProjectStructureTool#call started: project_id=#{project_id || 'DEFAULT'}, max_depth=#{max_depth}, include_closed=#{include_closed}"

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

          # トラッカー取得
          epic_tracker = find_tracker(:epic)
          feature_tracker = find_tracker(:feature)
          user_story_tracker = find_tracker(:user_story)
          task_tracker = find_tracker(:task)
          bug_tracker = find_tracker(:bug)
          test_tracker = find_tracker(:test)

          return error_response("Epic階層のトラッカーが設定されていません") unless epic_tracker && feature_tracker && user_story_tracker

          # Epic取得（include_closedがfalseの場合はopenのみ）
          epics = project.issues.where(tracker: epic_tracker)
          epics = apply_status_filter(epics, status, include_closed)

          # 構造構築（max_depthで階層を制御）
          trackers = { task: task_tracker, bug: bug_tracker, test: test_tracker }
          filter_opts = { status: status, include_closed: include_closed, version_id: version_id }

          structure = epics.map do |epic|
            epic_data = {
              id: epic.id.to_s,
              subject: epic.subject,
              type: "Epic",
              status: {
                name: epic.status.name,
                is_closed: epic.status.is_closed
              }
            }
            # max_depth >= 2 の場合のみFeatureを取得
            epic_data[:features] = max_depth >= 2 ? build_features(epic, feature_tracker, user_story_tracker, trackers, max_depth, filter_opts) : []
            epic_data
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
        def build_features(epic, feature_tracker, user_story_tracker, trackers, max_depth, filter_opts)
          features = epic.children.where(tracker: feature_tracker)
          features = apply_status_filter(features, filter_opts[:status], filter_opts[:include_closed])

          features.map do |feature|
            feature_data = {
              id: feature.id.to_s,
              subject: feature.subject,
              type: "Feature",
              status: {
                name: feature.status.name,
                is_closed: feature.status.is_closed
              }
            }
            # max_depth >= 3 の場合のみUserStoryを取得
            feature_data[:user_stories] = max_depth >= 3 ? build_user_stories(feature, user_story_tracker, trackers, max_depth, filter_opts) : []
            feature_data
          end
        end

        # UserStory構造構築
        def build_user_stories(feature, user_story_tracker, trackers, max_depth, filter_opts)
          user_stories = feature.children.where(tracker: user_story_tracker)
          user_stories = user_stories.where(fixed_version_id: filter_opts[:version_id]) if filter_opts[:version_id].present?
          user_stories = apply_status_filter(user_stories, filter_opts[:status], filter_opts[:include_closed])

          user_stories.map do |story|
            story_data = {
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
              } : nil
            }
            # max_depth >= 4 の場合のみTask/Bug/Testを取得
            story_data[:children] = max_depth >= 4 ? build_children(story, trackers, filter_opts[:include_closed]) : { tasks: [], bugs: [], tests: [] }
            story_data
          end
        end

        # UserStoryの子チケット（Task/Bug/Test）構築
        def build_children(user_story, trackers, include_closed)
          children = {
            tasks: [],
            bugs: [],
            tests: []
          }

          child_issues = user_story.children
          # include_closedがfalseの場合はopenのみ
          child_issues = child_issues.joins(:status).where(issue_statuses: { is_closed: false }) unless include_closed

          child_issues.each do |child|
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

        # ステータスフィルタ適用
        # @param issues [ActiveRecord::Relation] チケットのクエリ
        # @param status [String, nil] "open"または"closed"（明示的指定用、非推奨）
        # @param include_closed [Boolean] クローズ済みを含むか（推奨）
        def apply_status_filter(issues, status, include_closed)
          # 明示的なstatusパラメータが指定されている場合はそちらを優先（後方互換性）
          if status.present?
            if status.downcase == 'open'
              return issues.joins(:status).where(issue_statuses: { is_closed: false })
            elsif status.downcase == 'closed'
              return issues.joins(:status).where(issue_statuses: { is_closed: true })
            end
          end

          # include_closedがfalseの場合はopenのみ
          unless include_closed
            issues = issues.joins(:status).where(issue_statuses: { is_closed: false })
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
