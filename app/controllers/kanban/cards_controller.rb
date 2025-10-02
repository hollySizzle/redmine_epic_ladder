# frozen_string_literal: true

module Kanban
  # Feature Cards管理コントローラー
  # Feature一覧・詳細・CRUD操作API提供
  class CardsController < BaseApiController

    # Feature Card一覧取得
    def index
      filter_params = params.permit(:version_id, :assignee_id, :status_id, :tracker_name)

      # 設計書準拠: KanbanDataBuilderを使用
      kanban_data = Kanban::KanbanDataBuilder.new(@project, User.current, filter_params).build

      render_success({
        epics: kanban_data[:epics],
        columns: kanban_data[:columns],
        metadata: kanban_data[:metadata].merge({
          applied_filters: filter_params.to_h
        })
      })
    end

    # Feature Card作成
    def create
      feature_params = params.require(:feature).permit(:subject, :description, :assigned_to_id, :fixed_version_id, :parent_id)

      result = Kanban::FeatureCreationService.execute(
        project: @project,
        feature_params: feature_params,
        user: User.current
      )

      if result[:success]
        render_success({
          feature: serialize_issue_with_children(result[:feature]),
          parent_epic: result[:parent_epic] ? serialize_issue(result[:parent_epic]) : nil,
          grid_updates: result[:grid_updates]
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    end

    # Feature Card更新
    def update
      feature = Issue.find(params[:id])
      feature_params = params.require(:feature).permit(:subject, :description, :assigned_to_id, :fixed_version_id, :status_id)

      result = Kanban::FeatureUpdateService.execute(
        feature: feature,
        feature_params: feature_params,
        user: User.current
      )

      if result[:success]
        render_success({
          feature: serialize_issue_with_children(result[:feature]),
          affected_issues: result[:affected_issues].map { |issue| serialize_issue(issue) },
          version_propagation: result[:version_propagation]
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたFeatureが見つかりません', :not_found)
    end

    # Feature Card詳細取得
    def show
      feature = Issue.find(params[:id])

      render_success({
        feature: serialize_issue_with_children(feature),
        user_stories: serialize_user_stories_with_children(feature.children.joins(:tracker).where(trackers: { name: Kanban::TrackerHierarchy.tracker_names[:user_story] })),
        relationships: serialize_relationships(feature),
        activity_timeline: build_activity_timeline(feature),
        validation_status: Kanban::ValidationGuardService.validate_feature_readiness(feature)
      })
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたFeatureが見つかりません', :not_found)
    end

    # UserStory作成
    def create_user_story
      feature_id = params[:feature_id]
      user_story_params = params.require(:user_story).permit(:subject, :description, :assigned_to_id)

      result = Kanban::UserStoryCreationService.execute(
        feature_id: feature_id,
        user_story_params: user_story_params,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          user_story: serialize_issue_with_children(result[:user_story]),
          feature: serialize_issue(result[:feature])
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたFeatureが見つかりません', :not_found)
    end

    # UserStory更新
    def update_user_story
      user_story = Issue.find(params[:id])
      user_story_params = params.require(:user_story).permit(:subject, :description, :assigned_to_id, :status_id)

      result = Kanban::UserStoryUpdateService.execute(
        user_story: user_story,
        user_story_params: user_story_params,
        user: User.current
      )

      if result[:success]
        render_success({
          user_story: serialize_issue_with_children(result[:user_story]),
          affected_tasks: result[:affected_tasks].map { |task| serialize_issue(task) }
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたUserStoryが見つかりません', :not_found)
    end

    # UserStory削除
    def destroy_user_story
      user_story = Issue.find(params[:id])

      result = Kanban::UserStoryDeletionService.execute(
        user_story: user_story,
        user: User.current
      )

      if result[:success]
        render_success({
          deleted_user_story_id: user_story.id,
          feature: serialize_issue(result[:feature]),
          message: 'UserStoryが削除されました'
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたUserStoryが見つかりません', :not_found)
    end

    # Task作成
    def create_task
      user_story_id = params[:user_story_id]
      task_params = params.require(:task).permit(:subject, :description, :assigned_to_id, :estimated_hours)

      result = Kanban::TaskCreationService.execute(
        user_story_id: user_story_id,
        task_params: task_params,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          task: serialize_issue(result[:task]),
          user_story: serialize_issue_with_children(result[:user_story])
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたUserStoryが見つかりません', :not_found)
    end

    # Test作成
    def create_test
      user_story_id = params[:user_story_id]
      test_params = params.require(:test).permit(:subject, :description, :assigned_to_id)

      result = Kanban::TestCreationService.execute(
        user_story_id: user_story_id,
        test_params: test_params,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          test: serialize_issue(result[:test]),
          user_story: serialize_issue_with_children(result[:user_story])
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたUserStoryが見つかりません', :not_found)
    end

    # Bug作成
    def create_bug
      user_story_id = params[:user_story_id]
      bug_params = params.require(:bug).permit(:subject, :description, :assigned_to_id, :priority_id)

      result = Kanban::BugCreationService.execute(
        user_story_id: user_story_id,
        bug_params: bug_params,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          bug: serialize_issue(result[:bug]),
          user_story: serialize_issue_with_children(result[:user_story])
        }, :created)
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたUserStoryが見つかりません', :not_found)
    end

    # Task/Test/Bug更新（共通）
    def update_item
      item = Issue.find(params[:id])
      item_params = params.require(:item).permit(:subject, :description, :assigned_to_id, :status_id, :done_ratio, :estimated_hours)

      result = Kanban::ItemUpdateService.execute(
        item: item,
        item_params: item_params,
        user: User.current
      )

      if result[:success]
        render_success({
          item: serialize_issue(result[:item]),
          user_story: serialize_issue_with_children(result[:user_story])
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたアイテムが見つかりません', :not_found)
    end

    # Task/Test/Bug削除（共通）
    def destroy_item
      item = Issue.find(params[:id])

      result = Kanban::ItemDeletionService.execute(
        item: item,
        user: User.current
      )

      if result[:success]
        render_success({
          deleted_item_id: item.id,
          user_story: serialize_issue_with_children(result[:user_story]),
          message: "#{item.tracker.name}が削除されました"
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたアイテムが見つかりません', :not_found)
    end

    # 一括操作: 複数UserStoryの状態更新
    def bulk_update_user_stories
      user_story_ids = params.require(:user_story_ids)
      bulk_params = params.require(:bulk_update).permit(:status_id, :assigned_to_id, :fixed_version_id)

      result = Kanban::BulkUpdateService.execute(
        user_story_ids: user_story_ids,
        bulk_params: bulk_params,
        user: User.current
      )

      if result[:success]
        render_success({
          updated_user_stories: result[:updated_user_stories].map { |us| serialize_issue(us) },
          failed_updates: result[:failed_updates],
          success_count: result[:success_count],
          total_count: result[:total_count]
        })
      else
        render_validation_error(result[:errors], result[:details])
      end
    end

    private

    def apply_filters(data, filters)
      filtered_data = data.dup

      if filters[:version_id].present?
        version_id = filters[:version_id].to_i
        filtered_data[:epics] = filter_epics_by_version(data[:epics], version_id)
      end

      if filters[:assignee_id].present?
        assignee_id = filters[:assignee_id].to_i
        filtered_data[:epics] = filter_epics_by_assignee(filtered_data[:epics], assignee_id)
      end

      if filters[:status_id].present?
        status_id = filters[:status_id].to_i
        filtered_data[:epics] = filter_epics_by_status(filtered_data[:epics], status_id)
      end

      if filters[:tracker_name].present?
        filtered_data[:epics] = filter_epics_by_tracker(filtered_data[:epics], filters[:tracker_name])
      end

      filtered_data
    end

    def filter_epics_by_version(epics, version_id)
      epics.map do |epic_data|
        filtered_features = epic_data[:features].select do |feature_data|
          feature_data[:issue][:fixed_version_id] == version_id
        end

        epic_data.merge(features: filtered_features) if filtered_features.any?
      end.compact
    end

    def filter_epics_by_assignee(epics, assignee_id)
      epics.map do |epic_data|
        filtered_features = epic_data[:features].select do |feature_data|
          has_assigned_user_story = feature_data[:user_stories].any? do |us_data|
            us_data[:issue][:assigned_to_id] == assignee_id
          end
          feature_data[:issue][:assigned_to_id] == assignee_id || has_assigned_user_story
        end

        epic_data.merge(features: filtered_features) if filtered_features.any?
      end.compact
    end

    def filter_epics_by_status(epics, status_id)
      epics.map do |epic_data|
        filtered_features = epic_data[:features].select do |feature_data|
          has_status_user_story = feature_data[:user_stories].any? do |us_data|
            us_data[:issue][:status_id] == status_id
          end
          feature_data[:issue][:status_id] == status_id || has_status_user_story
        end

        epic_data.merge(features: filtered_features) if filtered_features.any?
      end.compact
    end

    def filter_epics_by_tracker(epics, tracker_name)
      epics.select do |epic_data|
        epic_data[:issue][:tracker] == tracker_name ||
          epic_data[:features].any? { |f| f[:issue][:tracker] == tracker_name }
      end
    end

    def serialize_epics_with_features(epics)
      epics.map do |epic_data|
        {
          issue: serialize_issue(epic_data[:issue]),
          features: serialize_features_with_user_stories(epic_data[:features]),
          statistics: calculate_epic_statistics(epic_data)
        }
      end
    end

    def serialize_features_with_user_stories(features)
      features.map do |feature_data|
        {
          issue: serialize_issue(feature_data[:issue]),
          user_stories: serialize_user_stories_with_children(feature_data[:user_stories]),
          completion_status: calculate_feature_completion(feature_data),
          risk_assessment: assess_feature_risk(feature_data)
        }
      end
    end

    def serialize_user_stories_with_children(user_stories)
      user_stories.map do |us_data|
        {
          issue: serialize_issue(us_data[:issue]),
          tasks: us_data[:tasks].map { |task| serialize_issue(task) },
          tests: us_data[:tests].map { |test| serialize_issue(test) },
          bugs: us_data[:bugs].map { |bug| serialize_issue(bug) },
          completion_ratio: calculate_user_story_completion(us_data),
          blocking_relations: serialize_blocking_relations(us_data[:issue])
        }
      end
    end

    def serialize_issue_with_children(issue)
      base_data = serialize_issue(issue)

      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      if issue.tracker.name == feature_tracker_name
        user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
        user_stories = issue.children.joins(:tracker).where(trackers: { name: user_story_tracker_name })
        base_data.merge({
          user_stories: user_stories.map do |us|
            {
              issue: serialize_issue(us),
              tasks: serialize_children_by_tracker(us, Kanban::TrackerHierarchy.tracker_names[:task]),
              tests: serialize_children_by_tracker(us, Kanban::TrackerHierarchy.tracker_names[:test]),
              bugs: serialize_children_by_tracker(us, Kanban::TrackerHierarchy.tracker_names[:bug])
            }
          end
        })
      else
        base_data
      end
    end

    def serialize_children_by_tracker(parent_issue, tracker_name)
      parent_issue.children
                  .joins(:tracker)
                  .where(trackers: { name: tracker_name })
                  .map { |issue| serialize_issue(issue) }
    end

    def serialize_issue(issue)
      # Issueがハッシュの場合とActiveRecordオブジェクトの場合を処理
      if issue.is_a?(Hash)
        issue
      else
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
          hierarchy_level: Kanban::TrackerHierarchy.level(issue.tracker.name),
          created_on: issue.created_on.iso8601,
          updated_on: issue.updated_on.iso8601,
          estimated_hours: issue.estimated_hours,
          done_ratio: issue.done_ratio,
          lock_version: issue.lock_version,
          can_edit: User.current.allowed_to?(:edit_issues, @project)
        }
      end
    end

    def serialize_relationships(feature)
      relations = IssueRelation.where(
        '(issue_from_id = ? OR issue_to_id = ?)',
        feature.id, feature.id
      ).includes(:issue_from, :issue_to)

      relations.map do |relation|
        {
          id: relation.id,
          relation_type: relation.relation_type,
          issue_from: {
            id: relation.issue_from.id,
            subject: relation.issue_from.subject,
            tracker: relation.issue_from.tracker.name
          },
          issue_to: {
            id: relation.issue_to.id,
            subject: relation.issue_to.subject,
            tracker: relation.issue_to.tracker.name
          },
          delay: relation.delay
        }
      end
    end

    def build_activity_timeline(feature)
      # 最近の活動ログを構築
      journals = feature.journals
                       .includes(:user, :details)
                       .order(created_on: :desc)
                       .limit(20)

      journals.map do |journal|
        {
          id: journal.id,
          user: journal.user&.name,
          created_on: journal.created_on.iso8601,
          notes: journal.notes,
          details: journal.details.map do |detail|
            {
              property: detail.property,
              prop_key: detail.prop_key,
              old_value: detail.old_value,
              value: detail.value
            }
          end
        }
      end
    end

    def serialize_blocking_relations(issue)
      # ハッシュの場合は既存のロジックを使用
      return [] if issue.is_a?(Hash)

      issue.relations_to.where(relation_type: 'blocks').map do |relation|
        {
          id: relation.id,
          blocking_issue_id: relation.issue_from_id,
          blocking_issue_tracker: relation.issue_from.tracker.name
        }
      end
    end

    def determine_kanban_column(issue)
      status_name = issue.is_a?(Hash) ? issue[:status] : issue.status.name

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

    def calculate_totals(data)
      total_epics = data[:epics].count
      total_features = data[:epics].sum { |epic| epic[:features].count }
      total_user_stories = data[:epics].sum do |epic|
        epic[:features].sum { |feature| feature[:user_stories].count }
      end

      {
        epics: total_epics,
        features: total_features,
        user_stories: total_user_stories
      }
    end

    def calculate_epic_statistics(epic_data)
      features = epic_data[:features]

      {
        total_features: features.count,
        completed_features: features.count { |f| f[:issue][:status].in?(['Resolved', 'Closed']) },
        completion_ratio: calculate_completion_ratio(features)
      }
    end

    def calculate_feature_completion(feature_data)
      user_stories = feature_data[:user_stories]
      return 0 if user_stories.empty?

      completed_count = user_stories.count { |us| us[:issue][:status].in?(['Resolved', 'Closed']) }
      (completed_count.to_f / user_stories.count * 100).round(1)
    end

    def calculate_user_story_completion(us_data)
      children_count = us_data[:tasks].count + us_data[:tests].count
      return 0 if children_count == 0

      completed_count = (us_data[:tasks] + us_data[:tests]).count do |child|
        child[:status].in?(['Resolved', 'Closed'])
      end

      (completed_count.to_f / children_count * 100).round(1)
    end

    def calculate_completion_ratio(items)
      return 0 if items.empty?

      completed_count = items.count { |item| item[:issue][:status].in?(['Resolved', 'Closed']) }
      (completed_count.to_f / items.count * 100).round(1)
    end

    def assess_feature_risk(feature_data)
      risk_factors = []

      # 期限遅れリスク
      if feature_data[:issue][:fixed_version_id]
        version = Version.find_by(id: feature_data[:issue][:fixed_version_id])
        if version&.effective_date && version.effective_date < Date.current
          risk_factors << 'overdue_version'
        end
      end

      # 未割当リスク
      if feature_data[:user_stories].any? { |us| us[:issue][:assigned_to_id].nil? }
        risk_factors << 'unassigned_user_stories'
      end

      # テスト不足リスク
      if feature_data[:user_stories].any? { |us| us[:tests].empty? }
        risk_factors << 'missing_tests'
      end

      {
        level: calculate_risk_level(risk_factors),
        factors: risk_factors
      }
    end

    def calculate_risk_level(factors)
      case factors.count
      when 0
        'low'
      when 1
        'medium'
      else
        'high'
      end
    end

    def project_metadata
      {
        id: @project.id,
        name: @project.name,
        identifier: @project.identifier,
        trackers: @project.trackers.pluck(:id, :name),
        versions: @project.versions.pluck(:id, :name),
        members: @project.users.pluck(:id, :firstname, :lastname)
      }
    end

    def user_metadata
      {
        id: User.current.id,
        name: User.current.name,
        firstname: User.current.firstname,
        lastname: User.current.lastname
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
  end
end