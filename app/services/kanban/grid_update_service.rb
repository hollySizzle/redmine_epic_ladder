# frozen_string_literal: true

module Kanban
  # GridUpdateService - リアルタイム更新サービス
  # 設計書仕様: マルチユーザー間のグリッド状態同期、差分更新配信
  class GridUpdateService
    attr_reader :project, :user, :since_timestamp

    def initialize(project, user, since_timestamp = nil)
      @project = project
      @user = user
      @since_timestamp = parse_timestamp(since_timestamp)
    end

    # 更新データ取得メイン処理
    def get_updates
      begin
        updates = {
          updates: collect_issue_updates,
          deleted_issues: collect_deleted_issues,
          grid_structure_changes: collect_structure_changes,
          version_updates: collect_version_updates,
          metadata_updates: collect_metadata_updates,
          has_more: false,
          next_timestamp: Time.current.iso8601
        }

        # データサイズ制限チェック
        if updates_too_large?(updates)
          updates[:has_more] = true
          updates = limit_updates_size(updates)
        end

        updates
      rescue => e
        Rails.logger.error "Grid update service error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        {
          updates: [],
          deleted_issues: [],
          grid_structure_changes: [],
          error: e.message,
          has_more: false,
          next_timestamp: Time.current.iso8601
        }
      end
    end

    # リアルタイム同期チェック
    def has_updates?
      return true unless @since_timestamp

      last_project_update = @project.updated_on
      last_issue_update = @project.issues.maximum(:updated_on)

      latest_update = [last_project_update, last_issue_update].compact.max

      latest_update > @since_timestamp
    end

    private

    # Issue更新収集
    def collect_issue_updates
      return [] unless @since_timestamp

      updated_issues = @project.issues
                              .includes(:tracker, :status, :assigned_to, :fixed_version, :parent)
                              .where('updated_on > ?', @since_timestamp)
                              .where(tracker: epic_and_feature_trackers)
                              .order(:updated_on)
                              .limit(100) # パフォーマンス制限

      updated_issues.map do |issue|
        build_issue_update(issue)
      end
    end

    # 削除Issue収集
    def collect_deleted_issues
      # Redmineは論理削除ではなく物理削除のため、
      # 別途削除ログシステムが必要（将来実装）
      # 現在は空配列を返す
      []
    end

    # グリッド構造変更収集
    def collect_structure_changes
      changes = []

      # Epic追加・削除・変更
      epic_changes = collect_epic_changes
      changes.concat(epic_changes)

      # Version追加・削除・変更
      version_changes = collect_version_structure_changes
      changes.concat(version_changes)

      changes
    end

    # Epic変更収集
    def collect_epic_changes
      return [] unless @since_timestamp

      updated_epics = @project.issues
                             .joins(:tracker)
                             .where(trackers: { name: 'Epic' })
                             .where('updated_on > ?', @since_timestamp)

      updated_epics.map do |epic|
        {
          type: 'epic_change',
          change_type: determine_epic_change_type(epic),
          epic: build_issue_summary(epic),
          affected_features: epic.children.where(tracker: feature_tracker).map { |f| build_issue_summary(f) },
          timestamp: epic.updated_on.iso8601
        }
      end
    end

    # Version構造変更収集
    def collect_version_structure_changes
      return [] unless @since_timestamp

      updated_versions = @project.versions
                                .where('updated_on > ?', @since_timestamp)

      updated_versions.map do |version|
        {
          type: 'version_change',
          change_type: determine_version_change_type(version),
          version: build_version_summary(version),
          affected_issues_count: version.issues.count,
          timestamp: version.updated_on.iso8601
        }
      end
    end

    # Version更新収集
    def collect_version_updates
      return [] unless @since_timestamp

      updated_versions = @project.versions
                                .where('updated_on > ?', @since_timestamp)
                                .order(:updated_on)

      updated_versions.map do |version|
        {
          id: version.id,
          name: version.name,
          description: version.description,
          status: version.status,
          effective_date: version.effective_date&.iso8601,
          issue_count: version.issues.count,
          updated_on: version.updated_on.iso8601,
          change_type: 'version_updated'
        }
      end
    end

    # メタデータ更新収集
    def collect_metadata_updates
      {
        project_last_updated: @project.updated_on.iso8601,
        total_issues_count: @project.issues.count,
        grid_cache_version: calculate_grid_cache_version,
        user_permissions: gather_current_user_permissions,
        last_sync_timestamp: Time.current.iso8601
      }
    end

    # Issue更新詳細構築
    def build_issue_update(issue)
      {
        issue: build_issue_detail(issue),
        update_type: determine_update_type(issue),
        grid_position: calculate_grid_position(issue),
        affected_cells: calculate_affected_cells(issue),
        propagation_effects: calculate_propagation_effects(issue),
        timestamp: issue.updated_on.iso8601
      }
    end

    def build_issue_detail(issue)
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
        estimated_hours: issue.estimated_hours,
        done_ratio: issue.done_ratio,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601
      }
    end

    def build_issue_summary(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name
      }
    end

    def build_version_summary(version)
      {
        id: version.id,
        name: version.name,
        status: version.status,
        effective_date: version.effective_date&.iso8601
      }
    end

    # 更新種別判定
    def determine_update_type(issue)
      # Issue作成からの経過時間で判定
      if issue.created_on == issue.updated_on
        'created'
      elsif issue.updated_on > 1.minute.ago
        'modified'
      else
        'updated'
      end
    end

    def determine_epic_change_type(epic)
      if epic.created_on == epic.updated_on
        'epic_created'
      else
        'epic_updated'
      end
    end

    def determine_version_change_type(version)
      if version.created_on == version.updated_on
        'version_created'
      else
        'version_updated'
      end
    end

    # グリッド位置計算
    def calculate_grid_position(issue)
      {
        epic_id: issue.parent_id || 'no-epic',
        version_id: issue.fixed_version_id || 'no-version',
        column: determine_kanban_column(issue)
      }
    end

    # 影響セル計算
    def calculate_affected_cells(issue)
      cells = []

      # 現在のセル
      current_cell = {
        epic_id: issue.parent_id || 'no-epic',
        version_id: issue.fixed_version_id || 'no-version',
        column: determine_kanban_column(issue),
        cell_type: 'current'
      }
      cells << current_cell

      # 移動前のセル（変更履歴から推測）
      if issue.parent_id_changed? || issue.fixed_version_id_changed?
        previous_cell = {
          epic_id: issue.parent_id_was || 'no-epic',
          version_id: issue.fixed_version_id_was || 'no-version',
          cell_type: 'previous'
        }
        cells << previous_cell
      end

      cells
    end

    # 伝播効果計算
    def calculate_propagation_effects(issue)
      effects = []

      # 子要素への影響
      if issue.tracker.name == 'Epic' && issue.fixed_version_id_changed?
        child_features = issue.children.where(tracker: feature_tracker)
        if child_features.any?
          effects << {
            type: 'version_propagation',
            affected_count: child_features.count,
            affected_issues: child_features.map { |f| build_issue_summary(f) }
          }
        end
      end

      # 統計情報への影響
      if issue.status_id_changed?
        effects << {
          type: 'statistics_update',
          affected_statistics: ['completion_rate', 'status_distribution']
        }
      end

      effects
    end

    # ヘルパーメソッド群

    def parse_timestamp(timestamp_string)
      return nil unless timestamp_string.present?

      begin
        Time.parse(timestamp_string)
      rescue ArgumentError
        Rails.logger.warn "Invalid timestamp format: #{timestamp_string}"
        nil
      end
    end

    def epic_and_feature_trackers
      Tracker.where(name: ['Epic', 'Feature'])
    end

    def feature_tracker
      Tracker.find_by(name: 'Feature')
    end

    def determine_kanban_column(issue)
      status_column_mapping = {
        'New' => 'backlog',
        'Open' => 'backlog',
        'Ready' => 'ready',
        'In Progress' => 'in_progress',
        'Assigned' => 'in_progress',
        'Review' => 'review',
        'Ready for Test' => 'review',
        'Testing' => 'testing',
        'QA' => 'testing',
        'Resolved' => 'done',
        'Closed' => 'done'
      }

      status_column_mapping[issue.status.name] || 'backlog'
    end

    def calculate_grid_cache_version
      latest_update = [@project.updated_on, @project.issues.maximum(:updated_on)].compact.max
      issue_count = @project.issues.count
      Digest::MD5.hexdigest("#{latest_update}-#{issue_count}")
    end

    def gather_current_user_permissions
      {
        view_issues: @user.allowed_to?(:view_issues, @project),
        edit_issues: @user.allowed_to?(:edit_issues, @project),
        add_issues: @user.allowed_to?(:add_issues, @project),
        delete_issues: @user.allowed_to?(:delete_issues, @project),
        manage_versions: @user.allowed_to?(:manage_versions, @project)
      }
    end

    # データサイズ制限
    def updates_too_large?(updates)
      # JSON文字列化してサイズチェック（概算）
      estimated_size = updates.to_json.bytesize
      estimated_size > 1.megabyte # 1MB制限
    end

    def limit_updates_size(updates)
      # 更新データを制限（最新のものを優先）
      limited_updates = updates.dup

      # Issue更新を最新50件に制限
      if limited_updates[:updates].length > 50
        limited_updates[:updates] = limited_updates[:updates].last(50)
        limited_updates[:has_more] = true
      end

      # 構造変更を最新20件に制限
      if limited_updates[:grid_structure_changes].length > 20
        limited_updates[:grid_structure_changes] = limited_updates[:grid_structure_changes].last(20)
        limited_updates[:has_more] = true
      end

      limited_updates
    end
  end
end