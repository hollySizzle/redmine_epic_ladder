# frozen_string_literal: true

module Kanban
  # Zeitwerkが期待するExceptionsモジュール
  module Exceptions
    # カスタム例外クラス群
    
    class KanbanError < StandardError
      attr_reader :details

      def initialize(message = nil, details = {})
        super(message)
        @details = details
      end
    end

    class PermissionDenied < KanbanError
      attr_reader :permission, :resource

      def initialize(permission = nil, resource = nil, message = nil)
        @permission = permission
        @resource = resource
        super(message || "権限が不足しています: #{permission}")
      end
    end

    class WorkflowViolation < KanbanError
      attr_reader :current_status, :attempted_action, :suggested_actions

      def initialize(current_status = nil, attempted_action = nil, suggested_actions = [], message = nil)
        @current_status = current_status
        @attempted_action = attempted_action
        @suggested_actions = suggested_actions
        super(message || "ワークフロー違反: #{attempted_action}")
      end
    end

    class ValidationError < KanbanError
      attr_reader :errors

      def initialize(errors = {}, message = nil)
        @errors = errors
        super(message || "バリデーションエラー")
      end
    end

    class ConcurrencyError < KanbanError
      attr_reader :resource_id, :current_version, :attempted_version

      def initialize(resource_id = nil, current_version = nil, attempted_version = nil, message = nil)
        @resource_id = resource_id
        @current_version = current_version
        @attempted_version = attempted_version
        super(message || "競合エラー: リソースが他のユーザーによって更新されています")
      end
    end

    class RateLimitExceeded < KanbanError
      attr_reader :limit, :window, :retry_after

      def initialize(limit = nil, window = nil, retry_after = nil, message = nil)
        @limit = limit
        @window = window
        @retry_after = retry_after
        super(message || "レート制限に達しました")
      end
    end
  end

  # 後方互換性のため、直接Kanbanモジュール下でもアクセス可能にする
  KanbanError = Exceptions::KanbanError
  PermissionDenied = Exceptions::PermissionDenied
  WorkflowViolation = Exceptions::WorkflowViolation
  ValidationError = Exceptions::ValidationError
  ConcurrencyError = Exceptions::ConcurrencyError
  RateLimitExceeded = Exceptions::RateLimitExceeded
end