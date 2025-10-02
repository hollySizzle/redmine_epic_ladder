# frozen_string_literal: true

module Kanban
  # Version統計情報モデル
  # Version全体のEpic、Feature統計と完了率推移を管理
  class VersionStatistics
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :version_id, :integer
    attribute :total_epics, :integer, default: 0
    attribute :total_features, :integer, default: 0
    attribute :total_issues, :integer, default: 0
    attribute :issues_by_status, :string, default: '{}'
    attribute :completion_trend, :string, default: '[]'
    attribute :release_readiness, :decimal, default: 0.0
    attribute :last_updated, :datetime

    validates :version_id, presence: true, numericality: { greater_than: 0 }
    validates :total_epics, :total_features, :total_issues, numericality: { greater_than_or_equal_to: 0 }
    validates :release_readiness, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    def self.for_version(version)
      statistics_data = StatisticsEngine.calculate_version_statistics(version)
      new(statistics_data)
    end

    def self.for_version_ids(version_ids)
      version_ids.map do |version_id|
        version = Version.find(version_id)
        for_version(version)
      end
    end

    # 統計データを更新
    def refresh!
      version = Version.find(version_id)
      updated_data = StatisticsEngine.calculate_version_statistics(version)
      assign_attributes(updated_data)
      self
    end

    # ステータス別Issue統計をハッシュで取得
    def issues_by_status_hash
      return {} if issues_by_status.blank?

      case issues_by_status
      when String
        JSON.parse(issues_by_status)
      when Hash
        issues_by_status
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end

    # ステータス別Issue統計を設定
    def issues_by_status=(value)
      case value
      when Hash
        super(value.to_json)
      when String
        super(value)
      else
        super('{}')
      end
    end

    # 完了率推移データを配列で取得
    def completion_trend_array
      return [] if completion_trend.blank?

      case completion_trend
      when String
        JSON.parse(completion_trend)
      when Array
        completion_trend
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    # 完了率推移データを設定
    def completion_trend=(value)
      case value
      when Array
        super(value.to_json)
      when String
        super(value)
      else
        super('[]')
      end
    end

    # 現在の完了率
    def current_completion_rate
      return 0.0 if total_issues.zero?

      status_stats = issues_by_status_hash
      closed_statuses = ['Resolved', 'Closed']
      completed_count = closed_statuses.sum { |status| status_stats[status] || 0 }

      (completed_count.to_f / total_issues * 100).round(2)
    end

    # 予定完了日との比較
    def schedule_variance
      version = Version.find(version_id)
      return nil unless version.effective_date

      if Date.current <= version.effective_date
        # 予定内
        days_remaining = (version.effective_date - Date.current).to_i
        completion_needed_per_day = (100.0 - current_completion_rate) / days_remaining if days_remaining > 0

        {
          status: 'on_time',
          days_remaining: days_remaining,
          completion_needed_per_day: completion_needed_per_day || 0,
          message: "予定まで#{days_remaining}日"
        }
      else
        # 遅延
        days_overdue = (Date.current - version.effective_date).to_i

        {
          status: 'overdue',
          days_overdue: days_overdue,
          remaining_completion: 100.0 - current_completion_rate,
          message: "#{days_overdue}日遅延"
        }
      end
    end

    # ベロシティ計算（直近7日間）
    def velocity_last_week
      trend_data = completion_trend_array
      return 0.0 if trend_data.size < 2

      recent_data = trend_data.last(7)
      return 0.0 if recent_data.size < 2

      first_rate = recent_data.first['completion_rate'] || 0
      last_rate = recent_data.last['completion_rate'] || 0

      velocity = (last_rate - first_rate) / recent_data.size
      velocity.round(3)
    end

    # リリース可能性判定
    def release_feasibility
      version = Version.find(version_id)
      return nil unless version.effective_date

      variance = schedule_variance
      return nil unless variance

      if variance[:status] == 'overdue'
        {
          feasible: false,
          confidence: 0,
          message: '既に遅延しており、追加対応が必要です'
        }
      else
        required_velocity = variance[:completion_needed_per_day] || 0
        current_velocity = velocity_last_week

        if current_velocity <= 0
          confidence = 10
        elsif required_velocity <= current_velocity
          confidence = 90
        else
          velocity_ratio = current_velocity / required_velocity
          confidence = [velocity_ratio * 70, 90].min.round
        end

        {
          feasible: confidence >= 50,
          confidence: confidence,
          current_velocity: current_velocity,
          required_velocity: required_velocity,
          message: confidence >= 70 ? 'リリース可能性が高い' :
                  confidence >= 50 ? 'リリース可能だが注意が必要' :
                  'リリース困難、計画見直し推奨'
        }
      end
    end

    # 重要な問題の特定
    def critical_issues
      version = Version.find(version_id)
      critical_issues = []

      # Epic単位での問題
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      epics = version.issues.joins(:tracker).where(trackers: { name: epic_tracker_name })
      epics.each do |epic|
        epic_stats = EpicStatistics.for_epic(epic)

        if epic_stats.health_score < 50
          critical_issues << {
            type: 'unhealthy_epic',
            severity: 'high',
            issue_id: epic.id,
            issue_subject: epic.subject,
            health_score: epic_stats.health_score,
            message: "Epic「#{epic.subject}」の健康度が低下"
          }
        end
      end

      # Feature単位での問題
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      features = version.issues.joins(:tracker).where(trackers: { name: feature_tracker_name })
      high_risk_features = features.select do |feature|
        feature_stats = FeatureStatistics.for_feature(feature)
        feature_stats.blocking_issues.any? { |issue| issue[:severity] == 'high' }
      end

      high_risk_features.each do |feature|
        critical_issues << {
          type: 'high_risk_feature',
          severity: 'high',
          issue_id: feature.id,
          issue_subject: feature.subject,
          message: "Feature「#{feature.subject}」に高リスク問題"
        }
      end

      # 全体的な進捗遅延
      if release_readiness < 50 && schedule_variance&.dig(:status) == 'overdue'
        critical_issues << {
          type: 'overall_delay',
          severity: 'critical',
          message: 'Version全体で深刻な進捗遅延',
          release_readiness: release_readiness
        }
      end

      critical_issues
    end

    # JSON表現
    def as_json(options = {})
      {
        version_id: version_id,
        total_epics: total_epics,
        total_features: total_features,
        total_issues: total_issues,
        issues_by_status: issues_by_status_hash,
        completion_trend: completion_trend_array,
        release_readiness: release_readiness,
        current_completion_rate: current_completion_rate,
        schedule_variance: schedule_variance,
        velocity_last_week: velocity_last_week,
        release_feasibility: release_feasibility,
        critical_issues: critical_issues,
        last_updated: last_updated
      }
    end
  end
end