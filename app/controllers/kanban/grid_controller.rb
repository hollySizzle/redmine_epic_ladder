# frozen_string_literal: true

module Kanban
  # グリッドデータ管理コントローラー
  # Epic×Version マトリクスデータ取得・操作API提供
  class GridController < BaseApiController
    before_action :find_issue, only: [:move_feature, :create_epic]

    # Grid Data取得 (API001)
    def show
      grid_data = Kanban::GridDataBuilder.new(@project, User.current).build
      statistics = Kanban::StatisticsCalculator.new(@project).calculate

      render_success({
        project: project_metadata,
        grid: grid_data,
        statistics: statistics,
        metadata: {
          last_updated: Time.current.iso8601,
          cache_version: calculate_cache_version,
          user_permissions: user_permissions
        }
      })
    rescue => e
      Rails.logger.error "Grid data error: #{e.message}"
      render_error('グリッドデータの取得に失敗しました', :internal_server_error)
    end

    # Feature移動 (API002) - 楽観的更新対応
    def move_feature
      feature = Issue.find(params[:feature_id])
      target_epic_id = params[:target_epic_id]
      target_version_id = params[:target_version_id]
      optimistic_lock_version = params[:lock_version]

      # 楽観的ロックチェック
      if optimistic_lock_version && feature.lock_version != optimistic_lock_version.to_i
        raise Kanban::ConcurrencyError.new(
          feature.id,
          feature.lock_version,
          optimistic_lock_version
        )
      end

      result = Kanban::FeatureMoveService.execute(
        feature: feature,
        target_epic_id: target_epic_id,
        target_version_id: target_version_id,
        user: User.current
      )

      if result[:success]
        render_success({
          feature: serialize_issue(result[:feature]),
          affected_issues: result[:affected_issues].map { |issue| serialize_issue(issue) },
          propagation_results: result[:propagation_results],
          grid_updates: result[:grid_updates]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    rescue Kanban::ConcurrencyError => e
      render_error(
        'リソースが他のユーザーによって更新されています',
        :conflict,
        {
          resource_id: e.resource_id,
          current_version: e.current_version,
          attempted_version: e.attempted_version
        }
      )
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたFeatureが見つかりません', :not_found)
    end

    # Epic作成 (API003)
    def create_epic
      epic_params = params.require(:epic).permit(:subject, :description, :assigned_to_id, :fixed_version_id)

      result = Kanban::EpicCreationService.execute(
        project: @project,
        epic_params: epic_params,
        user: User.current
      )

      if result[:success]
        render_success({
          epic: serialize_issue(result[:epic]),
          grid_position: result[:grid_position],
          affected_statistics: result[:statistics_update]
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue => e
      Rails.logger.error "Epic creation error: #{e.message}"
      render_error('Epicの作成に失敗しました', :internal_server_error)
    end

    # Version自動伝播 (API004)
    def propagate_version
      issue = Issue.find(params[:issue_id])
      version = params[:version_id].present? ? Version.find(params[:version_id]) : nil

      result = Kanban::VersionPropagationService.propagate_to_children(issue, version)

      if result[:success]
        render_success({
          root_issue: serialize_issue(issue.reload),
          affected_issues: result[:affected_issues].map { |issue| serialize_issue(issue) },
          propagation_summary: result[:summary],
          consistency_validation: result[:consistency_check]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたIssueまたはVersionが見つかりません', :not_found)
    end

    private

    def find_issue
      @issue = Issue.find(params[:issue_id]) if params[:issue_id]
    end

    def project_metadata
      {
        id: @project.id,
        name: @project.name,
        identifier: @project.identifier,
        description: @project.description,
        trackers: @project.trackers.pluck(:id, :name),
        versions: @project.versions.pluck(:id, :name, :status),
        issue_statuses: IssueStatus.all.pluck(:id, :name)
      }
    end

    def user_permissions
      {
        view_issues: User.current.allowed_to?(:view_issues, @project),
        edit_issues: User.current.allowed_to?(:edit_issues, @project),
        manage_versions: User.current.allowed_to?(:manage_versions, @project),
        view_kanban: User.current.allowed_to?(:view_kanban, @project),
        manage_kanban: User.current.allowed_to?(:manage_kanban, @project)
      }
    end

    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        status_column: determine_kanban_column(issue),
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        fixed_version: issue.fixed_version&.name,
        parent_id: issue.parent_id,
        hierarchy_level: Kanban::TrackerHierarchy.level(issue.tracker.name),
        lock_version: issue.lock_version,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        can_edit: User.current.allowed_to?(:edit_issues, @project),
        workflow_transitions: available_status_transitions(issue)
      }
    end

    def determine_kanban_column(issue)
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

    def available_status_transitions(issue)
      issue.new_statuses_allowed_to(User.current).map do |status|
        {
          id: status.id,
          name: status.name,
          column: determine_kanban_column_by_status(status)
        }
      end
    end

    def determine_kanban_column_by_status(status)
      determine_kanban_column(OpenStruct.new(status: status))
    end

    def calculate_cache_version
      # プロジェクトの最終更新時刻とIssue数をベースにキャッシュバージョン計算
      latest_issue_update = @project.issues.maximum(:updated_on) || @project.updated_on
      issue_count = @project.issues.count
      Digest::MD5.hexdigest("#{latest_issue_update}-#{issue_count}")
    end
  end
end