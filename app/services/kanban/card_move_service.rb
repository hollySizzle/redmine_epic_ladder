# frozen_string_literal: true

module Kanban
  # CardMoveService - D&Dカード移動処理サービス
  # 設計書仕様: Feature移動の制約検証、状態遷移、バージョン伝播処理
  class CardMoveService
    # 静的メソッドとしてのメインインターフェース
    def self.execute(card:, source_cell:, target_cell:, user:, project:)
      service = new(card, user)
      service.execute(source_cell, target_cell)
    end

    attr_reader :issue, :user, :move_constraints

    def initialize(issue, user)
      @issue = issue
      @user = user
      @move_constraints = build_move_constraints
    end

    # メインの移動実行メソッド（インスタンスメソッド）
    def execute(source_cell, target_cell)
      begin
        ActiveRecord::Base.transaction do
          # 1. 移動前検証
          validation_result = validate_move(source_cell, target_cell)
          return validation_result unless validation_result[:success]

          # 2. 移動種別判定と処理
          move_type = determine_move_type(source_cell, target_cell)
          move_result = execute_move_by_type(move_type, source_cell, target_cell)

          return move_result unless move_result[:success]

          # 3. 関連Issue更新（Version伝播等）
          propagation_result = handle_version_propagation(target_cell)
          return propagation_result unless propagation_result[:success]

          # 4. 統計情報更新
          statistics_update = update_grid_statistics(source_cell, target_cell)

          # 5. 成功レスポンス構築
          {
            success: true,
            issue: @issue.reload,
            move_type: move_type,
            affected_cells: build_affected_cells(source_cell, target_cell),
            propagation_results: propagation_result[:results],
            statistics_update: statistics_update,
            timestamp: Time.current.iso8601
          }
        end
      rescue => e
        Rails.logger.error "Card move service error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        {
          success: false,
          error: "移動処理中にエラーが発生しました: #{e.message}",
          timestamp: Time.current.iso8601
        }
      end
    end

    private

    # 移動前検証
    def validate_move(source_cell, target_cell)
      # 基本検証
      if source_cell.nil? || target_cell.nil?
        return {
          success: false,
          error: '移動元または移動先のセル情報が不正です',
          constraints_violated: ['invalid_cell_coordinates']
        }
      end

      # 権限検証
      unless @user.allowed_to?(:edit_issues, @issue.project)
        return {
          success: false,
          error: 'Issue編集権限がありません',
          constraints_violated: ['insufficient_permissions']
        }
      end

      # 移動制約検証
      constraints_result = validate_move_constraints(source_cell, target_cell)
      return constraints_result unless constraints_result[:success]

      # Workflow遷移制約検証
      workflow_result = validate_workflow_transitions(target_cell)
      return workflow_result unless workflow_result[:success]

      { success: true }
    end

    # 移動制約検証
    def validate_move_constraints(source_cell, target_cell)
      violated_constraints = []

      # Epic変更制約
      if source_cell[:epic_id] != target_cell[:epic_id]
        unless @move_constraints[:epic_change_allowed]
          violated_constraints << 'epic_change_not_allowed'
        end
      end

      # Version変更制約
      if source_cell[:version_id] != target_cell[:version_id]
        unless @move_constraints[:version_change_allowed]
          violated_constraints << 'version_change_not_allowed'
        end
      end

      # セル内最大Feature数制約
      if @move_constraints[:max_features_per_cell]
        target_feature_count = count_features_in_cell(target_cell)
        if target_feature_count >= @move_constraints[:max_features_per_cell]
          violated_constraints << 'max_features_per_cell_exceeded'
        end
      end

      if violated_constraints.any?
        return {
          success: false,
          error: '移動制約に違反しています',
          constraints_violated: violated_constraints
        }
      end

      { success: true }
    end

    # Workflow遷移制約検証
    def validate_workflow_transitions(target_cell)
      # ステータス遷移が必要な場合の検証
      target_status = determine_target_status(target_cell)

      if target_status && target_status != @issue.status
        available_statuses = @issue.new_statuses_allowed_to(@user)

        unless available_statuses.include?(target_status)
          return {
            success: false,
            error: "ステータス '#{target_status.name}' への遷移は許可されていません",
            constraints_violated: ['workflow_transition_not_allowed'],
            available_statuses: available_statuses.map(&:name)
          }
        end
      end

      { success: true }
    end

    # 移動種別判定
    def determine_move_type(source_cell, target_cell)
      changes = []

      if source_cell[:epic_id] != target_cell[:epic_id]
        changes << 'epic_change'
      end

      if source_cell[:version_id] != target_cell[:version_id]
        changes << 'version_change'
      end

      if source_cell[:column_id] != target_cell[:column_id]
        changes << 'status_change'
      end

      case changes.length
      when 0
        'no_change'
      when 1
        changes.first
      else
        'multiple_changes'
      end
    end

    # 移動種別に応じた処理実行
    def execute_move_by_type(move_type, source_cell, target_cell)
      case move_type
      when 'no_change'
        { success: true, changes: [] }
      when 'epic_change'
        execute_epic_change(target_cell)
      when 'version_change'
        execute_version_change(target_cell)
      when 'status_change'
        execute_status_change(target_cell)
      when 'multiple_changes'
        execute_multiple_changes(target_cell)
      else
        {
          success: false,
          error: "未知の移動種別: #{move_type}"
        }
      end
    end

    # Epic変更処理
    def execute_epic_change(target_cell)
      new_parent_id = target_cell[:epic_id]

      @issue.parent_id = new_parent_id

      if @issue.save
        {
          success: true,
          changes: [{
            field: 'parent_id',
            old_value: @issue.parent_id_was,
            new_value: new_parent_id
          }]
        }
      else
        {
          success: false,
          error: @issue.errors.full_messages.join(', ')
        }
      end
    end

    # Version変更処理
    def execute_version_change(target_cell)
      new_version_id = target_cell[:version_id]

      @issue.fixed_version_id = new_version_id

      if @issue.save
        {
          success: true,
          changes: [{
            field: 'fixed_version_id',
            old_value: @issue.fixed_version_id_was,
            new_value: new_version_id
          }]
        }
      else
        {
          success: false,
          error: @issue.errors.full_messages.join(', ')
        }
      end
    end

    # ステータス変更処理
    def execute_status_change(target_cell)
      target_status = determine_target_status(target_cell)

      if target_status
        old_status_id = @issue.status_id
        @issue.status = target_status

        if @issue.save
          {
            success: true,
            changes: [{
              field: 'status_id',
              old_value: old_status_id,
              new_value: target_status.id
            }]
          }
        else
          {
            success: false,
            error: @issue.errors.full_messages.join(', ')
          }
        end
      else
        { success: true, changes: [] }
      end
    end

    # 複数変更処理
    def execute_multiple_changes(target_cell)
      changes = []

      # Epic変更
      if target_cell[:epic_id] != @issue.parent_id
        old_parent_id = @issue.parent_id
        @issue.parent_id = target_cell[:epic_id]
        changes << {
          field: 'parent_id',
          old_value: old_parent_id,
          new_value: target_cell[:epic_id]
        }
      end

      # Version変更
      if target_cell[:version_id] != @issue.fixed_version_id
        old_version_id = @issue.fixed_version_id
        @issue.fixed_version_id = target_cell[:version_id]
        changes << {
          field: 'fixed_version_id',
          old_value: old_version_id,
          new_value: target_cell[:version_id]
        }
      end

      # ステータス変更
      target_status = determine_target_status(target_cell)
      if target_status && target_status != @issue.status
        old_status_id = @issue.status_id
        @issue.status = target_status
        changes << {
          field: 'status_id',
          old_value: old_status_id,
          new_value: target_status.id
        }
      end

      if @issue.save
        {
          success: true,
          changes: changes
        }
      else
        {
          success: false,
          error: @issue.errors.full_messages.join(', ')
        }
      end
    end

    # バージョン自動伝播処理
    def handle_version_propagation(target_cell)
      if target_cell[:version_id] && target_cell[:version_id] != @issue.fixed_version_id_was
        version = Version.find(target_cell[:version_id]) if target_cell[:version_id]
        result = Kanban::VersionPropagationService.propagate_to_children(@issue, version)

        if result[:success]
          {
            success: true,
            results: result
          }
        else
          {
            success: false,
            error: result[:error],
            details: result
          }
        end
      else
        {
          success: true,
          results: { propagated_issues: [] }
        }
      end
    end

    # グリッド統計情報更新
    def update_grid_statistics(source_cell, target_cell)
      {
        source_cell_update: calculate_cell_statistics(source_cell),
        target_cell_update: calculate_cell_statistics(target_cell),
        overall_statistics: calculate_overall_statistics
      }
    end

    # セル統計計算
    def calculate_cell_statistics(cell)
      features_in_cell = count_features_in_cell(cell)
      completed_features = count_completed_features_in_cell(cell)

      {
        total_features: features_in_cell,
        completed_features: completed_features,
        completion_rate: features_in_cell > 0 ? (completed_features.to_f / features_in_cell * 100).round(2) : 0
      }
    end

    # 全体統計計算
    def calculate_overall_statistics
      project = @issue.project
      {
        total_issues: project.issues.count,
        updated_at: Time.current.iso8601
      }
    end

    # ヘルパーメソッド群

    def build_move_constraints
      {
        epic_change_allowed: @user.allowed_to?(:edit_issues, @issue.project),
        version_change_allowed: @user.allowed_to?(:manage_versions, @issue.project),
        required_permissions: ['edit_issues'],
        max_features_per_cell: 50 # 設定可能値
      }
    end

    def count_features_in_cell(cell)
      query = @issue.project.issues.joins(:tracker).where(trackers: { name: 'Feature' })

      if cell[:epic_id]
        query = query.where(parent_id: cell[:epic_id])
      else
        query = query.where(parent_id: nil)
      end

      if cell[:version_id]
        query = query.where(fixed_version_id: cell[:version_id])
      else
        query = query.where(fixed_version_id: nil)
      end

      query.count
    end

    def count_completed_features_in_cell(cell)
      query = @issue.project.issues.joins(:tracker, :status)
                   .where(trackers: { name: 'Feature' })
                   .where(issue_statuses: { name: ['Resolved', 'Closed'] })

      if cell[:epic_id]
        query = query.where(parent_id: cell[:epic_id])
      else
        query = query.where(parent_id: nil)
      end

      if cell[:version_id]
        query = query.where(fixed_version_id: cell[:version_id])
      else
        query = query.where(fixed_version_id: nil)
      end

      query.count
    end

    def determine_target_status(target_cell)
      # カラムIDに基づいてステータスを決定
      column_status_mapping = {
        'backlog' => 'New',
        'ready' => 'Ready',
        'in_progress' => 'In Progress',
        'review' => 'Review',
        'testing' => 'Testing',
        'done' => 'Resolved'
      }

      target_status_name = column_status_mapping[target_cell[:column_id]]
      return nil unless target_status_name

      IssueStatus.find_by(name: target_status_name)
    end

    def build_affected_cells(source_cell, target_cell)
      [
        {
          cell_coordinates: source_cell,
          cell_type: 'source',
          statistics: calculate_cell_statistics(source_cell)
        },
        {
          cell_coordinates: target_cell,
          cell_type: 'target',
          statistics: calculate_cell_statistics(target_cell)
        }
      ]
    end
  end
end