# AutoGeneration技術実装仕様

## 概要
UserStory作成時のTest自動生成とblocks関係作成。Ready for Test移動時の検証とTest確実作成。

## 自動生成サービス

### Test自動生成サービス
```ruby
# app/services/kanban/test_generation_service.rb
module Kanban
  class TestGenerationService
    TEMPLATE_CONFIGS = {
      default: {
        subject_template: 'Test: %{user_story_subject}',
        description_template: "ユーザーストーリー: %{user_story_subject}\n\n受入条件:\n- [ ] 機能が正常に動作する\n- [ ] エラーハンドリングが適切\n- [ ] UIが仕様通り"
      }
    }.freeze

    def self.generate_test_for_user_story(user_story, options = {})
      return unless user_story.tracker.name == 'UserStory'

      existing_test = find_existing_test(user_story)
      return existing_test if existing_test && !options[:force_recreate]

      ActiveRecord::Base.transaction do
        test_issue = create_test_issue(user_story, options)
        create_blocks_relation(test_issue, user_story)
        propagate_version_to_test(test_issue, user_story)

        Rails.logger.info "Test自動生成完了: UserStory##{user_story.id} -> Test##{test_issue.id}"

        { test_issue: test_issue, relation_created: true }
      end
    rescue => e
      Rails.logger.error "Test自動生成エラー: #{e.message}"
      { error: e.message }
    end

    def self.ensure_test_exists_for_ready_state(user_story)
      return unless user_story.tracker.name == 'UserStory'
      return if find_existing_test(user_story)

      generate_test_for_user_story(user_story, auto_generated: true)
    end

    def self.find_existing_test(user_story)
      user_story.children.joins(:tracker).find_by(trackers: { name: 'Test' })
    end

    private

    def self.create_test_issue(user_story, options)
      template = TEMPLATE_CONFIGS[:default]
      test_tracker = Tracker.find_by!(name: 'Test')

      Issue.create!(
        project: user_story.project,
        tracker: test_tracker,
        subject: template[:subject_template] % { user_story_subject: user_story.subject },
        description: template[:description_template] % { user_story_subject: user_story.subject },
        author: User.current,
        assigned_to: options[:assigned_to] || user_story.assigned_to,
        priority: user_story.priority,
        parent: user_story,
        status: IssueStatus.find_by(name: 'New') || IssueStatus.first
      )
    end

    def self.create_blocks_relation(test_issue, user_story)
      IssueRelation.create!(
        issue_from: test_issue,
        issue_to: user_story,
        relation_type: 'blocks'
      )
    end

    def self.propagate_version_to_test(test_issue, user_story)
      return unless user_story.fixed_version

      test_issue.update!(fixed_version: user_story.fixed_version)
    end
  end
end
```

### Bug自動関連付けサービス
```ruby
# app/services/kanban/bug_relation_service.rb
module Kanban
  class BugRelationService
    HIGH_PRIORITY_NAMES = ['High', 'Urgent', 'Immediate'].freeze

    def self.create_bug_relations(bug)
      return unless bug.tracker.name == 'Bug'

      if bug.parent&.tracker&.name == 'UserStory'
        create_blocks_relation_for_user_story(bug, bug.parent)
      end

      if high_priority?(bug) && bug.parent&.tracker&.name == 'UserStory'
        assign_version_from_user_story(bug, bug.parent)
      end
    end

    def self.create_blocks_relation_for_user_story(bug, user_story)
      existing_relation = IssueRelation.find_by(
        issue_from: bug,
        issue_to: user_story,
        relation_type: 'blocks'
      )

      return if existing_relation

      IssueRelation.create!(
        issue_from: bug,
        issue_to: user_story,
        relation_type: 'blocks'
      )

      Rails.logger.info "Bug blocks関係作成: Bug##{bug.id} blocks UserStory##{user_story.id}"
    end

    def self.assign_version_from_user_story(bug, user_story)
      return unless user_story.fixed_version
      return if bug.fixed_version

      bug.update!(fixed_version: user_story.fixed_version)
      Rails.logger.info "高優先度Bug版本割当: Bug##{bug.id} -> Version:#{user_story.fixed_version.name}"
    end

    private

    def self.high_priority?(bug)
      HIGH_PRIORITY_NAMES.include?(bug.priority.name)
    end
  end
end
```

## モデル拡張

### Issue自動生成拡張
```ruby
# app/models/concerns/kanban/auto_generation.rb
module Kanban
  module AutoGeneration
    extend ActiveSupport::Concern

    included do
      after_create :trigger_auto_generation
      after_update :handle_status_change_auto_generation
    end

    def ready_for_test_status_names
      ['Ready for Test', 'Testing', 'QA Ready']
    end

    def moved_to_ready_for_test?
      saved_change_to_status_id? &&
      ready_for_test_status_names.include?(status.name) &&
      !ready_for_test_status_names.include?(status_id_before_last_save&.then { |id| IssueStatus.find(id).name })
    end

    private

    def trigger_auto_generation
      case tracker.name
      when 'UserStory'
        generate_test_async
      when 'Bug'
        create_bug_relations_async
      end
    end

    def handle_status_change_auto_generation
      if tracker.name == 'UserStory' && moved_to_ready_for_test?
        ensure_test_exists_async
      end
    end

    def generate_test_async
      TestGenerationJob.perform_later(self)
    end

    def create_bug_relations_async
      BugRelationJob.perform_later(self)
    end

    def ensure_test_exists_async
      EnsureTestExistsJob.perform_later(self)
    end
  end
end

Issue.include(Kanban::AutoGeneration)
```

## Job実装

### Test生成Job
```ruby
# app/jobs/kanban/test_generation_job.rb
module Kanban
  class TestGenerationJob < ApplicationJob
    queue_as :auto_generation

    def perform(user_story)
      result = TestGenerationService.generate_test_for_user_story(user_story)

      if result[:error]
        Rails.logger.error "Test生成Job失敗: #{result[:error]}"
      else
        Rails.logger.info "Test生成Job完了: Test##{result[:test_issue]&.id}"
      end
    end
  end
end
```

### Bug関連付けJob
```ruby
# app/jobs/kanban/bug_relation_job.rb
module Kanban
  class BugRelationJob < ApplicationJob
    queue_as :auto_generation

    def perform(bug)
      BugRelationService.create_bug_relations(bug)
    end
  end
end
```

### Test存在確認Job
```ruby
# app/jobs/kanban/ensure_test_exists_job.rb
module Kanban
  class EnsureTestExistsJob < ApplicationJob
    queue_as :auto_generation

    def perform(user_story)
      TestGenerationService.ensure_test_exists_for_ready_state(user_story)
    end
  end
end
```

## API実装

### 自動生成管理コントローラー
```ruby
# app/controllers/kanban/auto_generation_controller.rb
class Kanban::AutoGenerationController < ApplicationController
  before_action :require_login, :find_project, :authorize

  def generate_test
    @user_story = Issue.find(params[:user_story_id])

    unless @user_story.tracker.name == 'UserStory'
      render json: { error: 'UserStoryのみTest生成可能' }, status: :unprocessable_entity
      return
    end

    result = TestGenerationService.generate_test_for_user_story(@user_story, force_recreate: params[:force])

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: {
        success: true,
        test_issue: issue_json(result[:test_issue]),
        relation_created: result[:relation_created]
      }
    end
  end

  def batch_generate_tests
    user_story_ids = params[:user_story_ids]
    results = []

    user_story_ids.each do |user_story_id|
      user_story = Issue.find(user_story_id)
      next unless user_story.tracker.name == 'UserStory'

      result = TestGenerationService.generate_test_for_user_story(user_story)
      results << {
        user_story_id: user_story_id,
        success: !result[:error],
        test_issue_id: result[:test_issue]&.id,
        error: result[:error]
      }
    end

    render json: { results: results, total_processed: results.count }
  end

  def auto_generation_status
    @user_story = Issue.find(params[:user_story_id])

    status = {
      user_story: issue_json(@user_story),
      has_test: TestGenerationService.find_existing_test(@user_story).present?,
      test_issue: nil,
      blocks_relations: []
    }

    if existing_test = TestGenerationService.find_existing_test(@user_story)
      status[:test_issue] = issue_json(existing_test)
      status[:blocks_relations] = existing_test.relations_from
                                             .where(relation_type: 'blocks', issue_to: @user_story)
                                             .map { |rel| relation_json(rel) }
    end

    render json: status
  end

  private

  def issue_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      assigned_to: issue.assigned_to&.name,
      created_on: issue.created_on
    }
  end

  def relation_json(relation)
    {
      id: relation.id,
      relation_type: relation.relation_type,
      issue_from_id: relation.issue_from_id,
      issue_to_id: relation.issue_to_id
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

### Test自動生成コンポーネント
```javascript
// assets/javascripts/kanban/components/TestGenerationButton.jsx
import React, { useState } from 'react';
import { AutoGenerationAPI } from '../utils/AutoGenerationAPI';

export const TestGenerationButton = ({ userStory, onTestGenerated }) => {
  const [loading, setLoading] = useState(false);
  const [hasTest, setHasTest] = useState(false);

  useEffect(() => {
    checkAutoGenerationStatus();
  }, [userStory.id]);

  const checkAutoGenerationStatus = async () => {
    try {
      const status = await AutoGenerationAPI.getAutoGenerationStatus(userStory.project_id, userStory.id);
      setHasTest(status.has_test);
    } catch (error) {
      console.error('自動生成状態取得エラー:', error);
    }
  };

  const handleGenerateTest = async (force = false) => {
    setLoading(true);
    try {
      const result = await AutoGenerationAPI.generateTest(userStory.project_id, userStory.id, { force });
      setHasTest(true);
      onTestGenerated?.(result.test_issue);
    } catch (error) {
      console.error('Test生成エラー:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="test-generation-controls">
      {!hasTest ? (
        <button
          className="btn-generate-test"
          onClick={() => handleGenerateTest()}
          disabled={loading}
        >
          {loading ? 'Test生成中...' : 'Test作成'}
        </button>
      ) : (
        <div className="test-exists">
          <span className="test-exists-badge">Test作成済み</span>
          <button
            className="btn-regenerate-test"
            onClick={() => handleGenerateTest(true)}
            disabled={loading}
          >
            再作成
          </button>
        </div>
      )}
    </div>
  );
};
```

### 自動生成API
```javascript
// assets/javascripts/kanban/utils/AutoGenerationAPI.js
export class AutoGenerationAPI {
  static async generateTest(projectId, userStoryId, options = {}) {
    const response = await fetch(`/kanban/projects/${projectId}/generate_test`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        user_story_id: userStoryId,
        force: options.force || false
      })
    });

    if (!response.ok) throw new Error('Test生成失敗');
    return await response.json();
  }

  static async batchGenerateTests(projectId, userStoryIds) {
    const response = await fetch(`/kanban/projects/${projectId}/batch_generate_tests`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ user_story_ids: userStoryIds })
    });

    if (!response.ok) throw new Error('一括Test生成失敗');
    return await response.json();
  }

  static async getAutoGenerationStatus(projectId, userStoryId) {
    const response = await fetch(
      `/kanban/projects/${projectId}/auto_generation_status?user_story_id=${userStoryId}`
    );

    if (!response.ok) throw new Error('自動生成状態取得失敗');
    return await response.json();
  }
}
```

## テスト実装

### サービステスト
```ruby
# spec/services/kanban/test_generation_service_spec.rb
RSpec.describe Kanban::TestGenerationService do
  let(:project) { create(:project) }
  let(:user_story) { create(:issue, project: project, tracker: create(:tracker, name: 'UserStory')) }

  describe '.generate_test_for_user_story' do
    it 'UserStoryにTestを自動生成' do
      result = described_class.generate_test_for_user_story(user_story)

      expect(result[:test_issue]).to be_present
      expect(result[:test_issue].tracker.name).to eq('Test')
      expect(result[:test_issue].parent).to eq(user_story)
      expect(result[:relation_created]).to be true
    end

    it 'Testとblocks関係を作成' do
      result = described_class.generate_test_for_user_story(user_story)
      test_issue = result[:test_issue]

      relation = IssueRelation.find_by(
        issue_from: test_issue,
        issue_to: user_story,
        relation_type: 'blocks'
      )
      expect(relation).to be_present
    end

    it '既存Testがある場合は作成しない' do
      existing_test = create(:issue, project: project, tracker: create(:tracker, name: 'Test'), parent: user_story)

      result = described_class.generate_test_for_user_story(user_story)

      expect(result[:test_issue]).to eq(existing_test)
      expect(Issue.where(tracker: { name: 'Test' }, parent: user_story).count).to eq(1)
    end
  end
end
```

### Job テスト
```ruby
# spec/jobs/kanban/test_generation_job_spec.rb
RSpec.describe Kanban::TestGenerationJob do
  let(:user_story) { create(:issue, tracker: create(:tracker, name: 'UserStory')) }

  it 'Test生成サービスを呼び出し' do
    expect(Kanban::TestGenerationService).to receive(:generate_test_for_user_story).with(user_story)

    described_class.perform_now(user_story)
  end
end
```

## Hook実装

### 自動生成Hook
```ruby
# lib/kanban/hooks/auto_generation_hook.rb
module Kanban::Hooks
  class AutoGenerationHook < Redmine::Hook::ViewListener
    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      trigger_auto_generation(issue) if issue.persisted?
    end

    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      handle_status_change(issue) if issue.saved_change_to_status_id?
    end

    private

    def trigger_auto_generation(issue)
      case issue.tracker.name
      when 'UserStory'
        TestGenerationJob.perform_later(issue)
      when 'Bug'
        BugRelationJob.perform_later(issue)
      end
    end

    def handle_status_change(issue)
      if issue.tracker.name == 'UserStory' && issue.moved_to_ready_for_test?
        EnsureTestExistsJob.perform_later(issue)
      end
    end
  end
end
```

---

*UserStory→Test自動生成とblocks関係作成をJob/Hook統合で実装*