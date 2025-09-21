# frozen_string_literal: true

module Kanban
  # APIコントローラー
  # React-バックエンド間効率的データ交換とRedmine標準API統合
  class ApiController < ApplicationController
    before_action :require_login
    before_action :find_project, except: [:test_connection]
    before_action :authorize_kanban, except: [:test_connection]

    # カンバンデータの取得
    def kanban_data
      begin
        data = build_kanban_response
        render json: data
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end

    # イシューの状態遷移
    def transition_issue
      issue = Issue.find(params[:issue_id])
      target_column = params[:target_column]

      result = StateTransitionService.transition_to_column(issue, target_column)

      if result[:error]
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: {
          success: true,
          issue: issue_json(issue.reload),
          transition: result
        }
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'イシューが見つかりません' }, status: :not_found
    end

    # バージョン割当
    def assign_version
      issue = Issue.find(params[:issue_id])
      version_id = params[:version_id]
      version = version_id.present? ? Version.find(version_id) : nil

      result = VersionPropagationService.propagate_to_children(issue, version)

      if result[:error]
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: {
          success: true,
          issue: issue_json(issue.reload),
          propagation: result
        }
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'リソースが見つかりません' }, status: :not_found
    end

    # Test自動生成
    def generate_test
      user_story = Issue.find(params[:user_story_id])
      force = params[:force] == true

      result = TestGenerationService.generate_test_for_user_story(user_story, force_recreate: force)

      if result[:error]
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: {
          success: true,
          test_issue: issue_json(result[:test_issue]),
          relation_created: result[:relation_created]
        }
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'UserStoryが見つかりません' }, status: :not_found
    end

    # リリース準備検証
    def validate_release
      user_story = Issue.find(params[:user_story_id])

      result = ValidationGuardService.validate_release_readiness(user_story)

      render json: result
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'UserStoryが見つかりません' }, status: :not_found
    end

    # 接続テスト
    def test_connection
      render json: {
        status: 'ok',
        timestamp: Time.current.iso8601,
        user: User.current&.name,
        version: '1.0.0-skeleton'
      }
    end

    private

    def build_kanban_response
      issues = @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version, :parent, :children)

      {
        project: project_json(@project),
        columns: kanban_columns,
        issues: issues.map { |issue| issue_json(issue) },
        statistics: build_statistics(issues),
        metadata: {
          last_updated: Time.current.iso8601,
          total_issues: issues.count
        }
      }
    end

    def kanban_columns
      [
        { id: 'backlog', title: 'バックログ', statuses: ['New', 'Open'] },
        { id: 'ready', title: '準備完了', statuses: ['Ready'] },
        { id: 'in_progress', title: '進行中', statuses: ['In Progress', 'Assigned'] },
        { id: 'review', title: 'レビュー', statuses: ['Review', 'Ready for Test'] },
        { id: 'testing', title: 'テスト中', statuses: ['Testing', 'QA'] },
        { id: 'done', title: '完了', statuses: ['Resolved', 'Closed'] }
      ]
    end

    def build_statistics(issues)
      {
        by_tracker: issues.group_by { |i| i.tracker.name }.transform_values(&:count),
        by_status: issues.group_by { |i| i.status.name }.transform_values(&:count),
        by_assignee: issues.group_by { |i| i.assigned_to&.name || '未割当' }.transform_values(&:count)
      }
    end

    def project_json(project)
      {
        id: project.id,
        name: project.name,
        identifier: project.identifier,
        description: project.description
      }
    end

    def issue_json(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        fixed_version: issue.fixed_version&.name,
        parent_id: issue.parent_id,
        hierarchy_level: TrackerHierarchy.level(issue.tracker.name),
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        column: determine_column_for_issue(issue)
      }
    end

    def determine_column_for_issue(issue)
      status_name = issue.status.name
      kanban_columns.each do |column|
        return column[:id] if column[:statuses].include?(status_name)
      end
      'backlog'
    end

    def find_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    end

    def authorize_kanban
      deny_access unless User.current.allowed_to?(:view_issues, @project)
    end
  end
end