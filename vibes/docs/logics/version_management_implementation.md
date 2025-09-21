# VersionManagement技術実装仕様

## 概要
UserStoryへのバージョン割当と子Task/Testへの自動伝播機能。カンバンUI統合とRedmine Version API活用。

## サービス実装

### バージョン伝播サービス
```ruby
# app/services/kanban/version_propagation_service.rb
module Kanban
  class VersionPropagationService
    def self.propagate_to_children(user_story, version, options = {})
      return unless user_story.tracker.name == 'UserStory'

      children = user_story.children.where(tracker: { name: ['Task', 'Test', 'Bug'] })
      propagation_mode = options[:mode] || :force_overwrite

      ActiveRecord::Base.transaction do
        children.each do |child|
          next if propagation_mode == :preserve_existing && child.fixed_version_id.present?

          child.update!(
            fixed_version_id: version&.id,
            updated_on: Time.current
          )

          log_propagation(user_story, child, version)
        end
      end

      { propagated_count: children.count, affected_issues: children.pluck(:id) }
    end

    def self.remove_version_from_children(user_story)
      children = user_story.children.where(tracker: { name: ['Task', 'Test', 'Bug'] })

      ActiveRecord::Base.transaction do
        children.update_all(
          fixed_version_id: nil,
          updated_on: Time.current.to_s(:db)
        )
      end

      { removed_count: children.count }
    end

    private

    def self.log_propagation(parent, child, version)
      Rails.logger.info(
        "Version propagated: UserStory##{parent.id} -> #{child.tracker.name}##{child.id}, " \
        "Version: #{version&.name || 'None'}"
      )
    end
  end
end
```

### バージョン管理モデル拡張
```ruby
# app/models/concerns/kanban/version_management.rb
module Kanban
  module VersionManagement
    extend ActiveSupport::Concern

    included do
      after_update :propagate_version_to_children, if: :saved_change_to_fixed_version_id?
      validate :validate_version_assignment_rules
    end

    def can_assign_version?
      tracker.name == 'UserStory'
    end

    def inherited_version
      return fixed_version if fixed_version.present?
      return parent.inherited_version if parent&.tracker&.name == 'UserStory'
      nil
    end

    def version_source
      return :direct if fixed_version.present?
      return :inherited if inherited_version.present?
      :none
    end

    def propagate_version_now!(version = nil, options = {})
      target_version = version || fixed_version
      return unless can_assign_version?

      VersionPropagationService.propagate_to_children(self, target_version, options)
    end

    private

    def propagate_version_to_children
      return unless tracker.name == 'UserStory'

      if fixed_version.present?
        VersionPropagationService.propagate_to_children(self, fixed_version)
      else
        VersionPropagationService.remove_version_from_children(self)
      end
    end

    def validate_version_assignment_rules
      # Feature/Epicへの直接バージョン割当を禁止
      if %w[Epic Feature].include?(tracker.name) && fixed_version_id.present?
        errors.add(:fixed_version_id, "#{tracker.name}には直接バージョンを割り当てできません")
      end
    end
  end
end

Issue.include(Kanban::VersionManagement)
```

## API実装

### バージョン管理コントローラー
```ruby
# app/controllers/kanban/versions_controller.rb
class Kanban::VersionsController < ApplicationController
  before_action :require_login, :find_project, :authorize

  def assign_version
    @issue = Issue.find(params[:issue_id])
    @version = params[:version_id].present? ? Version.find(params[:version_id]) : nil

    unless @issue.can_assign_version?
      render json: { error: "#{@issue.tracker.name}にはバージョンを割り当てできません" }, status: :unprocessable_entity
      return
    end

    result = assign_version_with_propagation(@issue, @version)
    render json: result
  end

  def bulk_assign_version
    issue_ids = params[:issue_ids]
    version_id = params[:version_id]
    version = version_id.present? ? Version.find(version_id) : nil

    results = []

    ActiveRecord::Base.transaction do
      issue_ids.each do |issue_id|
        issue = Issue.find(issue_id)
        next unless issue.can_assign_version?

        result = assign_version_with_propagation(issue, version)
        results << result.merge(issue_id: issue_id)
      end
    end

    render json: { results: results, total_processed: results.count }
  end

  def create_version
    @version = @project.versions.build(version_params)

    if @version.save
      render json: version_json(@version), status: :created
    else
      render json: { errors: @version.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def version_assignment_preview
    @issue = Issue.find(params[:issue_id])
    @version = params[:version_id].present? ? Version.find(params[:version_id]) : nil

    children = @issue.children.where(tracker: { name: ['Task', 'Test', 'Bug'] })

    preview = {
      parent_issue: issue_json(@issue),
      target_version: @version&.name,
      affected_children: children.map { |child|
        {
          id: child.id,
          subject: child.subject,
          tracker: child.tracker.name,
          current_version: child.fixed_version&.name,
          will_change: child.fixed_version != @version
        }
      }
    }

    render json: preview
  end

  private

  def assign_version_with_propagation(issue, version)
    old_version = issue.fixed_version

    issue.update!(fixed_version: version)

    propagation_result = issue.propagate_version_now!(version)

    {
      success: true,
      issue: issue_json(issue),
      old_version: old_version&.name,
      new_version: version&.name,
      propagation: propagation_result
    }
  rescue => e
    {
      success: false,
      error: e.message,
      issue_id: issue.id
    }
  end

  def issue_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      fixed_version: issue.fixed_version&.name,
      version_source: issue.version_source
    }
  end

  def version_json(version)
    {
      id: version.id,
      name: version.name,
      description: version.description,
      due_date: version.effective_date,
      status: version.status
    }
  end

  def version_params
    params.require(:version).permit(:name, :description, :effective_date, :sharing)
  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize
    deny_access unless User.current.allowed_to?(:manage_versions, @project)
  end
end
```

## React実装

### バージョンバーコンポーネント
```javascript
// assets/javascripts/kanban/components/VersionBar.jsx
import React, { useState, useEffect } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { VersionAPI } from '../utils/VersionAPI';

export const VersionBar = ({ projectId, onVersionChange }) => {
  const [versions, setVersions] = useState([]);
  const [showCreateModal, setShowCreateModal] = useState(false);

  useEffect(() => {
    fetchVersions();
  }, [projectId]);

  const fetchVersions = async () => {
    try {
      const data = await VersionAPI.getProjectVersions(projectId);
      setVersions(data);
    } catch (error) {
      console.error('バージョン取得エラー:', error);
    }
  };

  const handleCreateVersion = async (versionData) => {
    try {
      const newVersion = await VersionAPI.createVersion(projectId, versionData);
      setVersions([...versions, newVersion]);
      setShowCreateModal(false);
      onVersionChange?.();
    } catch (error) {
      console.error('バージョン作成エラー:', error);
    }
  };

  return (
    <div className="version-bar">
      <div className="version-tabs">
        {versions.map(version => (
          <VersionTab
            key={version.id}
            version={version}
            projectId={projectId}
            onAssignmentChange={onVersionChange}
          />
        ))}
        <button
          className="create-version-btn"
          onClick={() => setShowCreateModal(true)}
        >
          + 新規
        </button>
      </div>

      {showCreateModal && (
        <CreateVersionModal
          onSubmit={handleCreateVersion}
          onClose={() => setShowCreateModal(false)}
        />
      )}
    </div>
  );
};

const VersionTab = ({ version, projectId, onAssignmentChange }) => {
  const { setNodeRef, isOver } = useDroppable({
    id: `version-${version.id}`,
    data: { type: 'version', version }
  });

  const handleDrop = async (cardData) => {
    try {
      await VersionAPI.assignVersion(projectId, cardData.issue.id, version.id);
      onAssignmentChange?.();
    } catch (error) {
      console.error('バージョン割当エラー:', error);
    }
  };

  return (
    <div
      ref={setNodeRef}
      className={`version-tab ${isOver ? 'drop-hover' : ''}`}
      data-version-id={version.id}
    >
      <span className="version-name">{version.name}</span>
      <span className="version-due-date">{version.due_date}</span>
    </div>
  );
};
```

### バージョン割当ユーティリティ
```javascript
// assets/javascripts/kanban/utils/VersionAPI.js
export class VersionAPI {
  static async getProjectVersions(projectId) {
    const response = await fetch(`/projects/${projectId}/versions.json`);
    const data = await response.json();
    return data.versions || [];
  }

  static async createVersion(projectId, versionData) {
    const response = await fetch(`/kanban/projects/${projectId}/versions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ version: versionData })
    });

    if (!response.ok) throw new Error('バージョン作成失敗');
    return await response.json();
  }

  static async assignVersion(projectId, issueId, versionId) {
    const response = await fetch(`/kanban/projects/${projectId}/assign_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_id: issueId,
        version_id: versionId
      })
    });

    if (!response.ok) throw new Error('バージョン割当失敗');
    return await response.json();
  }

  static async bulkAssignVersion(projectId, issueIds, versionId) {
    const response = await fetch(`/kanban/projects/${projectId}/bulk_assign_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_ids: issueIds,
        version_id: versionId
      })
    });

    if (!response.ok) throw new Error('一括バージョン割当失敗');
    return await response.json();
  }

  static async getAssignmentPreview(projectId, issueId, versionId) {
    const response = await fetch(
      `/kanban/projects/${projectId}/version_assignment_preview?issue_id=${issueId}&version_id=${versionId}`
    );
    return await response.json();
  }
}
```

### バージョン設定モーダル
```javascript
// assets/javascripts/kanban/components/VersionAssignmentModal.jsx
import React, { useState, useEffect } from 'react';
import { VersionAPI } from '../utils/VersionAPI';

export const VersionAssignmentModal = ({ issue, projectId, onClose, onAssign }) => {
  const [versions, setVersions] = useState([]);
  const [selectedVersionId, setSelectedVersionId] = useState(issue.fixed_version?.id || '');
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadVersions();
  }, []);

  useEffect(() => {
    if (selectedVersionId && issue.tracker === 'UserStory') {
      loadPreview();
    }
  }, [selectedVersionId]);

  const loadVersions = async () => {
    try {
      const data = await VersionAPI.getProjectVersions(projectId);
      setVersions(data);
    } catch (error) {
      console.error('バージョン読み込みエラー:', error);
    }
  };

  const loadPreview = async () => {
    try {
      const previewData = await VersionAPI.getAssignmentPreview(
        projectId,
        issue.id,
        selectedVersionId
      );
      setPreview(previewData);
    } catch (error) {
      console.error('プレビュー読み込みエラー:', error);
    }
  };

  const handleAssign = async () => {
    setLoading(true);
    try {
      await VersionAPI.assignVersion(projectId, issue.id, selectedVersionId);
      onAssign?.();
      onClose();
    } catch (error) {
      console.error('バージョン割当エラー:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="version-assignment-modal">
        <h3>バージョン設定 - {issue.subject}</h3>

        <div className="version-select">
          <label>バージョン:</label>
          <select
            value={selectedVersionId}
            onChange={(e) => setSelectedVersionId(e.target.value)}
          >
            <option value="">未設定</option>
            {versions.map(version => (
              <option key={version.id} value={version.id}>
                {version.name} {version.due_date && `(${version.due_date})`}
              </option>
            ))}
          </select>
        </div>

        {preview && (
          <div className="assignment-preview">
            <h4>影響する子要素:</h4>
            {preview.affected_children.map(child => (
              <div key={child.id} className="affected-child">
                <span className="child-info">
                  {child.tracker} #{child.id}: {child.subject}
                </span>
                {child.will_change && (
                  <span className="version-change">
                    {child.current_version || '未設定'} → {preview.target_version || '未設定'}
                  </span>
                )}
              </div>
            ))}
          </div>
        )}

        <div className="modal-actions">
          <button onClick={onClose}>キャンセル</button>
          <button onClick={handleAssign} disabled={loading}>
            {loading ? '設定中...' : '設定'}
          </button>
        </div>
      </div>
    </div>
  );
};
```

## テスト実装

### サービステスト
```ruby
# spec/services/kanban/version_propagation_service_spec.rb
RSpec.describe Kanban::VersionPropagationService do
  let(:project) { create(:project) }
  let(:version) { create(:version, project: project) }
  let(:user_story) { create(:issue, project: project, tracker: create(:tracker, name: 'UserStory')) }
  let(:task) { create(:issue, project: project, tracker: create(:tracker, name: 'Task'), parent: user_story) }
  let(:test_issue) { create(:issue, project: project, tracker: create(:tracker, name: 'Test'), parent: user_story) }

  describe '.propagate_to_children' do
    it 'UserStoryのバージョンを子Task/Testに伝播' do
      result = described_class.propagate_to_children(user_story, version)

      expect(result[:propagated_count]).to eq(2)
      expect(task.reload.fixed_version).to eq(version)
      expect(test_issue.reload.fixed_version).to eq(version)
    end

    it '既存バージョン保持モードで既存のバージョンを保持' do
      task.update!(fixed_version: create(:version, project: project))

      result = described_class.propagate_to_children(user_story, version, mode: :preserve_existing)

      expect(task.reload.fixed_version).not_to eq(version)
      expect(test_issue.reload.fixed_version).to eq(version)
    end
  end
end
```

### 統合テスト
```ruby
# spec/requests/kanban/versions_controller_spec.rb
RSpec.describe Kanban::VersionsController do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_permissions, project: project) }
  let(:version) { create(:version, project: project) }
  let(:user_story) { create(:issue, project: project, tracker: create(:tracker, name: 'UserStory')) }

  before { User.current = user }

  describe 'POST assign_version' do
    it 'UserStoryにバージョンを割り当て' do
      post "/kanban/projects/#{project.id}/assign_version", params: {
        issue_id: user_story.id,
        version_id: version.id
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['new_version']).to eq(version.name)
    end
  end
end
```

---

*UserStoryへのバージョン割当と子要素への自動伝播をRedmine/React統合で実装*