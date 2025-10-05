# frozen_string_literal: true

module EpicGrid
  # カスタム例外クラス群
  class EpicGridError < StandardError
    attr_reader :details

    def initialize(message = nil, details = {})
      super(message)
      @details = details
    end
  end

  class PermissionDenied < EpicGridError
    attr_reader :permission, :resource

    def initialize(permission = nil, resource = nil, message = nil)
      @permission = permission
      @resource = resource
      super(message || "権限が不足しています: #{permission}")
    end
  end

  class WorkflowViolation < EpicGridError
    attr_reader :current_status, :attempted_action, :suggested_actions

    def initialize(current_status = nil, attempted_action = nil, suggested_actions = [], message = nil)
      @current_status = current_status
      @attempted_action = attempted_action
      @suggested_actions = suggested_actions
      super(message || "ワークフロー違反: #{attempted_action}")
    end
  end
  # 統一API基底コントローラー
  # API統合仕様書準拠の標準化されたレスポンス・エラーハンドリング提供
  class BaseApiController < ApplicationController
    before_action :api_require_login, :find_project, :authorize_kanban_access
    before_action :set_start_time

    # 統一例外ハンドリング
    rescue_from StandardError, with: :handle_internal_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from EpicGrid::PermissionDenied, with: :handle_permission_denied
    rescue_from EpicGrid::WorkflowViolation, with: :handle_workflow_error

    # パフォーマンス監視
    after_action :log_performance_metrics

    protected

    # 成功応答の統一形式
    def render_success(data = {}, status = :ok)
      response_data = build_success_response(data)
      render json: response_data, status: status
    end

    # エラー応答の統一形式
    def render_error(message, status, details = {})
      response_data = build_error_response(message, status, details)
      render json: response_data, status: status
    end

    # バリデーションエラー応答
    def render_validation_error(errors, details = {})
      response_data = build_validation_error_response(errors, details)
      render json: response_data, status: :unprocessable_entity
    end

    private

    # 成功応答データ構築
    def build_success_response(data)
      {
        success: true,
        data: data,
        meta: response_metadata
      }
    end

    # エラー応答データ構築
    def build_error_response(message, status, details)
      {
        success: false,
        error: {
          message: message,
          code: error_code_for_status(status),
          details: details
        },
        meta: response_metadata
      }
    end

    # バリデーションエラー応答データ構築
    def build_validation_error_response(errors, details)
      validation_errors = format_validation_errors(errors)

      {
        success: false,
        error: {
          message: 'バリデーションエラー',
          code: 'validation_failed',
          details: details,
          validation_errors: validation_errors
        },
        meta: response_metadata
      }
    end

    # レスポンスメタデータ
    def response_metadata
      {
        timestamp: Time.current.iso8601,
        request_id: request.uuid,
        api_version: 'v1',
        execution_time: execution_time
      }
    end

    # バリデーションエラー整形
    def format_validation_errors(errors)
      case errors
      when ActiveModel::Errors
        errors.messages.map do |field, messages|
          messages.map do |message|
            {
              field: field.to_s,
              message: message,
              code: "invalid_#{field}"
            }
          end
        end.flatten
      when Array
        errors
      else
        [{ field: 'base', message: errors.to_s, code: 'invalid' }]
      end
    end

    # ステータス別エラーコード
    def error_code_for_status(status)
      case status
      when :not_found, 404
        'not_found'
      when :forbidden, 403
        'permission_denied'
      when :unprocessable_entity, 422
        'validation_failed'
      when :workflow_violation
        'workflow_violation'
      when :internal_server_error, 500
        'internal_error'
      else
        'unknown_error'
      end
    end

    # 例外ハンドラ
    def handle_not_found(exception)
      Rails.logger.info "Not Found: #{exception.message}"
      render_error('リソースが見つかりません', :not_found, {
        resource_type: extract_resource_type(exception),
        resource_id: extract_resource_id(exception)
      })
    end

    def handle_validation_error(exception)
      Rails.logger.info "Validation Error: #{exception.message}"
      render_validation_error(exception.record.errors)
    end

    def handle_permission_denied(exception)
      Rails.logger.warn "Permission Denied: #{exception.message}"
      render_error('権限が不足しています', :forbidden, {
        required_permission: exception.try(:permission),
        resource: exception.try(:resource)
      })
    end

    def handle_workflow_error(exception)
      Rails.logger.info "Workflow Violation: #{exception.message}"
      render_error('ワークフロー違反です', :workflow_violation, {
        current_status: exception.try(:current_status),
        attempted_action: exception.try(:attempted_action),
        suggested_actions: exception.try(:suggested_actions)
      })
    end

    def handle_internal_error(exception)
      Rails.logger.error "Internal Error: #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
      render_error('サーバーエラー', :internal_server_error, {
        error_id: request.uuid
      })
    end

    # ユーティリティメソッド
    def extract_resource_type(exception)
      case exception.message
      when /Issue/
        'Issue'
      when /Project/
        'Project'
      when /Version/
        'Version'
      else
        'Unknown'
      end
    end

    def extract_resource_id(exception)
      exception.message.scan(/\d+/).first
    end

    def set_start_time
      @start_time = Time.current
    end

    def execution_time
      return nil unless @start_time
      ((Time.current - @start_time) * 1000).round(1)
    end

    def find_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    end

    def authorize_kanban_access
      # view_issues 権限で代用（view_kanban が未定義の場合）
      unless User.current.allowed_to?(:view_issues, @project)
        raise EpicGrid::PermissionDenied.new('view_issues', @project)
      end
    end

    def log_performance_metrics
      return unless @start_time

      duration = execution_time
      Rails.logger.info "API Performance: #{controller_name}##{action_name} #{duration}ms"

      if duration > 2000
        Rails.logger.warn "Slow API: #{controller_name}##{action_name} #{duration}ms"
      end
    end

    # API専用認証処理（設計書準拠）
    def api_require_login
      # セッション認証を試行
      if session_authenticated?
        return true
      end

      # API トークン認証を試行
      if api_token_authenticated?
        return true
      end

      # 認証失敗
      Rails.logger.info "API Authentication failed: session=#{session[:user_id]}, token=#{api_token_from_request}"
      raise EpicGrid::PermissionDenied.new('login', nil, '認証が必要です')
    end

    # セッション認証確認
    def session_authenticated?
      return false unless session[:user_id]

      user = User.find_by(id: session[:user_id])
      return false unless user&.active?

      User.current = user
      Rails.logger.info "API Session authenticated: user=#{user.login} (id=#{user.id})"
      true
    rescue => e
      Rails.logger.warn "Session authentication error: #{e.message}"
      false
    end

    # API トークン認証確認
    def api_token_authenticated?
      token = api_token_from_request
      return false if token.blank?

      user = User.find_by_api_key(token)
      return false unless user&.active?

      User.current = user
      Rails.logger.info "API Token authenticated: user=#{user.login} (id=#{user.id})"
      true
    rescue => e
      Rails.logger.warn "API token authentication error: #{e.message}"
      false
    end

    # リクエストからAPIトークン取得
    def api_token_from_request
      # ヘッダーからトークン取得
      token = request.headers['X-Redmine-API-Key']
      return token if token.present?

      # パラメータからトークン取得
      params[:key]
    end

    # Issue シリアライザー（基本情報のみ）
    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        description: issue.description,
        tracker_id: issue.tracker_id,
        tracker_name: issue.tracker&.name,
        status_id: issue.status_id,
        status_name: issue.status&.name,
        priority_id: issue.priority_id,
        assigned_to_id: issue.assigned_to_id,
        assigned_to_name: issue.assigned_to&.name,
        fixed_version_id: issue.fixed_version_id,
        fixed_version_name: issue.fixed_version&.name,
        parent_id: issue.parent_id,
        start_date: issue.start_date,
        due_date: issue.due_date,
        estimated_hours: issue.estimated_hours,
        done_ratio: issue.done_ratio,
        created_on: issue.created_on,
        updated_on: issue.updated_on
      }
    end

    # Issue シリアライザー（子要素付き）
    def serialize_issue_with_children(issue)
      base = serialize_issue(issue)
      base[:children] = issue.children.map { |child| serialize_issue(child) }
      base
    end

    # UserStory シリアライザー（Task/Test/Bug付き）
    def serialize_user_stories_with_children(user_stories)
      user_stories.map do |us|
        serialize_issue_with_children(us)
      end
    end

    # Issue関係性シリアライザー
    def serialize_relationships(issue)
      {
        parent: issue.parent ? serialize_issue(issue.parent) : nil,
        children: issue.children.map { |child| serialize_issue(child) },
        relations: []
      }
    end

    # アクティビティタイムライン構築
    def build_activity_timeline(issue)
      []
    end
  end
end