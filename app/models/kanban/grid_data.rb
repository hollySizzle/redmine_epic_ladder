# frozen_string_literal: true

module Kanban
  # GridData - 設計書準拠のグリッドデータ構造
  # 設計書仕様: 2次元マトリクス構造のデータモデル
  class GridData
    include ActiveModel::Model
    include ActiveModel::Serializers::JSON

    attr_accessor :project, :versions, :epics, :orphan_features, :metadata

    def initialize(attributes = {})
      super
      @project ||= {}
      @versions ||= []
      @epics ||= []
      @orphan_features ||= []
      @metadata ||= {}
    end

    def attributes
      {
        'project' => @project,
        'versions' => @versions,
        'epics' => @epics,
        'orphan_features' => @orphan_features,
        'metadata' => @metadata
      }
    end

    def to_hash
      {
        grid: {
          rows: epic_rows,
          columns: version_columns,
          versions: versions
        },
        orphan_features: orphan_features,
        metadata: metadata,
        statistics: calculate_statistics
      }
    end

    def to_json(options = {})
      to_hash.to_json(options)
    end

    private

    def epic_rows
      epics.map { |epic| EpicRow.new(epic).to_hash }
    end

    def version_columns
      versions.map { |version| VersionColumn.new(version).to_hash }
    end

    def calculate_statistics
      {
        total_epics: epics.length,
        total_features: total_features_count,
        total_versions: versions.length,
        completion_rate: overall_completion_rate
      }
    end

    def total_features_count
      epic_features = epics.sum { |epic| epic[:features]&.length || 0 }
      orphan_features.length + epic_features
    end

    def overall_completion_rate
      total_features = total_features_count
      return 0 if total_features == 0

      completed_count = count_completed_features
      ((completed_count.to_f / total_features) * 100).round(2)
    end

    def count_completed_features
      epic_completed = epics.sum do |epic|
        features = epic[:features] || []
        features.count { |f| ['Resolved', 'Closed'].include?(f[:issue][:status]) }
      end

      orphan_completed = orphan_features.count do |f|
        ['Resolved', 'Closed'].include?(f[:issue][:status])
      end

      epic_completed + orphan_completed
    end
  end

  # EpicRow - Epic行データ構造
  class EpicRow
    include ActiveModel::Model

    attr_accessor :issue, :features, :statistics, :ui_state

    def initialize(epic_data)
      @issue = epic_data[:issue] || {}
      @features = epic_data[:features] || []
      @statistics = epic_data[:statistics] || {}
      @ui_state = epic_data[:ui_state] || { expanded: true }
    end

    def to_hash
      {
        issue: issue,
        features: features,
        statistics: statistics,
        ui_state: ui_state
      }
    end
  end

  # VersionColumn - Version列データ構造
  class VersionColumn
    include ActiveModel::Model

    attr_accessor :id, :name, :description, :effective_date, :status, :issue_count

    def initialize(version_data)
      @id = version_data[:id]
      @name = version_data[:name]
      @description = version_data[:description]
      @effective_date = version_data[:effective_date]
      @status = version_data[:status]
      @issue_count = version_data[:issue_count] || 0
    end

    def to_hash
      {
        id: id,
        name: name,
        description: description,
        effective_date: effective_date,
        status: status,
        issue_count: issue_count,
        type: 'version'
      }
    end
  end

  # GridCell - 個別セルデータ構造
  class GridCell
    include ActiveModel::Model

    attr_accessor :coordinates, :features, :statistics, :drop_allowed, :cell_type

    def initialize(cell_data)
      @coordinates = CellCoordinate.new(cell_data[:coordinates] || {})
      @features = cell_data[:features] || []
      @statistics = CellStatistics.new(cell_data[:statistics] || {})
      @drop_allowed = cell_data[:drop_allowed] || true
      @cell_type = cell_data[:cell_type] || 'epic-version'
    end

    def to_hash
      {
        coordinates: coordinates.to_hash,
        features: features,
        statistics: statistics.to_hash,
        drop_allowed: drop_allowed,
        cell_type: cell_type
      }
    end
  end

  # CellCoordinate - セル座標データ構造
  class CellCoordinate
    include ActiveModel::Model

    attr_accessor :epic_id, :version_id, :column_id

    def initialize(coord_data)
      @epic_id = coord_data[:epic_id]
      @version_id = coord_data[:version_id]
      @column_id = coord_data[:column_id]
    end

    def to_hash
      {
        epic_id: epic_id,
        version_id: version_id,
        column_id: column_id
      }
    end

    def ==(other)
      other.is_a?(CellCoordinate) &&
        epic_id == other.epic_id &&
        version_id == other.version_id &&
        column_id == other.column_id
    end
  end

  # CellStatistics - セル統計データ構造
  class CellStatistics
    include ActiveModel::Model

    attr_accessor :total_features, :completed_features, :completion_rate

    def initialize(stats_data)
      @total_features = stats_data[:total_features] || 0
      @completed_features = stats_data[:completed_features] || 0
      @completion_rate = stats_data[:completion_rate] || 0.0
    end

    def to_hash
      {
        total_features: total_features,
        completed_features: completed_features,
        completion_rate: completion_rate
      }
    end

    def update_statistics(features)
      @total_features = features.length
      @completed_features = features.count { |f|
        ['Resolved', 'Closed'].include?(f[:issue][:status])
      }
      @completion_rate = total_features > 0 ?
        ((completed_features.to_f / total_features) * 100).round(2) : 0.0
    end
  end

  # GridMetadata - グリッドメタデータ構造
  class GridMetadata
    include ActiveModel::Model

    attr_accessor :project, :total_epics, :total_features, :total_versions,
                  :matrix_dimensions, :user_permissions, :last_updated

    def initialize(metadata = {})
      @project = metadata[:project] || {}
      @total_epics = metadata[:total_epics] || 0
      @total_features = metadata[:total_features] || 0
      @total_versions = metadata[:total_versions] || 0
      @matrix_dimensions = MatrixDimensions.new(metadata[:matrix_dimensions] || {})
      @user_permissions = metadata[:user_permissions] || {}
      @last_updated = metadata[:last_updated] || Time.current.iso8601
    end

    def to_hash
      {
        project: project,
        total_epics: total_epics,
        total_features: total_features,
        total_versions: total_versions,
        matrix_dimensions: matrix_dimensions.to_hash,
        user_permissions: user_permissions,
        last_updated: last_updated
      }
    end
  end

  # MatrixDimensions - マトリクス次元情報
  class MatrixDimensions
    include ActiveModel::Model

    attr_accessor :rows, :columns

    def initialize(dimensions_data)
      @rows = dimensions_data[:rows] || 0
      @columns = dimensions_data[:columns] || 0
    end

    def to_hash
      {
        rows: rows,
        columns: columns
      }
    end

    def total_cells
      rows * columns
    end
  end

  # DropConstraintConfig - ドロップ制約設定
  class DropConstraintConfig
    include ActiveModel::Model

    attr_accessor :epic_change_allowed, :version_change_allowed,
                  :required_permissions, :max_features_per_cell

    def initialize(constraints = {})
      @epic_change_allowed = constraints[:epic_change_allowed] || true
      @version_change_allowed = constraints[:version_change_allowed] || true
      @required_permissions = constraints[:required_permissions] || ['edit_issues']
      @max_features_per_cell = constraints[:max_features_per_cell]
    end

    def to_hash
      {
        epic_change_allowed: epic_change_allowed,
        version_change_allowed: version_change_allowed,
        required_permissions: required_permissions,
        max_features_per_cell: max_features_per_cell
      }
    end

    def validate_move(source_cell, target_cell)
      violations = []

      if source_cell.epic_id != target_cell.epic_id && !epic_change_allowed
        violations << 'epic_change_not_allowed'
      end

      if source_cell.version_id != target_cell.version_id && !version_change_allowed
        violations << 'version_change_not_allowed'
      end

      violations
    end
  end

  # GridError - グリッド固有エラー構造
  class GridError
    include ActiveModel::Model

    attr_accessor :type, :message, :details, :timestamp

    def initialize(error_data)
      @type = error_data[:type] || 'unknown'
      @message = error_data[:message] || 'An error occurred'
      @details = error_data[:details] || {}
      @timestamp = error_data[:timestamp] || Time.current.iso8601
    end

    def to_hash
      {
        type: type,
        message: message,
        details: details,
        timestamp: timestamp
      }
    end
  end
end