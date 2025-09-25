# APIコントローラー サーバーサイド実装仕様

## 概要
Kanban UI用APIコントローラー実装。RESTful設計、エラーハンドリング、認証・認可、レート制限、バリデーション、レスポンス標準化。

## ベースコントローラー

### Kanban API共通コントローラー
```ruby
# app/controllers/kanban/base_api_controller.rb
module Kanban
  class BaseApiController < ApplicationController
    include KanbanApiConcern

    before_action :require_login
    before_action :find_project
    before_action :authorize_kanban_access
    before_action :check_rate_limit
    before_action :set_current_user

    rescue_from StandardError, with: :handle_internal_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from Kanban::PermissionDenied, with: :handle_permission_denied
    rescue_from Kanban::WorkflowViolation, with: :handle_workflow_violation

    protected

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_error('プロジェクトが見つかりません', :not_found)
    end

    def authorize_kanban_access
      unless User.current.allowed_to?(:view_kanban, @project)
        raise Kanban::PermissionDenied.new('Kanban表示権限がありません', :view_kanban)
      end
    end

    def check_rate_limit
      key = "kanban_api:#{request.remote_ip}:#{User.current&.id}"
      current_requests = Rails.cache.read(key) || 0

      if current_requests >= rate_limit_threshold
        render_error('リクエスト制限に達しました。しばらく待ってから再試行してください。', :too_many_requests)
        return
      end

      Rails.cache.write(key, current_requests + 1, expires_in: 1.minute)
    end

    def set_current_user
      User.current = current_user
    end

    def render_success(data = {}, status = :ok)
      response_data = {
        success: true,
        data: data,
        meta: build_response_meta
      }

      render json: response_data, status: status
    end

    def render_error(message, status = :bad_request, details = {})
      response_data = {
        success: false,
        error: {
          message: message,
          code: status,
          details: details,
          request_id: request.uuid
        },
        meta: build_response_meta
      }

      render json: response_data, status: status
    end

    def handle_not_found(exception)
      Kanban::ErrorHandlingService.log_error(exception, controller_context)
      render_error('リソースが見つかりません', :not_found)
    end

    def handle_validation_error(exception)
      Kanban::ErrorHandlingService.log_error(exception, controller_context)
      render_error(
        'バリデーションエラー',
        :unprocessable_entity,
        { validation_errors: format_validation_errors(exception.record) }
      )
    end

    def handle_permission_denied(exception)
      Kanban::ErrorHandlingService.log_error(exception, controller_context)
      render_error(exception.message, :forbidden, { required_permission: exception.required_permission })
    end

    def handle_workflow_violation(exception)
      Kanban::ErrorHandlingService.log_error(exception, controller_context)
      render_error(
        exception.message,
        :unprocessable_entity,
        { suggested_actions: exception.suggested_actions }
      )
    end

    def handle_internal_error(exception)
      Kanban::ErrorHandlingService.log_error(exception, controller_context)
      message = Rails.env.development? ? exception.message : 'サーバーエラーが発生しました'
      render_error(message, :internal_server_error)
    end

    private

    def rate_limit_threshold
      Rails.env.development? ? 1000 : 100 # 1分間のリクエスト制限
    end

    def build_response_meta
      {
        timestamp: Time.zone.now.iso8601,
        request_id: request.uuid,
        api_version: 'v1',
        execution_time: calculate_execution_time
      }
    end

    def controller_context
      {
        controller: self.class.name,
        action: action_name,
        project_id: @project&.id,
        user_id: User.current&.id,
        params: params.except(:password, :password_confirmation),
        request_id: request.uuid
      }
    end

    def format_validation_errors(record)
      record.errors.full_messages.map do |message|
        {
          field: record.errors.keys.first,
          message: message,
          code: determine_error_code(record.errors.keys.first)
        }
      end
    end

    def calculate_execution_time
      return nil unless @start_time
      ((Time.current - @start_time) * 1000).round(2) # ミリ秒
    end
  end
end
```

## 主要APIコントローラー

### Kanban データAPIコントローラー
```ruby
# app/controllers/kanban/api/data_controller.rb
module Kanban
  module Api
    class DataController < BaseApiController
      before_action :authorize_view_issues, only: [:index, :show]
      before_action :authorize_edit_issues, only: [:update, :move, :bulk_update]

      def index
        cache_key = "kanban_data:#{@project.id}:#{current_user.id}:#{data_params.to_h.hash}"

        data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
          Kanban::KanbanDataBuilder.new(@project, current_user, data_params.to_h).build
        end

        render_success(data)
      end

      def show
        issue = find_issue(params[:id])
        epic = issue.root

        data = Kanban::IssueDetailBuilder.new(issue, current_user).build

        render_success({
          issue: data,
          epic_context: Kanban::SerializerService.serialize_issue(epic, include_hierarchy: true)
        })
      end

      def move
        issue = find_issue(params[:id])

        result = Kanban::CardMoveService.new(
          current_user,
          issue.id,
          move_params[:source_cell],
          move_params[:target_cell]
        ).execute

        if result.success?
          # キャッシュ無効化
          invalidate_related_cache(issue)

          # リアルタイム通知
          Kanban::NotificationService.notify_issue_update(issue.reload, current_user, 'moved')

          render_success({
            updated_issue: Kanban::SerializerService.serialize_issue(result.updated_card, include_relations: true),
            affected_issues: result.affected_issues.map { |i| Kanban::SerializerService.serialize_issue(i) },
            statistics_delta: result.statistics_delta
          })
        else
          render_error(result.error_message, :unprocessable_entity, {
            validation_errors: result.validation_errors
          })
        end
      end

      def bulk_update
        issues = find_issues(bulk_update_params[:issue_ids])

        result = Kanban::BulkUpdateService.new(
          current_user,
          issues,
          bulk_update_params[:action],
          bulk_update_params[:action_params]
        ).execute

        if result.success?
          # キャッシュ無効化
          issues.each { |issue| invalidate_related_cache(issue) }

          # リアルタイム通知
          Kanban::NotificationService.notify_bulk_update(issues, current_user, bulk_update_params[:action], result.statistics)

          render_success({
            updated_issues: result.updated_issues.map { |i| Kanban::SerializerService.serialize_issue(i) },
            failed_issues: result.failed_issues,
            statistics: result.statistics
          })
        else
          render_error(result.error_message, :unprocessable_entity, {
            failed_issues: result.failed_issues
          })
        end
      end

      def statistics
        stats = Kanban::StatisticsBuilder.new(@project, current_user, stats_params.to_h).build

        render_success(stats)
      end

      private

      def authorize_view_issues
        unless current_user.allowed_to?(:view_issues, @project)
          raise Kanban::PermissionDenied.new('Issue表示権限がありません', :view_issues)
        end
      end

      def authorize_edit_issues
        unless current_user.allowed_to?(:edit_issues, @project)
          raise Kanban::PermissionDenied.new('Issue編集権限がありません', :edit_issues)
        end
      end

      def find_issue(id)
        @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version, :children, :parent).find(id)
      end

      def find_issues(ids)
        @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version).where(id: ids)
      end

      def data_params
        params.permit(:version_filter, :assignee_filter, :status_filter, :tracker_filter, :epic_filter,
                     :include_closed, :sort_by, :sort_direction)
      end

      def move_params
        params.require(:move).permit(
          source_cell: [:epic_id, :version_id, :column_id],
          target_cell: [:epic_id, :version_id, :column_id]
        )
      end

      def bulk_update_params
        params.require(:bulk_update).permit(
          :action,
          issue_ids: [],
          action_params: [:version_id, :status_id, :assignee_id, :priority_id]
        )
      end

      def stats_params
        params.permit(:period, :group_by, :include_trends)
      end

      def invalidate_related_cache(issue)
        Kanban::CacheService.invalidate_kanban_data(@project, [issue.root.id])
        Kanban::CacheService.invalidate_issue_data([issue.id])
      end
    end
  end
end
```

### バージョン管理APIコントローラー
```ruby
# app/controllers/kanban/api/versions_controller.rb
module Kanban
  module Api
    class VersionsController < BaseApiController
      before_action :authorize_view_versions, only: [:index, :show]
      before_action :authorize_manage_versions, only: [:create, :update, :destroy, :bulk_assign]

      def index
        versions = @project.versions
                          .includes(:issues)
                          .order(:effective_date, :name)

        render_success({
          versions: versions.map { |v| serialize_version(v) },
          statistics: calculate_versions_statistics(versions)
        })
      end

      def show
        version = @project.versions.find(params[:id])

        render_success({
          version: serialize_version(version),
          issues: serialize_version_issues(version),
          timeline: build_version_timeline(version)
        })
      end

      def create
        version = @project.versions.build(version_params)

        if version.save
          # グリッドに新しい列を追加
          grid_update = {
            type: 'version_added',
            version: serialize_version(version),
            column_data: Kanban::VersionColumnBuilder.new(version).build
          }

          # リアルタイム通知
          Kanban::NotificationService.notify_version_creation(version, current_user)

          render_success({
            version: serialize_version(version),
            grid_update: grid_update
          }, :created)
        else
          render_error(
            'バージョン作成に失敗しました',
            :unprocessable_entity,
            { validation_errors: format_validation_errors(version) }
          )
        end
      end

      def update
        version = @project.versions.find(params[:id])

        if version.update(version_params)
          # 影響するグリッドセルを計算
          grid_updates = calculate_version_update_impact(version)

          render_success({
            version: serialize_version(version),
            grid_updates: grid_updates
          })
        else
          render_error(
            'バージョン更新に失敗しました',
            :unprocessable_entity,
            { validation_errors: format_validation_errors(version) }
          )
        end
      end

      def bulk_assign
        version = @project.versions.find(params[:id])
        issues = @project.issues.where(id: bulk_assign_params[:issue_ids])

        result = Kanban::BulkVersionAssignmentService.new(current_user, version, issues).execute

        if result.success?
          # キャッシュ無効化
          affected_epic_ids = issues.map(&:root).uniq.pluck(:id)
          Kanban::CacheService.invalidate_kanban_data(@project, affected_epic_ids)

          # リアルタイム通知
          Kanban::NotificationService.notify_version_assignment(version, issues, current_user)

          render_success({
            assigned_issues: result.assigned_issues.map { |i| Kanban::SerializerService.serialize_issue(i) },
            grid_updates: result.grid_updates,
            statistics: result.statistics
          })
        else
          render_error(
            result.error_message,
            :unprocessable_entity,
            { failed_assignments: result.failed_assignments }
          )
        end
      end

      def timeline
        version = @project.versions.find(params[:id])
        timeline_data = Kanban::VersionTimelineBuilder.new(version, timeline_params).build

        render_success(timeline_data)
      end

      private

      def authorize_view_versions
        unless current_user.allowed_to?(:view_versions, @project)
          raise Kanban::PermissionDenied.new('バージョン表示権限がありません', :view_versions)
        end
      end

      def authorize_manage_versions
        unless current_user.allowed_to?(:manage_versions, @project)
          raise Kanban::PermissionDenied.new('バージョン管理権限がありません', :manage_versions)
        end
      end

      def version_params
        params.require(:version).permit(:name, :description, :effective_date, :status, :wiki_page_title)
      end

      def bulk_assign_params
        params.require(:bulk_assign).permit(issue_ids: [])
      end

      def timeline_params
        params.permit(:start_date, :end_date, :granularity)
      end

      def serialize_version(version)
        {
          id: version.id,
          name: version.name,
          description: version.description,
          effective_date: version.effective_date,
          status: version.status,
          created_on: version.created_on.iso8601,
          updated_on: version.updated_on.iso8601,
          issue_count: version.issues.count,
          completion_ratio: calculate_version_completion_ratio(version),
          can_edit: current_user.allowed_to?(:manage_versions, @project)
        }
      end

      def serialize_version_issues(version)
        version.issues
               .includes(:tracker, :status, :parent)
               .group_by(&:root)
               .map do |epic, issues|
          {
            epic: Kanban::SerializerService.serialize_issue(epic),
            issues: issues.map { |i| Kanban::SerializerService.serialize_issue(i) }
          }
        end
      end

      def calculate_versions_statistics(versions)
        {
          total: versions.count,
          open: versions.count(&:open?),
          closed: versions.count(&:closed?),
          locked: versions.count(&:locked?),
          total_issues: versions.sum { |v| v.issues.count },
          completion_ratio: calculate_overall_completion_ratio(versions)
        }
      end
    end
  end
end
```

### WebSocket リアルタイム通信コントローラー
```ruby
# app/controllers/kanban/api/realtime_controller.rb
module Kanban
  module Api
    class RealtimeController < BaseApiController
      def subscribe
        channel_name = "kanban_project_#{@project.id}"

        # WebSocket接続情報をセッションに保存
        session_data = {
          user_id: current_user.id,
          project_id: @project.id,
          subscribed_at: Time.zone.now,
          channel: channel_name
        }

        Rails.cache.write("kanban_session:#{current_user.id}:#{@project.id}", session_data, expires_in: 4.hours)

        render_success({
          channel: channel_name,
          connection_id: generate_connection_id,
          polling_fallback: {
            enabled: true,
            interval: 30000 # 30秒
          }
        })
      end

      def unsubscribe
        Rails.cache.delete("kanban_session:#{current_user.id}:#{@project.id}")

        render_success({
          message: '購読を停止しました'
        })
      end

      def poll_updates
        since = Time.zone.parse(params[:since]) if params[:since].present?
        since ||= 30.seconds.ago

        updates = Kanban::GridUpdateService.get_updates_since(@project, since)

        render_success({
          updates: updates,
          current_timestamp: Time.zone.now.iso8601,
          has_more: updates[:issue_updates].size >= 50 # ページング指標
        })
      end

      def heartbeat
        session = Rails.cache.read("kanban_session:#{current_user.id}:#{@project.id}")

        if session
          session[:last_heartbeat] = Time.zone.now
          Rails.cache.write("kanban_session:#{current_user.id}:#{@project.id}", session, expires_in: 4.hours)

          render_success({
            status: 'connected',
            server_time: Time.zone.now.iso8601
          })
        else
          render_error('セッションが見つかりません', :not_found)
        end
      end

      private

      def generate_connection_id
        "#{current_user.id}_#{@project.id}_#{Time.current.to_i}"
      end
    end
  end
end
```

## ルーティング設定

```ruby
# config/routes.rb
scope 'api/kanban/projects/:project_id', module: 'kanban/api' do
  # データAPI
  resources :data, only: [:index, :show] do
    member do
      patch :move
      get :statistics
    end
    collection do
      patch :bulk_update
    end
  end

  # バージョン管理API
  resources :versions do
    member do
      post :bulk_assign
      get :timeline
    end
  end

  # リアルタイム通信API
  scope :realtime, controller: :realtime do
    post :subscribe
    delete :unsubscribe
    get :poll_updates
    post :heartbeat
  end

  # システム情報API
  scope :system, controller: :system do
    get :health
    get :configuration
    get :permissions
  end
end
```

## ミドルウェア

### APIレート制限ミドルウェア
```ruby
# app/middleware/kanban_rate_limiter.rb
class KanbanRateLimiter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if kanban_api_request?(request)
      return rate_limit_exceeded if rate_limit_exceeded?(request)
    end

    @app.call(env)
  end

  private

  def kanban_api_request?(request)
    request.path.start_with?('/api/kanban/')
  end

  def rate_limit_exceeded?(request)
    # IP + ユーザーベースのレート制限
    key = "rate_limit:#{request.ip}:#{extract_user_id(request)}"
    current_count = Rails.cache.increment(key, 1, expires_in: 1.minute)

    current_count > rate_limit_threshold(request)
  end

  def rate_limit_threshold(request)
    # パスによって制限を変える
    case request.path
    when %r{/api/kanban/.+/data}
      20 # データ取得は制限緩め
    when %r{/api/kanban/.+/(move|bulk_update)}
      5  # 更新系は制限厳しく
    else
      10 # デフォルト
    end
  end

  def rate_limit_exceeded
    [429, { 'Content-Type' => 'application/json' }, [
      { error: 'Rate limit exceeded', retry_after: 60 }.to_json
    ]]
  end
end
```

## テスト実装

```ruby
# spec/requests/kanban/api/data_controller_spec.rb
RSpec.describe Kanban::Api::DataController, type: :request do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_kanban_permissions, project: project) }

  before { sign_in user }

  describe 'GET /api/kanban/projects/:project_id/data' do
    it 'Kanbanデータを正常に返す' do
      get "/api/kanban/projects/#{project.id}/data"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to include('grid', 'metadata', 'statistics')
      expect(json['meta']).to include('timestamp', 'api_version')
    end

    it 'フィルターパラメータを適用' do
      version = create(:version, project: project)

      get "/api/kanban/projects/#{project.id}/data", params: { version_filter: version.id }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /api/kanban/projects/:project_id/data/:id/move' do
    let(:feature) { create(:feature_issue, project: project) }

    it 'カード移動を正常に処理' do
      patch "/api/kanban/projects/#{project.id}/data/#{feature.id}/move",
            params: {
              move: {
                source_cell: { epic_id: feature.root.id, column_id: 'todo' },
                target_cell: { epic_id: feature.root.id, column_id: 'in_progress' }
              }
            }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end
end
```

---

*Kanban UI用APIコントローラー実装。RESTful設計、認証・認可、エラーハンドリング、リアルタイム通信*