# frozen_string_literal: true

module Kanban
  # 一括操作コントローラー
  # 複数Issue同時更新・一括割り当て・一括処理API提供
  class BatchOperationsController < BaseApiController

    # 一括更新 (API005)
    def update
      issue_ids = params[:issue_ids] || []
      update_params = params.require(:updates).permit(:status_id, :assigned_to_id, :fixed_version_id, :priority_id)

      if issue_ids.empty?
        render_error('更新対象のIssueが指定されていません', :bad_request)
        return
      end

      if issue_ids.count > 100
        render_error('一度に更新できるIssueは100件までです', :bad_request)
        return
      end

      result = Kanban::BatchUpdateService.execute(
        issue_ids: issue_ids,
        update_params: update_params,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          updated_issues: result[:updated_issues].map { |issue| serialize_issue(issue) },
          failed_updates: result[:failed_updates],
          summary: result[:summary],
          affected_relationships: result[:affected_relationships],
          performance_metrics: result[:performance_metrics]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # Version一括割当 (API004拡張)
    def assign_version
      issue_ids = params[:issue_ids] || []
      version_id = params[:version_id]
      propagate_to_children = params[:propagate_to_children] == true
      force_update = params[:force_update] == true

      if issue_ids.empty?
        render_error('割り当て対象のIssueが指定されていません', :bad_request)
        return
      end

      result = Kanban::BatchVersionAssignmentService.execute(
        issue_ids: issue_ids,
        version_id: version_id,
        propagate_to_children: propagate_to_children,
        force_update: force_update,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          assigned_issues: result[:assigned_issues].map { |issue| serialize_issue(issue) },
          propagation_results: result[:propagation_results],
          conflicts_resolved: result[:conflicts_resolved],
          summary: result[:summary],
          validation_warnings: result[:validation_warnings]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # テスト一括生成
    def generate_tests
      user_story_ids = params[:user_story_ids] || []
      force_recreate = params[:force_recreate] == true
      test_template = params[:test_template]

      if user_story_ids.empty?
        render_error('テスト生成対象のUserStoryが指定されていません', :bad_request)
        return
      end

      result = Kanban::BatchTestGenerationService.execute(
        user_story_ids: user_story_ids,
        force_recreate: force_recreate,
        test_template: test_template,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          generated_tests: result[:generated_tests].map { |test| serialize_issue(test) },
          skipped_user_stories: result[:skipped_user_stories],
          created_relations: result[:created_relations],
          summary: result[:summary],
          generation_metrics: result[:generation_metrics]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # 状態一括遷移
    def transition_status
      issue_ids = params[:issue_ids] || []
      target_status_id = params[:target_status_id]
      workflow_validation = params[:workflow_validation] != false
      notes = params[:notes]

      if issue_ids.empty?
        render_error('遷移対象のIssueが指定されていません', :bad_request)
        return
      end

      if target_status_id.blank?
        render_error('遷移先ステータスが指定されていません', :bad_request)
        return
      end

      result = Kanban::BatchStatusTransitionService.execute(
        issue_ids: issue_ids,
        target_status_id: target_status_id,
        workflow_validation: workflow_validation,
        notes: notes,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          transitioned_issues: result[:transitioned_issues].map { |issue| serialize_issue(issue) },
          workflow_violations: result[:workflow_violations],
          permission_denials: result[:permission_denials],
          summary: result[:summary],
          cascade_effects: result[:cascade_effects]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # 関連Issue一括作成
    def create_related_issues
      parent_issue_id = params[:parent_issue_id]
      issue_templates = params[:issue_templates] || []

      if parent_issue_id.blank?
        render_error('親Issueが指定されていません', :bad_request)
        return
      end

      if issue_templates.empty?
        render_error('作成するIssueのテンプレートが指定されていません', :bad_request)
        return
      end

      parent_issue = Issue.find(parent_issue_id)

      result = Kanban::BatchRelatedIssueCreationService.execute(
        parent_issue: parent_issue,
        issue_templates: issue_templates,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          created_issues: result[:created_issues].map { |issue| serialize_issue(issue) },
          parent_issue: serialize_issue(parent_issue.reload),
          created_relations: result[:created_relations],
          hierarchy_updates: result[:hierarchy_updates],
          summary: result[:summary]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定された親Issueが見つかりません', :not_found)
    end

    # 優先度一括調整
    def adjust_priorities
      issue_priority_pairs = params[:issue_priority_pairs] || []

      if issue_priority_pairs.empty?
        render_error('優先度調整対象が指定されていません', :bad_request)
        return
      end

      result = Kanban::BatchPriorityAdjustmentService.execute(
        issue_priority_pairs: issue_priority_pairs,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          adjusted_issues: result[:adjusted_issues].map { |issue| serialize_issue(issue) },
          priority_conflicts: result[:priority_conflicts],
          dependency_updates: result[:dependency_updates],
          summary: result[:summary]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # 一括削除（ソフトデリート）
    def soft_delete
      issue_ids = params[:issue_ids] || []
      deletion_reason = params[:deletion_reason]

      if issue_ids.empty?
        render_error('削除対象のIssueが指定されていません', :bad_request)
        return
      end

      result = Kanban::BatchSoftDeleteService.execute(
        issue_ids: issue_ids,
        deletion_reason: deletion_reason,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          deleted_issues: result[:deleted_issues].map { |issue| serialize_issue(issue) },
          cascade_deletions: result[:cascade_deletions],
          preserved_relations: result[:preserved_relations],
          summary: result[:summary]
        })
      else
        render_error(result[:error], :unprocessable_entity, result[:details])
      end
    end

    # バッチ操作ステータス確認
    def status
      batch_job_id = params[:batch_job_id]

      if batch_job_id.blank?
        render_error('バッチジョブIDが指定されていません', :bad_request)
        return
      end

      job_status = Kanban::BatchJobTracker.status(batch_job_id)

      if job_status
        render_success({
          job_id: batch_job_id,
          status: job_status[:status],
          progress: job_status[:progress],
          total_items: job_status[:total_items],
          processed_items: job_status[:processed_items],
          errors: job_status[:errors],
          estimated_completion: job_status[:estimated_completion],
          results_preview: job_status[:results_preview]
        })
      else
        render_error('指定されたバッチジョブが見つかりません', :not_found)
      end
    end

    # 操作履歴取得
    def operation_history
      limit = [params[:limit]&.to_i || 50, 100].min
      offset = params[:offset]&.to_i || 0
      operation_type = params[:operation_type]
      user_id = params[:user_id]

      history = Kanban::BatchOperationHistory.for_project(@project)
                                           .with_operation_type(operation_type)
                                           .with_user(user_id)
                                           .order(created_at: :desc)
                                           .limit(limit)
                                           .offset(offset)

      total_count = history.count

      render_success({
        operations: history.map do |operation|
          {
            id: operation.id,
            operation_type: operation.operation_type,
            user: operation.user.name,
            affected_issues_count: operation.affected_issues_count,
            success_count: operation.success_count,
            error_count: operation.error_count,
            execution_time: operation.execution_time,
            created_at: operation.created_at.iso8601,
            summary: operation.summary
          }
        end,
        pagination: {
          current_offset: offset,
          limit: limit,
          total_count: total_count,
          has_more: offset + limit < total_count
        }
      })
    end

    private

    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        status_column: determine_kanban_column(issue),
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        assigned_to_id: issue.assigned_to_id,
        fixed_version: issue.fixed_version&.name,
        fixed_version_id: issue.fixed_version_id,
        parent_id: issue.parent_id,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        lock_version: issue.lock_version,
        can_edit: User.current.allowed_to?(:edit_issues, @project)
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
  end
end