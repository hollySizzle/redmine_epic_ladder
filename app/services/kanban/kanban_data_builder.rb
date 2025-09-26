# app/services/kanban/kanban_data_builder.rb
# 設計仕様書準拠: @vibes/docs/logics/feature_card/feature_card_server_specification.md

module Kanban
  class KanbanDataBuilder
    def initialize(project, user, filter_params = {})
      @project = project
      @user = user
      @filter_params = filter_params
    end

    def build
      {
        epics: build_epics_data,
        columns: build_columns_data,
        metadata: build_metadata
      }
    end

    private

    def build_epics_data
      epics = fetch_epics_with_hierarchy
      epics.map do |epic|
        EpicData.new(epic, @user).to_hash
      end
    end

    def fetch_epics_with_hierarchy
      # N+1クエリ回避：階層データを効率的に取得
      base_query = @project.issues
        .joins(:tracker, :status)
        .includes(
          :tracker,
          :status,
          :assigned_to,
          :fixed_version,
          children: [
            :tracker,
            :status,
            :assigned_to,
            :fixed_version,
            children: [:tracker, :status, :assigned_to, :fixed_version]
          ]
        )

      # Epicレベル（トラッカー階層の最上位）を取得
      epic_tracker_ids = Kanban::TrackerHierarchy.epic_tracker_ids
      epics = base_query.where(tracker_id: epic_tracker_ids)

      # フィルタリング適用
      epics = apply_filters(epics)

      epics.order(:id)
    end

    def apply_filters(scope)
      scope = scope.where(fixed_version_id: @filter_params[:version_id]) if @filter_params[:version_id].present?
      scope = scope.where(assigned_to_id: @filter_params[:assignee_id]) if @filter_params[:assignee_id].present?
      scope = scope.where(status_id: @filter_params[:status_id]) if @filter_params[:status_id].present?
      scope
    end

    def build_columns_data
      # カンバン列設定を取得
      @project.issue_statuses.map do |status|
        {
          id: status.id,
          name: status.name,
          is_closed: status.is_closed,
          position: status.position
        }
      end
    end

    def build_metadata
      {
        project: project_metadata,
        user: user_metadata,
        permissions: user_permissions,
        version_context: version_context
      }
    end

    def project_metadata
      {
        id: @project.id,
        name: @project.name,
        trackers: @project.trackers.pluck(:id, :name),
        versions: @project.versions.open.pluck(:id, :name)
      }
    end

    def user_metadata
      {
        id: @user.id,
        name: @user.name
      }
    end

    def user_permissions
      {
        view_issues: @user.allowed_to?(:view_issues, @project),
        edit_issues: @user.allowed_to?(:edit_issues, @project),
        manage_versions: @user.allowed_to?(:manage_versions, @project),
        view_kanban: @user.allowed_to?(:view_kanban, @project),
        manage_kanban: @user.allowed_to?(:manage_kanban, @project)
      }
    end

    def version_context
      return {} unless @filter_params[:version_id].present?

      version = @project.versions.find(@filter_params[:version_id])
      {
        id: version.id,
        name: version.name,
        due_date: version.due_date,
        status: version.status
      }
    end

  end

  # Epic階層データ構築クラス
  class EpicData
    def initialize(epic_issue, user)
      @epic = epic_issue
      @user = user
    end

    def to_hash
      {
        issue: IssueSerializer.new(@epic).to_hash,
        features: build_features
      }
    end

    private

    def build_features
      feature_children = @epic.children.select { |child|
        Kanban::TrackerHierarchy.feature_tracker_ids.include?(child.tracker_id)
      }

      feature_children.map do |feature|
        FeatureData.new(feature, @user).to_hash
      end
    end
  end

  # Feature階層データ構築クラス
  class FeatureData
    def initialize(feature_issue, user)
      @feature = feature_issue
      @user = user
    end

    def to_hash
      {
        issue: IssueSerializer.new(@feature).to_hash,
        user_stories: build_user_stories,
        statistics: calculate_statistics
      }
    end

    private

    def build_user_stories
      user_story_children = @feature.children.select { |child|
        Kanban::TrackerHierarchy.user_story_tracker_ids.include?(child.tracker_id)
      }

      user_story_children.map do |user_story|
        UserStoryData.new(user_story, @user).to_hash
      end
    end

    def calculate_statistics
      user_stories = build_user_stories
      total_items = user_stories.sum { |us| us[:tasks].size + us[:tests].size + us[:bugs].size }
      completed_items = user_stories.sum { |us|
        (us[:tasks] + us[:tests] + us[:bugs]).count { |item| item[:status] == '完了' }
      }

      {
        total_user_stories: user_stories.size,
        total_items: total_items,
        completed_items: completed_items,
        progress_percentage: total_items > 0 ? (completed_items.to_f / total_items * 100).round(1) : 0
      }
    end
  end

  # UserStory階層データ構築クラス
  class UserStoryData
    def initialize(user_story_issue, user)
      @user_story = user_story_issue
      @user = user
    end

    def to_hash
      {
        issue: IssueSerializer.new(@user_story).to_hash,
        tasks: build_tasks,
        tests: build_tests,
        bugs: build_bugs
      }
    end

    private

    def build_tasks
      task_children = @user_story.children.select { |child|
        Kanban::TrackerHierarchy.task_tracker_ids.include?(child.tracker_id)
      }
      task_children.map { |task| IssueSerializer.new(task).to_hash }
    end

    def build_tests
      test_children = @user_story.children.select { |child|
        Kanban::TrackerHierarchy.test_tracker_ids.include?(child.tracker_id)
      }
      test_children.map { |test| IssueSerializer.new(test).to_hash }
    end

    def build_bugs
      bug_children = @user_story.children.select { |child|
        Kanban::TrackerHierarchy.bug_tracker_ids.include?(child.tracker_id)
      }
      bug_children.map { |bug| IssueSerializer.new(bug).to_hash }
    end
  end

  # Issue共通シリアライザー
  class IssueSerializer
    def initialize(issue)
      @issue = issue
    end

    def to_hash
      {
        id: @issue.id,
        subject: @issue.subject,
        tracker: @issue.tracker.name,
        status: @issue.status.name,
        status_column: kanban_column,
        assigned_to: @issue.assigned_to&.name,
        fixed_version: @issue.fixed_version&.name,
        version_source: determine_version_source,
        hierarchy_level: determine_hierarchy_level,
        can_release: can_release?,
        blocked_by_relations: serialize_blocking_relations,
        created_on: @issue.created_on,
        updated_on: @issue.updated_on
      }
    end

    private

    def kanban_column
      # カンバン列の決定ロジック（ステータスベース）
      @issue.status.name
    end

    def determine_version_source
      return 'direct' if @issue.fixed_version_id.present?
      return 'inherited' if @issue.parent&.fixed_version_id.present?
      'none'
    end

    def determine_hierarchy_level
      if Kanban::TrackerHierarchy.epic_tracker_ids.include?(@issue.tracker_id)
        'Epic'
      elsif Kanban::TrackerHierarchy.feature_tracker_ids.include?(@issue.tracker_id)
        'Feature'
      elsif Kanban::TrackerHierarchy.user_story_tracker_ids.include?(@issue.tracker_id)
        'UserStory'
      elsif Kanban::TrackerHierarchy.task_tracker_ids.include?(@issue.tracker_id)
        'Task'
      elsif Kanban::TrackerHierarchy.test_tracker_ids.include?(@issue.tracker_id)
        'Test'
      elsif Kanban::TrackerHierarchy.bug_tracker_ids.include?(@issue.tracker_id)
        'Bug'
      else
        'Other'
      end
    end

    def can_release?
      # リリース可能判定ロジック
      return false unless @issue.fixed_version_id.present?
      return false unless @issue.status.is_closed?

      # 依存関係チェック
      blocking_relations = @issue.relations_to.where(relation_type: 'blocks')
      blocking_relations.all? { |rel| rel.issue_from.status.is_closed? }
    end

    def serialize_blocking_relations
      @issue.relations_to.where(relation_type: 'blocks').map do |relation|
        {
          id: relation.id,
          blocking_issue_id: relation.issue_from_id,
          blocking_issue_subject: relation.issue_from.subject,
          blocking_issue_tracker: relation.issue_from.tracker.name,
          blocking_issue_status: relation.issue_from.status.name
        }
      end
    end
  end
end