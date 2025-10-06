# frozen_string_literal: true

module EpicGrid
  module IssueExtensions
    extend ActiveSupport::Concern

    # ========================================
    # Feature移動 + Version伝播
    # ========================================

    # Feature を別の Epic とバージョンに移動
    # @param target_epic_id [Integer] 移動先のEpic ID
    # @param target_version_id [Integer, nil] 移動先のバージョンID
    def epic_grid_move_to_cell(target_epic_id, target_version_id)
      transaction do
        # 親とバージョンを更新
        self.parent_issue_id = target_epic_id
        self.fixed_version_id = target_version_id
        save!

        # 子要素にバージョンを伝播
        epic_grid_propagate_version_to_children(target_version_id)
      end
    end

    # 子孫全てにバージョンを伝播
    # @param version_id [Integer, nil] 伝播するバージョンID
    def epic_grid_propagate_version_to_children(version_id = nil)
      target_version_id = version_id || self.fixed_version_id

      descendants.find_each do |descendant|
        descendant.reload
        descendant.update!(fixed_version_id: target_version_id)
      end
    end

    # ========================================
    # MSW準拠のJSON出力
    # ========================================

    # 正規化されたJSON形式で出力（Epic用）
    # @return [Hash] MSW NormalizedAPIResponse準拠のHash
    def epic_grid_as_normalized_json
      base = {
        id: id.to_s,
        subject: subject,
        description: description || '',
        status: status.is_closed? ? 'closed' : 'open',
        fixed_version_id: fixed_version_id&.to_s,
        tracker_id: tracker_id,
        created_on: created_on.iso8601,
        updated_on: updated_on.iso8601
      }

      # トラッカー別に異なるフィールドを追加
      case tracker.name
      when EpicGrid::TrackerHierarchy.tracker_names[:epic]
        base.merge(
          feature_ids: children.pluck(:id).map(&:to_s),
          statistics: {
            total_features: children.count,
            completed_features: 0,
            total_user_stories: 0,
            total_child_items: 0,
            completion_percentage: 0
          }
        )
      when EpicGrid::TrackerHierarchy.tracker_names[:feature]
        base.merge(
          title: subject,
          parent_epic_id: parent_id&.to_s,
          user_story_ids: children.pluck(:id).map(&:to_s),
          version_source: fixed_version_id ? 'direct' : 'none',
          statistics: {
            total_user_stories: children.count,
            completed_user_stories: 0,
            total_child_items: 0,
            child_items_by_type: { tasks: 0, tests: 0, bugs: 0 },
            completion_percentage: 0
          },
          assigned_to_id: assigned_to_id,
          priority_id: priority_id
        )
      when EpicGrid::TrackerHierarchy.tracker_names[:user_story]
        base.merge(
          title: subject,
          parent_feature_id: parent_id&.to_s,
          task_ids: children.where(tracker: Tracker.find_by(name: EpicGrid::TrackerHierarchy.tracker_names[:task])).pluck(:id).map(&:to_s),
          test_ids: children.where(tracker: Tracker.find_by(name: EpicGrid::TrackerHierarchy.tracker_names[:test])).pluck(:id).map(&:to_s),
          bug_ids: children.where(tracker: Tracker.find_by(name: EpicGrid::TrackerHierarchy.tracker_names[:bug])).pluck(:id).map(&:to_s),
          version_source: fixed_version_id ? 'direct' : 'none',
          expansion_state: true,
          statistics: {
            total_tasks: 0,
            completed_tasks: 0,
            total_tests: 0,
            passed_tests: 0,
            total_bugs: 0,
            resolved_bugs: 0,
            completion_percentage: 0
          },
          assigned_to_id: assigned_to_id,
          estimated_hours: estimated_hours
        )
      when EpicGrid::TrackerHierarchy.tracker_names[:task]
        base.merge(
          title: subject,
          parent_user_story_id: parent_id&.to_s,
          assigned_to_id: assigned_to_id,
          estimated_hours: estimated_hours,
          spent_hours: 0.0,
          done_ratio: done_ratio || 0
        )
      when EpicGrid::TrackerHierarchy.tracker_names[:test]
        base.merge(
          title: subject,
          parent_user_story_id: parent_id&.to_s,
          test_result: 'pending',
          assigned_to_id: assigned_to_id
        )
      when EpicGrid::TrackerHierarchy.tracker_names[:bug]
        base.merge(
          title: subject,
          parent_user_story_id: parent_id&.to_s,
          severity: 'minor',
          assigned_to_id: assigned_to_id
        )
      else
        base
      end
    end

    # ========================================
    # JSON変換・階層判定・親探索
    # ========================================

    # Issueを詳細JSON形式で出力（カンバンカラム情報含む）
    # @return [Hash] カンバン用JSON
    def epic_grid_build_issue_json
      {
        id: id,
        subject: subject,
        tracker: tracker.name,
        status: status.name,
        priority: priority&.name,
        assigned_to: assigned_to&.name,
        fixed_version: fixed_version&.name,
        parent_id: parent_id,
        hierarchy_level: epic_grid_determine_hierarchy_level,
        created_on: created_on.iso8601,
        updated_on: updated_on.iso8601,
        column: epic_grid_determine_column_for_status,
        epic: epic_grid_find_epic_name
      }
    end

    # トラッカー階層レベルを判定
    # @return [Integer] 階層レベル（1: Epic, 2: Feature, 3: UserStory, 4: Task/Test/Bug）
    def epic_grid_determine_hierarchy_level
      tracker_names = EpicGrid::TrackerHierarchy.tracker_names
      hierarchy_map = {
        tracker_names[:epic] => 1,
        tracker_names[:feature] => 2,
        tracker_names[:user_story] => 3
      }
      hierarchy_map.fetch(tracker.name, 4)
    end

    # ステータスから対応するカンバンカラムを判定
    # @return [String] カラムID ('todo', 'in_progress', 'ready_for_test', 'released')
    def epic_grid_determine_column_for_status
      case status.name
      when 'New', 'Open'
        'todo'
      when 'In Progress', 'Assigned'
        'in_progress'
      when 'Review', 'Ready for Test'
        'ready_for_test'
      when 'Resolved', 'Closed'
        'released'
      else
        'todo'
      end
    end

    # 親階層を辿ってEpic名を取得
    # @return [String, nil] Epic名（見つからない場合はnil）
    def epic_grid_find_epic_name
      epic_tracker_name = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      current = parent
      while current
        return current.subject if current.tracker.name == epic_tracker_name
        current = current.parent
      end
      nil
    end

    # ========================================
    # 統計・完了率・リスク評価
    # ========================================

    # Epic統計を計算
    # @return [Hash] Epic統計情報
    def epic_grid_calculate_epic_statistics
      features = children

      {
        total_features: features.count,
        completed_features: features.joins(:status).where(issue_statuses: { is_closed: true }).count,
        completion_ratio: epic_grid_calculate_completion_ratio(features)
      }
    end

    # Feature完了率を計算
    # @return [Float] 完了率（0-100）
    def epic_grid_calculate_feature_completion
      user_stories = children.joins(:tracker).where(
        trackers: { name: EpicGrid::TrackerHierarchy.tracker_names[:user_story] }
      )
      return 0.0 if user_stories.empty?

      completed_count = user_stories.joins(:status).where(issue_statuses: { is_closed: true }).count
      (completed_count.to_f / user_stories.count * 100).round(1)
    end

    # UserStory完了率を計算
    # @return [Float] 完了率（0-100）
    def epic_grid_calculate_user_story_completion
      task_tracker = EpicGrid::TrackerHierarchy.tracker_names[:task]
      test_tracker = EpicGrid::TrackerHierarchy.tracker_names[:test]

      tasks_and_tests = children.joins(:tracker).where(trackers: { name: [task_tracker, test_tracker] })
      return 0.0 if tasks_and_tests.empty?

      completed_count = tasks_and_tests.joins(:status).where(issue_statuses: { is_closed: true }).count
      (completed_count.to_f / tasks_and_tests.count * 100).round(1)
    end

    # 完了率を計算（汎用）
    # @param items [ActiveRecord::Relation] 計算対象のIssue群
    # @return [Float] 完了率（0-100）
    def epic_grid_calculate_completion_ratio(items)
      return 0.0 if items.empty?

      completed_count = items.joins(:status).where(issue_statuses: { is_closed: true }).count
      (completed_count.to_f / items.count * 100).round(1)
    end

    # Featureリスク評価
    # @return [Hash] リスク評価結果
    def epic_grid_assess_feature_risk
      risk_factors = []

      # 期限遅れリスク
      if fixed_version_id.present?
        version = Version.find_by(id: fixed_version_id)
        if version&.effective_date && version.effective_date < Date.current
          risk_factors << 'overdue_version'
        end
      end

      # 未割当リスク
      user_story_tracker = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
      user_stories = children.joins(:tracker).where(trackers: { name: user_story_tracker })
      if user_stories.where(assigned_to_id: nil).exists?
        risk_factors << 'unassigned_user_stories'
      end

      # テスト不足リスク
      test_tracker = EpicGrid::TrackerHierarchy.tracker_names[:test]
      user_stories.each do |us|
        tests = us.children.joins(:tracker).where(trackers: { name: test_tracker })
        if tests.empty?
          risk_factors << 'missing_tests'
          break
        end
      end

      {
        level: epic_grid_calculate_risk_level(risk_factors),
        factors: risk_factors
      }
    end

    # リスクレベルを計算
    # @param factors [Array<String>] リスク要因の配列
    # @return [String] リスクレベル ('low', 'medium', 'high')
    def epic_grid_calculate_risk_level(factors)
      case factors.count
      when 0
        'low'
      when 1
        'medium'
      else
        'high'
      end
    end
  end
end
