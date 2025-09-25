# データビルダー サーバーサイド実装仕様

## 概要
Kanban UI用データ構築サービス。Issue階層データ変換、統計計算、キャッシュ戦略、フィルタリング、ソート処理、パフォーマンス最適化。

## 基底データビルダークラス

### 抽象データビルダー
```ruby
# app/services/kanban/base_data_builder.rb
module Kanban
  class BaseDataBuilder
    include ActiveSupport::Benchmarkable

    def initialize(project, user, options = {})
      @project = project
      @user = user
      @options = options.with_indifferent_access
      @cache_enabled = @options[:cache_enabled] != false
      @logger = Rails.logger
    end

    def build
      benchmark "#{self.class.name}#build" do
        validate_permissions!

        if @cache_enabled
          cache_key = generate_cache_key
          Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
            build_data
          end
        else
          build_data
        end
      end
    end

    protected

    def build_data
      raise NotImplementedError, "#{self.class.name} must implement #build_data"
    end

    def validate_permissions!
      unless @user.allowed_to?(:view_kanban, @project)
        raise Kanban::PermissionDenied.new('Kanban表示権限がありません')
      end
    end

    def generate_cache_key
      key_parts = [
        'kanban',
        self.class.name.demodulize.underscore,
        @project.id,
        @user.id,
        Digest::MD5.hexdigest(@options.to_json),
        @project.issues.maximum(:updated_on)&.to_i || 0
      ]
      key_parts.join(':')
    end

    def cache_expiry
      @options[:cache_expiry] || 10.minutes
    end

    def serialize_issue(issue, options = {})
      Kanban::SerializerService.serialize_issue(issue, options)
    end

    def filter_issues(scope)
      scope = apply_version_filter(scope)
      scope = apply_assignee_filter(scope)
      scope = apply_status_filter(scope)
      scope = apply_tracker_filter(scope)
      scope = apply_date_filter(scope)
      scope
    end

    def apply_version_filter(scope)
      return scope unless @options[:version_filter].present?

      version_ids = Array(@options[:version_filter])
      scope.where(fixed_version_id: version_ids)
    end

    def apply_assignee_filter(scope)
      return scope unless @options[:assignee_filter].present?

      assignee_ids = Array(@options[:assignee_filter])
      scope.where(assigned_to_id: assignee_ids)
    end

    def apply_status_filter(scope)
      return scope unless @options[:status_filter].present?

      status_ids = Array(@options[:status_filter])
      scope.where(status_id: status_ids)
    end

    def apply_tracker_filter(scope)
      return scope unless @options[:tracker_filter].present?

      tracker_names = Array(@options[:tracker_filter])
      scope.joins(:tracker).where(trackers: { name: tracker_names })
    end

    def apply_date_filter(scope)
      scope = scope.where('created_on >= ?', Date.parse(@options[:created_after])) if @options[:created_after].present?
      scope = scope.where('created_on <= ?', Date.parse(@options[:created_before])) if @options[:created_before].present?
      scope = scope.where('updated_on >= ?', Date.parse(@options[:updated_after])) if @options[:updated_after].present?
      scope = scope.where('updated_on <= ?', Date.parse(@options[:updated_before])) if @options[:updated_before].present?
      scope
    end
  end
end
```

## 主要データビルダー実装

### Kanbanグリッドデータビルダー
```ruby
# app/services/kanban/kanban_grid_data_builder.rb
module Kanban
  class KanbanGridDataBuilder < BaseDataBuilder
    BATCH_SIZE = 100

    protected

    def build_data
      {
        grid_structure: build_grid_structure,
        metadata: build_metadata,
        statistics: build_statistics,
        performance_metrics: build_performance_metrics
      }
    end

    private

    def build_grid_structure
      benchmark 'build_grid_structure' do
        epics = load_epics_with_hierarchy
        versions = load_active_versions
        columns = load_column_configuration

        {
          rows: build_epic_rows(epics, versions, columns),
          columns: columns,
          versions: versions.map { |v| serialize_version(v) }
        }
      end
    end

    def load_epics_with_hierarchy
      benchmark 'load_epics_with_hierarchy' do
        epic_scope = @project.issues
                            .includes(epic_includes)
                            .joins(:tracker)
                            .where(trackers: { name: 'Epic' })

        epic_scope = filter_issues(epic_scope)
        epic_scope = apply_epic_specific_filters(epic_scope)

        epics = epic_scope.order(:id).to_a

        # 子要素を効率的に読み込み
        preload_epic_children(epics)

        epics
      end
    end

    def epic_includes
      [
        :tracker, :status, :assigned_to, :fixed_version, :priority,
        { children: [
          :tracker, :status, :assigned_to, :fixed_version, :priority,
          { children: [:tracker, :status, :assigned_to, :fixed_version, :priority] }
        ]}
      ]
    end

    def preload_epic_children(epics)
      return if epics.empty?

      # すべての子Issueを一括読み込み
      all_child_ids = epics.flat_map { |epic| collect_all_child_ids(epic) }

      if all_child_ids.any?
        child_issues = Issue.includes(:tracker, :status, :assigned_to, :fixed_version, :priority)
                           .where(id: all_child_ids)
                           .index_by(&:id)

        # 階層構造を効率的に構築
        build_hierarchy_associations(epics, child_issues)
      end
    end

    def collect_all_child_ids(issue, collected_ids = Set.new)
      issue.children.each do |child|
        next if collected_ids.include?(child.id)
        collected_ids.add(child.id)
        collect_all_child_ids(child, collected_ids)
      end
      collected_ids.to_a
    end

    def build_epic_rows(epics, versions, columns)
      benchmark 'build_epic_rows' do
        epics.map.with_index do |epic, index|
          {
            epic: serialize_epic_with_context(epic, index),
            cells: build_epic_cells(epic, versions, columns)
          }
        end
      end
    end

    def serialize_epic_with_context(epic, index)
      base_data = serialize_issue(epic, include_hierarchy: true)
      base_data.merge({
        row_index: index,
        feature_count: count_features(epic),
        total_user_stories: count_user_stories(epic),
        completion_percentage: calculate_epic_completion(epic),
        last_activity: epic.descendants.maximum(:updated_on) || epic.updated_on
      })
    end

    def build_epic_cells(epic, versions, columns)
      versions.map do |version|
        features_in_cell = find_features_for_cell(epic, version)

        {
          epic_id: epic.id,
          version_id: version.id,
          position: { row: epic.id, column: version.id },
          features: build_cell_features(features_in_cell, columns),
          statistics: calculate_cell_statistics(features_in_cell),
          interaction_config: build_cell_interaction_config(epic, version)
        }
      end
    end

    def find_features_for_cell(epic, version)
      features = epic.children.select { |child| child.tracker.name == 'Feature' }

      features.select do |feature|
        feature_matches_version?(feature, version)
      end
    end

    def feature_matches_version?(feature, version)
      # Direct version assignment
      return true if feature.fixed_version == version

      # Child UserStory version assignment
      feature.children.any? do |child|
        child.tracker.name == 'UserStory' && child.fixed_version == version
      end
    end

    def build_cell_features(features, columns)
      features.map do |feature|
        current_column = determine_feature_column(feature, columns)

        {
          feature: serialize_issue(feature, include_relations: true),
          current_column: current_column,
          user_stories: build_feature_user_stories(feature),
          visual_indicators: calculate_visual_indicators(feature),
          drag_config: build_drag_configuration(feature)
        }
      end
    end

    def build_feature_user_stories(feature)
      user_stories = feature.children.select { |child| child.tracker.name == 'UserStory' }

      user_stories.map do |us|
        {
          issue: serialize_issue(us),
          child_items: build_user_story_children(us),
          completion_status: calculate_user_story_completion(us)
        }
      end
    end

    def build_user_story_children(user_story)
      children = user_story.children.group_by { |child| child.tracker.name }

      {
        tasks: (children['Task'] || []).map { |task| serialize_issue(task) },
        tests: (children['Test'] || []).map { |test| serialize_issue(test) },
        bugs: (children['Bug'] || []).map { |bug| serialize_issue(bug) }
      }
    end

    def build_metadata
      {
        project: serialize_project_metadata,
        user_permissions: calculate_user_permissions,
        grid_configuration: load_grid_configuration,
        filter_options: build_filter_options,
        last_build_time: Time.zone.now.iso8601
      }
    end

    def load_grid_configuration
      {
        column_definitions: KanbanColumnConfig.for_project(@project),
        tracker_hierarchy: TrackerHierarchy.for_project(@project),
        workflow_rules: WorkflowRules.for_project(@project),
        drag_drop_rules: DragDropRules.for_project(@project)
      }
    end

    def build_filter_options
      {
        versions: @project.versions.open.pluck(:id, :name),
        assignees: @project.assignable_users.active.pluck(:id, :name),
        statuses: @project.rolled_up_statuses.pluck(:id, :name),
        trackers: @project.trackers.pluck(:id, :name)
      }
    end

    def build_statistics
      all_issues = @project.issues.joins(:tracker)
      epic_issues = all_issues.where(trackers: { name: 'Epic' })
      feature_issues = all_issues.where(trackers: { name: 'Feature' })

      {
        overview: build_overview_statistics(all_issues),
        by_tracker: build_tracker_statistics(all_issues),
        by_status: build_status_statistics(all_issues),
        by_version: build_version_statistics,
        trends: build_trend_statistics,
        completion_analysis: build_completion_analysis
      }
    end

    def build_overview_statistics(all_issues)
      {
        total_issues: all_issues.count,
        total_epics: all_issues.joins(:tracker).where(trackers: { name: 'Epic' }).count,
        total_features: all_issues.joins(:tracker).where(trackers: { name: 'Feature' }).count,
        completion_ratio: calculate_overall_completion_ratio,
        velocity: calculate_velocity_metrics
      }
    end

    def build_performance_metrics
      {
        query_time: @query_time || 0,
        serialization_time: @serialization_time || 0,
        cache_hit_ratio: calculate_cache_hit_ratio,
        total_build_time: @total_build_time || 0
      }
    end

    # ヘルパーメソッド続き...
    def count_features(epic)
      epic.children.count { |child| child.tracker.name == 'Feature' }
    end

    def count_user_stories(epic)
      epic.descendants.count { |desc| desc.tracker.name == 'UserStory' }
    end

    def calculate_epic_completion(epic)
      user_stories = epic.descendants.select { |desc| desc.tracker.name == 'UserStory' }
      return 0 if user_stories.empty?

      completed = user_stories.count(&:closed?)
      (completed.to_f / user_stories.size * 100).round(1)
    end
  end
end
```

### Issue詳細データビルダー
```ruby
# app/services/kanban/issue_detail_data_builder.rb
module Kanban
  class IssueDetailDataBuilder < BaseDataBuilder
    def initialize(issue, user, options = {})
      @issue = issue
      super(issue.project, user, options)
    end

    protected

    def build_data
      {
        issue: build_issue_data,
        hierarchy_context: build_hierarchy_context,
        relations: build_relations_data,
        activity: build_activity_data,
        permissions: build_permissions_data
      }
    end

    private

    def build_issue_data
      base_data = serialize_issue(@issue, include_description: true, include_relations: true)

      base_data.merge({
        custom_fields: serialize_custom_fields,
        attachments: serialize_attachments,
        watchers: serialize_watchers,
        time_entries: serialize_time_entries,
        changesets: serialize_changesets
      })
    end

    def build_hierarchy_context
      {
        root: @issue.root ? serialize_issue(@issue.root) : nil,
        parent: @issue.parent ? serialize_issue(@issue.parent) : nil,
        children: @issue.children.map { |child| serialize_issue(child) },
        siblings: load_and_serialize_siblings,
        ancestry_path: build_ancestry_path,
        descendants_summary: build_descendants_summary
      }
    end

    def load_and_serialize_siblings
      return [] unless @issue.parent

      @issue.parent.children
                   .where.not(id: @issue.id)
                   .includes(:tracker, :status, :assigned_to)
                   .map { |sibling| serialize_issue(sibling) }
    end

    def build_ancestry_path
      path = []
      current = @issue.parent

      while current
        path.unshift(serialize_issue(current))
        current = current.parent
        break if path.size > 10 # 無限ループ防止
      end

      path
    end

    def build_descendants_summary
      descendants = @issue.descendants.includes(:tracker, :status)
      grouped = descendants.group_by { |desc| desc.tracker.name }

      grouped.transform_values do |issues|
        {
          total: issues.size,
          by_status: issues.group_by { |i| i.status.name }.transform_values(&:size),
          completion_ratio: issues.empty? ? 0 : (issues.count(&:closed?).to_f / issues.size * 100).round(1)
        }
      end
    end

    def build_relations_data
      {
        blocks: build_blocking_relations,
        blocked_by: build_blocked_by_relations,
        relates: build_related_relations,
        duplicates: build_duplicate_relations,
        follows: build_follows_relations,
        precedes: build_precedes_relations
      }
    end

    def build_blocking_relations
      @issue.relations_from
             .where(relation_type: 'blocks')
             .includes(:issue_to)
             .map do |relation|
        {
          id: relation.id,
          target_issue: serialize_issue(relation.issue_to),
          delay: relation.delay
        }
      end
    end

    def build_activity_data
      return {} unless @options[:include_activity]

      journals = @issue.journals
                       .includes(:user, :details)
                       .order(created_on: :desc)
                       .limit(@options[:activity_limit] || 50)

      {
        journals: serialize_journals(journals),
        recent_changes: build_recent_changes_summary,
        activity_statistics: build_activity_statistics
      }
    end

    def serialize_journals(journals)
      journals.map do |journal|
        {
          id: journal.id,
          user: journal.user ? { id: journal.user.id, name: journal.user.name } : nil,
          created_on: journal.created_on.iso8601,
          notes: journal.notes,
          details: serialize_journal_details(journal.details)
        }
      end
    end

    def serialize_journal_details(details)
      details.map do |detail|
        {
          property: detail.property,
          prop_key: detail.prop_key,
          old_value: detail.old_value,
          value: detail.value,
          formatted_change: format_journal_detail(detail)
        }
      end
    end

    def build_permissions_data
      {
        can_edit: @user.allowed_to?(:edit_issues, @project),
        can_add_notes: @user.allowed_to?(:add_issue_notes, @project),
        can_change_status: can_change_status?,
        can_assign_version: @user.allowed_to?(:manage_versions, @project),
        can_delete: @user.allowed_to?(:delete_issues, @project),
        can_add_watchers: @user.allowed_to?(:add_issue_watchers, @project),
        available_transitions: calculate_available_transitions
      }
    end

    def calculate_available_transitions
      return [] unless @user.allowed_to?(:edit_issues, @project)

      WorkflowPermission
        .where(
          tracker_id: @issue.tracker_id,
          old_status_id: @issue.status_id,
          role_id: @user.roles_for_project(@project).pluck(:id)
        )
        .includes(:new_status)
        .map do |transition|
          {
            id: transition.new_status.id,
            name: transition.new_status.name,
            color: transition.new_status.color,
            is_closed: transition.new_status.is_closed?
          }
        end
    end
  end
end
```

### 統計データビルダー
```ruby
# app/services/kanban/statistics_data_builder.rb
module Kanban
  class StatisticsDataBuilder < BaseDataBuilder
    TREND_PERIODS = %w[daily weekly monthly].freeze
    DEFAULT_PERIOD = 30.days

    protected

    def build_data
      {
        overview: build_overview_statistics,
        trends: build_trend_analysis,
        performance: build_performance_metrics,
        completion: build_completion_analysis,
        bottlenecks: build_bottleneck_analysis,
        velocity: build_velocity_metrics
      }
    end

    private

    def build_overview_statistics
      issues = load_project_issues
      epics = issues.select { |i| i.tracker.name == 'Epic' }
      features = issues.select { |i| i.tracker.name == 'Feature' }

      {
        total_issues: issues.size,
        by_tracker: issues.group_by { |i| i.tracker.name }.transform_values(&:size),
        by_status: issues.group_by { |i| i.status.name }.transform_values(&:size),
        completion_ratios: calculate_completion_ratios(issues),
        active_vs_closed: calculate_active_vs_closed(issues),
        assignment_distribution: calculate_assignment_distribution(issues)
      }
    end

    def build_trend_analysis
      period = @options[:period]&.to_sym || :monthly
      range = calculate_date_range

      case period
      when :daily
        build_daily_trends(range)
      when :weekly
        build_weekly_trends(range)
      when :monthly
        build_monthly_trends(range)
      else
        build_monthly_trends(range)
      end
    end

    def build_daily_trends(range)
      trends = {}
      range.each do |date|
        day_start = date.beginning_of_day
        day_end = date.end_of_day

        trends[date.iso8601] = {
          created: count_issues_created_in_period(day_start, day_end),
          closed: count_issues_closed_in_period(day_start, day_end),
          updated: count_issues_updated_in_period(day_start, day_end),
          velocity: calculate_daily_velocity(day_start, day_end)
        }
      end
      trends
    end

    def build_completion_analysis
      issues_by_epic = load_project_issues.group_by(&:root)

      epic_analysis = issues_by_epic.map do |epic, epic_issues|
        features = epic_issues.select { |i| i.tracker.name == 'Feature' }
        user_stories = epic_issues.select { |i| i.tracker.name == 'UserStory' }

        {
          epic: serialize_issue(epic),
          feature_completion: calculate_feature_completion(features),
          user_story_completion: calculate_user_story_completion(user_stories),
          overall_progress: calculate_epic_progress(epic_issues),
          estimated_completion: estimate_completion_date(epic_issues),
          blockers: identify_epic_blockers(epic_issues)
        }
      end

      {
        by_epic: epic_analysis,
        project_health: calculate_project_health_score,
        risk_indicators: identify_risk_indicators
      }
    end

    def build_bottleneck_analysis
      status_transitions = analyze_status_transitions
      assignment_patterns = analyze_assignment_patterns
      version_patterns = analyze_version_patterns

      {
        status_bottlenecks: identify_status_bottlenecks(status_transitions),
        assignment_bottlenecks: identify_assignment_bottlenecks(assignment_patterns),
        version_bottlenecks: identify_version_bottlenecks(version_patterns),
        recommendations: generate_bottleneck_recommendations
      }
    end

    def build_velocity_metrics
      period_days = (@options[:velocity_period] || 30).to_i
      end_date = Date.current
      start_date = end_date - period_days.days

      completed_issues = @project.issues
                                .joins(:status)
                                .where(issue_statuses: { is_closed: true })
                                .where(closed_on: start_date..end_date)

      {
        period: { start: start_date.iso8601, end: end_date.iso8601 },
        total_completed: completed_issues.count,
        by_tracker: completed_issues.joins(:tracker).group('trackers.name').count,
        average_daily: (completed_issues.count.to_f / period_days).round(2),
        story_points: calculate_story_points_velocity(completed_issues),
        cycle_time: calculate_average_cycle_time(completed_issues),
        throughput_trend: calculate_throughput_trend(start_date, end_date)
      }
    end

    # ヘルパーメソッド
    def load_project_issues
      @project.issues
              .includes(:tracker, :status, :assigned_to, :fixed_version, :priority)
              .to_a
    end

    def calculate_completion_ratios(issues)
      total = issues.size
      return {} if total.zero?

      closed_count = issues.count(&:closed?)

      {
        overall: (closed_count.to_f / total * 100).round(1),
        by_tracker: issues.group_by { |i| i.tracker.name }.transform_values do |tracker_issues|
          tracker_total = tracker_issues.size
          tracker_closed = tracker_issues.count(&:closed?)
          (tracker_closed.to_f / tracker_total * 100).round(1)
        end
      }
    end

    def calculate_project_health_score
      issues = load_project_issues
      total_score = 0
      max_score = 0

      # 完了率スコア (40%)
      completion_ratio = issues.count(&:closed?).to_f / issues.size
      total_score += completion_ratio * 40
      max_score += 40

      # 期限遵守スコア (30%)
      overdue_ratio = calculate_overdue_ratio(issues)
      total_score += (1 - overdue_ratio) * 30
      max_score += 30

      # アクティビティスコア (30%)
      activity_score = calculate_activity_score(issues)
      total_score += activity_score * 30
      max_score += 30

      (total_score / max_score * 100).round(1)
    end
  end
end
```

## ファクトリーパターン実装

### データビルダーファクトリー
```ruby
# app/services/kanban/data_builder_factory.rb
module Kanban
  class DataBuilderFactory
    BUILDER_TYPES = {
      grid: KanbanGridDataBuilder,
      issue_detail: IssueDetailDataBuilder,
      statistics: StatisticsDataBuilder,
      feature_card: FeatureCardDataBuilder,
      version_timeline: VersionTimelineDataBuilder
    }.freeze

    def self.create(type, *args)
      builder_class = BUILDER_TYPES[type.to_sym]

      unless builder_class
        raise ArgumentError, "Unknown builder type: #{type}. Available types: #{BUILDER_TYPES.keys}"
      end

      builder_class.new(*args)
    end

    def self.available_types
      BUILDER_TYPES.keys
    end
  end
end
```

## テスト実装

```ruby
# spec/services/kanban/kanban_grid_data_builder_spec.rb
RSpec.describe Kanban::KanbanGridDataBuilder do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_kanban_permissions, project: project) }
  let(:builder) { described_class.new(project, user) }

  describe '#build' do
    let!(:epic) { create(:epic_issue, project: project) }
    let!(:feature) { create(:feature_issue, project: project, parent: epic) }
    let!(:version) { create(:version, project: project) }

    it 'グリッド構造データを構築' do
      result = builder.build

      expect(result).to include(:grid_structure, :metadata, :statistics)
      expect(result[:grid_structure]).to include(:rows, :columns, :versions)
      expect(result[:grid_structure][:rows]).to be_an(Array)
      expect(result[:grid_structure][:rows].first[:epic][:id]).to eq(epic.id)
    end

    it 'フィルターを適用' do
      builder = described_class.new(project, user, version_filter: version.id)
      result = builder.build

      expect(result[:grid_structure][:rows]).to be_an(Array)
    end

    it 'キャッシュが有効' do
      expect(Rails.cache).to receive(:fetch).and_call_original
      builder.build
    end
  end

  describe '#build_epic_rows' do
    let!(:epic) { create(:epic_issue, project: project) }
    let!(:feature) { create(:feature_issue, project: project, parent: epic) }

    it 'Epic行データを正しく構築' do
      result = builder.send(:build_epic_rows, [epic], [create(:version, project: project)], [])

      expect(result).to be_an(Array)
      expect(result.first[:epic][:id]).to eq(epic.id)
      expect(result.first[:cells]).to be_an(Array)
    end
  end
end
```

---

*Kanban UI用データ構築サービス。Issue階層データ変換、統計計算、キャッシュ戦略、パフォーマンス最適化*