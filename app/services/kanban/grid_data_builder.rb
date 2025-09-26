# frozen_string_literal: true

module Kanban
  # GridDataBuilder - 2次元グリッドマトリクス構築サービス
  # 設計書仕様: Epic行 × Version列の2次元構造を効率的に構築
  class GridDataBuilder
    attr_reader :project, :user, :filters

    def initialize(project, user, filters = {})
      @project = project
      @user = user
      @filters = filters
      @cache_key = generate_cache_key
    end

    # メインの構築メソッド - キャッシュ戦略適用
    def build
      Rails.cache.fetch(@cache_key, expires_in: 5.minutes) do
        build_grid_structure
      end
    end

    private

    def generate_cache_key
      filter_hash = Digest::MD5.hexdigest(@filters.to_json)
      "kanban_grid:#{@project.id}:#{@user.id}:#{filter_hash}:#{@project.updated_on.to_i}"
    end

    def build_grid_structure
      {
        grid: {
          rows: build_epic_rows,
          columns: build_version_columns,
          versions: load_project_versions
        },
        metadata: build_grid_metadata,
        statistics: build_grid_statistics
      }
    end

    # Epic行構築 - N+1クエリ回避
    def build_epic_rows
      epics = load_filtered_epics

      rows = epics.map { |epic| build_epic_row(epic) }

      # No Epic行を追加
      rows << build_no_epic_row

      rows
    end

    def load_filtered_epics
      query = @project.issues
                     .includes(:tracker, :status, :fixed_version, :assigned_to)
                     .joins(:tracker)
                     .where(trackers: { name: 'Epic' })

      # フィルタ適用
      query = apply_filters(query) if @filters.present?

      query.order(:created_on)
    end

    def apply_filters(query)
      if @filters[:assignee_id].present?
        query = query.where(assigned_to_id: @filters[:assignee_id])
      end

      if @filters[:status_ids].present?
        query = query.where(status_id: @filters[:status_ids])
      end

      if @filters[:version_ids].present?
        query = query.where(fixed_version_id: @filters[:version_ids])
      end

      if @filters[:search].present?
        search_term = "%#{@filters[:search]}%"
        query = query.where('subject LIKE ? OR description LIKE ?', search_term, search_term)
      end

      query
    end

    def build_epic_row(epic)
      # Load features efficiently using parent_id query
      features = @project.issues
                         .includes(:tracker, :status, :fixed_version, :assigned_to)
                         .joins(:tracker)
                         .where(trackers: { name: 'Feature' })
                         .where(parent_id: epic.id)

      {
        issue: build_issue_json(epic),
        features: features.map { |feature| build_feature_json(feature) },
        statistics: build_epic_statistics(epic, features),
        ui_state: { expanded: true }
      }
    end

    def build_no_epic_row
      orphan_features = load_orphan_features

      {
        issue: {
          id: 'no-epic',
          subject: 'No EPIC',
          tracker: 'No Epic',
          status: 'N/A',
          type: 'no-epic'
        },
        features: orphan_features.map { |feature| build_feature_json(feature) },
        statistics: build_orphan_statistics(orphan_features),
        ui_state: { expanded: true }
      }
    end

    def load_orphan_features
      @project.issues
              .includes(:tracker, :status, :fixed_version, :assigned_to)
              .joins(:tracker)
              .where(trackers: { name: 'Feature' })
              .where(parent_id: nil)
    end

    # Version列構築
    def build_version_columns
      versions = load_project_versions

      columns = versions.map { |version| build_version_column(version) }

      # No Version列を追加
      columns << build_no_version_column

      columns
    end

    def load_project_versions
      @project.versions
              .includes(:fixed_issues)
              .order(:effective_date, :name)
    end

    def build_version_column(version)
      {
        id: version.id,
        name: version.name,
        description: version.description,
        effective_date: version.effective_date&.iso8601,
        status: version.status,
        issue_count: version.fixed_issues.count,
        type: 'version'
      }
    end

    def build_no_version_column
      {
        id: 'no-version',
        name: 'No Version',
        description: 'バージョン未割当のFeature',
        effective_date: nil,
        status: 'open',
        issue_count: count_no_version_issues,
        type: 'no-version'
      }
    end

    def count_no_version_issues
      @project.issues
              .joins(:tracker)
              .where(trackers: { name: 'Feature' })
              .where(fixed_version_id: nil)
              .count
    end

    # 統計・メタデータ構築
    def build_grid_metadata
      epics = load_filtered_epics
      all_features = @project.issues.joins(:tracker).where(trackers: { name: 'Feature' })
      versions = load_project_versions

      {
        project: build_project_json(@project),
        total_epics: epics.count,
        total_features: all_features.count,
        total_versions: versions.count,
        matrix_dimensions: {
          rows: epics.count + 1, # +1 for No Epic row
          columns: versions.count + 1 # +1 for No Version column
        },
        user_permissions: gather_user_permissions,
        last_updated: Time.current.iso8601
      }
    end

    def build_grid_statistics
      issues = @project.issues.includes(:tracker, :status, :assigned_to, :fixed_version)

      {
        overview: build_project_statistics(issues),
        by_version: build_version_statistics(issues),
        by_status: build_status_distribution(issues)
      }
    end

    # JSON構築ヘルパー
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

    def build_feature_json(feature)
      # Load user stories efficiently using parent_id query
      user_stories = @project.issues
                             .includes(:tracker, :status, :fixed_version, :assigned_to)
                             .joins(:tracker)
                             .where(trackers: { name: 'UserStory' })
                             .where(parent_id: feature.id)

      {
        issue: build_issue_json(feature),
        user_stories: user_stories.map { |us| build_issue_json(us) },
        statistics: build_feature_statistics(feature, user_stories)
      }
    end

    def build_project_json(project)
      {
        id: project.id,
        name: project.name,
        identifier: project.identifier,
        description: project.description,
        status: project.status,
        created_on: project.created_on.iso8601,
        updated_on: project.updated_on.iso8601
      }
    end

    # 統計計算メソッド
    def build_epic_statistics(epic, features)
      # Count user stories efficiently using database query
      feature_ids = features.map(&:id)
      total_user_stories = if feature_ids.any?
        @project.issues
                .joins(:tracker)
                .where(trackers: { name: 'UserStory' })
                .where(parent_id: feature_ids)
                .count
      else
        0
      end

      completed_features = features.count { |f| ['Resolved', 'Closed'].include?(f.status.name) }

      {
        total_features: features.count,
        completed_features: completed_features,
        total_user_stories: total_user_stories,
        completion_rate: features.any? ? (completed_features.to_f / features.count * 100).round(2) : 0,
        estimated_hours: features.sum(&:estimated_hours).to_f,
        spent_hours: calculate_spent_hours(features)
      }
    end

    def build_feature_statistics(feature, user_stories)
      completed_stories = user_stories.count { |us| ['Resolved', 'Closed'].include?(us.status.name) }

      {
        total_user_stories: user_stories.count,
        completed_user_stories: completed_stories,
        completion_rate: user_stories.any? ? (completed_stories.to_f / user_stories.count * 100).round(2) : 0,
        estimated_hours: feature.estimated_hours.to_f,
        spent_hours: calculate_spent_hours([feature])
      }
    end

    def build_orphan_statistics(orphan_features)
      completed_features = orphan_features.count { |f| ['Resolved', 'Closed'].include?(f.status.name) }

      {
        total_features: orphan_features.count,
        completed_features: completed_features,
        completion_rate: orphan_features.any? ? (completed_features.to_f / orphan_features.count * 100).round(2) : 0,
        estimated_hours: orphan_features.sum(&:estimated_hours).to_f
      }
    end

    def build_project_statistics(issues)
      {
        total_issues: issues.count,
        by_tracker: issues.group_by { |i| i.tracker.name }.transform_values(&:count),
        by_status: issues.group_by { |i| i.status.name }.transform_values(&:count),
        by_assignee: issues.group_by { |i| i.assigned_to&.name || '未割当' }.transform_values(&:count)
      }
    end

    def build_version_statistics(issues)
      issues.group_by { |i| i.fixed_version&.name || 'No Version' }
            .transform_values do |version_issues|
              {
                count: version_issues.count,
                by_status: version_issues.group_by { |i| i.status.name }.transform_values(&:count),
                completion_rate: calculate_completion_rate(version_issues)
              }
            end
    end

    def build_status_distribution(issues)
      issues.group_by { |i| i.status.name }
            .transform_values do |status_issues|
              {
                count: status_issues.count,
                by_tracker: status_issues.group_by { |i| i.tracker.name }.transform_values(&:count)
              }
            end
    end

    def calculate_spent_hours(issues)
      issues.sum do |issue|
        issue.time_entries.sum(&:hours)
      end
    end

    def calculate_completion_rate(issues)
      return 0 if issues.empty?

      completed = issues.count { |i| ['Resolved', 'Closed'].include?(i.status.name) }
      (completed.to_f / issues.count * 100).round(2)
    end

    def gather_user_permissions
      {
        view_issues: @user.allowed_to?(:view_issues, @project),
        edit_issues: @user.allowed_to?(:edit_issues, @project),
        add_issues: @user.allowed_to?(:add_issues, @project),
        delete_issues: @user.allowed_to?(:delete_issues, @project),
        manage_versions: @user.allowed_to?(:manage_versions, @project),
        view_time_entries: @user.allowed_to?(:view_time_entries, @project)
      }
    end
  end
end