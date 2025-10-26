# frozen_string_literal: true

module Kanban
  module Hooks
    # Issueの操作フック
    # 作成・更新時の自動処理トリガー
    class IssueHooks < Redmine::Hook::ViewListener
      # Issue作成後の処理
      def controller_issues_new_after_save(context = {})
        issue = context[:issue]
        return unless issue.persisted?

        trigger_creation_hooks(issue)
      end

      # Issue更新後の処理
      def controller_issues_edit_after_save(context = {})
        issue = context[:issue]

        handle_status_change(issue) if issue.saved_change_to_status_id?
        handle_version_change(issue) if issue.saved_change_to_fixed_version_id?
        validate_hierarchy_change(issue) if issue.saved_change_to_parent_id?
      end

      private

      def trigger_creation_hooks(issue)
        tracker_names = EpicGrid::TrackerHierarchy.tracker_names
        case issue.tracker.name
        when tracker_names[:user_story]
          trigger_user_story_creation(issue)
        when tracker_names[:bug]
          trigger_bug_creation(issue)
        end
      end

      def trigger_user_story_creation(user_story)
        # Test自動生成をバックグラウンドで実行
        TestGenerationJob.perform_later(user_story)

        Rails.logger.info "UserStory作成Hook実行: ##{user_story.id}"
      end

      def trigger_bug_creation(bug)
        # Bug関連付け処理
        user_story_tracker_name = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
        if bug.parent&.tracker&.name == user_story_tracker_name
          create_bug_blocks_relation(bug, bug.parent)
        end

        Rails.logger.info "Bug作成Hook実行: ##{bug.id}"
      end

      def handle_status_change(issue)
        user_story_tracker_name = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
        if issue.tracker.name == user_story_tracker_name && moved_to_ready_for_test?(issue)
          TestGenerationService.ensure_test_exists_for_ready_state(issue)
        end
      end

      def handle_version_change(issue)
        user_story_tracker_name = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
        if issue.tracker.name == user_story_tracker_name
          version = issue.fixed_version
          # TODO: Implement version propagation to children
          # See: vibes/docs/temps/backend_file_structure.md:173
          # Plan: Move to Issue#propagate_version_to_children
          # VersionPropagationService.propagate_to_children(issue, version)
        end
      end

      def validate_hierarchy_change(issue)
        unless EpicGrid::TrackerHierarchy.validate_hierarchy(issue)
          Rails.logger.warn "階層制約違反: Issue##{issue.id} - #{issue.tracker.name} -> #{issue.parent&.tracker&.name}"
        end
      end

      def moved_to_ready_for_test?(issue)
        ready_statuses = ['Ready for Test', 'Testing', 'QA Ready']
        current_status = issue.status.name
        previous_status_id = issue.status_id_before_last_save

        return false unless ready_statuses.include?(current_status)
        return true unless previous_status_id

        previous_status = IssueStatus.find(previous_status_id).name
        !ready_statuses.include?(previous_status)
      end

      def create_bug_blocks_relation(bug, user_story)
        return if IssueRelation.exists?(
          issue_from: bug,
          issue_to: user_story,
          relation_type: 'blocks'
        )

        IssueRelation.create!(
          issue_from: bug,
          issue_to: user_story,
          relation_type: 'blocks'
        )

        Rails.logger.info "Bug blocks関係作成: Bug##{bug.id} blocks UserStory##{user_story.id}"
      end
    end
  end
end