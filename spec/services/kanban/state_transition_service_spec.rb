# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::StateTransitionService, type: :service do
  include KanbanTestHelpers

  let!(:project) { Project.create!(name: 'Test Project', identifier: 'test-state-transition') }
  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }
  let!(:priority) { IssuePriority.create!(name: 'Normal', is_default: true) }

  # ステータス作成
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false, position: 1) }
  let!(:status_open) { IssueStatus.create!(name: 'Open', is_closed: false, position: 2) }
  let!(:status_ready) { IssueStatus.create!(name: 'Ready', is_closed: false, position: 3) }
  let!(:status_in_progress) { IssueStatus.create!(name: 'In Progress', is_closed: false, position: 4) }
  let!(:status_assigned) { IssueStatus.create!(name: 'Assigned', is_closed: false, position: 5) }
  let!(:status_review) { IssueStatus.create!(name: 'Review', is_closed: false, position: 6) }
  let!(:status_ready_for_test) { IssueStatus.create!(name: 'Ready for Test', is_closed: false, position: 7) }
  let!(:status_testing) { IssueStatus.create!(name: 'Testing', is_closed: false, position: 8) }
  let!(:status_qa) { IssueStatus.create!(name: 'QA', is_closed: false, position: 9) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true, position: 10) }
  let!(:status_closed) { IssueStatus.create!(name: 'Closed', is_closed: true, position: 11) }
  let!(:status_failed) { IssueStatus.create!(name: 'Failed', is_closed: false, position: 12) }

  # トラッカー作成
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 1, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 2, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 3, is_in_chlog: false) }

  # ワークフロー設定（全てのロールで全ての状態遷移を許可）
  let!(:role) { Role.create!(name: 'Test Role', permissions: [:edit_issues]) }

  before do
    User.current = user
    # 全ての状態遷移を許可するワークフローを設定
    [user_story_tracker, task_tracker, test_tracker].each do |tracker|
      [status_new, status_open, status_ready, status_in_progress, status_assigned,
       status_review, status_ready_for_test, status_testing, status_qa,
       status_resolved, status_closed, status_failed].each do |from_status|
        [status_new, status_open, status_ready, status_in_progress, status_assigned,
         status_review, status_ready_for_test, status_testing, status_qa,
         status_resolved, status_closed, status_failed].each do |to_status|
          WorkflowTransition.find_or_create_by(
            tracker: tracker,
            role: role,
            old_status: from_status,
            new_status: to_status
          )
        end
      end
    end

    # テストユーザーをプロジェクトに追加
    Member.create!(
      project: project,
      user: user,
      roles: [role]
    )
  end

  # UserStory作成
  let!(:user_story) do
    Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_new,
      subject: 'Test UserStory',
      author: user,
      priority: priority
    )
  end

  describe '.transition_to_column' do
    context '正常ケース' do
      it 'backlogカラムへの遷移（New状態）' do
        user_story.update!(status: status_ready)

        result = described_class.transition_to_column(user_story, 'backlog')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to be_in(['New', 'Open'])
      end

      it 'readyカラムへの遷移（Ready状態）' do
        result = described_class.transition_to_column(user_story, 'ready')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to eq('Ready')
      end

      it 'in_progressカラムへの遷移（In Progress or Assigned状態）' do
        result = described_class.transition_to_column(user_story, 'in_progress')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to be_in(['In Progress', 'Assigned'])
      end

      it 'reviewカラムへの遷移（Review or Ready for Test状態）' do
        result = described_class.transition_to_column(user_story, 'review')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to be_in(['Review', 'Ready for Test'])
      end

      it 'testingカラムへの遷移（Testing or QA状態）' do
        result = described_class.transition_to_column(user_story, 'testing')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to be_in(['Testing', 'QA'])
      end

      it 'doneカラムへの遷移（Resolved or Closed状態）' do
        result = described_class.transition_to_column(user_story, 'done')

        expect(result[:error]).to be_nil
        expect(result[:success]).to be true
        user_story.reload
        expect(user_story.status.name).to be_in(['Resolved', 'Closed'])
      end

      it '既に適切な状態の場合は遷移しない' do
        user_story.update!(status: status_ready)
        original_updated_at = user_story.updated_on

        result = described_class.transition_to_column(user_story, 'ready')

        expect(result[:unchanged]).to be true
        expect(result[:current_status]).to eq('Ready')
        user_story.reload
        expect(user_story.updated_on).to eq(original_updated_at)
      end

      it '遷移前後の状態が返される' do
        user_story.update!(status: status_new)

        result = described_class.transition_to_column(user_story, 'in_progress')

        expect(result[:old_status]).to eq('New')
        expect(result[:new_status]).to be_in(['In Progress', 'Assigned'])
      end
    end

    context '異常ケース' do
      it '不正なカラム名でエラーを返す' do
        result = described_class.transition_to_column(user_story, 'invalid_column')

        expect(result[:error]).to eq('不正なカラム')
      end

      it '遷移可能な状態がない場合はエラーを返す' do
        # 全ての遷移を無効にする
        WorkflowTransition.delete_all

        result = described_class.transition_to_column(user_story, 'ready')

        expect(result[:error]).to eq('遷移可能な状態がありません')
      end

      it 'データベースエラーが発生した場合はエラーを返す' do
        allow(user_story).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user_story))

        result = described_class.transition_to_column(user_story, 'ready')

        expect(result[:error]).to be_present
      end
    end
  end

  describe '.check_transition_blocks' do
    context 'UserStoryの子Task完了チェック' do
      let!(:completed_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Completed Task',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      let!(:incomplete_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: 'Incomplete Task',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it 'Testing状態への遷移時、未完了Taskがある場合はブロックする' do
        result = described_class.check_transition_blocks(user_story, status_testing)

        expect(result[:blocked]).to be true
        expect(result[:blocks]).to include('未完了のTask: Incomplete Task')
      end

      it 'Resolved状態への遷移時、未完了Taskがある場合はブロックする' do
        result = described_class.check_transition_blocks(user_story, status_resolved)

        expect(result[:blocked]).to be true
        expect(result[:blocks]).to include('未完了のTask: Incomplete Task')
      end

      it '全Taskが完了している場合はブロックしない' do
        incomplete_task.update!(status: status_resolved)

        result = described_class.check_transition_blocks(user_story, status_testing)

        expect(result[:blocked]).to be false
        expect(result[:blocks]).to be_empty
      end

      it '子Taskが存在しない場合はブロックしない' do
        completed_task.destroy
        incomplete_task.destroy

        result = described_class.check_transition_blocks(user_story, status_testing)

        expect(result[:blocked]).to be false
        expect(result[:blocks]).to be_empty
      end
    end

    context 'UserStoryのTest合格チェック' do
      let!(:passed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_resolved,
          subject: 'Passed Test',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      let!(:failed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_failed,
          subject: 'Failed Test',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it 'Resolved状態への遷移時、失敗したTestがある場合はブロックする' do
        result = described_class.check_transition_blocks(user_story, status_resolved)

        expect(result[:blocked]).to be true
        expect(result[:blocks]).to include('失敗したTest: Failed Test')
      end

      it '全Testが合格している場合はブロックしない' do
        failed_test.update!(status: status_resolved)

        result = described_class.check_transition_blocks(user_story, status_resolved)

        expect(result[:blocked]).to be false
        expect(result[:blocks]).to be_empty
      end

      it 'Testing状態への遷移はTestの状態をチェックしない' do
        result = described_class.check_transition_blocks(user_story, status_testing)

        # Testの失敗はチェックされない（Testing状態は対象外）
        test_blocks = result[:blocks].select { |block| block.include?('失敗したTest') }
        expect(test_blocks).to be_empty
      end
    end

    context '複合的なブロック条件' do
      let!(:incomplete_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: 'Incomplete Task',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      let!(:failed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_failed,
          subject: 'Failed Test',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it '複数のブロック条件が同時に発生する場合、全てをブロック理由に含む' do
        result = described_class.check_transition_blocks(user_story, status_resolved)

        expect(result[:blocked]).to be true
        expect(result[:blocks]).to include('未完了のTask: Incomplete Task')
        expect(result[:blocks]).to include('失敗したTest: Failed Test')
      end
    end

    context 'Task以外のトラッカーでの動作' do
      let!(:task_issue) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task Issue',
          author: user,
          priority: priority
        )
      end

      it 'Task自体の遷移では子要素チェックをしない' do
        result = described_class.check_transition_blocks(task_issue, status_resolved)

        expect(result[:blocked]).to be false
        expect(result[:blocks]).to be_empty
      end
    end
  end

  describe 'COLUMN_STATUS_MAPPINGの検証' do
    it '正しいマッピング構造を持っている' do
      mapping = described_class::COLUMN_STATUS_MAPPING

      expect(mapping['backlog']).to include('New', 'Open')
      expect(mapping['ready']).to include('Ready')
      expect(mapping['in_progress']).to include('In Progress', 'Assigned')
      expect(mapping['review']).to include('Review', 'Ready for Test')
      expect(mapping['testing']).to include('Testing', 'QA')
      expect(mapping['done']).to include('Resolved', 'Closed')
    end

    it '全てのカラムが定義されている' do
      expected_columns = %w[backlog ready in_progress review testing done]
      actual_columns = described_class::COLUMN_STATUS_MAPPING.keys

      expect(actual_columns).to contain_exactly(*expected_columns)
    end
  end

  describe 'プライベートメソッドのテスト', :private do
    describe 'find_available_status' do
      it '遷移可能な状態から優先して選択する' do
        available_statuses = [status_in_progress, status_assigned]
        target_statuses = ['In Progress', 'Assigned']

        result = described_class.send(:find_available_status, user_story, target_statuses)

        expect(result).to be_in([status_in_progress, status_assigned])
      end

      it '遷移可能な状態がない場合はnilを返す' do
        # 遷移を制限
        WorkflowTransition.delete_all

        target_statuses = ['In Progress']
        result = described_class.send(:find_available_status, user_story, target_statuses)

        expect(result).to be_nil
      end
    end
  end

  describe 'パフォーマンステスト', :performance do
    it '大量の子要素があってもブロックチェックが高速' do
      # 100個の子Taskを作成
      100.times do |i|
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: "Task #{i}",
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      expect do
        described_class.check_transition_blocks(user_story, status_resolved)
      end.to perform_under(100).ms
    end
  end
end