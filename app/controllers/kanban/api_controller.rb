# frozen_string_literal: true

module Kanban
  # APIコントローラー（既存互換性維持）
  # BaseApiController継承による統一応答形式対応
  class ApiController < BaseApiController
    # 統一応答形式のテスト用にBaseApiControllerを継承
    # 既存エンドポイントの後方互換性を維持

    # カンバンデータの取得（既存API互換）
    def kanban_data
      grid_data = Kanban::GridDataBuilderService.new(@project, User.current).build

      # 既存形式での応答（後方互換性のため）
      legacy_data = build_legacy_response(grid_data)
      render_success(legacy_data)
    rescue => e
      Rails.logger.error "Kanban data error: #{e.message}"
      render_error('カンバンデータの取得に失敗しました', :internal_server_error)
    end

    # イシューの状態遷移（既存API互換）
    def transition_issue
      issue = Issue.find(params[:issue_id])
      target_column = params[:target_column]

      result = Kanban::StateTransitionService.transition_to_column(issue, target_column)

      if result[:error]
        render_error(result[:error], :unprocessable_entity, result[:details])
      else
        render_success({
          issue: serialize_issue(issue.reload),
          transition: result
        })
      end
    rescue ActiveRecord::RecordNotFound
      render_error('イシューが見つかりません', :not_found)
    end

    # バージョン割当（既存API互換）
    def assign_version
      issue = Issue.find(params[:issue_id])
      version_id = params[:version_id]
      version = version_id.present? ? Version.find(version_id) : nil

      result = Kanban::VersionPropagationService.propagate_to_children(issue, version)

      if result[:error]
        render_error(result[:error], :unprocessable_entity, result[:details])
      else
        render_success({
          issue: serialize_issue(issue.reload),
          propagation: result
        })
      end
    rescue ActiveRecord::RecordNotFound
      render_error('リソースが見つかりません', :not_found)
    end

    # Test自動生成（既存API互換）
    def generate_test
      user_story = Issue.find(params[:user_story_id])
      force = params[:force] == true

      result = Kanban::TestGenerationService.generate_test_for_user_story(user_story, force_recreate: force)

      if result[:error]
        render_error(result[:error], :unprocessable_entity, result[:details])
      else
        render_success({
          test_issue: serialize_issue(result[:test_issue]),
          relation_created: result[:relation_created]
        })
      end
    rescue ActiveRecord::RecordNotFound
      render_error('UserStoryが見つかりません', :not_found)
    end

    # リリース準備検証（既存API互換）
    def validate_release
      user_story = Issue.find(params[:user_story_id])

      result = Kanban::ValidationGuardService.validate_release_readiness(user_story)
      render_success(result)
    rescue ActiveRecord::RecordNotFound
      render_error('UserStoryが見つかりません', :not_found)
    end

    # 接続テスト（既存API互換）
    def test_connection
      render_success({
        status: 'ok',
        timestamp: Time.current.iso8601,
        user: User.current&.name,
        version: '2.0.0-api-integrated',
        api_features: {
          unified_response: true,
          realtime_communication: true,
          batch_operations: true,
          optimistic_updates: true
        }
      })
    end

    private

    # 既存形式レスポンス構築（後方互換性）
    def build_legacy_response(grid_data)
      issues = @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version, :parent)

      {
        project: project_metadata,
        columns: grid_data[:columns],
        issues: issues.map { |issue| serialize_issue(issue) },
        statistics: build_statistics(issues),
        metadata: {
          last_updated: Time.current.iso8601,
          total_issues: issues.count,
          api_version: '2.0.0-legacy-compatible'
        }
      }
    end

    def build_statistics(issues)
      {
        by_tracker: issues.group_by { |i| i.tracker.name }.transform_values(&:count),
        by_status: issues.group_by { |i| i.status.name }.transform_values(&:count),
        by_assignee: issues.group_by { |i| i.assigned_to&.name || '未割当' }.transform_values(&:count)
      }
    end

    def project_metadata
      {
        id: @project.id,
        name: @project.name,
        identifier: @project.identifier,
        description: @project.description,
        trackers: @project.trackers.pluck(:id, :name),
        versions: @project.versions.pluck(:id, :name)
      }
    end

    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        assigned_to_id: issue.assigned_to_id,
        fixed_version: issue.fixed_version&.name,
        fixed_version_id: issue.fixed_version_id,
        parent_id: issue.parent_id,
        hierarchy_level: Kanban::TrackerHierarchy.level(issue.tracker.name),
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        lock_version: issue.lock_version,
        column: determine_column_for_issue(issue),
        can_edit: User.current.allowed_to?(:edit_issues, @project)
      }
    end

    def determine_column_for_issue(issue)
      status_name = issue.status.name
      case status_name
      when 'New', 'Open'
        'backlog'
      when 'Ready'
        'ready'
      when 'In Progress', 'Assigned'
        'in_progress'
      when 'Review', 'Ready for Test'
        'review'
      when 'Testing', 'QA'
        'testing'
      when 'Resolved', 'Closed'
        'done'
      else
        'backlog'
      end
    end
  end
end