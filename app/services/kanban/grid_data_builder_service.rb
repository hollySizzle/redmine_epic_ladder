# frozen_string_literal: true

module Kanban
  # グリッドデータ構築サービス
  class GridDataBuilderService
    def initialize(project, current_user)
      @project = project
      @current_user = current_user
    end

    def build
      {
        epics: build_epics_with_features,
        versions: build_versions_data,
        matrix: build_matrix_data,
        columns: build_kanban_columns
      }
    end

    private

    def build_epics_with_features
      @project.issues
              .joins(:tracker)
              .where(trackers: { name: 'Epic' })
              .includes(:children, :fixed_version, :status, :assigned_to)
              .map do |epic|
        {
          issue: serialize_issue(epic),
          features: build_features_for_epic(epic)
        }
      end
    end

    def build_features_for_epic(epic)
      epic.children
          .joins(:tracker)
          .where(trackers: { name: 'Feature' })
          .includes(:children, :fixed_version, :status, :assigned_to)
          .map do |feature|
        {
          issue: serialize_issue(feature),
          user_stories: build_user_stories_for_feature(feature)
        }
      end
    end

    def build_user_stories_for_feature(feature)
      feature.children
             .joins(:tracker)
             .where(trackers: { name: 'UserStory' })
             .includes(:children, :fixed_version, :status, :assigned_to)
             .map do |user_story|
        {
          issue: serialize_issue(user_story),
          tasks: serialize_child_issues(user_story, 'Task'),
          tests: serialize_child_issues(user_story, 'Test'),
          bugs: serialize_child_issues(user_story, 'Bug')
        }
      end
    end

    def build_versions_data
      @project.versions
              .where(status: 'open')
              .order(:effective_date)
              .map do |version|
        {
          id: version.id,
          name: version.name,
          description: version.description,
          effective_date: version.effective_date&.iso8601,
          status: version.status
        }
      end
    end

    def build_matrix_data
      epics = @project.issues.joins(:tracker).where(trackers: { name: 'Epic' })
      versions = @project.versions.where(status: 'open')

      matrix = {}
      epics.each do |epic|
        matrix[epic.id] = {}
        versions.each do |version|
          matrix[epic.id][version.id] = {
            feature_count: count_features_in_cell(epic, version)
          }
        end
      end

      matrix
    end

    def build_kanban_columns
      [
        { id: 'backlog', title: 'バックログ', statuses: ['New', 'Open'] },
        { id: 'ready', title: '準備完了', statuses: ['Ready'] },
        { id: 'in_progress', title: '進行中', statuses: ['In Progress', 'Assigned'] },
        { id: 'review', title: 'レビュー', statuses: ['Review', 'Ready for Test'] },
        { id: 'testing', title: 'テスト中', statuses: ['Testing', 'QA'] },
        { id: 'done', title: '完了', statuses: ['Resolved', 'Closed'] }
      ]
    end

    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        fixed_version: issue.fixed_version&.name,
        parent_id: issue.parent_id,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        lock_version: issue.lock_version
      }
    end

    def serialize_child_issues(parent_issue, tracker_name)
      parent_issue.children
                  .joins(:tracker)
                  .where(trackers: { name: tracker_name })
                  .map { |issue| serialize_issue(issue) }
    end

    def count_features_in_cell(epic, version)
      epic.children
          .joins(:tracker)
          .where(trackers: { name: 'Feature' }, fixed_version_id: version.id)
          .count
    end
  end
end