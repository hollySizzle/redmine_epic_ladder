# ValidationGuard技術実装仕様

## 概要
UserStoryリリース前のガード検証システム。子Task完了・Test合格・重大Bug解決の3層チェック機能。

## 検証ルール定義

### リリースガード設定
```ruby
# app/models/kanban/release_guard_rules.rb
module Kanban
  class ReleaseGuardRules
    GUARD_RULES = {
      user_story_release: {
        required_conditions: [
          :all_child_tasks_completed,
          :all_blocking_tests_passed,
          :no_critical_bugs_remaining,
          :version_assigned
        ],
        warning_conditions: [
          :no_description,
          :no_acceptance_criteria,
          :assigned_to_missing
        ]
      },
      epic_release: {
        required_conditions: [
          :all_child_features_completed
        ]
      },
      feature_release: {
        required_conditions: [
          :all_child_user_stories_completed
        ]
      }
    }.freeze

    CRITICAL_PRIORITIES = ['High', 'Urgent', 'Immediate'].freeze
    COMPLETION_STATUSES = ['Done', 'Closed', 'Resolved', 'Passed', 'Verified'].freeze

    def self.get_required_conditions(tracker_name)
      rule_key = "#{tracker_name.downcase}_release".to_sym
      GUARD_RULES.dig(rule_key, :required_conditions) || []
    end

    def self.get_warning_conditions(tracker_name)
      rule_key = "#{tracker_name.downcase}_release".to_sym
      GUARD_RULES.dig(rule_key, :warning_conditions) || []
    end

    def self.critical_priority?(priority_name)
      CRITICAL_PRIORITIES.include?(priority_name)
    end

    def self.completed_status?(status_name)
      COMPLETION_STATUSES.include?(status_name)
    end
  end
end
```

## バリデーションサービス

### リリースガードサービス
```ruby
# app/services/kanban/release_guard_service.rb
module Kanban
  class ReleaseGuardService
    def self.validate_release(issue)
      validator = new(issue)
      validator.perform_validation
    end

    def initialize(issue)
      @issue = issue
      @validation_result = {
        can_release: true,
        blockers: [],
        warnings: [],
        details: {}
      }
    end

    def perform_validation
      required_conditions = ReleaseGuardRules.get_required_conditions(@issue.tracker.name)
      warning_conditions = ReleaseGuardRules.get_warning_conditions(@issue.tracker.name)

      required_conditions.each do |condition|
        check_required_condition(condition)
      end

      warning_conditions.each do |condition|
        check_warning_condition(condition)
      end

      @validation_result[:can_release] = @validation_result[:blockers].empty?
      @validation_result
    end

    private

    def check_required_condition(condition)
      case condition
      when :all_child_tasks_completed
        check_child_tasks_completion
      when :all_blocking_tests_passed
        check_blocking_tests_status
      when :no_critical_bugs_remaining
        check_critical_bugs_status
      when :version_assigned
        check_version_assignment
      when :all_child_features_completed
        check_child_features_completion
      when :all_child_user_stories_completed
        check_child_user_stories_completion
      end
    end

    def check_warning_condition(condition)
      case condition
      when :no_description
        check_description_presence
      when :no_acceptance_criteria
        check_acceptance_criteria
      when :assigned_to_missing
        check_assignee_presence
      end
    end

    def check_child_tasks_completion
      incomplete_tasks = @issue.children
                               .joins(:tracker, :status)
                               .where(trackers: { name: 'Task' })
                               .where.not(statuses: { name: ReleaseGuardRules::COMPLETION_STATUSES })

      if incomplete_tasks.exists?
        add_blocker(
          :incomplete_tasks,
          "未完了のTaskがあります",
          { count: incomplete_tasks.count, tasks: incomplete_tasks.pluck(:id, :subject) }
        )
      end
    end

    def check_blocking_tests_status
      blocking_tests = IssueRelation.joins(:issue_from => [:tracker, :status])
                                   .where(issue_to: @issue, relation_type: 'blocks')
                                   .where(issues: { tracker: { name: 'Test' } })
                                   .where.not(issues: { status: { name: ReleaseGuardRules::COMPLETION_STATUSES } })

      if blocking_tests.exists?
        test_details = blocking_tests.joins(:issue_from).pluck('issues.id', 'issues.subject')
        add_blocker(
          :incomplete_tests,
          "未完了のTestがあります",
          { count: blocking_tests.count, tests: test_details }
        )
      end
    end

    def check_critical_bugs_status
      critical_bugs = IssueRelation.joins(:issue_from => [:tracker, :priority, :status])
                                  .where(issue_to: @issue, relation_type: 'blocks')
                                  .where(issues: { tracker: { name: 'Bug' } })
                                  .where(issues: { priority: { name: ReleaseGuardRules::CRITICAL_PRIORITIES } })
                                  .where.not(issues: { status: { name: ReleaseGuardRules::COMPLETION_STATUSES } })

      if critical_bugs.exists?
        bug_details = critical_bugs.joins(:issue_from).pluck('issues.id', 'issues.subject', 'issues.priority_id')
        add_blocker(
          :critical_bugs,
          "重大なBugが残っています",
          { count: critical_bugs.count, bugs: bug_details }
        )
      end
    end

    def check_version_assignment
      unless @issue.fixed_version
        add_blocker(
          :no_version,
          "バージョンが設定されていません",
          { issue_id: @issue.id }
        )
      end
    end

    def check_child_features_completion
      incomplete_features = @issue.children
                                  .joins(:tracker, :status)
                                  .where(trackers: { name: 'Feature' })
                                  .where.not(statuses: { name: ReleaseGuardRules::COMPLETION_STATUSES })

      if incomplete_features.exists?
        add_blocker(
          :incomplete_features,
          "未完了のFeatureがあります",
          { count: incomplete_features.count, features: incomplete_features.pluck(:id, :subject) }
        )
      end
    end

    def check_child_user_stories_completion
      incomplete_user_stories = @issue.children
                                       .joins(:tracker, :status)
                                       .where(trackers: { name: 'UserStory' })
                                       .where.not(statuses: { name: ReleaseGuardRules::COMPLETION_STATUSES })

      if incomplete_user_stories.exists?
        add_blocker(
          :incomplete_user_stories,
          "未完了のUserStoryがあります",
          { count: incomplete_user_stories.count, user_stories: incomplete_user_stories.pluck(:id, :subject) }
        )
      end
    end

    def check_description_presence
      if @issue.description.blank?
        add_warning(
          :no_description,
          "説明が設定されていません",
          { issue_id: @issue.id }
        )
      end
    end

    def check_acceptance_criteria
      if @issue.tracker.name == 'UserStory' && !@issue.description&.include?('受入条件')
        add_warning(
          :no_acceptance_criteria,
          "受入条件が明記されていません",
          { issue_id: @issue.id }
        )
      end
    end

    def check_assignee_presence
      unless @issue.assigned_to
        add_warning(
          :no_assignee,
          "担当者が設定されていません",
          { issue_id: @issue.id }
        )
      end
    end

    def add_blocker(type, message, details = {})
      @validation_result[:blockers] << {
        type: type,
        message: message,
        severity: :error
      }
      @validation_result[:details][type] = details
    end

    def add_warning(type, message, details = {})
      @validation_result[:warnings] << {
        type: type,
        message: message,
        severity: :warning
      }
      @validation_result[:details][type] = details
    end
  end
end
```

## モデル拡張

### Issue検証拡張
```ruby
# app/models/concerns/kanban/validation_guard.rb
module Kanban
  module ValidationGuard
    extend ActiveSupport::Concern

    included do
      validate :validate_release_conditions, if: :status_requires_release_validation?
    end

    def release_validation_result
      @release_validation_result ||= ReleaseGuardService.validate_release(self)
    end

    def can_release?
      release_validation_result[:can_release]
    end

    def release_blockers
      release_validation_result[:blockers]
    end

    def release_warnings
      release_validation_result[:warnings]
    end

    def release_blocker_summary
      blockers = release_blockers
      return "リリース可能" if blockers.empty?

      summary = blockers.map { |blocker| blocker[:message] }.join("、")
      "ブロック中: #{summary}"
    end

    def has_critical_blockers?
      release_blockers.any? { |blocker| blocker[:severity] == :error }
    end

    def validation_details
      release_validation_result[:details]
    end

    private

    def status_requires_release_validation?
      return false unless status_id_changed?

      released_statuses = ['Released', 'Done', 'Closed']
      new_status_name = status&.name

      released_statuses.include?(new_status_name) &&
      %w[Epic Feature UserStory].include?(tracker.name)
    end

    def validate_release_conditions
      result = ReleaseGuardService.validate_release(self)

      unless result[:can_release]
        result[:blockers].each do |blocker|
          errors.add(:status_id, blocker[:message])
        end
      end
    end
  end
end

Issue.include(Kanban::ValidationGuard)
```

## API実装

### 検証コントローラー
```ruby
# app/controllers/kanban/validations_controller.rb
class Kanban::ValidationsController < ApplicationController
  before_action :require_login, :find_project, :authorize

  def release_validation
    @issue = Issue.find(params[:issue_id])

    validation_result = ReleaseGuardService.validate_release(@issue)

    render json: {
      issue: issue_summary(@issue),
      validation: validation_result,
      recommendations: generate_recommendations(validation_result)
    }
  end

  def bulk_validation
    issue_ids = params[:issue_ids]
    issues = Issue.where(id: issue_ids)

    results = issues.map do |issue|
      validation_result = ReleaseGuardService.validate_release(issue)
      {
        issue_id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        can_release: validation_result[:can_release],
        blocker_count: validation_result[:blockers].count,
        warning_count: validation_result[:warnings].count,
        summary: issue.release_blocker_summary
      }
    end

    render json: {
      results: results,
      summary: {
        total: results.count,
        can_release: results.count { |r| r[:can_release] },
        blocked: results.count { |r| !r[:can_release] }
      }
    }
  end

  def validation_rules
    tracker_name = params[:tracker_name]

    rules = {
      required_conditions: ReleaseGuardRules.get_required_conditions(tracker_name),
      warning_conditions: ReleaseGuardRules.get_warning_conditions(tracker_name),
      critical_priorities: ReleaseGuardRules::CRITICAL_PRIORITIES,
      completion_statuses: ReleaseGuardRules::COMPLETION_STATUSES
    }

    render json: rules
  end

  private

  def issue_summary(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name
    }
  end

  def generate_recommendations(validation_result)
    recommendations = []

    validation_result[:blockers].each do |blocker|
      case blocker[:type]
      when :incomplete_tasks
        recommendations << "子Taskを完了してください"
      when :incomplete_tests
        recommendations << "関連Testを完了してください"
      when :critical_bugs
        recommendations << "重大Bugを解決してください"
      when :no_version
        recommendations << "バージョンを設定してください"
      end
    end

    validation_result[:warnings].each do |warning|
      case warning[:type]
      when :no_description
        recommendations << "説明を追加することを推奨"
      when :no_acceptance_criteria
        recommendations << "受入条件を明記することを推奨"
      when :no_assignee
        recommendations << "担当者を設定することを推奨"
      end
    end

    recommendations
  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize
    deny_access unless User.current.allowed_to?(:view_issues, @project)
  end
end
```

## React実装

### バリデーション表示コンポーネント
```javascript
// assets/javascripts/kanban/components/ValidationStatusBadge.jsx
import React, { useState, useEffect } from 'react';
import { ValidationAPI } from '../utils/ValidationAPI';

export const ValidationStatusBadge = ({ issue, onClick }) => {
  const [validationStatus, setValidationStatus] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (issue.tracker === 'UserStory' || issue.tracker === 'Feature' || issue.tracker === 'Epic') {
      checkValidationStatus();
    }
  }, [issue.id, issue.status]);

  const checkValidationStatus = async () => {
    setLoading(true);
    try {
      const result = await ValidationAPI.getReleaseValidation(issue.project_id, issue.id);
      setValidationStatus(result.validation);
    } catch (error) {
      console.error('バリデーション状態取得エラー:', error);
    } finally {
      setLoading(false);
    }
  };

  const getBadgeStyle = () => {
    if (loading) return { backgroundColor: '#6c757d', color: 'white' };

    if (!validationStatus) return null;

    if (validationStatus.can_release) {
      return { backgroundColor: '#28a745', color: 'white' };
    } else {
      return { backgroundColor: '#dc3545', color: 'white' };
    }
  };

  const getBadgeText = () => {
    if (loading) return '確認中';
    if (!validationStatus) return null;

    if (validationStatus.can_release) {
      return 'リリース可';
    } else {
      const blockerCount = validationStatus.blockers.length;
      return `ブロック中(${blockerCount})`;
    }
  };

  const badgeStyle = getBadgeStyle();
  const badgeText = getBadgeText();

  if (!badgeStyle || !badgeText) return null;

  return (
    <span
      className="validation-status-badge"
      style={badgeStyle}
      onClick={() => onClick?.(validationStatus)}
      title={validationStatus?.blockers.map(b => b.message).join(', ')}
    >
      {badgeText}
    </span>
  );
};
```

### バリデーション詳細モーダル
```javascript
// assets/javascripts/kanban/components/ValidationDetailModal.jsx
import React from 'react';

export const ValidationDetailModal = ({ validationResult, issue, onClose, onRevalidate }) => {
  if (!validationResult) return null;

  const { validation, recommendations } = validationResult;

  return (
    <div className="modal-overlay">
      <div className="validation-detail-modal">
        <h3>リリース検証結果 - {issue.subject}</h3>

        <div className="validation-summary">
          <div className={`status-indicator ${validation.can_release ? 'success' : 'error'}`}>
            {validation.can_release ? '✓ リリース可能' : '✗ リリースブロック中'}
          </div>
        </div>

        {validation.blockers.length > 0 && (
          <div className="validation-blockers">
            <h4>ブロック要因:</h4>
            <ul>
              {validation.blockers.map((blocker, index) => (
                <li key={index} className="blocker-item error">
                  <span className="blocker-icon">⚠️</span>
                  {blocker.message}
                </li>
              ))}
            </ul>
          </div>
        )}

        {validation.warnings.length > 0 && (
          <div className="validation-warnings">
            <h4>改善提案:</h4>
            <ul>
              {validation.warnings.map((warning, index) => (
                <li key={index} className="warning-item warning">
                  <span className="warning-icon">⚡</span>
                  {warning.message}
                </li>
              ))}
            </ul>
          </div>
        )}

        {recommendations.length > 0 && (
          <div className="validation-recommendations">
            <h4>推奨アクション:</h4>
            <ul>
              {recommendations.map((rec, index) => (
                <li key={index} className="recommendation-item">
                  <span className="rec-icon">💡</span>
                  {rec}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="modal-actions">
          <button onClick={onRevalidate}>再検証</button>
          <button onClick={onClose} className="btn-primary">閉じる</button>
        </div>
      </div>
    </div>
  );
};
```

### バリデーションAPI
```javascript
// assets/javascripts/kanban/utils/ValidationAPI.js
export class ValidationAPI {
  static async getReleaseValidation(projectId, issueId) {
    const response = await fetch(
      `/kanban/projects/${projectId}/release_validation?issue_id=${issueId}`
    );
    if (!response.ok) throw new Error('バリデーション取得失敗');
    return await response.json();
  }

  static async bulkValidation(projectId, issueIds) {
    const response = await fetch(`/kanban/projects/${projectId}/bulk_validation`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ issue_ids: issueIds })
    });

    if (!response.ok) throw new Error('一括バリデーション失敗');
    return await response.json();
  }
}
```

## テスト実装

### サービステスト
```ruby
# spec/services/kanban/release_guard_service_spec.rb
RSpec.describe Kanban::ReleaseGuardService do
  let(:user_story) { create(:issue, tracker: create(:tracker, name: 'UserStory')) }

  describe '#perform_validation' do
    context '全ての条件が満たされている場合' do
      it 'リリース可能と判定' do
        user_story.update!(fixed_version: create(:version))

        result = described_class.validate_release(user_story)

        expect(result[:can_release]).to be true
        expect(result[:blockers]).to be_empty
      end
    end

    context '未完了Taskがある場合' do
      let!(:incomplete_task) do
        create(:issue, tracker: create(:tracker, name: 'Task'), parent: user_story, status: create(:issue_status, name: 'New'))
      end

      it 'リリース不可と判定' do
        result = described_class.validate_release(user_story)

        expect(result[:can_release]).to be false
        expect(result[:blockers]).to include(hash_including(type: :incomplete_tasks))
      end
    end
  end
end
```

---

*UserStoryリリース前の3層ガード検証。子Task完了・Test合格・重大Bug解決を確実にチェック*