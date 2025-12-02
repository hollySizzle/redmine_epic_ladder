# frozen_string_literal: true

# Epic Grid メインコントローラー
# ReactアプリとRedmine統合のエントリーポイント
class EpicLadderController < ApplicationController
  helper EpicLadderHelper

  before_action :require_login
  before_action :find_project
  before_action :authorize_kanban

  # メインカンバン画面の表示
  def index
    # プロジェクトの基本情報を取得
    @project_data = {
      id: @project.id,
      name: @project.name,
      identifier: @project.identifier,
      description: @project.description
    }

    # 現在のユーザー情報
    @current_user_data = {
      id: User.current.id,
      name: User.current.name,
      login: User.current.login,
      mail: User.current.mail
    }

    # 初期データの準備（オプション）
    @initial_kanban_data = build_initial_data if params[:preload] == 'true'

    # ページタイトルとメタ情報
    @page_title = "Epic Grid - #{@project.name}"

    # React アプリケーション用の設定
    @react_config = {
      projectId: @project.id,
      currentUser: @current_user_data,
      initialData: @initial_kanban_data,
      permissions: gather_user_permissions,
      settings: gather_kanban_settings
    }

    respond_to do |format|
      format.html { render layout: 'base' }
      format.json { render json: @react_config }
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    @project ||= Project.find(params[:id]) if params[:id]

    unless @project
      render_404
      return false
    end

    @project
  end

  def authorize_kanban
    # カンバン表示権限をチェック（既存の権限チェックを拡張）
    unless User.current.allowed_to?(:view_issues, @project)
      deny_access
      return false
    end

    # TODO: カスタム権限の実装
    # unless User.current.allowed_to?(:view_release_kanban, @project)
    #   deny_access
    #   return false
    # end

    true
  end

  def build_initial_data
    begin
      # 簡易版の初期データ構築
      issues = @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version, :parent)

      {
        project: @project_data,
        columns: [
          { id: 'todo', title: 'ToDo', statuses: ['New', 'Open'] },
          { id: 'in_progress', title: 'In Progress', statuses: ['In Progress', 'Assigned'] },
          { id: 'ready_for_test', title: 'Ready for Test', statuses: ['Review', 'Ready for Test'] },
          { id: 'released', title: 'Released', statuses: ['Resolved', 'Closed'] }
        ],
        issues: issues.limit(100).map { |issue| build_issue_json(issue) },
        statistics: build_statistics(issues),
        metadata: {
          last_updated: Time.current.iso8601,
          total_issues: issues.count
        }
      }
    rescue => e
      Rails.logger.error "初期データ構築エラー: #{e.message}"
      nil
    end
  end

  def build_issue_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      priority: issue.priority&.name,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name,
      parent_id: issue.parent_id,
      hierarchy_level: determine_hierarchy_level(issue.tracker.name),
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601,
      column: determine_column_for_status(issue.status.name),
      epic: find_epic_name(issue)
    }
  end

  def determine_hierarchy_level(tracker_name)
    tracker_names = EpicLadder::TrackerHierarchy.tracker_names
    hierarchy_map = {
      tracker_names[:epic] => 1,
      tracker_names[:feature] => 2,
      tracker_names[:user_story] => 3
    }
    hierarchy_map.fetch(tracker_name, 4)
  end

  def determine_column_for_status(status_name)
    column_mapping = {
      ['New', 'Open'] => 'todo',
      ['In Progress', 'Assigned'] => 'in_progress',
      ['Review', 'Ready for Test'] => 'ready_for_test',
      ['Resolved', 'Closed'] => 'released'
    }

    column_mapping.each do |statuses, column|
      return column if statuses.include?(status_name)
    end

    'todo'
  end

  def find_epic_name(issue)
    epic_tracker_name = EpicLadder::TrackerHierarchy.tracker_names[:epic]
    current = issue.parent
    while current
      return current.subject if current.tracker.name == epic_tracker_name
      current = current.parent
    end
    nil
  end

  def build_statistics(issues)
    {
      by_tracker: issues.group(:tracker_id).count.transform_keys { |id| Tracker.find(id).name },
      by_status: issues.group(:status_id).count.transform_keys { |id| IssueStatus.find(id).name },
      by_assignee: issues.group(:assigned_to_id).count.transform_keys { |id| id ? User.find(id).name : '未割当' }
    }
  end

  def gather_user_permissions
    {
      view_issues: User.current.allowed_to?(:view_issues, @project),
      edit_issues: User.current.allowed_to?(:edit_issues, @project),
      add_issues: User.current.allowed_to?(:add_issues, @project),
      delete_issues: User.current.allowed_to?(:delete_issues, @project),
      manage_versions: User.current.allowed_to?(:manage_versions, @project),
      view_time_entries: User.current.allowed_to?(:view_time_entries, @project)
    }
  end

  def gather_kanban_settings
    {
      # プロジェクト固有の設定
      enable_epic_swimlanes: true,
      enable_drag_and_drop: true,
      enable_batch_operations: true,
      enable_auto_generation: true,
      enable_validation_guards: true,

      # 機能フラグ
      features: {
        tracker_hierarchy: true,
        version_management: true,
        auto_generation: true,
        state_transition: true,
        validation_guard: true,
        api_integration: true
      },

      # UI設定
      ui: {
        theme: 'default',
        compact_mode: false,
        show_issue_ids: true,
        show_assignee: true,
        show_version: true
      }
    }
  end
end
