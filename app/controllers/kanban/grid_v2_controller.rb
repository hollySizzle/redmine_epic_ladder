# frozen_string_literal: true

module Kanban
  # GridV2Controller - 設計書準拠のカンバングリッド専用コントローラー
  # 設計書仕様: 2次元グリッドマトリクス管理とAPI提供（完全新規実装）
  class GridV2Controller < ApplicationController
    before_action :require_login
    before_action :find_project
    before_action :authorize_kanban
    before_action :find_issue, only: [:move_feature, :assign_version]

    # GET /kanban/projects/:project_id/grid_v2
    # グリッドデータの初期取得
    def index
      begin
        filters = parse_grid_filters
        builder = Kanban::GridDataBuilder.new(@project, User.current, filters)
        grid_data = builder.build

        render json: {
          success: true,
          data: grid_data,
          timestamp: Time.current.iso8601
        }
      rescue => e
        Rails.logger.error "Grid data building error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # POST /kanban/projects/:project_id/grid_v2/move_feature
    # Feature D&D移動処理
    def move_feature
      begin
        source_cell = parse_cell_coordinates(params[:source_cell])
        target_cell = parse_cell_coordinates(params[:target_cell])

        # CardMoveServiceによる移動処理
        move_service = Kanban::CardMoveService.new(@issue, User.current)
        result = move_service.execute(source_cell, target_cell)

        if result[:success]
          # グリッドデータ再構築
          builder = Kanban::GridDataBuilder.new(@project, User.current)
          updated_data = builder.build

          render json: {
            success: true,
            updated_card: build_issue_json(@issue.reload),
            affected_cells: result[:affected_cells],
            updated_data: updated_data,
            move_result: result,
            timestamp: Time.current.iso8601
          }
        else
          render json: {
            success: false,
            error: result[:error],
            constraints_violated: result[:constraints_violated],
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Feature move error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # POST /kanban/projects/:project_id/grid_v2/assign_version
    # バージョン割当処理
    def assign_version
      begin
        version_id = params[:version_id]
        version = version_id.present? ? @project.versions.find(version_id) : nil

        # VersionPropagationServiceによる伝播処理
        result = Kanban::VersionPropagationService.propagate_to_children(@issue, version)

        if result[:success]
          builder = Kanban::GridDataBuilder.new(@project, User.current)
          updated_data = builder.build

          render json: {
            success: true,
            updated_issue: build_issue_json(@issue.reload),
            propagated_issues: result[:propagated_issues],
            updated_data: updated_data,
            timestamp: Time.current.iso8601
          }
        else
          render json: {
            success: false,
            error: result[:error],
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound => e
        render json: {
          success: false,
          error: 'Version not found',
          timestamp: Time.current.iso8601
        }, status: :not_found
      rescue => e
        Rails.logger.error "Version assignment error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # POST /kanban/projects/:project_id/grid_v2/create_epic
    # Epic作成処理
    def create_epic
      begin
        epic_params = params.require(:epic).permit(:subject, :description, :assigned_to_id, :fixed_version_id)

        epic = @project.issues.build(epic_params.merge(
          tracker: Tracker.find_by(name: 'Epic'),
          author: User.current,
          status: IssueStatus.default
        ))

        if epic.save
          builder = Kanban::GridDataBuilder.new(@project, User.current)
          updated_data = builder.build

          render json: {
            success: true,
            created_epic: build_issue_json(epic),
            updated_data: updated_data,
            timestamp: Time.current.iso8601
          }
        else
          render json: {
            success: false,
            error: epic.errors.full_messages.join(', '),
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Epic creation error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # POST /kanban/projects/:project_id/grid_v2/create_version
    # Version作成処理
    def create_version
      begin
        version_params = params.require(:version).permit(:name, :description, :effective_date, :status)

        version = @project.versions.build(version_params)

        if version.save
          builder = Kanban::GridDataBuilder.new(@project, User.current)
          updated_data = builder.build

          render json: {
            success: true,
            created_version: build_version_json(version),
            updated_data: updated_data,
            timestamp: Time.current.iso8601
          }
        else
          render json: {
            success: false,
            error: version.errors.full_messages.join(', '),
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Version creation error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # GET /kanban/projects/:project_id/grid_v2/updates
    # リアルタイム更新データ取得
    def updates
      begin
        since_timestamp = params[:since]
        service = Kanban::GridUpdateService.new(@project, User.current, since_timestamp)
        updates = service.get_updates

        render json: {
          success: true,
          updates: updates[:updates],
          deleted_issues: updates[:deleted_issues],
          grid_structure_changes: updates[:grid_structure_changes],
          last_update_timestamp: Time.current.iso8601,
          has_more: updates[:has_more]
        }
      rescue => e
        Rails.logger.error "Grid updates error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    # DELETE /kanban/projects/:project_id/grid_v2/epic/:id
    # Epic削除処理
    def destroy_epic
      begin
        epic = @project.issues.find(params[:id])

        unless epic.tracker.name == 'Epic'
          render json: {
            success: false,
            error: 'Not an Epic',
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
          return
        end

        # 子要素の確認
        if epic.children.any?
          render json: {
            success: false,
            error: 'Cannot delete Epic with child Features',
            child_count: epic.children.count,
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
          return
        end

        if epic.destroy
          builder = Kanban::GridDataBuilder.new(@project, User.current)
          updated_data = builder.build

          render json: {
            success: true,
            deleted_epic_id: epic.id,
            updated_data: updated_data,
            timestamp: Time.current.iso8601
          }
        else
          render json: {
            success: false,
            error: epic.errors.full_messages.join(', '),
            timestamp: Time.current.iso8601
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Epic not found',
          timestamp: Time.current.iso8601
        }, status: :not_found
      rescue => e
        Rails.logger.error "Epic deletion error: #{e.message}"

        render json: {
          success: false,
          error: e.message,
          timestamp: Time.current.iso8601
        }, status: :internal_server_error
      end
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: 'Project not found',
        timestamp: Time.current.iso8601
      }, status: :not_found
    end

    def find_issue
      @issue = @project.issues.find(params[:issue_id] || params[:feature_id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: 'Issue not found',
        timestamp: Time.current.iso8601
      }, status: :not_found
    end

    def authorize_kanban
      unless User.current.allowed_to?(:view_issues, @project)
        render json: {
          success: false,
          error: 'Access denied',
          timestamp: Time.current.iso8601
        }, status: :forbidden
        return false
      end

      # 編集操作の権限チェック
      if action_name.in?(['move_feature', 'assign_version', 'create_epic', 'create_version', 'destroy_epic'])
        unless User.current.allowed_to?(:edit_issues, @project)
          render json: {
            success: false,
            error: 'Edit permission required',
            timestamp: Time.current.iso8601
          }, status: :forbidden
          return false
        end
      end

      true
    end

    def parse_grid_filters
      filters = {}

      filters[:assignee_id] = params[:assignee_id] if params[:assignee_id].present?
      filters[:status_ids] = params[:status_ids].split(',').map(&:to_i) if params[:status_ids].present?
      filters[:version_ids] = params[:version_ids].split(',').map(&:to_i) if params[:version_ids].present?
      filters[:search] = params[:search] if params[:search].present?

      filters
    end

    def parse_cell_coordinates(cell_params)
      return nil unless cell_params.is_a?(Hash)

      {
        epic_id: cell_params[:epic_id] == 'no-epic' ? nil : cell_params[:epic_id].to_i,
        version_id: cell_params[:version_id] == 'no-version' ? nil : cell_params[:version_id].to_i,
        column_id: cell_params[:column_id]
      }
    end

    def build_issue_json(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        priority: issue.priority&.name,
        assigned_to: issue.assigned_to&.name,
        assigned_to_id: issue.assigned_to_id,
        fixed_version: issue.fixed_version&.name,
        fixed_version_id: issue.fixed_version_id,
        parent_id: issue.parent_id,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        description: issue.description,
        estimated_hours: issue.estimated_hours,
        done_ratio: issue.done_ratio
      }
    end

    def build_version_json(version)
      {
        id: version.id,
        name: version.name,
        description: version.description,
        effective_date: version.effective_date&.iso8601,
        status: version.status,
        created_on: version.created_on.iso8601,
        updated_on: version.updated_on.iso8601
      }
    end
  end
end