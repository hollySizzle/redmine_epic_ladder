# frozen_string_literal: true

module Kanban
  # Test自動生成サービス
  # UserStory作成時のTest自動生成とblocks関係作成
  class TestGenerationService
    TEMPLATE_CONFIGS = {
      default: {
        subject_template: 'Test: %{user_story_subject}',
        description_template: "ユーザーストーリー: %{user_story_subject}\n\n受入条件:\n- [ ] 機能が正常に動作する\n- [ ] エラーハンドリングが適切\n- [ ] UIが仕様通り"
      }
    }.freeze

    # UserStoryに対応するTestを自動生成
    def self.generate_test_for_user_story(user_story, options = {})
      return { error: 'UserStoryではありません' } unless user_story.tracker.name == 'UserStory'

      existing_test = find_existing_test(user_story)
      return { test_issue: existing_test, existing: true } if existing_test && !options[:force_recreate]

      ActiveRecord::Base.transaction do
        test_issue = create_test_issue(user_story, options)
        create_blocks_relation(test_issue, user_story)
        propagate_version_to_test(test_issue, user_story)

        Rails.logger.info "Test自動生成完了: UserStory##{user_story.id} -> Test##{test_issue.id}"

        { test_issue: test_issue, relation_created: true }
      end
    rescue => e
      Rails.logger.error "Test自動生成エラー: #{e.message}"
      { error: e.message }
    end

    # Ready for Test状態移動時のTest存在確認
    def self.ensure_test_exists_for_ready_state(user_story)
      return { error: 'UserStoryではありません' } unless user_story.tracker.name == 'UserStory'
      return { test_issue: find_existing_test(user_story), existing: true } if find_existing_test(user_story)

      generate_test_for_user_story(user_story, auto_generated: true)
    end

    # 既存Testの検索
    def self.find_existing_test(user_story)
      user_story.children.joins(:tracker).find_by(trackers: { name: 'Test' })
    end

    private

    def self.create_test_issue(user_story, options)
      template = TEMPLATE_CONFIGS[:default]
      test_tracker = Tracker.find_by!(name: 'Test')

      Issue.create!(
        project: user_story.project,
        tracker: test_tracker,
        subject: template[:subject_template] % { user_story_subject: user_story.subject },
        description: template[:description_template] % { user_story_subject: user_story.subject },
        author: User.current,
        assigned_to: options[:assigned_to] || user_story.assigned_to,
        priority: user_story.priority,
        parent: user_story,
        status: IssueStatus.find_by(name: 'New') || IssueStatus.first
      )
    end

    def self.create_blocks_relation(test_issue, user_story)
      IssueRelation.create!(
        issue_from: test_issue,
        issue_to: user_story,
        relation_type: 'blocks'
      )
    end

    def self.propagate_version_to_test(test_issue, user_story)
      return unless user_story.fixed_version

      test_issue.update!(fixed_version: user_story.fixed_version)
    end
  end
end