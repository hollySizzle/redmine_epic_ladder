# frozen_string_literal: true

module Kanban
  # 統一API基底コントローラー
  # API統合仕様書準拠の標準化されたレスポンス・エラーハンドリング提供
  class BaseApiController < ApplicationController
    before_action :require_login, :find_project, :authorize_kanban_access
    before_action :set_start_time

    # 統一例外ハンドリング
    rescue_from StandardError, with: :handle_internal_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from Kanban::PermissionDenied, with: :handle_permission_denied
    rescue_from Kanban::WorkflowViolation, with: :handle_workflow_error

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
      unless User.current.allowed_to?(:view_kanban, @project)
        raise Kanban::PermissionDenied.new('view_kanban', @project)
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
  end
end