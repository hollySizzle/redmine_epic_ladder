# frozen_string_literal: true

module Kanban
  # 検証ガードサービス
  # リリース前3層ガード検証システム（子Task完了・Test合格・重大Bug解決）
  class ValidationGuardService
    # 3層ガード検証の実行
    def self.validate_release_readiness(user_story)
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      return { error: 'UserStoryではありません' } unless user_story.tracker.name == user_story_tracker_name

      results = {
        task_completion: validate_task_completion(user_story),
        test_validation: validate_test_success(user_story),
        bug_resolution: validate_critical_bugs(user_story)
      }

      # 全体の検証結果を集約
      all_passed = results.values.all? { |result| result[:passed] }
      blocking_issues = results.values.flat_map { |result| result[:issues] || [] }

      {
        release_ready: all_passed,
        validation_results: results,
        blocking_issues: blocking_issues,
        summary: generate_validation_summary(results)
      }
    end

    # レイヤー1: 子Taskの完了検証
    def self.validate_task_completion(user_story)
      task_tracker_name = Kanban::TrackerHierarchy.tracker_names[:task]
      incomplete_tasks = user_story.children.joins(:tracker, :status)
                                  .where(trackers: { name: task_tracker_name })
                                  .where.not(issue_statuses: { name: ['Resolved', 'Closed'] })

      {
        layer: 1,
        name: 'Task完了検証',
        passed: incomplete_tasks.empty?,
        issues: incomplete_tasks.map { |task| format_issue_info(task, 'タスク未完了') },
        count: { total: count_child_tasks(user_story), incomplete: incomplete_tasks.count }
      }
    end

    # レイヤー2: Test合格検証
    def self.validate_test_success(user_story)
      test_tracker_name = Kanban::TrackerHierarchy.tracker_names[:test]
      tests = user_story.children.joins(:tracker).where(trackers: { name: test_tracker_name })
      failed_tests = tests.joins(:status).where.not(issue_statuses: { name: ['Resolved', 'Closed', 'Passed'] })

      {
        layer: 2,
        name: 'Test合格検証',
        passed: tests.any? && failed_tests.empty?,
        issues: failed_tests.map { |test| format_issue_info(test, 'テスト失敗') },
        count: { total: tests.count, failed: failed_tests.count },
        warning: tests.empty? ? 'Testが存在しません' : nil
      }
    end

    # レイヤー3: 重大Bug解決検証
    def self.validate_critical_bugs(user_story)
      bug_tracker_name = Kanban::TrackerHierarchy.tracker_names[:bug]
      critical_bugs = user_story.children.joins(:tracker, :priority, :status)
                               .where(trackers: { name: bug_tracker_name })
                               .where(enumerations: { name: ['High', 'Urgent', 'Immediate'] })
                               .where.not(issue_statuses: { name: ['Resolved', 'Closed'] })

      {
        layer: 3,
        name: '重大Bug解決検証',
        passed: critical_bugs.empty?,
        issues: critical_bugs.map { |bug| format_issue_info(bug, "重大Bug未解決 (優先度: #{bug.priority.name})") },
        count: { total: count_critical_bugs(user_story), unresolved: critical_bugs.count }
      }
    end

    # ガード突破の試行
    def self.attempt_guard_bypass(user_story, options = {})
      validation = validate_release_readiness(user_story)

      # 強制突破フラグがある場合
      if options[:force_bypass] && options[:bypass_reason].present?
        log_forced_bypass(user_story, validation, options[:bypass_reason])
        return { bypassed: true, reason: options[:bypass_reason], original_validation: validation }
      end

      # 自動突破条件の判定
      auto_bypass = check_auto_bypass_conditions(validation)
      if auto_bypass[:allowed]
        log_auto_bypass(user_story, auto_bypass)
        return { bypassed: true, auto: true, reason: auto_bypass[:reason], validation: validation }
      end

      { bypassed: false, validation: validation }
    end

    private

    def self.count_child_tasks(user_story)
      task_tracker_name = Kanban::TrackerHierarchy.tracker_names[:task]
      user_story.children.joins(:tracker).where(trackers: { name: task_tracker_name }).count
    end

    def self.count_critical_bugs(user_story)
      bug_tracker_name = Kanban::TrackerHierarchy.tracker_names[:bug]
      user_story.children.joins(:tracker, :priority)
               .where(trackers: { name: bug_tracker_name })
               .where(enumerations: { name: ['High', 'Urgent', 'Immediate'] }).count
    end

    def self.format_issue_info(issue, reason)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        reason: reason
      }
    end

    def self.generate_validation_summary(results)
      passed_layers = results.count { |_, result| result[:passed] }
      "#{passed_layers}/3層のガードを通過"
    end

    def self.check_auto_bypass_conditions(validation)
      # 自動突破の条件を定義（現在は保守的にfalse）
      { allowed: false, reason: nil }
    end

    def self.log_forced_bypass(user_story, validation, reason)
      Rails.logger.warn "Forced validation bypass: UserStory##{user_story.id}, Reason: #{reason}"
    end

    def self.log_auto_bypass(user_story, auto_bypass)
      Rails.logger.info "Auto validation bypass: UserStory##{user_story.id}, Reason: #{auto_bypass[:reason]}"
    end
  end
end