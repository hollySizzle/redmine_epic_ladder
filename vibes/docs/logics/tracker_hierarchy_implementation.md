# TrackerHierarchy技術実装仕様

## 概要
Epic→Feature→UserStory→Task/Test 4段階構造のRedmine実装。階層制約とリレーション自動管理。

## トラッカー定義

### マイグレーション
```ruby
# db/migrate/001_create_kanban_trackers.rb
def up
  [
    { name: 'Epic', position: 1 },
    { name: 'Feature', position: 2 },
    { name: 'UserStory', position: 3 },
    { name: 'Task', position: 4 },
    { name: 'Test', position: 5 },
    { name: 'Bug', position: 6 }
  ].each { |attrs| Tracker.create!(attrs) unless Tracker.find_by(name: attrs[:name]) }
end
```

### 階層制約モデル
```ruby
# app/models/kanban/tracker_hierarchy.rb
module Kanban::TrackerHierarchy
  RULES = {
    'Epic' => { children: ['Feature'], parents: [] },
    'Feature' => { children: ['UserStory'], parents: ['Epic'] },
    'UserStory' => { children: ['Task', 'Test', 'Bug'], parents: ['Feature'] },
    'Task' => { children: [], parents: ['UserStory'] },
    'Test' => { children: [], parents: ['UserStory'] },
    'Bug' => { children: [], parents: ['UserStory', 'Feature'] }
  }.freeze

  def self.valid_parent?(child_tracker, parent_tracker)
    RULES.dig(child_tracker.name, :parents)&.include?(parent_tracker.name) || false
  end

  def self.allowed_children(tracker_name)
    RULES.dig(tracker_name, :children) || []
  end
end
```

### Issue拡張
```ruby
# app/models/concerns/kanban/issue_hierarchy.rb
module Kanban::IssueHierarchy
  extend ActiveSupport::Concern

  included do
    validate :validate_hierarchy
    before_save :enforce_depth_limit
  end

  def hierarchy_level
    { 'Epic' => 1, 'Feature' => 2, 'UserStory' => 3 }.fetch(tracker.name, 4)
  end

  def epic
    find_ancestor('Epic')
  end

  def feature
    find_ancestor('Feature')
  end

  def user_story
    find_ancestor('UserStory')
  end

  private

  def find_ancestor(tracker_name)
    current = parent
    while current
      return current if current.tracker.name == tracker_name
      current = current.parent
    end
    nil
  end

  def validate_hierarchy
    return unless parent_id_changed? && parent
    unless TrackerHierarchy.valid_parent?(tracker, parent.tracker)
      errors.add(:parent_id, "無効な親子関係")
    end
  end

  def enforce_depth_limit
    errors.add(:base, "階層深度超過") if hierarchy_path_length > 4
  end
end

Issue.include(Kanban::IssueHierarchy)
```

## API実装

### 階層管理コントローラー
```ruby
# app/controllers/kanban/hierarchy_controller.rb
class Kanban::HierarchyController < ApplicationController
  before_action :require_login, :find_project, :authorize

  def hierarchy_tree
    issues = @project.issues.includes(:tracker, :status, :parent, :children)
                   .joins(:tracker)
                   .where(trackers: { name: TrackerHierarchy::RULES.keys })
    render json: build_tree(issues)
  end

  def validate_hierarchy
    child = Tracker.find(params[:child_tracker_id])
    parent = Tracker.find(params[:parent_tracker_id])
    render json: { valid: TrackerHierarchy.valid_parent?(child, parent) }
  end

  private

  def build_tree(issues)
    epics = issues.select { |i| i.tracker.name == 'Epic' && i.parent.nil? }
    epics.map { |epic| build_epic_node(epic, issues) }
  end

  def build_epic_node(epic, issues)
    {
      issue: issue_json(epic),
      features: epic.children.select { |f| f.tracker.name == 'Feature' }
                    .map { |feature| build_feature_node(feature, issues) }
    }
  end

  def build_feature_node(feature, issues)
    {
      issue: issue_json(feature),
      user_stories: feature.children.select { |us| us.tracker.name == 'UserStory' }
                          .map { |us| build_user_story_node(us) }
    }
  end

  def build_user_story_node(user_story)
    {
      issue: issue_json(user_story),
      tasks: user_story.children.select { |c| c.tracker.name == 'Task' }.map { |t| issue_json(t) },
      tests: user_story.children.select { |c| c.tracker.name == 'Test' }.map { |t| issue_json(t) },
      bugs: user_story.children.select { |c| c.tracker.name == 'Bug' }.map { |b| issue_json(b) }
    }
  end

  def issue_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name,
      hierarchy_level: issue.hierarchy_level
    }
  end
end
```

## React実装

### 階層表示コンポーネント
```javascript
// assets/javascripts/kanban/components/HierarchyTree.jsx
import React, { useState, useEffect } from 'react';

export const HierarchyTree = ({ projectId }) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/kanban/projects/${projectId}/hierarchy_tree`)
      .then(res => res.json())
      .then(setData)
      .finally(() => setLoading(false));
  }, [projectId]);

  if (loading) return <div>読み込み中...</div>;

  return (
    <div className="hierarchy-tree">
      {data.map(epic => <EpicNode key={epic.issue.id} epic={epic} />)}
    </div>
  );
};

const EpicNode = ({ epic }) => {
  const [expanded, setExpanded] = useState(true);

  return (
    <div className="epic-node">
      <IssueCard issue={epic.issue} level={1} onToggle={() => setExpanded(!expanded)} />
      {expanded && (
        <div className="features">
          {epic.features.map(feature => <FeatureNode key={feature.issue.id} feature={feature} />)}
        </div>
      )}
    </div>
  );
};

const FeatureNode = ({ feature }) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="feature-node">
      <IssueCard issue={feature.issue} level={2} onToggle={() => setExpanded(!expanded)} />
      {expanded && (
        <div className="user-stories">
          {feature.user_stories.map(us => <UserStoryNode key={us.issue.id} userStory={us} />)}
        </div>
      )}
    </div>
  );
};

const UserStoryNode = ({ userStory }) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="user-story-node">
      <IssueCard issue={userStory.issue} level={3} onToggle={() => setExpanded(!expanded)} />
      {expanded && (
        <div className="children">
          <div className="tasks">{userStory.tasks.map(t => <IssueCard key={t.id} issue={t} level={4} />)}</div>
          <div className="tests">{userStory.tests.map(t => <IssueCard key={t.id} issue={t} level={4} />)}</div>
          <div className="bugs">{userStory.bugs.map(b => <IssueCard key={b.id} issue={b} level={4} />)}</div>
        </div>
      )}
    </div>
  );
};
```

### 階層制約ユーティリティ
```javascript
// assets/javascripts/kanban/utils/TrackerHierarchy.js
export class TrackerHierarchy {
  static RULES = {
    'Epic': { children: ['Feature'], parents: [] },
    'Feature': { children: ['UserStory'], parents: ['Epic'] },
    'UserStory': { children: ['Task', 'Test', 'Bug'], parents: ['Feature'] },
    'Task': { children: [], parents: ['UserStory'] },
    'Test': { children: [], parents: ['UserStory'] },
    'Bug': { children: [], parents: ['UserStory', 'Feature'] }
  };

  static validateParent(childTracker, parentTracker) {
    return this.RULES[childTracker]?.parents.includes(parentTracker) || false;
  }

  static getAllowedChildren(tracker) {
    return this.RULES[tracker]?.children || [];
  }

  static getLevel(tracker) {
    const levels = { 'Epic': 1, 'Feature': 2, 'UserStory': 3 };
    return levels[tracker] || 4;
  }
}
```

## テスト実装

### モデルテスト
```ruby
# spec/models/kanban/tracker_hierarchy_spec.rb
RSpec.describe Kanban::TrackerHierarchy do
  let(:epic) { create(:tracker, name: 'Epic') }
  let(:feature) { create(:tracker, name: 'Feature') }
  let(:user_story) { create(:tracker, name: 'UserStory') }
  let(:task) { create(:tracker, name: 'Task') }

  describe '.valid_parent?' do
    it { expect(described_class.valid_parent?(feature, epic)).to be true }
    it { expect(described_class.valid_parent?(task, feature)).to be false }
    it { expect(described_class.valid_parent?(task, user_story)).to be true }
  end

  describe '.allowed_children' do
    it { expect(described_class.allowed_children('Epic')).to eq(['Feature']) }
    it { expect(described_class.allowed_children('UserStory')).to contain_exactly('Task', 'Test', 'Bug') }
  end
end
```

### 統合テスト
```ruby
# spec/requests/kanban/hierarchy_controller_spec.rb
RSpec.describe Kanban::HierarchyController do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_permissions, project: project) }

  before { User.current = user }

  describe 'GET hierarchy_tree' do
    let!(:epic) { create(:issue, project: project, tracker: create(:tracker, name: 'Epic')) }
    let!(:feature) { create(:issue, project: project, tracker: create(:tracker, name: 'Feature'), parent: epic) }

    it '階層構造を返す' do
      get "/kanban/projects/#{project.id}/hierarchy_tree"
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.first['issue']['tracker']).to eq('Epic')
      expect(json.first['features'].first['issue']['tracker']).to eq('Feature')
    end
  end
end
```

## Hook実装

### 階層制約Hook
```ruby
# lib/kanban/hooks/hierarchy_hook.rb
module Kanban::Hooks
  class HierarchyHook < Redmine::Hook::ViewListener
    def controller_issues_new_after_save(context = {})
      validate_hierarchy(context[:issue])
    end

    def controller_issues_edit_after_save(context = {})
      validate_hierarchy(context[:issue]) if context[:issue].parent_id_changed?
    end

    private

    def validate_hierarchy(issue)
      return unless issue.parent
      unless TrackerHierarchy.valid_parent?(issue.tracker, issue.parent.tracker)
        Rails.logger.warn "階層制約違反: #{issue.id}"
      end
    end
  end
end
```

---

*Epic→Feature→UserStory→Task/Test階層制約をRedmine/React統合環境で実装*