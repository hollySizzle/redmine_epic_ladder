# frozen_string_literal: true

module Kanban
  # Feature統計情報モデル
  # Feature配下のUserStory、Task/Test/Bugの統計データを管理
  class FeatureStatistics
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :feature_id, :integer
    attribute :total_user_stories, :integer, default: 0
    attribute :total_child_items, :integer, default: 0
    attribute :child_items_by_type, :string, default: '{}'
    attribute :completion_percentage, :decimal, default: 0.0
    attribute :version_consistency, :boolean, default: true
    attribute :last_updated, :datetime

    validates :feature_id, presence: true, numericality: { greater_than: 0 }
    validates :total_user_stories, :total_child_items, numericality: { greater_than_or_equal_to: 0 }
    validates :completion_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    def self.for_feature(feature)
      statistics_data = StatisticsEngine.calculate_feature_statistics(feature)
      new(statistics_data)
    end

    def self.for_feature_ids(feature_ids)
      feature_ids.map do |feature_id|
        feature = Issue.find(feature_id)
        for_feature(feature)
      end
    end

    # 統計データを更新
    def refresh!
      feature = Issue.find(feature_id)
      updated_data = StatisticsEngine.calculate_feature_statistics(feature)
      assign_attributes(updated_data)
      self
    end

    # 子要素タイプ別統計をハッシュで取得
    def child_items_by_type_hash
      return {} if child_items_by_type.blank?

      case child_items_by_type
      when String
        JSON.parse(child_items_by_type)
      when Hash
        child_items_by_type
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end

    # 子要素タイプ別統計を設定
    def child_items_by_type=(value)
      case value
      when Hash
        super(value.to_json)
      when String
        super(value)
      else
        super('{}')
      end
    end

    # Task完了率
    def task_completion_rate
      type_stats = child_items_by_type_hash
      task_count = type_stats['Task'] || 0
      return 0.0 if task_count.zero?

      feature = Issue.find(feature_id)
      completed_tasks = feature.children
                               .joins(:tracker, :status)
                               .where(trackers: { name: 'Task' })
                               .where(issue_statuses: { is_closed: true })
                               .count

      (completed_tasks.to_f / task_count * 100).round(2)
    end

    # Test合格率
    def test_pass_rate
      type_stats = child_items_by_type_hash
      test_count = type_stats['Test'] || 0
      return 0.0 if test_count.zero?

      feature = Issue.find(feature_id)
      passed_tests = feature.children
                            .joins(:tracker, :status)
                            .where(trackers: { name: 'Test' })
                            .where(issue_statuses: { name: ['Resolved', 'Closed'] })
                            .count

      (passed_tests.to_f / test_count * 100).round(2)
    end

    # Bug修正率
    def bug_fix_rate
      type_stats = child_items_by_type_hash
      bug_count = type_stats['Bug'] || 0
      return 0.0 if bug_count.zero?

      feature = Issue.find(feature_id)
      fixed_bugs = feature.children
                          .joins(:tracker, :status)
                          .where(trackers: { name: 'Bug' })
                          .where(issue_statuses: { is_closed: true })
                          .count

      (fixed_bugs.to_f / bug_count * 100).round(2)
    end

    # 品質スコア計算
    def quality_score
      return 100.0 if total_child_items.zero?

      type_stats = child_items_by_type_hash
      task_weight = 0.4
      test_weight = 0.4
      bug_weight = 0.2

      score = 0.0
      total_weight = 0.0

      if (type_stats['Task'] || 0) > 0
        score += task_completion_rate * task_weight
        total_weight += task_weight
      end

      if (type_stats['Test'] || 0) > 0
        score += test_pass_rate * test_weight
        total_weight += test_weight
      end

      if (type_stats['Bug'] || 0) > 0
        score += bug_fix_rate * bug_weight
        total_weight += bug_weight
      end

      return 100.0 if total_weight.zero?

      (score / total_weight).round(2)
    end

    # 開発効率指標
    def development_efficiency
      return 0.0 if total_user_stories.zero?

      feature = Issue.find(feature_id)
      return 0.0 unless feature.created_on

      days_elapsed = (Date.current - feature.created_on.to_date).to_i
      return 0.0 if days_elapsed <= 0

      user_stories_per_day = total_user_stories.to_f / days_elapsed
      user_stories_per_day.round(3)
    end

    # ブロッキング問題の特定
    def blocking_issues
      feature = Issue.find(feature_id)
      blocking_issues = []

      # 未完了のUserStoryが多い場合
      incomplete_user_stories = feature.children
                                       .joins(:tracker, :status)
                                       .where(trackers: { name: 'UserStory' })
                                       .where.not(issue_statuses: { is_closed: true })

      if incomplete_user_stories.count > (total_user_stories * 0.7)
        blocking_issues << {
          type: 'many_incomplete_user_stories',
          severity: 'high',
          count: incomplete_user_stories.count,
          message: '多数のUserStoryが未完了です'
        }
      end

      # 失敗したTestが多い場合
      type_stats = child_items_by_type_hash
      if (type_stats['Test'] || 0) > 0 && test_pass_rate < 70
        blocking_issues << {
          type: 'low_test_pass_rate',
          severity: 'medium',
          rate: test_pass_rate,
          message: 'Test合格率が低いです'
        }
      end

      # 未修正のBugが多い場合
      if (type_stats['Bug'] || 0) > 0 && bug_fix_rate < 80
        blocking_issues << {
          type: 'many_unfixed_bugs',
          severity: 'high',
          rate: bug_fix_rate,
          message: '未修正のBugが多数あります'
        }
      end

      blocking_issues
    end

    # JSON表現
    def as_json(options = {})
      {
        feature_id: feature_id,
        total_user_stories: total_user_stories,
        total_child_items: total_child_items,
        child_items_by_type: child_items_by_type_hash,
        completion_percentage: completion_percentage,
        version_consistency: version_consistency,
        last_updated: last_updated,
        task_completion_rate: task_completion_rate,
        test_pass_rate: test_pass_rate,
        bug_fix_rate: bug_fix_rate,
        quality_score: quality_score,
        development_efficiency: development_efficiency,
        blocking_issues: blocking_issues
      }
    end
  end
end