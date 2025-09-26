# API統合設計仕様書

## 🔗 関連ドキュメント
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
- @vibes/logics/ui_components/kanban_grid/kanban_grid_layout_specification.md
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/api_integration_implementation.md

## 1. 概要

React FrontendとRuby Rails Backendの完全統合。Redmine標準APIとカスタムAPI統合によるリアルタイムデータ同期システム。

## 2. API アーキテクチャ

### 2.1 API階層構造

```
API Layer Architecture:
┌─────────────────────────────────┐
│ React Frontend (Client)         │
├─────────────────────────────────┤
│ KanbanAPI Utility (Abstraction) │
├─────────────────────────────────┤
│ Custom Kanban Controllers       │
├─────────────────────────────────┤
│ Redmine Standard API           │
├─────────────────────────────────┤
│ Service Layer (Business Logic) │
├─────────────────────────────────┤
│ ActiveRecord Models            │
└─────────────────────────────────┘
```

### 2.2 エンドポイント設計

| 機能 | Method | エンドポイント | 説明 |
|------|--------|---------------|------|
| **Grid Data** | GET | `/kanban/projects/:id/grid` | グリッドレイアウト用データ |
| **Feature Cards** | GET | `/kanban/projects/:id/feature_cards` | Feature Card一覧 |
| **Move Feature** | POST | `/kanban/projects/:id/grid/move_feature` | Feature移動 |
| **Create Epic** | POST | `/kanban/projects/:id/grid/create_epic` | Epic作成 |
| **Create Version** | POST | `/kanban/projects/:id/grid/create_version` | Version作成 |
| **UserStory CRUD** | POST/PUT/DELETE | `/kanban/projects/:id/feature_cards/:id/user_stories` | UserStory管理 |
| **Task CRUD** | POST/PUT/DELETE | `/kanban/projects/:id/user_stories/:id/tasks` | Task管理 |
| **Test Generation** | POST | `/kanban/projects/:id/user_stories/:id/generate_test` | Test自動生成 |
| **Version Assignment** | POST | `/kanban/projects/:id/assign_version` | Version割当 |
| **Batch Operations** | POST | `/kanban/projects/:id/batch_update` | 一括操作 |

## 3. Frontend API Client

### 3.1 KanbanAPI クラス

```javascript
// assets/javascripts/kanban/utils/KanbanAPI.js
class KanbanAPIError extends Error {
  constructor(message, status, response) {
    super(message);
    this.name = 'KanbanAPIError';
    this.status = status;
    this.response = response;
  }
}

export class KanbanAPI {
  static BASE_URL = '/kanban/projects';
  static DEFAULT_HEADERS = {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  };

  // CSRF Token管理
  static getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }

  static getHeaders(additionalHeaders = {}) {
    return {
      ...this.DEFAULT_HEADERS,
      'X-CSRF-Token': this.getCSRFToken(),
      ...additionalHeaders
    };
  }

  // 共通リクエストメソッド
  static async request(method, url, data = null, options = {}) {
    const config = {
      method,
      headers: this.getHeaders(options.headers),
      ...options
    };

    if (data) {
      config.body = JSON.stringify(data);
    }

    try {
      const response = await fetch(url, config);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new KanbanAPIError(
          errorData.message || `HTTP Error ${response.status}`,
          response.status,
          errorData
        );
      }

      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        return await response.json();
      }

      return await response.text();
    } catch (error) {
      if (error instanceof KanbanAPIError) {
        throw error;
      }
      throw new KanbanAPIError('Network Error', 0, { originalError: error });
    }
  }

  // GET requests
  static async get(endpoint, params = {}) {
    const url = new URL(`${this.BASE_URL}${endpoint}`, window.location.origin);
    Object.keys(params).forEach(key => {
      if (params[key] !== null && params[key] !== undefined) {
        url.searchParams.append(key, params[key]);
      }
    });

    return this.request('GET', url.toString());
  }

  // POST requests
  static async post(endpoint, data = {}) {
    return this.request('POST', `${this.BASE_URL}${endpoint}`, data);
  }

  // PUT requests
  static async put(endpoint, data = {}) {
    return this.request('PUT', `${this.BASE_URL}${endpoint}`, data);
  }

  // DELETE requests
  static async delete(endpoint) {
    return this.request('DELETE', `${this.BASE_URL}${endpoint}`);
  }

  // --- Grid API Methods ---

  // グリッドデータ取得
  static async getGridData(projectId, filters = {}) {
    return this.get(`/${projectId}/grid`, filters);
  }

  // Feature移動
  static async moveFeatureCard(projectId, moveData) {
    return this.post(`/${projectId}/grid/move_feature`, moveData);
  }

  // Epic作成
  static async createEpic(projectId, epicData) {
    return this.post(`/${projectId}/grid/create_epic`, { epic: epicData });
  }

  // Version作成
  static async createVersion(projectId, versionData) {
    return this.post(`/${projectId}/grid/create_version`, { version: versionData });
  }

  // --- Feature Card API Methods ---

  // Feature Card一覧
  static async getFeatureCards(projectId, filters = {}) {
    return this.get(`/${projectId}/feature_cards`, filters);
  }

  // UserStory作成
  static async createUserStory(projectId, featureId, userStoryData) {
    return this.post(`/${projectId}/feature_cards/${featureId}/user_stories`, {
      user_story: userStoryData
    });
  }

  // UserStory更新
  static async updateUserStory(projectId, featureId, userStoryId, userStoryData) {
    return this.put(`/${projectId}/feature_cards/${featureId}/user_stories/${userStoryId}`, {
      user_story: userStoryData
    });
  }

  // UserStory削除
  static async deleteUserStory(projectId, featureId, userStoryId) {
    return this.delete(`/${projectId}/feature_cards/${featureId}/user_stories/${userStoryId}`);
  }

  // Task作成
  static async createTask(projectId, userStoryId, taskData) {
    return this.post(`/${projectId}/user_stories/${userStoryId}/tasks`, {
      task: taskData
    });
  }

  // Task更新
  static async updateTask(projectId, userStoryId, taskId, taskData) {
    return this.put(`/${projectId}/user_stories/${userStoryId}/tasks/${taskId}`, {
      task: taskData
    });
  }

  // Task削除
  static async deleteTask(projectId, userStoryId, taskId) {
    return this.delete(`/${projectId}/user_stories/${userStoryId}/tasks/${taskId}`);
  }

  // Test自動生成
  static async generateTest(projectId, userStoryId, testData = {}) {
    return this.post(`/${projectId}/user_stories/${userStoryId}/generate_test`, {
      test: testData
    });
  }

  // --- Version Management API Methods ---

  // Version割当
  static async assignVersion(projectId, assignmentData) {
    return this.post(`/${projectId}/assign_version`, assignmentData);
  }

  // Version一覧取得
  static async getVersions(projectId) {
    return this.get(`/${projectId}/versions`);
  }

  // --- Batch Operations API Methods ---

  // 一括更新
  static async batchUpdate(projectId, batchData) {
    return this.post(`/${projectId}/batch_update`, batchData);
  }

  // 一括削除
  static async batchDelete(projectId, deleteData) {
    return this.post(`/${projectId}/batch_delete`, deleteData);
  }

  // --- Real-time Updates ---

  // ポーリング用データ取得
  static async getUpdatedData(projectId, lastUpdated) {
    return this.get(`/${projectId}/updates`, { since: lastUpdated });
  }

  // データ変更通知
  static async notifyDataChange(projectId, changeData) {
    return this.post(`/${projectId}/notify_change`, changeData);
  }
}
```

### 3.2 React Hook統合

```javascript
// assets/javascripts/kanban/hooks/useKanbanAPI.js
import { useState, useCallback, useRef } from 'react';
import { KanbanAPI } from '../utils/KanbanAPI';

export const useKanbanAPI = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const abortControllerRef = useRef(null);

  const execute = useCallback(async (apiCall, options = {}) => {
    // 前回のリクエストをキャンセル
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // 新しいAbortControllerを作成
    abortControllerRef.current = new AbortController();

    try {
      setLoading(true);
      setError(null);

      const result = await apiCall({
        signal: abortControllerRef.current.signal,
        ...options
      });

      return result;
    } catch (err) {
      if (err.name === 'AbortError') {
        return null; // リクエストがキャンセルされた場合
      }

      setError(err);

      if (options.onError) {
        options.onError(err);
      } else {
        console.error('Kanban API Error:', err);
      }

      throw err;
    } finally {
      setLoading(false);
      abortControllerRef.current = null;
    }
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  return {
    loading,
    error,
    execute,
    clearError
  };
};
```

### 3.3 エラーハンドリング Hook

```javascript
// assets/javascripts/kanban/hooks/useErrorHandler.js
import { useCallback } from 'react';
import { useToast } from '../components/shared/Toast';

export const useErrorHandler = () => {
  const { showToast } = useToast();

  const handleError = useCallback((error, context = '') => {
    let message = 'システムエラーが発生しました';
    let type = 'error';

    if (error.status) {
      switch (error.status) {
        case 400:
          message = 'リクエストが無効です';
          break;
        case 401:
          message = 'ログインが必要です';
          break;
        case 403:
          message = 'この操作を実行する権限がありません';
          break;
        case 404:
          message = 'データが見つかりません';
          break;
        case 422:
          message = error.response?.errors
            ? Object.values(error.response.errors).flat().join(', ')
            : 'データの検証に失敗しました';
          break;
        case 500:
          message = 'サーバーエラーが発生しました';
          break;
        default:
          message = error.message || 'システムエラーが発生しました';
      }
    } else if (error.message) {
      message = error.message;
    }

    if (context) {
      message = `${context}: ${message}`;
    }

    showToast(message, type);

    // 開発環境では詳細なエラー情報をコンソールに出力
    if (process.env.NODE_ENV === 'development') {
      console.error('Error Details:', {
        context,
        error,
        message,
        stack: error.stack
      });
    }
  }, [showToast]);

  return { handleError };
};
```

## 4. Backend API Controllers

### 4.1 Base Controller

```ruby
# app/controllers/kanban/base_controller.rb
class Kanban::BaseController < ApplicationController
  include KanbanApiConcern

  before_action :require_login
  before_action :find_project
  before_action :authorize_kanban
  before_action :set_cors_headers

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error
  rescue_from StandardError, with: :render_internal_error

  protected

  def find_project
    @project = Project.find(params[:project_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('プロジェクトが見つかりません')
  end

  def authorize_kanban
    unless User.current.allowed_to?(:view_issues, @project)
      render_forbidden('カンバン表示権限がありません')
      return false
    end

    # 操作系API用権限チェック
    if request.post? || request.put? || request.patch? || request.delete?
      unless User.current.allowed_to?(:edit_issues, @project)
        render_forbidden('編集権限がありません')
        return false
      end
    end

    true
  end

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Requested-With, X-CSRF-Token'
  end

  def render_success(data = {}, message = nil, status = :ok)
    render json: {
      success: true,
      data: data,
      message: message,
      timestamp: Time.current.iso8601
    }, status: status
  end

  def render_error(message, status = :bad_request, errors = nil)
    render json: {
      success: false,
      message: message,
      errors: errors,
      timestamp: Time.current.iso8601
    }, status: status
  end

  def render_not_found(message = 'データが見つかりません')
    render_error(message, :not_found)
  end

  def render_forbidden(message = 'アクセス権限がありません')
    render_error(message, :forbidden)
  end

  def render_validation_error(exception)
    render_error(
      'データの検証に失敗しました',
      :unprocessable_entity,
      exception.record.errors.full_messages
    )
  end

  def render_internal_error(exception)
    Rails.logger.error "Kanban API Error: #{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    render_error(
      Rails.env.development? ? exception.message : 'システムエラーが発生しました',
      :internal_server_error
    )
  end

  def pagination_params
    params.permit(:page, :per_page).tap do |p|
      p[:page] = [p[:page].to_i, 1].max
      p[:per_page] = [[p[:per_page].to_i, 100].min, 10].max
    end
  end

  def filter_params
    params.permit(:version_id, :assignee_id, :status_id, :tracker_id, :priority_id, :q)
  end

  # ページング情報を含むレスポンス
  def render_paginated_success(collection, serializer = nil)
    data = if serializer
             collection.map { |item| serializer.call(item) }
           else
             collection.to_a
           end

    render_success({
      items: data,
      pagination: {
        current_page: collection.current_page,
        per_page: collection.limit_value,
        total_pages: collection.total_pages,
        total_count: collection.total_count
      }
    })
  end
end
```

### 4.2 Feature Cards Controller

```ruby
# app/controllers/kanban/feature_cards_controller.rb
class Kanban::FeatureCardsController < Kanban::BaseController

  # GET /kanban/projects/:project_id/feature_cards
  def index
    features = build_feature_query
                 .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                 .page(pagination_params[:page])
                 .per(pagination_params[:per_page])

    render_paginated_success(features, method(:serialize_feature_card))
  end

  # GET /kanban/projects/:project_id/feature_cards/:id
  def show
    feature = find_feature

    render_success(
      Kanban::FeatureCardDataBuilder.new(feature).build
    )
  end

  # POST /kanban/projects/:project_id/feature_cards/:id/user_stories
  def create_user_story
    feature = find_feature
    user_story = build_user_story(feature)

    ActiveRecord::Base.transaction do
      user_story.save!

      # 自動化処理
      trigger_automations(user_story, :created)
    end

    render_success(
      serialize_issue(user_story),
      'UserStory作成が完了しました',
      :created
    )
  end

  # PUT /kanban/projects/:project_id/feature_cards/:feature_id/user_stories/:id
  def update_user_story
    user_story = find_user_story
    old_attributes = user_story.attributes.dup

    ActiveRecord::Base.transaction do
      user_story.update!(user_story_params)

      # 変更検知と自動化処理
      trigger_automations(user_story, :updated, old_attributes)
    end

    render_success(
      serialize_issue(user_story),
      'UserStory更新が完了しました'
    )
  end

  # DELETE /kanban/projects/:project_id/feature_cards/:feature_id/user_stories/:id
  def destroy_user_story
    user_story = find_user_story

    ActiveRecord::Base.transaction do
      # 依存関係チェック
      if user_story.children.exists?
        render_error('子要素が存在するため削除できません', :unprocessable_entity)
        return
      end

      user_story.destroy!
    end

    render_success(nil, 'UserStory削除が完了しました')
  end

  # POST /kanban/projects/:project_id/user_stories/:user_story_id/tasks
  def create_task
    user_story = find_user_story_for_tasks
    task = build_task(user_story)

    ActiveRecord::Base.transaction do
      task.save!
      trigger_automations(task, :created)
    end

    render_success(
      serialize_issue(task),
      'Task作成が完了しました',
      :created
    )
  end

  # POST /kanban/projects/:project_id/user_stories/:user_story_id/generate_test
  def generate_test
    user_story = find_user_story_for_tasks

    begin
      test_issue = Kanban::TestGenerationService.new(user_story, User.current).execute

      render_success(
        serialize_issue(test_issue),
        'Test自動生成が完了しました',
        :created
      )
    rescue Kanban::TestGenerationService::Error => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  private

  def find_feature
    @project.issues
            .joins(:tracker)
            .where(trackers: { name: 'Feature' }, id: params[:id])
            .first!
  end

  def find_user_story
    Issue.joins(:tracker)
         .where(
           trackers: { name: 'UserStory' },
           id: params[:id],
           project_id: @project.id
         )
         .first!
  end

  def find_user_story_for_tasks
    Issue.joins(:tracker)
         .where(
           trackers: { name: 'UserStory' },
           id: params[:user_story_id],
           project_id: @project.id
         )
         .first!
  end

  def build_feature_query
    query = @project.issues.joins(:tracker).where(trackers: { name: 'Feature' })

    # フィルタリング
    query = query.where(fixed_version_id: filter_params[:version_id]) if filter_params[:version_id].present?
    query = query.where(assigned_to_id: filter_params[:assignee_id]) if filter_params[:assignee_id].present?
    query = query.where(status_id: filter_params[:status_id]) if filter_params[:status_id].present?

    # 検索
    if filter_params[:q].present?
      query = query.where("subject ILIKE ?", "%#{filter_params[:q]}%")
    end

    query.order(:created_on)
  end

  def build_user_story(feature)
    user_story = Issue.new(user_story_params)
    user_story.project = @project
    user_story.parent = feature
    user_story.tracker = Tracker.find_by!(name: 'UserStory')
    user_story.author = User.current
    user_story.status = IssueStatus.default

    user_story
  end

  def build_task(user_story)
    task = Issue.new(task_params)
    task.project = @project
    task.parent = user_story
    task.tracker = Tracker.find_by!(name: 'Task')
    task.author = User.current
    task.status = IssueStatus.default

    task
  end

  def serialize_feature_card(feature)
    Kanban::FeatureCardDataBuilder.new(feature).build
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      description: issue.description,
      status: issue.status.name,
      priority: issue.priority&.name,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name,
      tracker: issue.tracker.name,
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601
    }
  end

  def trigger_automations(issue, action, old_attributes = nil)
    case action
    when :created
      # UserStory作成時の自動Test生成
      if issue.tracker.name == 'UserStory'
        Kanban::TestGenerationService.new(issue, User.current).execute_if_needed
      end

      # バージョン自動伝播
      if issue.parent&.fixed_version
        Kanban::VersionPropagationService.new(issue.parent, issue.parent.fixed_version).execute
      end

    when :updated
      # バージョン変更時の自動伝播
      if old_attributes['fixed_version_id'] != issue.fixed_version_id && issue.fixed_version
        Kanban::VersionPropagationService.new(issue, issue.fixed_version).execute
      end

      # ステータス変更時のvalidation guard
      if old_attributes['status_id'] != issue.status_id
        Kanban::ValidationGuardService.new(issue).execute
      end
    end
  end

  def user_story_params
    params.require(:user_story).permit(:subject, :description, :assigned_to_id, :priority_id)
  end

  def task_params
    params.require(:task).permit(:subject, :description, :assigned_to_id, :priority_id, :estimated_hours)
  end
end
```

### 4.3 Real-time Update Service

```ruby
# app/services/kanban/real_time_update_service.rb
class Kanban::RealTimeUpdateService
  CACHE_PREFIX = 'kanban_updates'.freeze
  UPDATE_EXPIRY = 1.hour

  def initialize(project)
    @project = project
    @cache_key = "#{CACHE_PREFIX}:#{@project.id}"
  end

  def register_change(change_data)
    changes = get_cached_changes
    changes << {
      id: SecureRandom.uuid,
      timestamp: Time.current.iso8601,
      **change_data
    }

    # 古い変更履歴をクリーンアップ（最新100件まで保持）
    changes = changes.last(100)

    Rails.cache.write(@cache_key, changes, expires_in: UPDATE_EXPIRY)
  end

  def get_updates_since(since_timestamp)
    changes = get_cached_changes

    if since_timestamp.present?
      since_time = Time.parse(since_timestamp)
      changes = changes.select { |change| Time.parse(change[:timestamp]) > since_time }
    end

    {
      updates: changes,
      last_updated: Time.current.iso8601,
      has_more: false
    }
  end

  def notify_feature_moved(feature, old_epic_id, new_epic_id, old_version_id, new_version_id)
    register_change(
      type: 'feature_moved',
      feature_id: feature.id,
      old_epic_id: old_epic_id,
      new_epic_id: new_epic_id,
      old_version_id: old_version_id,
      new_version_id: new_version_id,
      updated_feature: Kanban::FeatureCardDataBuilder.new(feature).build
    )
  end

  def notify_user_story_created(user_story)
    register_change(
      type: 'user_story_created',
      feature_id: user_story.parent_id,
      user_story: serialize_issue(user_story)
    )
  end

  def notify_task_updated(task)
    register_change(
      type: 'task_updated',
      user_story_id: task.parent_id,
      task: serialize_issue(task)
    )
  end

  def notify_version_created(version)
    register_change(
      type: 'version_created',
      version: serialize_version(version)
    )
  end

  private

  def get_cached_changes
    Rails.cache.fetch(@cache_key, expires_in: UPDATE_EXPIRY) { [] }
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      status: issue.status.name,
      assigned_to: issue.assigned_to&.name,
      updated_on: issue.updated_on.iso8601
    }
  end

  def serialize_version(version)
    {
      id: version.id,
      name: version.name,
      effective_date: version.effective_date&.iso8601
    }
  end
end
```

## 5. データ同期戦略

### 5.1 楽観的更新パターン

```javascript
// assets/javascripts/kanban/hooks/useOptimisticUpdate.js
import { useState, useCallback } from 'react';

export const useOptimisticUpdate = (initialData) => {
  const [data, setData] = useState(initialData);
  const [optimisticChanges, setOptimisticChanges] = useState(new Map());

  const applyOptimisticUpdate = useCallback((id, updateFn) => {
    const changeId = `${id}_${Date.now()}`;

    // UI即座に更新
    setData(prevData => updateFn(prevData));

    // 楽観的変更を記録
    setOptimisticChanges(prev => new Map(prev).set(changeId, { id, updateFn }));

    return changeId;
  }, []);

  const confirmUpdate = useCallback((changeId, serverData) => {
    // サーバーからの確定データで更新
    setData(serverData);

    // 楽観的変更をクリーンアップ
    setOptimisticChanges(prev => {
      const newMap = new Map(prev);
      newMap.delete(changeId);
      return newMap;
    });
  }, []);

  const revertUpdate = useCallback((changeId, originalData) => {
    // 楽観的変更を元に戻す
    setData(originalData);

    setOptimisticChanges(prev => {
      const newMap = new Map(prev);
      newMap.delete(changeId);
      return newMap;
    });
  }, []);

  return {
    data,
    setData,
    applyOptimisticUpdate,
    confirmUpdate,
    revertUpdate,
    hasOptimisticChanges: optimisticChanges.size > 0
  };
};
```

### 5.2 ポーリング更新システム

```javascript
// assets/javascripts/kanban/hooks/useRealTimeUpdates.js
import { useEffect, useRef, useState } from 'react';
import { KanbanAPI } from '../utils/KanbanAPI';

export const useRealTimeUpdates = (projectId, onUpdate, enabled = true) => {
  const [lastUpdated, setLastUpdated] = useState(null);
  const intervalRef = useRef(null);
  const POLLING_INTERVAL = 30000; // 30秒間隔

  const checkForUpdates = useCallback(async () => {
    try {
      const updates = await KanbanAPI.getUpdatedData(projectId, lastUpdated);

      if (updates.updates.length > 0) {
        onUpdate(updates.updates);
        setLastUpdated(updates.last_updated);
      }
    } catch (error) {
      console.error('Real-time update check failed:', error);
    }
  }, [projectId, lastUpdated, onUpdate]);

  useEffect(() => {
    if (!enabled) return;

    // 初回チェック
    checkForUpdates();

    // 定期ポーリング開始
    intervalRef.current = setInterval(checkForUpdates, POLLING_INTERVAL);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [enabled, checkForUpdates]);

  const forceUpdate = useCallback(() => {
    checkForUpdates();
  }, [checkForUpdates]);

  return { forceUpdate };
};
```

## 6. キャッシュ戦略

### 6.1 Frontend キャッシュ

```javascript
// assets/javascripts/kanban/utils/KanbanCache.js
class KanbanCache {
  constructor() {
    this.cache = new Map();
    this.timestamps = new Map();
    this.DEFAULT_TTL = 5 * 60 * 1000; // 5分
  }

  set(key, value, ttl = this.DEFAULT_TTL) {
    this.cache.set(key, value);
    this.timestamps.set(key, Date.now() + ttl);
  }

  get(key) {
    if (!this.cache.has(key)) return null;

    const expiry = this.timestamps.get(key);
    if (Date.now() > expiry) {
      this.cache.delete(key);
      this.timestamps.delete(key);
      return null;
    }

    return this.cache.get(key);
  }

  invalidate(pattern) {
    if (pattern instanceof RegExp) {
      for (const key of this.cache.keys()) {
        if (pattern.test(key)) {
          this.cache.delete(key);
          this.timestamps.delete(key);
        }
      }
    } else {
      this.cache.delete(pattern);
      this.timestamps.delete(pattern);
    }
  }

  clear() {
    this.cache.clear();
    this.timestamps.clear();
  }
}

export const kanbanCache = new KanbanCache();

// キャッシュ対応KanbanAPI拡張
KanbanAPI.getWithCache = async function(endpoint, params = {}, ttl) {
  const cacheKey = `${endpoint}?${new URLSearchParams(params).toString()}`;

  // キャッシュから取得試行
  const cached = kanbanCache.get(cacheKey);
  if (cached) return cached;

  // APIから取得してキャッシュ
  const result = await this.get(endpoint, params);
  kanbanCache.set(cacheKey, result, ttl);

  return result;
};
```

---

*React Frontend と Ruby Rails Backend の完全統合API設計。楽観的更新とリアルタイム同期によるUX最適化を実現*