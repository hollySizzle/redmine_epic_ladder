# frozen_string_literal: true

module Kanban
  # 統計計算エンジン
  # 階層データのリアルタイム統計計算・キャッシング機能
  class StatisticsEngine
    include Rails.application.routes.url_helpers

    CACHE_TTL = 5.minutes

    # Epic統計計算
    def self.calculate_epic_statistics(epic)
      cache_key = "epic_statistics_#{epic.id}_#{epic.updated_on.to_i}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
        features = epic.children.joins(:tracker)
                      .where(trackers: { name: feature_tracker_name })
                      .includes(:status, children: [:tracker, :status])

        {
          epic_id: epic.id,
          total_features: features.count,
          total_user_stories: count_user_stories(features),
          total_child_items: count_child_items(features),
          completed_features: count_completed_issues(features),
          completed_user_stories: count_completed_user_stories(features),
          completed_child_items: count_completed_child_items(features),
          completion_percentage: calculate_completion_percentage(features),
          last_updated: Time.current,
          version_consistency: check_version_consistency(epic, features)
        }
      end
    end

    # Feature統計計算
    def self.calculate_feature_statistics(feature)
      cache_key = "feature_statistics_#{feature.id}_#{feature.updated_on.to_i}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
        user_stories = feature.children.joins(:tracker)
                              .where(trackers: { name: user_story_tracker_name })
                              .includes(:status, children: [:tracker, :status])

        child_items = user_stories.flat_map(&:children)

        {
          feature_id: feature.id,
          total_user_stories: user_stories.count,
          total_child_items: child_items.count,
          child_items_by_type: group_child_items_by_type(child_items),
          completion_percentage: calculate_user_story_completion_percentage(user_stories),
          version_consistency: check_version_consistency(feature, user_stories),
          last_updated: Time.current
        }
      end
    end

    # UserStory統計計算
    def self.calculate_user_story_statistics(user_story)
      cache_key = "user_story_statistics_#{user_story.id}_#{user_story.updated_on.to_i}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        tracker_names = Kanban::TrackerHierarchy.tracker_names
        child_tracker_names = [tracker_names[:task], tracker_names[:test], tracker_names[:bug]]
        child_items = user_story.children.joins(:tracker)
                                .where(trackers: { name: child_tracker_names })
                                .includes(:status, :tracker)

        {
          user_story_id: user_story.id,
          total_child_items: child_items.count,
          child_items_by_type: group_child_items_by_type(child_items),
          completed_child_items: count_completed_issues(child_items),
          completion_percentage: calculate_child_item_completion_percentage(child_items),
          version_consistency: check_version_consistency(user_story, child_items),
          blocking_issues: find_blocking_issues(user_story),
          last_updated: Time.current
        }
      end
    end

    # Version統計計算
    def self.calculate_version_statistics(version)
      cache_key = "version_statistics_#{version.id}_#{version.updated_on.to_i}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        issues = Issue.where(fixed_version_id: version.id)
                     .includes(:tracker, :status)

        tracker_names = Kanban::TrackerHierarchy.tracker_names
        epic_tracker_name = tracker_names[:epic]
        feature_tracker_name = tracker_names[:feature]
        epics = issues.joins(:tracker).where(trackers: { name: epic_tracker_name })
        features = issues.joins(:tracker).where(trackers: { name: feature_tracker_name })

        {
          version_id: version.id,
          total_epics: epics.count,
          total_features: features.count,
          total_issues: issues.count,
          issues_by_status: group_issues_by_status(issues),
          completion_trend: calculate_completion_trend(version),
          release_readiness: calculate_release_readiness(version, issues),
          last_updated: Time.current
        }
      end
    end

    # 統計キャッシュクリア
    def self.clear_statistics_cache(issue)
      cache_keys = []

      # 自身のキャッシュ
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      case issue.tracker.name
      when tracker_names[:epic]
        cache_keys << "epic_statistics_#{issue.id}_*"
      when tracker_names[:feature]
        cache_keys << "feature_statistics_#{issue.id}_*"
        cache_keys << "epic_statistics_#{issue.parent_id}_*" if issue.parent
      when tracker_names[:user_story]
        cache_keys << "user_story_statistics_#{issue.id}_*"
        if issue.parent
          cache_keys << "feature_statistics_#{issue.parent_id}_*"
          cache_keys << "epic_statistics_#{issue.parent.parent_id}_*" if issue.parent.parent
        end
      when tracker_names[:task], tracker_names[:test], tracker_names[:bug]
        if issue.parent
          cache_keys << "user_story_statistics_#{issue.parent_id}_*"
          if issue.parent.parent
            cache_keys << "feature_statistics_#{issue.parent.parent_id}_*"
            cache_keys << "epic_statistics_#{issue.parent.parent.parent_id}_*" if issue.parent.parent.parent
          end
        end
      end

      # Versionキャッシュ
      if issue.fixed_version_id
        cache_keys << "version_statistics_#{issue.fixed_version_id}_*"
      end

      cache_keys.each do |pattern|
        Rails.cache.delete_matched(pattern)
      end
    end

    private

    def self.count_user_stories(features)
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      features.flat_map do |feature|
        feature.children.joins(:tracker).where(trackers: { name: user_story_tracker_name })
      end.count
    end

    def self.count_child_items(features)
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      user_story_tracker_name = tracker_names[:user_story]
      child_tracker_names = [tracker_names[:task], tracker_names[:test], tracker_names[:bug]]

      user_stories = features.flat_map do |feature|
        feature.children.joins(:tracker).where(trackers: { name: user_story_tracker_name })
      end

      user_stories.flat_map do |user_story|
        user_story.children.joins(:tracker)
                  .where(trackers: { name: child_tracker_names })
      end.count
    end

    def self.count_completed_issues(issues)
      issues.joins(:status).where(issue_statuses: { is_closed: true }).count
    end

    def self.count_completed_user_stories(features)
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      user_stories = features.flat_map do |feature|
        feature.children.joins(:tracker).where(trackers: { name: user_story_tracker_name })
      end

      count_completed_issues(user_stories)
    end

    def self.count_completed_child_items(features)
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      user_story_tracker_name = tracker_names[:user_story]
      child_tracker_names = [tracker_names[:task], tracker_names[:test], tracker_names[:bug]]

      user_stories = features.flat_map do |feature|
        feature.children.joins(:tracker).where(trackers: { name: user_story_tracker_name })
      end

      child_items = user_stories.flat_map do |user_story|
        user_story.children.joins(:tracker)
                  .where(trackers: { name: child_tracker_names })
      end

      count_completed_issues(child_items)
    end

    def self.calculate_completion_percentage(issues)
      return 0.0 if issues.empty?

      completed = count_completed_issues(issues)
      ((completed.to_f / issues.count) * 100).round(2)
    end

    def self.calculate_user_story_completion_percentage(user_stories)
      calculate_completion_percentage(user_stories)
    end

    def self.calculate_child_item_completion_percentage(child_items)
      calculate_completion_percentage(child_items)
    end

    def self.group_child_items_by_type(child_items)
      child_items.group_by { |item| item.tracker.name }
                 .transform_values(&:count)
    end

    def self.group_issues_by_status(issues)
      issues.group_by { |issue| issue.status.name }
            .transform_values(&:count)
    end

    def self.check_version_consistency(parent, children)
      return true if children.empty?

      parent_version = parent.fixed_version_id
      children.all? { |child| child.fixed_version_id == parent_version }
    end

    def self.find_blocking_issues(user_story)
      blocking_issues = []

      # 未完了のTask
      task_tracker_name = Kanban::TrackerHierarchy.tracker_names[:task]
      incomplete_tasks = user_story.children.joins(:tracker, :status)
                                  .where(trackers: { name: task_tracker_name })
                                  .where.not(issue_statuses: { is_closed: true })

      if incomplete_tasks.any?
        blocking_issues << {
          type: 'incomplete_tasks',
          count: incomplete_tasks.count,
          issues: incomplete_tasks.pluck(:id, :subject)
        }
      end

      # 失敗したTest
      test_tracker_name = Kanban::TrackerHierarchy.tracker_names[:test]
      failed_tests = user_story.children.joins(:tracker, :status)
                              .where(trackers: { name: test_tracker_name })
                              .where(issue_statuses: { name: ['Failed', 'Rejected'] })

      if failed_tests.any?
        blocking_issues << {
          type: 'failed_tests',
          count: failed_tests.count,
          issues: failed_tests.pluck(:id, :subject)
        }
      end

      blocking_issues
    end

    def self.calculate_completion_trend(version)
      # 過去30日間の完了率推移を計算
      30.days.ago.to_date.upto(Date.current).map do |date|
        issues_at_date = Issue.where(fixed_version_id: version.id)
                             .where('created_on <= ?', date.end_of_day)

        completed_at_date = issues_at_date.joins(:status)
                                         .where(issue_statuses: { is_closed: true })
                                         .where('closed_on <= ?', date.end_of_day)

        completion_rate = if issues_at_date.count > 0
                           (completed_at_date.count.to_f / issues_at_date.count * 100).round(2)
                         else
                           0.0
                         end

        {
          date: date,
          completion_rate: completion_rate,
          total_issues: issues_at_date.count,
          completed_issues: completed_at_date.count
        }
      end
    end

    def self.calculate_release_readiness(version, issues)
      return 0.0 if issues.empty?

      # リリース準備度の計算ロジック
      total_score = 0
      max_score = 0

      # Epic完成度 (40%)
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      epic_tracker_name = tracker_names[:epic]
      epics = issues.joins(:tracker).where(trackers: { name: epic_tracker_name })
      if epics.any?
        epic_completion = epics.joins(:status).where(issue_statuses: { is_closed: true }).count.to_f / epics.count
        total_score += epic_completion * 40
      end
      max_score += 40

      # Feature完成度 (30%)
      feature_tracker_name = tracker_names[:feature]
      features = issues.joins(:tracker).where(trackers: { name: feature_tracker_name })
      if features.any?
        feature_completion = features.joins(:status).where(issue_statuses: { is_closed: true }).count.to_f / features.count
        total_score += feature_completion * 30
      end
      max_score += 30

      # Test合格率 (30%)
      test_tracker_name = tracker_names[:test]
      tests = issues.joins(:tracker).where(trackers: { name: test_tracker_name })
      if tests.any?
        passed_tests = tests.joins(:status).where(issue_statuses: { name: ['Resolved', 'Closed'] }).count.to_f
        test_pass_rate = passed_tests / tests.count
        total_score += test_pass_rate * 30
      end
      max_score += 30

      return 0.0 if max_score == 0

      (total_score / max_score * 100).round(2)
    end
  end
end