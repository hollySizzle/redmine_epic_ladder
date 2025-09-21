# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kanban Workflow Integration', type: :integration do
  include KanbanTestHelpers

  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }
  let!(:project) { Project.create!(name: 'Integration Test Project', identifier: 'integration-test') }

  # ステータス作成
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false) }
  let!(:status_ready) { IssueStatus.create!(name: 'Ready', is_closed: false) }
  let!(:status_in_progress) { IssueStatus.create!(name: 'In Progress', is_closed: false) }
  let!(:status_testing) { IssueStatus.create!(name: 'Testing', is_closed: false) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true) }
  let!(:status_closed) { IssueStatus.create!(name: 'Closed', is_closed: true) }

  # 優先度作成
  let!(:priority_normal) { IssuePriority.create!(name: 'Normal', position: 1, is_default: true) }
  let!(:priority_high) { IssuePriority.create!(name: 'High', position: 2) }

  # トラッカー作成
  let!(:epic_tracker) { Tracker.create!(name: 'Epic', position: 1, is_in_chlog: false) }
  let!(:feature_tracker) { Tracker.create!(name: 'Feature', position: 2, is_in_chlog: false) }
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 3, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 4, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 5, is_in_chlog: false) }
  let!(:bug_tracker) { Tracker.create!(name: 'Bug', position: 6, is_in_chlog: false) }

  # バージョン作成
  let!(:version_v1) { Version.create!(project: project, name: 'v1.0', effective_date: 1.month.from_now) }

  before do
    User.current = user

    # プロジェクトにトラッカーを関連付け
    project.trackers = [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]

    # 基本的な階層構造を作成
    @epic = Issue.create!(
      project: project,
      tracker: epic_tracker,
      status: status_new,
      subject: 'Test Epic',
      author: user,
      priority: priority_normal
    )

    @feature = Issue.create!(
      project: project,
      tracker: feature_tracker,
      status: status_new,
      subject: 'Test Feature',
      author: user,
      parent: @epic,
      priority: priority_normal
    )

    @user_story = Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_new,
      subject: 'Test UserStory',
      author: user,
      parent: @feature,
      priority: priority_normal
    )
  end

  describe '完全なワークフロー統合テスト' do
    context 'UserStory -> Task -> Test -> Release の完全フロー' do
      it '階層制約、自動生成、状態遷移、バージョン伝播、検証ガードが連携動作する' do
        # Step 1: UserStoryにバージョンを割り当て
        result = Kanban::VersionPropagationService.propagate_to_children(@user_story, version_v1)
        expect(result[:error]).to be_nil

        @user_story.update!(fixed_version: version_v1)

        # Step 2: TaskをUserStoryの子として作成（階層制約チェック）
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Implementation Task',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        # 階層制約が正しく機能
        expect(Kanban::TrackerHierarchy.validate_hierarchy(task)).to be true

        # バージョンが伝播されている
        task.reload
        expect(task.fixed_version).to eq(version_v1)

        # Step 3: Test自動生成
        test_result = Kanban::TestGenerationService.generate_test_for_user_story(@user_story)
        expect(test_result[:error]).to be_nil

        test_issue = test_result[:test_issue]
        expect(test_issue.parent).to eq(@user_story)
        expect(test_issue.fixed_version).to eq(version_v1)

        # blocks関係が作成されている
        relation = IssueRelation.find_by(issue_from: test_issue, issue_to: @user_story, relation_type: 'blocks')
        expect(relation).to be_present

        # Step 4: UserStoryを Ready for Test に移動（ブロック条件でエラー）
        transition_result = Kanban::StateTransitionService.transition_to_column(@user_story, 'testing')
        expect(transition_result[:blocked]).to be true
        expect(transition_result[:blocks]).to include(match(/未完了のTask/))

        # Step 5: Taskを完了
        task.update!(status: status_resolved)

        # Step 6: 再度 Testing に移動（今度は成功）
        transition_result = Kanban::StateTransitionService.transition_to_column(@user_story, 'testing')
        expect(transition_result[:error]).to be_nil
        expect(transition_result[:success]).to be true

        @user_story.reload
        expect(@user_story.status.name).to eq('Testing')

        # Step 7: リリース準備検証（Test未完了でブロック）
        validation_result = Kanban::ValidationGuardService.validate_release_readiness(@user_story)
        expect(validation_result[:release_ready]).to be false
        expect(validation_result[:validation_results][:test_validation][:passed]).to be false

        # Step 8: Testを完了
        test_issue.update!(status: status_resolved)

        # Step 9: 最終リリース準備検証（全て通過）
        validation_result = Kanban::ValidationGuardService.validate_release_readiness(@user_story)
        expect(validation_result[:release_ready]).to be true
        expect(validation_result[:summary]).to eq('3/3層のガードを通過')

        # Step 10: 最終的にDoneに移動
        transition_result = Kanban::StateTransitionService.transition_to_column(@user_story, 'done')
        expect(transition_result[:error]).to be_nil
        expect(transition_result[:success]).to be true

        @user_story.reload
        expect(@user_story.status.name).to be_in(['Resolved', 'Closed'])
      end
    end

    context 'Bug修正フローとの統合' do
      it 'UserStoryにBugが追加された場合の検証ガード動作' do
        # Taskを作成・完了
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Implementation Task',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        # Testを作成・完了
        test_result = Kanban::TestGenerationService.generate_test_for_user_story(@user_story)
        test_issue = test_result[:test_issue]
        test_issue.update!(status: status_resolved)

        # 重大Bugを追加
        bug = Issue.create!(
          project: project,
          tracker: bug_tracker,
          status: status_new,
          subject: 'Critical Bug',
          author: user,
          parent: @user_story,
          priority: priority_high
        )

        # リリース準備検証（Bug未解決でブロック）
        validation_result = Kanban::ValidationGuardService.validate_release_readiness(@user_story)
        expect(validation_result[:release_ready]).to be false
        expect(validation_result[:validation_results][:bug_resolution][:passed]).to be false

        # Bugを解決
        bug.update!(status: status_resolved)

        # 再検証（全て通過）
        validation_result = Kanban::ValidationGuardService.validate_release_readiness(@user_story)
        expect(validation_result[:release_ready]).to be true
      end
    end

    context '複数UserStoryのバージョン管理統合' do
      it '複数UserStoryでのバージョン一括管理が正しく動作する' do
        # 第2のUserStoryを作成
        user_story_2 = Issue.create!(
          project: project,
          tracker: user_story_tracker,
          status: status_new,
          subject: 'Second UserStory',
          author: user,
          parent: @feature,
          priority: priority_normal
        )

        # 各UserStoryに子要素を作成
        [@user_story, user_story_2].each_with_index do |us, index|
          # Task作成
          Issue.create!(
            project: project,
            tracker: task_tracker,
            status: status_new,
            subject: "Task #{index + 1}",
            author: user,
            parent: us,
            priority: priority_normal
          )

          # Test自動生成
          Kanban::TestGenerationService.generate_test_for_user_story(us)
        end

        # 第1のUserStoryにバージョン割当
        result = Kanban::VersionPropagationService.propagate_to_children(@user_story, version_v1)
        expect(result[:propagated_count]).to eq(2) # Task + Test

        # 第2のUserStoryには伝播されない
        user_story_2.reload
        expect(user_story_2.fixed_version).to be_nil

        # 第2のUserStoryにも個別にバージョン割当
        result = Kanban::VersionPropagationService.propagate_to_children(user_story_2, version_v1)
        expect(result[:propagated_count]).to eq(2) # Task + Test

        # 全ての子要素にバージョンが伝播されている
        [@user_story, user_story_2].each do |us|
          us.children.each do |child|
            expect(child.fixed_version).to eq(version_v1)
          end
        end
      end
    end
  end

  describe '階層制約とサービス連携' do
    context '不正な階層でのサービス呼び出し' do
      it 'Task に対する Test生成要求は拒否される' do
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Test Task',
          author: user,
          priority: priority_normal
        )

        result = Kanban::TestGenerationService.generate_test_for_user_story(task)
        expect(result[:error]).to eq('UserStoryではありません')
      end

      it 'Task に対するバージョン伝播要求は拒否される' do
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Test Task',
          author: user,
          priority: priority_normal
        )

        result = Kanban::VersionPropagationService.propagate_to_children(task, version_v1)
        expect(result[:error]).to eq('UserStoryではありません')
      end

      it 'Task に対するリリース検証要求は拒否される' do
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Test Task',
          author: user,
          priority: priority_normal
        )

        result = Kanban::ValidationGuardService.validate_release_readiness(task)
        expect(result[:error]).to eq('UserStoryではありません')
      end
    end
  end

  describe 'API統合とデータ整合性' do
    context 'API経由での操作が各サービスと正しく連携' do
      let(:api_controller) { Kanban::ApiController.new }

      before do
        allow(api_controller).to receive(:params).and_return(ActionController::Parameters.new)
        allow(api_controller).to receive(:render)
        api_controller.instance_variable_set(:@project, project)
      end

      it 'API経由でのTest生成が正しく動作する' do
        allow(api_controller).to receive(:params).and_return(
          ActionController::Parameters.new(user_story_id: @user_story.id)
        )

        # Test生成APIを実行
        api_controller.generate_test

        # Testが作成されている
        test_issue = Issue.joins(:tracker).find_by(trackers: { name: 'Test' }, parent: @user_story)
        expect(test_issue).to be_present

        # blocks関係も作成されている
        relation = IssueRelation.find_by(issue_from: test_issue, issue_to: @user_story, relation_type: 'blocks')
        expect(relation).to be_present
      end

      it 'API経由でのバージョン割当が正しく動作する' do
        # 子要素を作成
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        allow(api_controller).to receive(:params).and_return(
          ActionController::Parameters.new(issue_id: @user_story.id, version_id: version_v1.id)
        )

        # バージョン割当APIを実行
        api_controller.assign_version

        # UserStoryとTaskにバージョンが設定される
        @user_story.reload
        task.reload
        expect(@user_story.fixed_version).to eq(version_v1)
        expect(task.fixed_version).to eq(version_v1)
      end

      it 'API経由での状態遷移が検証ガードと連携動作する' do
        # 未完了Task作成
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Incomplete Task',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        allow(api_controller).to receive(:params).and_return(
          ActionController::Parameters.new(issue_id: @user_story.id, target_column: 'done')
        )

        # 状態遷移APIを実行（ブロックされる）
        expect(api_controller).to receive(:render).with(
          json: { error: match(/未完了のTask/) },
          status: :unprocessable_entity
        )

        api_controller.transition_issue
      end
    end
  end

  describe 'エラー処理とロールバック' do
    context 'トランザクション制御の確認' do
      it 'Test生成中にエラーが発生した場合、全ての変更がロールバックされる' do
        # blocks関係作成時にエラーを発生させる
        allow(IssueRelation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(IssueRelation.new))

        initial_issue_count = Issue.count
        initial_relation_count = IssueRelation.count

        result = Kanban::TestGenerationService.generate_test_for_user_story(@user_story)

        expect(result[:error]).to be_present
        expect(Issue.count).to eq(initial_issue_count)
        expect(IssueRelation.count).to eq(initial_relation_count)
      end

      it 'バージョン伝播中にエラーが発生した場合、部分的な更新がロールバックされる' do
        # 複数の子要素を作成
        task1 = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task 1',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        task2 = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task 2',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        # 2番目のタスクでエラーを発生させる
        allow(Issue).to receive(:update!).and_call_original
        allow(task2).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(task2))

        result = Kanban::VersionPropagationService.propagate_to_children(@user_story, version_v1)

        expect(result[:error]).to be_present

        # 全ての子要素のバージョンが変更されていない
        task1.reload
        task2.reload
        expect(task1.fixed_version).to be_nil
        expect(task2.fixed_version).to be_nil
      end
    end
  end

  describe 'パフォーマンス統合テスト' do
    context '大量データでの統合処理性能' do
      it '大量の子要素を持つUserStoryでも高速で処理される', :performance do
        # 50個の子要素を作成
        tasks = []
        50.times do |i|
          tasks << Issue.create!(
            project: project,
            tracker: task_tracker,
            status: status_new,
            subject: "Task #{i}",
            author: user,
            parent: @user_story,
            priority: priority_normal
          )
        end

        # バージョン伝播のパフォーマンステスト
        expect do
          Kanban::VersionPropagationService.propagate_to_children(@user_story, version_v1)
        end.to perform_under(200).ms

        # 検証ガードのパフォーマンステスト
        expect do
          Kanban::ValidationGuardService.validate_release_readiness(@user_story)
        end.to perform_under(150).ms

        # 全ての子要素が正しく処理されている
        tasks.each do |task|
          task.reload
          expect(task.fixed_version).to eq(version_v1)
        end
      end
    end
  end

  describe '同時実行制御' do
    context '複数ユーザーからの同時操作' do
      it '同じUserStoryに対する同時バージョン割当が正しく処理される' do
        task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Concurrent Task',
          author: user,
          parent: @user_story,
          priority: priority_normal
        )

        # 複数スレッドで同時にバージョン割当
        results = []
        threads = []

        2.times do |i|
          threads << Thread.new do
            version = i == 0 ? version_v1 : nil
            results << Kanban::VersionPropagationService.propagate_to_children(@user_story, version)
          end
        end

        threads.each(&:join)

        # 少なくとも1つは成功している
        expect(results.any? { |r| r[:error].nil? }).to be true

        # データの整合性が保たれている
        @user_story.reload
        task.reload
        expect(@user_story.fixed_version).to eq(task.fixed_version)
      end
    end
  end
end