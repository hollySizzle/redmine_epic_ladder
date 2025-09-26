# StateTransition技術実装仕様

## 概要
カンバンカラム移動時の状態遷移管理。ToDo→InProgress→Ready for Test→Released遷移制御とワークフロー整合性保証。

## 状態マッピング定義

### カラム-ステータス マッピング
```ruby
# app/models/kanban/column_status_mapping.rb
module Kanban
  class ColumnStatusMapping
    COLUMN_MAPPINGS = {
      'todo' => {
        'Epic' => ['New', 'Open'],
        'Feature' => ['New', 'Open'],
        'UserStory' => ['New', 'Open', 'ToDo'],
        'Task' => ['New', 'Open', 'ToDo'],
        'Test' => ['New', 'Open', 'ToDo'],
        'Bug' => ['New', 'Open', 'Reported']
      },
      'in_progress' => {
        'Epic' => ['In Progress'],
        'Feature' => ['In Progress'],
        'UserStory' => ['In Progress', 'Development'],
        'Task' => ['In Progress', 'Assigned'],
        'Test' => ['In Progress', 'Testing'],
        'Bug' => ['In Progress', 'Assigned']
      },
      'ready_for_test' => {
        'Epic' => ['Ready for Release'],
        'Feature' => ['Ready for Release'],
        'UserStory' => ['Ready for Test', 'QA Ready'],
        'Task' => ['Resolved', 'Done'],
        'Test' => ['Ready for Test', 'QA Ready'],
        'Bug' => ['Resolved', 'Fixed']
      },
      'released' => {
        'Epic' => ['Done', 'Closed'],
        'Feature' => ['Done', 'Closed'],
        'UserStory' => ['Released', 'Done', 'Closed'],
        'Task' => ['Closed'],
        'Test' => ['Closed', 'Passed'],
        'Bug' => ['Closed', 'Verified']
      }
    }.freeze

    def self.get_status_for_column(column_id, tracker_name)
      statuses = COLUMN_MAPPINGS.dig(column_id, tracker_name) || []
      statuses.first
    end

    def self.get_column_for_status(status_name, tracker_name)
      COLUMN_MAPPINGS.each do |column_id, tracker_mappings|
        tracker_statuses = tracker_mappings[tracker_name] || []
        return column_id if tracker_statuses.include?(status_name)
      end
      'todo'
    end

    def self.valid_transition?(from_column, to_column, tracker_name)
      valid_transitions = {
        'todo' => ['in_progress'],
        'in_progress' => ['todo', 'ready_for_test'],
        'ready_for_test' => ['in_progress', 'released'],
        'released' => ['ready_for_test']
      }

      allowed = valid_transitions[from_column] || []
      allowed.include?(to_column)
    end
  end
end
```

## 状態遷移サービス

### 状態遷移管理サービス
```ruby
# app/services/kanban/state_transition_service.rb
module Kanban
  class StateTransitionService
    def self.transition_to_column(issue, target_column)
      current_column = ColumnStatusMapping.get_column_for_status(issue.status.name, issue.tracker.name)

      unless ColumnStatusMapping.valid_transition?(current_column, target_column, issue.tracker.name)
        raise InvalidTransitionError, "#{current_column} -> #{target_column} 遷移は無効です"
      end

      target_status_name = ColumnStatusMapping.get_status_for_column(target_column, issue.tracker.name)
      target_status = IssueStatus.find_by!(name: target_status_name)

      ActiveRecord::Base.transaction do
        old_status = issue.status
        issue.update!(status: target_status)

        handle_post_transition_actions(issue, old_status, target_status, target_column)

        {
          success: true,
          issue: issue,
          old_status: old_status.name,
          new_status: target_status.name,
          column: target_column,
          triggered_actions: collect_triggered_actions(issue, target_column)
        }
      end
    rescue => e
      { success: false, error: e.message, issue_id: issue.id }
    end

    def self.bulk_transition(issues, target_column)
      results = []

      ActiveRecord::Base.transaction do
        issues.each do |issue|
          result = transition_to_column(issue, target_column)
          results << result.merge(issue_id: issue.id)
        end
      end

      { results: results, success_count: results.count { |r| r[:success] } }
    end

    private

    def self.handle_post_transition_actions(issue, old_status, new_status, target_column)
      case target_column
      when 'ready_for_test'
        TestGenerationService.ensure_test_exists_for_ready_state(issue) if issue.tracker.name == 'UserStory'
      when 'released'
        validate_release_conditions(issue) if issue.tracker.name == 'UserStory'
      end
    end

    def self.validate_release_conditions(user_story)
      incomplete_tasks = user_story.children.joins(:tracker, :status)
                                   .where(trackers: { name: 'Task' })
                                   .where.not(statuses: { name: ['Done', 'Closed'] })

      if incomplete_tasks.exists?
        raise TransitionBlockedError, "未完了のTaskがあります"
      end

      blocking_tests = IssueRelation.joins(:issue_from => [:tracker, :status])
                                   .where(issue_to: user_story, relation_type: 'blocks')
                                   .where(issues: { tracker: { name: 'Test' } })
                                   .where.not(issues: { status: { name: ['Done', 'Closed', 'Passed'] } })

      if blocking_tests.exists?
        raise TransitionBlockedError, "未完了のTestがあります"
      end
    end

    def self.collect_triggered_actions(issue, target_column)
      actions = []
      case target_column
      when 'ready_for_test'
        actions << { type: 'test_generation_triggered', issue_id: issue.id } if issue.tracker.name == 'UserStory'
      when 'released'
        actions << { type: 'release_validation_passed', issue_id: issue.id } if issue.tracker.name == 'UserStory'
      end
      actions
    end

    class InvalidTransitionError < StandardError; end
    class TransitionBlockedError < StandardError; end
  end
end
```

## API実装

### 状態遷移コントローラー
```ruby
# app/controllers/kanban/state_transitions_controller.rb
class Kanban::StateTransitionsController < ApplicationController
  before_action :require_login, :find_project, :authorize

  def move_card
    @issue = Issue.find(params[:card_id])
    target_column = params[:column_id]

    result = StateTransitionService.transition_to_column(@issue, target_column)

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  def bulk_move_cards
    issue_ids = params[:card_ids]
    target_column = params[:column_id]

    issues = Issue.where(id: issue_ids)
    result = StateTransitionService.bulk_transition(issues, target_column)

    render json: result
  end

  def transition_preview
    @issue = Issue.find(params[:issue_id])
    target_column = params[:target_column]

    preview = {
      issue: issue_json(@issue),
      current_column: @issue.current_kanban_column,
      target_column: target_column,
      valid_transition: @issue.can_transition_to_column?(target_column),
      blockers: @issue.release_blockers
    }

    render json: preview
  end

  private

  def issue_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      current_column: issue.current_kanban_column
    }
  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize
    deny_access unless User.current.allowed_to?(:edit_issues, @project)
  end
end
```

## React実装

### 状態遷移API
```javascript
// assets/javascripts/kanban/utils/StateTransitionAPI.js
export class StateTransitionAPI {
  static async moveCard(projectId, cardId, targetColumn) {
    const response = await fetch(`/kanban/projects/${projectId}/move_card`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ card_id: cardId, column_id: targetColumn })
    });

    if (!response.ok) throw new Error('カード移動失敗');
    return await response.json();
  }

  static async getTransitionPreview(projectId, issueId, targetColumn) {
    const response = await fetch(
      `/kanban/projects/${projectId}/transition_preview?issue_id=${issueId}&target_column=${targetColumn}`
    );
    return await response.json();
  }
}
```

## テスト実装

### サービステスト
```ruby
# spec/services/kanban/state_transition_service_spec.rb
RSpec.describe Kanban::StateTransitionService do
  let(:user_story) { create(:issue, tracker: create(:tracker, name: 'UserStory')) }

  describe '.transition_to_column' do
    it '有効な遷移は成功' do
      result = described_class.transition_to_column(user_story, 'in_progress')

      expect(result[:success]).to be true
      expect(result[:column]).to eq('in_progress')
      expect(user_story.reload.status.name).to eq('In Progress')
    end

    it '無効な遷移は失敗' do
      result = described_class.transition_to_column(user_story, 'released')

      expect(result[:success]).to be false
      expect(result[:error]).to include('遷移は無効です')
    end
  end
end
```

---

*カンバンカラム移動時の状態遷移制御とワークフロー整合性を保証*