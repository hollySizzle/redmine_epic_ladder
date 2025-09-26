# Kanban Grid サーバーサイド実装仕様

## 概要
Kanban Gridレイアウト用サーバーサイド実装。2次元グリッド（Epic行×Version列）データ構築、ドラッグ&ドロップ処理、バージョン管理、リアルタイム更新。

## コントローラー実装

### Grid専用コントローラー
```ruby
# app/controllers/kanban/grid_controller.rb
module Kanban
  class GridController < ApplicationController
    include KanbanApiConcern

    def index
      @grid_data = KanbanGridBuilder.new(@project, current_user, grid_params).build

      render json: {
        grid: @grid_data[:grid],
        metadata: @grid_data[:metadata],
        statistics: @grid_data[:statistics]
      }
    end

    def move_card
      result = CardMoveService.new(
        current_user,
        params[:card_id],
        params[:source_cell],
        params[:target_cell]
      ).execute

      if result.success?
        render json: {
          updated_card: serialize_issue(result.updated_card),
          affected_cells: result.affected_cells,
          statistics_update: result.statistics_delta
        }
      else
        render json: {
          error: result.error_message,
          validation_errors: result.validation_errors
        }, status: :unprocessable_entity
      end
    end

    def update_version_assignment
      version = @project.versions.find(params[:version_id])
      issues = Issue.where(id: params[:issue_ids])

      result = VersionAssignmentService.new(current_user, issues, version).execute

      if result.success?
        render json: {
          updated_issues: result.updated_issues.map { |issue| serialize_issue(issue) },
          grid_updates: calculate_grid_updates(result.updated_issues),
          statistics: result.statistics
        }
      else
        render json: {
          error: result.error_message,
          failed_assignments: result.failed_assignments
        }, status: :unprocessable_entity
      end
    end

    def column_configuration
      render json: {
        columns: KanbanColumnConfig.for_project(@project),
        status_mappings: StatusColumnMapping.for_project(@project),
        workflow_constraints: WorkflowConstraintChecker.for_project(@project)
      }
    end

    def real_time_updates
      last_update = Time.zone.parse(params[:since]) if params[:since].present?
      updates = GridUpdateService.get_updates_since(@project, last_update)

      render json: {
        updates: updates,
        current_timestamp: Time.zone.now.iso8601
      }
    end

    private

    def grid_params
      params.permit(:version_filter, :assignee_filter, :status_filter, :tracker_filter, :epic_filter)
    end

    def calculate_grid_updates(updated_issues)
      updated_issues.map do |issue|
        epic = issue.root
        version = issue.fixed_version

        {
          epic_id: epic.id,
          version_id: version&.id,
          cell_position: { row: epic.id, column: version&.id },
          issue_updates: serialize_issue(issue)
        }
      end
    end
  end
end
```

### Version管理コントローラー
```ruby
# app/controllers/kanban/versions_controller.rb
module Kanban
  class VersionsController < ApplicationController
    include KanbanApiConcern

    def index
      @versions = @project.versions
                          .includes(:issues)
                          .order(:effective_date, :name)

      render json: {
        versions: @versions.map { |v| serialize_version(v) },
        version_statistics: calculate_version_statistics
      }
    end

    def create
      @version = @project.versions.build(version_params)

      if @version.save
        render json: {
          version: serialize_version(@version),
          grid_column_added: {
            column_id: @version.id,
            column_data: build_version_column_data(@version)
          }
        }, status: :created
      else
        render json: {
          error: 'バージョン作成に失敗しました',
          validation_errors: @version.errors
        }, status: :unprocessable_entity
      end
    end

    def update
      @version = @project.versions.find(params[:id])

      if @version.update(version_params)
        grid_updates = calculate_version_update_impact(@version)

        render json: {
          version: serialize_version(@version),
          grid_updates: grid_updates
        }
      else
        render json: {
          error: 'バージョン更新に失敗しました',
          validation_errors: @version.errors
        }, status: :unprocessable_entity
      end
    end

    def bulk_assign_issues
      @version = @project.versions.find(params[:id])
      issue_ids = params[:issue_ids]

      result = BulkVersionAssignmentService.new(current_user, @version, issue_ids).execute

      if result.success?
        render json: {
          assigned_issues: result.assigned_issues.map { |issue| serialize_issue(issue) },
          grid_updates: result.grid_updates,
          statistics: result.statistics
        }
      else
        render json: {
          error: result.error_message,
          failed_assignments: result.failed_assignments
        }, status: :unprocessable_entity
      end
    end

    private

    def version_params
      params.require(:version).permit(:name, :description, :effective_date, :status)
    end

    def serialize_version(version)
      {
        id: version.id,
        name: version.name,
        description: version.description,
        effective_date: version.effective_date,
        status: version.status,
        issue_count: version.issues.count,
        completion_ratio: calculate_version_completion_ratio(version),
        can_edit: User.current.allowed_to?(:manage_versions, @project)
      }
    end

    def calculate_version_update_impact(version)
      affected_issues = version.issues.includes(:tracker, :status, :parent)

      affected_issues.group_by(&:root).map do |epic, issues|
        {
          epic_id: epic.id,
          version_id: version.id,
          updated_issues: issues.map { |issue| serialize_issue(issue) }
        }
      end
    end
  end
end
```

## サービスクラス実装

### Kanban Grid データビルダー
```ruby
# app/services/kanban/grid_data_builder.rb
module Kanban
  class GridDataBuilder
    def initialize(project, user, filters = {})
      @project = project
      @user = user
      @filters = filters
    end

    def build
      {
        grid: build_grid_structure,
        metadata: build_metadata,
        statistics: build_statistics
      }
    end

    private

    def build_grid_structure
      epics = load_filtered_epics
      versions = load_project_versions
      columns = KanbanColumnConfig.for_project(@project)

      {
        rows: epics.map { |epic| build_epic_row(epic, versions, columns) },
        columns: columns,
        versions: versions.map { |v| serialize_version(v) }
      }
    end

    def build_epic_row(epic, versions, columns)
      {
        epic: serialize_issue(epic),
        cells: versions.map { |version| build_grid_cell(epic, version, columns) }
      }
    end

    def build_grid_cell(epic, version, columns)
      # この Epic × Version の組み合わせにある Feature を取得
      features = epic.children
                    .select { |child| child.tracker.name == 'Feature' }
                    .select { |feature| version_matches?(feature, version) }

      {
        epic_id: epic.id,
        version_id: version.id,
        position: { row: epic.id, column: version.id },
        features: features.map { |feature| build_feature_cell_data(feature, columns) },
        statistics: calculate_cell_statistics(features),
        drop_zone_config: {
          accepts: calculate_accepted_trackers,
          drop_constraints: calculate_drop_constraints(epic, version)
        }
      }
    end

    def build_feature_cell_data(feature, columns)
      current_column = determine_feature_column(feature, columns)

      {
        feature: serialize_issue(feature),
        current_column: current_column,
        user_stories_count: feature.children.count { |child| child.tracker.name == 'UserStory' },
        completion_ratio: calculate_feature_completion_ratio(feature),
        visual_indicators: {
          status_color: feature.status.color || current_column[:color],
          priority_marker: feature.priority&.name,
          blocking_indicator: feature.relations_to.where(relation_type: 'blocks').exists?
        },
        drag_config: {
          draggable: can_drag_feature?(feature),
          drag_constraints: calculate_drag_constraints(feature)
        }
      }
    end

    def load_filtered_epics
      scope = @project.issues
                     .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                     .joins(:tracker)
                     .where(trackers: { name: 'Epic' })

      scope = apply_epic_filters(scope)
      scope.order(:id)
    end

    def apply_epic_filters(scope)
      if @filters[:epic_filter].present?
        scope = scope.where(id: @filters[:epic_filter])
      end

      if @filters[:assignee_filter].present?
        scope = scope.where(assigned_to_id: @filters[:assignee_filter])
      end

      scope
    end

    def load_project_versions
      @project.versions
              .where(status: 'open')
              .order(:effective_date, :name)
    end

    def version_matches?(feature, version)
      # Feature またはその UserStory が指定バージョンに割り当てられている
      return true if feature.fixed_version == version

      # 子の UserStory のいずれかが指定バージョンに割り当てられている
      feature.children.any? { |child| child.fixed_version == version }
    end

    def determine_feature_column(feature, columns)
      status_name = feature.status.name
      columns.find { |col| col[:statuses].include?(status_name) } || columns.first
    end

    def calculate_cell_statistics(features)
      {
        feature_count: features.size,
        completed_features: features.count(&:closed?),
        total_user_stories: features.sum { |f| f.children.count { |c| c.tracker.name == 'UserStory' } },
        completed_user_stories: features.sum { |f| f.children.count { |c| c.tracker.name == 'UserStory' && c.closed? } }
      }
    end

    def build_metadata
      {
        project: serialize_project_metadata,
        user_permissions: calculate_user_permissions,
        grid_configuration: {
          column_definitions: KanbanColumnConfig.for_project(@project),
          tracker_hierarchy: TrackerHierarchy.for_project(@project),
          workflow_rules: WorkflowRules.for_project(@project)
        },
        real_time_config: {
          polling_interval: 30000, # 30秒
          last_update: Time.zone.now.iso8601
        }
      }
    end

    def build_statistics
      all_epics = @project.issues.joins(:tracker).where(trackers: { name: 'Epic' })
      all_features = @project.issues.joins(:tracker).where(trackers: { name: 'Feature' })

      {
        overview: {
          total_epics: all_epics.count,
          total_features: all_features.count,
          completion_ratio: calculate_project_completion_ratio
        },
        by_version: calculate_version_statistics,
        by_status: calculate_status_distribution
      }
    end
  end
end
```

### カード移動処理サービス
```ruby
# app/services/kanban/card_move_service.rb
module Kanban
  class CardMoveService
    def initialize(user, card_id, source_cell, target_cell)
      @user = user
      @card_id = card_id
      @source_cell = source_cell
      @target_cell = target_cell
      @result = MoveResult.new
    end

    def execute
      validate_move_permissions!
      @card = find_card

      perform_move
      update_related_issues if @result.success?
      log_move_action if @result.success?

      @result
    end

    private

    def validate_move_permissions!
      unless @user.allowed_to?(:edit_issues, @card&.project)
        @result.add_error("移動権限がありません")
      end
    end

    def find_card
      Issue.joins(:tracker)
           .where(id: @card_id, trackers: { name: %w[Epic Feature UserStory Task Test Bug] })
           .first!
    end

    def perform_move
      case determine_move_type
      when :column_move
        perform_column_move
      when :version_move
        perform_version_move
      when :epic_assignment
        perform_epic_assignment
      else
        @result.add_error("不正な移動操作です")
      end
    end

    def determine_move_type
      if @source_cell[:epic_id] == @target_cell[:epic_id] &&
         @source_cell[:version_id] == @target_cell[:version_id]
        :column_move
      elsif @source_cell[:epic_id] == @target_cell[:epic_id]
        :version_move
      elsif @source_cell[:version_id] == @target_cell[:version_id]
        :epic_assignment
      else
        :complex_move
      end
    end

    def perform_column_move
      target_column = @target_cell[:column_id]
      status_mapping = StatusColumnMapping.for_project(@card.project)

      target_statuses = status_mapping.statuses_for_column_and_tracker(target_column, @card.tracker.name)

      if target_statuses.any?
        new_status = determine_best_status(target_statuses)

        if can_transition_to_status?(@card, new_status)
          @card.update!(status: new_status)
          @result.add_success(@card)
        else
          @result.add_error("ステータス '#{new_status.name}' への遷移はできません")
        end
      else
        @result.add_error("対象列に移動可能なステータスがありません")
      end
    end

    def perform_version_move
      target_version = Version.find(@target_cell[:version_id])

      if can_assign_version?(@card, target_version)
        @card.update!(fixed_version: target_version)
        @result.add_success(@card)
        @result.affected_cells << {
          epic_id: @target_cell[:epic_id],
          version_id: @target_cell[:version_id]
        }
      else
        @result.add_error("バージョン '#{target_version.name}' を割り当てできません")
      end
    end

    def update_related_issues
      # 移動したカードの関連Issue（子、親、関連）を更新
      propagate_version_to_children if version_changed?
      update_parent_status_if_needed if status_changed?
    end

    def propagate_version_to_children
      @card.children.each do |child|
        if should_propagate_version_to_child?(child)
          child.update(fixed_version: @card.fixed_version)
          @result.add_affected_issue(child)
        end
      end
    end
  end

  class MoveResult
    attr_reader :updated_card, :affected_issues, :affected_cells, :error_message

    def initialize
      @updated_card = nil
      @affected_issues = []
      @affected_cells = []
      @errors = []
    end

    def add_success(card)
      @updated_card = card
    end

    def add_affected_issue(issue)
      @affected_issues << issue
    end

    def add_error(message)
      @errors << message
    end

    def success?
      @errors.empty? && @updated_card.present?
    end

    def error_message
      @errors.first
    end

    def statistics_delta
      {
        moved_cards: @affected_issues.size + 1,
        affected_cells: @affected_cells.size
      }
    end
  end
end
```

## ルーティング設定

```ruby
# config/routes.rb
scope 'kanban/projects/:project_id' do
  get 'grid', to: 'kanban/grid#index'
  post 'grid/move_card', to: 'kanban/grid#move_card'
  patch 'grid/version_assignment', to: 'kanban/grid#update_version_assignment'
  get 'grid/column_config', to: 'kanban/grid#column_configuration'
  get 'grid/updates', to: 'kanban/grid#real_time_updates'

  resources :versions, only: [:index, :create, :update], controller: 'kanban/versions' do
    member do
      post :bulk_assign_issues
    end
  end
end
```

## リアルタイム更新機能

```ruby
# app/services/kanban/grid_update_service.rb
module Kanban
  class GridUpdateService
    def self.get_updates_since(project, since_time)
      since_time ||= 1.hour.ago

      updated_issues = Issue.where(project: project)
                           .where('updated_on > ?', since_time)
                           .includes(:tracker, :status, :fixed_version, :parent)

      {
        issue_updates: updated_issues.map { |issue| serialize_issue_update(issue) },
        deleted_issues: find_deleted_issues(project, since_time),
        grid_structure_changes: detect_grid_structure_changes(project, since_time)
      }
    end

    private

    def self.serialize_issue_update(issue)
      epic = issue.root
      {
        issue_id: issue.id,
        epic_id: epic.id,
        version_id: issue.fixed_version&.id,
        cell_position: { row: epic.id, column: issue.fixed_version&.id },
        updated_data: serialize_issue(issue),
        update_type: determine_update_type(issue)
      }
    end

    def self.determine_update_type(issue)
      if issue.previous_changes.key?('fixed_version_id')
        'version_changed'
      elsif issue.previous_changes.key?('status_id')
        'status_changed'
      elsif issue.previous_changes.key?('parent_id')
        'hierarchy_changed'
      else
        'general_update'
      end
    end
  end
end
```

## テスト実装

```ruby
# spec/controllers/kanban/grid_controller_spec.rb
RSpec.describe Kanban::GridController do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_kanban_permissions, project: project) }
  let(:epic) { create(:epic_issue, project: project) }
  let(:feature) { create(:feature_issue, project: project, parent: epic) }
  let(:version) { create(:version, project: project) }

  before { User.current = user }

  describe 'GET index' do
    it 'Grid構造データを返す' do
      get :index, params: { project_id: project.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['grid']).to include('rows', 'columns', 'versions')
      expect(json['metadata']).to include('project', 'user_permissions')
    end
  end

  describe 'POST move_card' do
    it 'Feature カードを移動する' do
      post :move_card, params: {
        project_id: project.id,
        card_id: feature.id,
        source_cell: { epic_id: epic.id, version_id: nil, column_id: 'todo' },
        target_cell: { epic_id: epic.id, version_id: nil, column_id: 'in_progress' }
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['updated_card']).to be_present
    end
  end

  describe 'PATCH update_version_assignment' do
    it '複数Issueにバージョンを一括割り当て' do
      patch :update_version_assignment, params: {
        project_id: project.id,
        version_id: version.id,
        issue_ids: [feature.id]
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['updated_issues']).to be_present
      expect(json['grid_updates']).to be_present
    end
  end
end
```

---

*Kanban Gridレイアウト用サーバーサイド実装。2D グリッド構造、D&D処理、バージョン管理、リアルタイム更新*