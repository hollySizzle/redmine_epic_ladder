# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::ValidationGuardService, type: :service do
  include KanbanTestHelpers

  let!(:project) { Project.create!(name: 'Test Project', identifier: 'test-validation-guard') }
  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }

  # ステータス作成
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false) }
  let!(:status_in_progress) { IssueStatus.create!(name: 'In Progress', is_closed: false) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true) }
  let!(:status_closed) { IssueStatus.create!(name: 'Closed', is_closed: true) }
  let!(:status_passed) { IssueStatus.create!(name: 'Passed', is_closed: true) }
  let!(:status_failed) { IssueStatus.create!(name: 'Failed', is_closed: false) }

  # 優先度作成
  let!(:priority_normal) { IssuePriority.create!(name: 'Normal', position: 1, is_default: true) }
  let!(:priority_high) { IssuePriority.create!(name: 'High', position: 2) }
  let!(:priority_urgent) { IssuePriority.create!(name: 'Urgent', position: 3) }
  let!(:priority_immediate) { IssuePriority.create!(name: 'Immediate', position: 4) }

  # トラッカー作成
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 1, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 2, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 3, is_in_chlog: false) }
  let!(:bug_tracker) { Tracker.create!(name: 'Bug', position: 4, is_in_chlog: false) }

  # UserStory作成
  let!(:user_story) do
    Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_in_progress,
      subject: 'Test UserStory',
      author: user,
      priority: priority_normal
    )
  end

  before do
    User.current = user
  end

  describe '.validate_release_readiness' do
    context '全ての検証に合格する場合' do
      let!(:completed_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Completed Task',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:passed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_passed,
          subject: 'Passed Test',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it 'リリース準備完了として判定される' do
        result = described_class.validate_release_readiness(user_story)

        expect(result[:release_ready]).to be true
        expect(result[:blocking_issues]).to be_empty
        expect(result[:summary]).to eq('3/3層のガードを通過')

        # 各層の詳細検証
        expect(result[:validation_results][:task_completion][:passed]).to be true
        expect(result[:validation_results][:test_validation][:passed]).to be true
        expect(result[:validation_results][:bug_resolution][:passed]).to be true
      end
    end

    context 'Task完了検証（レイヤー1）' do
      let!(:completed_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Completed Task',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:incomplete_task1) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: 'Incomplete Task 1',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:incomplete_task2) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Incomplete Task 2',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it '未完了Taskが存在する場合は検証に失敗する' do
        result = described_class.validate_release_readiness(user_story)

        task_result = result[:validation_results][:task_completion]
        expect(task_result[:passed]).to be false
        expect(task_result[:layer]).to eq(1)
        expect(task_result[:name]).to eq('Task完了検証')
        expect(task_result[:count][:total]).to eq(3)
        expect(task_result[:count][:incomplete]).to eq(2)

        # ブロッキング要因の詳細
        expect(task_result[:issues]).to have(2).items
        expect(task_result[:issues][0][:subject]).to eq('Incomplete Task 1')
        expect(task_result[:issues][0][:tracker]).to eq('Task')
        expect(task_result[:issues][0][:status]).to eq('In Progress')
        expect(task_result[:issues][0][:reason]).to eq('タスク未完了')
      end

      it '全Taskが完了している場合は検証に合格する' do
        [incomplete_task1, incomplete_task2].each { |task| task.update!(status: status_resolved) }

        result = described_class.validate_release_readiness(user_story)

        task_result = result[:validation_results][:task_completion]
        expect(task_result[:passed]).to be true
        expect(task_result[:issues]).to be_empty
      end

      it 'Taskが存在しない場合は検証に合格する' do
        [completed_task, incomplete_task1, incomplete_task2].each(&:destroy)

        result = described_class.validate_release_readiness(user_story)

        task_result = result[:validation_results][:task_completion]
        expect(task_result[:passed]).to be true
        expect(task_result[:count][:total]).to eq(0)
      end
    end

    context 'Test合格検証（レイヤー2）' do
      let!(:passed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_passed,
          subject: 'Passed Test',
          author: user,
          parent: user_story,
          priority: priority_normal
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
          priority: priority_normal
        )
      end

      let!(:incomplete_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_in_progress,
          subject: 'Incomplete Test',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it '失敗または未完了のTestが存在する場合は検証に失敗する' do
        result = described_class.validate_release_readiness(user_story)

        test_result = result[:validation_results][:test_validation]
        expect(test_result[:passed]).to be false
        expect(test_result[:layer]).to eq(2)
        expect(test_result[:name]).to eq('Test合格検証')
        expect(test_result[:count][:total]).to eq(3)
        expect(test_result[:count][:failed]).to eq(2)

        expect(test_result[:issues]).to have(2).items
        expect(test_result[:issues].map { |i| i[:subject] }).to contain_exactly('Failed Test', 'Incomplete Test')
      end

      it '全Testが合格している場合は検証に合格する' do
        [failed_test, incomplete_test].each { |test| test.update!(status: status_passed) }

        result = described_class.validate_release_readiness(user_story)

        test_result = result[:validation_results][:test_validation]
        expect(test_result[:passed]).to be true
        expect(test_result[:issues]).to be_empty
      end

      it 'Testが存在しない場合は警告付きで検証に失敗する' do
        [passed_test, failed_test, incomplete_test].each(&:destroy)

        result = described_class.validate_release_readiness(user_story)

        test_result = result[:validation_results][:test_validation]
        expect(test_result[:passed]).to be false
        expect(test_result[:warning]).to eq('Testが存在しません')
        expect(test_result[:count][:total]).to eq(0)
      end
    end

    context '重大Bug解決検証（レイヤー3）' do
      let!(:normal_bug) do
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_new,
          subject: 'Normal Bug',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:high_bug_resolved) do
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_resolved,
          subject: 'High Bug Resolved',
          author: user,
          parent: user_story,
          priority: priority_high
        )
      end

      let!(:urgent_bug_unresolved) do
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_in_progress,
          subject: 'Urgent Bug Unresolved',
          author: user,
          parent: user_story,
          priority: priority_urgent
        )
      end

      let!(:immediate_bug_unresolved) do
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_new,
          subject: 'Immediate Bug Unresolved',
          author: user,
          parent: user_story,
          priority: priority_immediate
        )
      end

      it '重大Bug（High/Urgent/Immediate）が未解決の場合は検証に失敗する' do
        result = described_class.validate_release_readiness(user_story)

        bug_result = result[:validation_results][:bug_resolution]
        expect(bug_result[:passed]).to be false
        expect(bug_result[:layer]).to eq(3)
        expect(bug_result[:name]).to eq('重大Bug解決検証')
        expect(bug_result[:count][:unresolved]).to eq(2)

        expect(bug_result[:issues]).to have(2).items
        urgent_issue = bug_result[:issues].find { |i| i[:subject] == 'Urgent Bug Unresolved' }
        expect(urgent_issue[:reason]).to include('重大Bug未解決 (優先度: Urgent)')
      end

      it '重大Bugが全て解決している場合は検証に合格する' do
        [urgent_bug_unresolved, immediate_bug_unresolved].each { |bug| bug.update!(status: status_resolved) }

        result = described_class.validate_release_readiness(user_story)

        bug_result = result[:validation_results][:bug_resolution]
        expect(bug_result[:passed]).to be true
        expect(bug_result[:issues]).to be_empty
      end

      it 'Normal優先度のBugは検証対象外' do
        # 重大Bugを全て削除し、Normal Bugのみ残す
        [high_bug_resolved, urgent_bug_unresolved, immediate_bug_unresolved].each(&:destroy)

        result = described_class.validate_release_readiness(user_story)

        bug_result = result[:validation_results][:bug_resolution]
        expect(bug_result[:passed]).to be true # Normal Bugは対象外
        expect(bug_result[:count][:unresolved]).to eq(0)
      end
    end

    context '異常ケース' do
      let!(:task_issue) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task Issue',
          author: user,
          priority: priority_normal
        )
      end

      it 'UserStory以外のトラッカーではエラーを返す' do
        result = described_class.validate_release_readiness(task_issue)

        expect(result[:error]).to eq('UserStoryではありません')
      end
    end
  end

  describe '.attempt_guard_bypass' do
    let!(:incomplete_task) do
      Issue.create!(
        project: project,
        tracker: task_tracker,
        status: status_in_progress,
        subject: 'Incomplete Task',
        author: user,
        parent: user_story,
        priority: priority_normal
      )
    end

    context '強制突破' do
      it 'force_bypassフラグとreason指定で強制突破できる' do
        result = described_class.attempt_guard_bypass(
          user_story,
          force_bypass: true,
          bypass_reason: 'Hotfix for critical issue'
        )

        expect(result[:bypassed]).to be true
        expect(result[:reason]).to eq('Hotfix for critical issue')
        expect(result[:original_validation][:release_ready]).to be false
      end

      it 'force_bypassがtrueでもreasonがない場合は突破できない' do
        result = described_class.attempt_guard_bypass(
          user_story,
          force_bypass: true
        )

        expect(result[:bypassed]).to be false
      end

      it '強制突破時にログが出力される' do
        expect(Rails.logger).to receive(:warn).with(
          "Forced validation bypass: UserStory##{user_story.id}, Reason: Emergency hotfix"
        )

        described_class.attempt_guard_bypass(
          user_story,
          force_bypass: true,
          bypass_reason: 'Emergency hotfix'
        )
      end
    end

    context '自動突破' do
      it '現在の実装では自動突破は許可されない' do
        result = described_class.attempt_guard_bypass(user_story)

        expect(result[:bypassed]).to be false
        expect(result[:validation][:release_ready]).to be false
      end
    end

    it '検証に合格している場合は突破不要' do
      incomplete_task.update!(status: status_resolved)

      result = described_class.attempt_guard_bypass(user_story)

      expect(result[:bypassed]).to be false
      expect(result[:validation][:release_ready]).to be true
    end
  end

  describe '個別検証メソッド' do
    describe '.validate_task_completion' do
      let!(:task1) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Task 1',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:task2) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: 'Task 2',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it '正しいTask完了情報を返す' do
        result = described_class.validate_task_completion(user_story)

        expect(result[:layer]).to eq(1)
        expect(result[:name]).to eq('Task完了検証')
        expect(result[:passed]).to be false
        expect(result[:count][:total]).to eq(2)
        expect(result[:count][:incomplete]).to eq(1)
        expect(result[:issues]).to have(1).item
      end
    end

    describe '.validate_test_success' do
      let!(:test1) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_passed,
          subject: 'Test 1',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it '正しいTest検証情報を返す' do
        result = described_class.validate_test_success(user_story)

        expect(result[:layer]).to eq(2)
        expect(result[:name]).to eq('Test合格検証')
        expect(result[:passed]).to be true
        expect(result[:count][:total]).to eq(1)
        expect(result[:count][:failed]).to eq(0)
      end
    end

    describe '.validate_critical_bugs' do
      let!(:high_bug) do
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_new,
          subject: 'High Priority Bug',
          author: user,
          parent: user_story,
          priority: priority_high
        )
      end

      it '正しい重大Bug検証情報を返す' do
        result = described_class.validate_critical_bugs(user_story)

        expect(result[:layer]).to eq(3)
        expect(result[:name]).to eq('重大Bug解決検証')
        expect(result[:passed]).to be false
        expect(result[:count][:unresolved]).to eq(1)
        expect(result[:issues]).to have(1).item
      end
    end
  end

  describe 'プライベートメソッドのテスト', :private do
    describe 'count_child_tasks' do
      let!(:task1) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task 1',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:task2) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Task 2',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:test_issue) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Test Issue',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it 'Taskトラッカーの子要素のみをカウントする' do
        count = described_class.send(:count_child_tasks, user_story)
        expect(count).to eq(2) # Testは含まれない
      end
    end

    describe 'format_issue_info' do
      let!(:task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Test Task',
          author: user,
          priority: priority_normal
        )
      end

      it '正しい形式でIssue情報をフォーマットする' do
        info = described_class.send(:format_issue_info, task, 'Test reason')

        expect(info[:id]).to eq(task.id)
        expect(info[:subject]).to eq('Test Task')
        expect(info[:tracker]).to eq('Task')
        expect(info[:status]).to eq('New')
        expect(info[:reason]).to eq('Test reason')
      end
    end

    describe 'generate_validation_summary' do
      it '正しいサマリーを生成する' do
        results = {
          task_completion: { passed: true },
          test_validation: { passed: false },
          bug_resolution: { passed: true }
        }

        summary = described_class.send(:generate_validation_summary, results)
        expect(summary).to eq('2/3層のガードを通過')
      end
    end
  end

  describe 'パフォーマンステスト', :performance do
    it '大量の子要素でも高速にバリデーションできる' do
      # 50個ずつ作成
      50.times do |i|
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_in_progress,
          subject: "Task #{i}",
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      50.times do |i|
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_failed,
          subject: "Test #{i}",
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      50.times do |i|
        Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_new,
          subject: "Bug #{i}",
          author: user,
          parent: user_story,
          priority: priority_high
        )
      end

      expect do
        described_class.validate_release_readiness(user_story)
      end.to perform_under(200).ms
    end
  end
end