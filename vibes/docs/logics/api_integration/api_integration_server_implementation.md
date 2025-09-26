# APIIntegration技術実装仕様

## 概要
Redmine標準API活用とプラグイン専用API統合。REST/JSON形式でカンバンUI-バックエンド間効率的データ交換。

## エンドポイント定義

### ルート設定
```ruby
# config/routes.rb
scope 'kanban/projects/:project_id' do
  get 'cards', to: 'kanban/cards#index'
  get 'hierarchy_tree', to: 'kanban/hierarchy#hierarchy_tree'
  post 'move_card', to: 'kanban/state_transitions#move_card'
  post 'assign_version', to: 'kanban/versions#assign_version'
  post 'generate_test', to: 'kanban/auto_generation#generate_test'
  get 'release_validation', to: 'kanban/validations#release_validation'
end
```

## 統合コントローラー

### メインデータ配信
```ruby
# app/controllers/kanban/cards_controller.rb
class Kanban::CardsController < ApplicationController
  include KanbanApiConcern

  def index
    @kanban_data = KanbanDataBuilder.new(@project, current_user, filter_params).build

    render json: {
      epics: serialize_epics(@kanban_data[:epics]),
      columns: @kanban_data[:columns],
      metadata: {
        project: project_metadata,
        user: user_metadata,
        permissions: user_permissions
      }
    }
  end

  private

  def serialize_epics(epics)
    epics.map do |epic|
      {
        issue: serialize_issue(epic),
        features: serialize_features(epic.features)
      }
    end
  end

  def filter_params
    params.permit(:version_id, :assignee_id, :status_id)
  end
end
```

### API共通処理
```ruby
# app/controllers/concerns/kanban_api_concern.rb
module KanbanApiConcern
  extend ActiveSupport::Concern

  included do
    before_action :require_login, :find_project, :authorize_kanban_access
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from StandardError, with: :render_internal_error
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      status_column: issue.current_kanban_column,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name,
      version_source: issue.version_source,
      hierarchy_level: issue.hierarchy_level,
      can_release: issue.can_release?,
      blocked_by_relations: serialize_blocking_relations(issue)
    }
  end

  def serialize_blocking_relations(issue)
    issue.relations_to.where(relation_type: 'blocks').map do |relation|
      {
        id: relation.id,
        blocking_issue_id: relation.issue_from_id,
        blocking_issue_tracker: relation.issue_from.tracker.name
      }
    end
  end

  def project_metadata
    {
      id: @project.id,
      name: @project.name,
      trackers: @project.trackers.pluck(:id, :name),
      versions: @project.versions.pluck(:id, :name)
    }
  end

  def user_permissions
    {
      view_issues: User.current.allowed_to?(:view_issues, @project),
      edit_issues: User.current.allowed_to?(:edit_issues, @project),
      manage_versions: User.current.allowed_to?(:manage_versions, @project)
    }
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize_kanban_access
    deny_access unless User.current.allowed_to?(:view_kanban, @project)
  end

  def render_not_found(exception)
    render json: { error: 'リソースが見つかりません' }, status: :not_found
  end

  def render_internal_error(exception)
    Rails.logger.error "Kanban API Error: #{exception.message}"
    render json: { error: 'サーバーエラー', request_id: request.uuid }, status: :internal_server_error
  end
end
```

## データビルダー

### カンバンデータ構築
```ruby
# app/services/kanban/kanban_data_builder.rb
module Kanban
  class KanbanDataBuilder
    def initialize(project, user, filters = {})
      @project = project
      @user = user
      @filters = filters
    end

    def build
      {
        epics: load_epics_with_hierarchy,
        columns: column_definitions,
        statistics: build_statistics
      }
    end

    private

    def load_epics_with_hierarchy
      epic_scope = @project.issues
                          .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                          .joins(:tracker)
                          .where(trackers: { name: 'Epic' })

      epic_scope = apply_filters(epic_scope)
      epic_scope.map { |epic| EpicWithHierarchy.new(epic) }
    end

    def apply_filters(scope)
      scope = scope.where(fixed_version_id: @filters[:version_id]) if @filters[:version_id].present?
      scope = scope.where(assigned_to_id: @filters[:assignee_id]) if @filters[:assignee_id].present?
      scope
    end

    def column_definitions
      [
        { id: 'todo', name: 'ToDo', color: '#f8f9fa' },
        { id: 'in_progress', name: 'In Progress', color: '#fff3cd' },
        { id: 'ready_for_test', name: 'Ready for Test', color: '#d1ecf1' },
        { id: 'released', name: 'Released', color: '#d4edda' }
      ]
    end

    def build_statistics
      all_issues = @project.issues.joins(:tracker)
                          .where(trackers: { name: %w[Epic Feature UserStory Task Test Bug] })

      {
        total_count: all_issues.count,
        by_tracker: all_issues.group('trackers.name').count,
        by_status: all_issues.joins(:status).group('issue_statuses.name').count
      }
    end
  end

  class EpicWithHierarchy
    def initialize(epic_issue)
      @epic = epic_issue
    end

    def issue
      @epic
    end

    def features
      @features ||= @epic.children
                         .select { |child| child.tracker.name == 'Feature' }
                         .map { |feature| FeatureWithHierarchy.new(feature) }
    end
  end

  class FeatureWithHierarchy
    def initialize(feature_issue)
      @feature = feature_issue
    end

    def issue
      @feature
    end

    def user_stories
      @user_stories ||= @feature.children
                               .select { |child| child.tracker.name == 'UserStory' }
                               .map { |us| UserStoryWithHierarchy.new(us) }
    end
  end

  class UserStoryWithHierarchy
    def initialize(user_story_issue)
      @user_story = user_story_issue
    end

    def issue
      @user_story
    end

    def tasks
      @tasks ||= @user_story.children.select { |child| child.tracker.name == 'Task' }
    end

    def tests
      @tests ||= @user_story.children.select { |child| child.tracker.name == 'Test' }
    end

    def bugs
      @bugs ||= @user_story.children.select { |child| child.tracker.name == 'Bug' }
    end
  end
end
```

## React統合層

### API統合サービス
```javascript
// assets/javascripts/kanban/services/KanbanAPIService.js
export class KanbanAPIService {
  constructor(projectId) {
    this.projectId = projectId;
    this.baseUrl = `/kanban/projects/${projectId}`;
  }

  async getKanbanData(filters = {}) {
    const queryString = new URLSearchParams(filters).toString();
    const url = `${this.baseUrl}/cards${queryString ? `?${queryString}` : ''}`;
    const response = await this.fetch(url);
    return await response.json();
  }

  async moveCard(cardId, columnId) {
    return await this.post('move_card', { card_id: cardId, column_id: columnId });
  }

  async assignVersion(issueId, versionId) {
    return await this.post('assign_version', { issue_id: issueId, version_id: versionId });
  }

  async generateTest(userStoryId, options = {}) {
    return await this.post('generate_test', { user_story_id: userStoryId, ...options });
  }

  async getReleaseValidation(issueId) {
    const response = await this.fetch(`release_validation?issue_id=${issueId}`);
    return await response.json();
  }

  async fetch(path, options = {}) {
    const url = path.startsWith('http') ? path : `${this.baseUrl}/${path}`;
    const response = await fetch(url, {
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', ...options.headers },
      ...options
    });

    if (!response.ok) {
      await this.handleErrorResponse(response);
    }
    return response;
  }

  async post(path, data) {
    const response = await this.fetch(path, {
      method: 'POST',
      headers: { 'X-CSRF-Token': this.getCSRFToken() },
      body: JSON.stringify(data)
    });
    return await response.json();
  }

  async handleErrorResponse(response) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    try {
      const errorData = await response.json();
      if (errorData.error) {
        errorMessage = errorData.error;
      }
    } catch (e) {
      // JSON パースエラーは無視
    }
    throw new Error(errorMessage);
  }

  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }
}
```

### API状態管理Hook
```javascript
// assets/javascripts/kanban/hooks/useKanbanAPI.js
import { useState, useCallback } from 'react';
import { KanbanAPIService } from '../services/KanbanAPIService';

export function useKanbanAPI(projectId) {
  const [api] = useState(() => new KanbanAPIService(projectId));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const executeWithLoading = useCallback(async (apiCall) => {
    setLoading(true);
    setError(null);
    try {
      const result = await apiCall();
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { api, loading, error, executeWithLoading, clearError: () => setError(null) };
}
```

## エラーハンドリング

### API統合エラーハンドラー
```javascript
// assets/javascripts/kanban/utils/ErrorHandler.js
export class KanbanErrorHandler {
  static handle(error, context = {}) {
    console.error('Kanban API Error:', error, context);

    if (error.message.includes('HTTP 401')) {
      this.handleAuthenticationError();
    } else if (error.message.includes('HTTP 403')) {
      this.handleAuthorizationError();
    } else if (error.message.includes('HTTP 422')) {
      this.handleValidationError(error, context);
    } else {
      this.handleGenericError(error, context);
    }
  }

  static handleAuthenticationError() {
    alert('セッションが切れました。ページを再読み込みしてください。');
    window.location.reload();
  }

  static handleAuthorizationError() {
    alert('この操作を実行する権限がありません。');
  }

  static handleValidationError(error, context) {
    const message = `入力エラー: ${error.message}`;
    this.showUserMessage(message, 'error');
  }

  static handleGenericError(error, context) {
    const message = `エラーが発生しました: ${error.message}`;
    this.showUserMessage(message, 'error');
  }

  static showUserMessage(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `kanban-notification ${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);
    setTimeout(() => document.body.removeChild(notification), 5000);
  }
}
```

## テスト実装

### API統合テスト
```ruby
# spec/requests/kanban/cards_controller_spec.rb
RSpec.describe Kanban::CardsController do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_kanban_permissions, project: project) }

  before { User.current = user }

  describe 'GET cards' do
    let!(:epic) { create(:issue, project: project, tracker: create(:tracker, name: 'Epic')) }

    it 'カンバンデータを返す' do
      get "/kanban/projects/#{project.id}/cards"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['epics']).to be_an(Array)
      expect(json['metadata']).to include('project', 'user', 'permissions')
    end
  end
end
```

### React統合テスト
```javascript
// spec/javascript/kanban/services/KanbanAPIService.test.js
import { KanbanAPIService } from '../../../assets/javascripts/kanban/services/KanbanAPIService';

describe('KanbanAPIService', () => {
  let apiService;

  beforeEach(() => {
    apiService = new KanbanAPIService(1);
    global.fetch = jest.fn();
    document.querySelector = jest.fn().mockReturnValue({ content: 'mock-token' });
  });

  test('getKanbanData fetches correct URL', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ epics: [] })
    });

    await apiService.getKanbanData({ version_id: 1 });

    expect(fetch).toHaveBeenCalledWith('/kanban/projects/1/cards?version_id=1', expect.any(Object));
  });

  test('moveCard handles API errors', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ error: 'Invalid transition' })
    });

    await expect(apiService.moveCard(123, 'released')).rejects.toThrow('Invalid transition');
  });
});
```

---

*Redmine標準API統合とプラグイン専用API。React-バックエンド間効率的データ交換*