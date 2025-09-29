# frozen_string_literal: true

module Kanban
  # プロジェクト全体統計計算クラス
  # GridControllerから呼び出され、設計書準拠の統計データ構造を提供
  class StatisticsCalculator
    attr_reader :project

    def initialize(project)
      @project = project
    end

    # プロジェクト全体統計を計算・集約
    def calculate
      {
        overview: calculate_project_overview,
        by_version: calculate_version_statistics,
        by_status: calculate_status_distribution
      }
    end

    private

    # プロジェクト全体統計（ProjectStats）
    def calculate_project_overview
      epics = load_project_epics
      features = load_project_features
      user_stories = load_project_user_stories
      child_items = load_project_child_items

      {
        total_epics: epics.count,
        total_features: features.count,
        total_user_stories: user_stories.count,
        total_child_items: child_items.count,
        completed_epics: count_completed_issues(epics),
        completed_features: count_completed_issues(features),
        completed_user_stories: count_completed_issues(user_stories),
        completed_child_items: count_completed_issues(child_items),
        overall_completion_percentage: calculate_overall_completion_percentage,
        last_updated: Time.current
      }
    end

    # バージョン別統計（VersionStats）
    def calculate_version_statistics
      versions = @project.versions.includes(:fixed_issues)

      versions.map do |version|
        version_stats = StatisticsEngine.calculate_version_statistics(version)
        {
          version_id: version.id,
          version_name: version.name,
          **version_stats
        }
      end
    end

    # ステータス別分布（StatusDistribution）
    def calculate_status_distribution
      all_issues = @project.issues.includes(:status, :tracker)

      # ステータス別集計
      status_distribution = all_issues.group_by { |issue| issue.status.name }
                                    .transform_values(&:count)

      # トラッカー別×ステータス別集計
      tracker_status_distribution = all_issues.group_by { |issue| issue.tracker.name }
                                            .transform_values do |issues|
                                              issues.group_by { |issue| issue.status.name }
                                                    .transform_values(&:count)
                                            end

      {
        by_status: status_distribution,
        by_tracker_and_status: tracker_status_distribution,
        total_issues: all_issues.count,
        closed_issues: all_issues.joins(:status).where(issue_statuses: { is_closed: true }).count,
        open_issues: all_issues.joins(:status).where(issue_statuses: { is_closed: false }).count
      }
    end

    # プロジェクト内のEpic一覧を取得
    def load_project_epics
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      @project.issues.joins(:tracker)
              .where(trackers: { name: epic_tracker_name })
              .includes(:status)
    end

    # プロジェクト内のFeature一覧を取得
    def load_project_features
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      @project.issues.joins(:tracker)
              .where(trackers: { name: feature_tracker_name })
              .includes(:status)
    end

    # プロジェクト内のUserStory一覧を取得
    def load_project_user_stories
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      @project.issues.joins(:tracker)
              .where(trackers: { name: user_story_tracker_name })
              .includes(:status)
    end

    # プロジェクト内のTask/Test/Bug一覧を取得
    def load_project_child_items
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      child_tracker_names = [tracker_names[:task], tracker_names[:test], tracker_names[:bug]]
      @project.issues.joins(:tracker)
              .where(trackers: { name: child_tracker_names })
              .includes(:status)
    end

    # 完了済みIssue数をカウント
    def count_completed_issues(issues)
      issues.joins(:status).where(issue_statuses: { is_closed: true }).count
    end

    # プロジェクト全体完了率を計算
    def calculate_overall_completion_percentage
      all_issues = @project.issues
      return 0.0 if all_issues.empty?

      completed = all_issues.joins(:status).where(issue_statuses: { is_closed: true }).count
      ((completed.to_f / all_issues.count) * 100).round(2)
    end
  end
end