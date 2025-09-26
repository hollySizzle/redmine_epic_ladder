# frozen_string_literal: true

module Kanban
  # Epic統計情報モデル
  # Epic配下のFeature、UserStory、Task/Test/Bugの統計データを管理
  class EpicStatistics
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :epic_id, :integer
    attribute :total_features, :integer, default: 0
    attribute :total_user_stories, :integer, default: 0
    attribute :total_child_items, :integer, default: 0
    attribute :completed_features, :integer, default: 0
    attribute :completed_user_stories, :integer, default: 0
    attribute :completed_child_items, :integer, default: 0
    attribute :completion_percentage, :decimal, default: 0.0
    attribute :version_consistency, :boolean, default: true
    attribute :last_updated, :datetime

    validates :epic_id, presence: true, numericality: { greater_than: 0 }
    validates :total_features, :total_user_stories, :total_child_items,
              :completed_features, :completed_user_stories, :completed_child_items,
              numericality: { greater_than_or_equal_to: 0 }
    validates :completion_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    def self.for_epic(epic)
      statistics_data = StatisticsEngine.calculate_epic_statistics(epic)
      new(statistics_data)
    end

    def self.for_epic_ids(epic_ids)
      epic_ids.map do |epic_id|
        epic = Issue.find(epic_id)
        for_epic(epic)
      end
    end

    # 統計データを更新
    def refresh!
      epic = Issue.find(epic_id)
      updated_data = StatisticsEngine.calculate_epic_statistics(epic)
      assign_attributes(updated_data)
      self
    end

    # 完了予測日を計算
    def estimated_completion_date
      return nil if completion_percentage >= 100.0 || completion_percentage.zero?

      epic = Issue.find(epic_id)
      return nil unless epic.created_on

      days_elapsed = (Date.current - epic.created_on.to_date).to_i
      return nil if days_elapsed <= 0

      progress_per_day = completion_percentage / days_elapsed
      remaining_percentage = 100.0 - completion_percentage
      remaining_days = (remaining_percentage / progress_per_day).ceil

      Date.current + remaining_days.days
    end

    # リスク評価
    def risk_assessment
      risks = []

      # 進捗遅延リスク
      if completion_percentage < expected_completion_percentage
        risks << {
          type: 'progress_delay',
          severity: 'medium',
          message: '進捗が予定より遅れています'
        }
      end

      # バージョン不整合リスク
      unless version_consistency
        risks << {
          type: 'version_inconsistency',
          severity: 'high',
          message: 'バージョンの不整合があります'
        }
      end

      # 子要素バランスリスク
      if total_features > 0 && (total_user_stories.to_f / total_features) < 2
        risks << {
          type: 'insufficient_user_stories',
          severity: 'low',
          message: 'FeatureあたりのUserStory数が少ない可能性があります'
        }
      end

      risks
    end

    # 健康度スコア (0-100)
    def health_score
      score = 100

      # 進捗遅延ペナルティ
      if completion_percentage < expected_completion_percentage
        delay_penalty = (expected_completion_percentage - completion_percentage) * 0.5
        score -= delay_penalty
      end

      # バージョン不整合ペナルティ
      score -= 20 unless version_consistency

      # 子要素不足ペナルティ
      if total_features > 0 && total_user_stories.zero?
        score -= 30
      end

      [score, 0].max.round(1)
    end

    # JSON表現
    def as_json(options = {})
      {
        epic_id: epic_id,
        total_features: total_features,
        total_user_stories: total_user_stories,
        total_child_items: total_child_items,
        completed_features: completed_features,
        completed_user_stories: completed_user_stories,
        completed_child_items: completed_child_items,
        completion_percentage: completion_percentage,
        version_consistency: version_consistency,
        last_updated: last_updated,
        estimated_completion_date: estimated_completion_date,
        risk_assessment: risk_assessment,
        health_score: health_score
      }
    end

    private

    def expected_completion_percentage
      epic = Issue.find_by(id: epic_id)
      return 0.0 unless epic&.created_on && epic.due_date

      total_days = (epic.due_date - epic.created_on.to_date).to_i
      elapsed_days = (Date.current - epic.created_on.to_date).to_i

      return 100.0 if elapsed_days >= total_days

      (elapsed_days.to_f / total_days * 100).round(2)
    end
  end
end