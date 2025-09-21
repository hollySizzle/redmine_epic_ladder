# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::TestGenerationService, type: :service do
  include KanbanTestHelpers

  let!(:project) { Project.create!(name: 'Test Project', identifier: 'test-generation') }
  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true) }
  let!(:priority) { IssuePriority.create!(name: 'Normal', is_default: true) }

  # トラッカー作成
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 1, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 2, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 3, is_in_chlog: false) }

  # バージョン作成
  let!(:version_v1) { Version.create!(project: project, name: 'v1.0', effective_date: 1.month.from_now) }

  # UserStory作成
  let!(:user_story) do
    User.current = user
    Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_new,
      subject: 'User can login to system',
      description: 'As a user, I want to login to the system',
      author: user,
      assigned_to: user,
      priority: priority,
      fixed_version: version_v1
    )
  end

  before do
    User.current = user
  end

  describe '.generate_test_for_user_story' do
    context '正常ケース' do
      it 'UserStoryに対応するTestを正常に生成する' do
        result = described_class.generate_test_for_user_story(user_story)

        expect(result[:error]).to be_nil
        expect(result[:test_issue]).to be_a(Issue)
        expect(result[:relation_created]).to be true

        test_issue = result[:test_issue]
        expect(test_issue.tracker.name).to eq('Test')
        expect(test_issue.subject).to eq('Test: User can login to system')
        expect(test_issue.parent).to eq(user_story)
        expect(test_issue.project).to eq(project)
        expect(test_issue.author).to eq(user)
        expect(test_issue.assigned_to).to eq(user)
        expect(test_issue.priority).to eq(priority)
        expect(test_issue.status.name).to eq('New')
      end

      it 'Testの件名と説明文がテンプレートに従って生成される' do
        result = described_class.generate_test_for_user_story(user_story)
        test_issue = result[:test_issue]

        expect(test_issue.subject).to eq('Test: User can login to system')
        expect(test_issue.description).to include('ユーザーストーリー: User can login to system')
        expect(test_issue.description).to include('受入条件:')
        expect(test_issue.description).to include('- [ ] 機能が正常に動作する')
        expect(test_issue.description).to include('- [ ] エラーハンドリングが適切')
        expect(test_issue.description).to include('- [ ] UIが仕様通り')
      end

      it 'UserStoryにバージョンが設定されている場合、Testにも伝播される' do
        result = described_class.generate_test_for_user_story(user_story)
        test_issue = result[:test_issue]

        expect(test_issue.fixed_version).to eq(version_v1)
      end

      it 'Test→UserStoryのblocks関係が作成される' do
        result = described_class.generate_test_for_user_story(user_story)
        test_issue = result[:test_issue]

        relation = IssueRelation.find_by(issue_from: test_issue, issue_to: user_story)
        expect(relation).not_to be_nil
        expect(relation.relation_type).to eq('blocks')
      end

      it 'assigned_toオプションで担当者を指定できる' do
        other_user = User.create!(login: 'other', firstname: 'Other', lastname: 'User', mail: 'other@test.com', status: User::STATUS_ACTIVE)

        result = described_class.generate_test_for_user_story(user_story, assigned_to: other_user)
        test_issue = result[:test_issue]

        expect(test_issue.assigned_to).to eq(other_user)
      end

      it 'ログが出力される' do
        expect(Rails.logger).to receive(:info).with(/Test自動生成完了: UserStory##{user_story.id} -> Test#\d+/)

        described_class.generate_test_for_user_story(user_story)
      end
    end

    context '既存Test処理' do
      let!(:existing_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Existing Test',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it '既存Testがある場合、新規作成せずに既存を返す' do
        result = described_class.generate_test_for_user_story(user_story)

        expect(result[:test_issue]).to eq(existing_test)
        expect(result[:existing]).to be true
        expect(result[:relation_created]).to be_nil
      end

      it 'force_recreateオプションで既存Testがあっても新規作成する' do
        result = described_class.generate_test_for_user_story(user_story, force_recreate: true)

        expect(result[:test_issue]).not_to eq(existing_test)
        expect(result[:test_issue].subject).to eq('Test: User can login to system')
        expect(result[:relation_created]).to be true
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
          priority: priority
        )
      end

      it 'UserStory以外のトラッカーではエラーを返す' do
        result = described_class.generate_test_for_user_story(task_issue)

        expect(result[:error]).to eq('UserStoryではありません')
        expect(result[:test_issue]).to be_nil
      end

      it 'データベースエラーが発生した場合はロールバックされる' do
        allow(Issue).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Issue.new))

        result = described_class.generate_test_for_user_story(user_story)

        expect(result[:error]).to include('Validation failed')
        expect(Rails.logger).to receive(:error).with(/Test自動生成エラー:/)
      end

      it 'Testトラッカーが存在しない場合はエラーになる' do
        test_tracker.destroy

        result = described_class.generate_test_for_user_story(user_story)

        expect(result[:error]).to include('ActiveRecord::RecordNotFound')
      end
    end
  end

  describe '.ensure_test_exists_for_ready_state' do
    context 'Testが存在しない場合' do
      it 'Testを自動生成する' do
        result = described_class.ensure_test_exists_for_ready_state(user_story)

        expect(result[:error]).to be_nil
        expect(result[:test_issue]).to be_a(Issue)
        expect(result[:test_issue].tracker.name).to eq('Test')
      end
    end

    context 'Testが既に存在する場合' do
      let!(:existing_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Existing Test',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it '既存Testを返す' do
        result = described_class.ensure_test_exists_for_ready_state(user_story)

        expect(result[:test_issue]).to eq(existing_test)
        expect(result[:existing]).to be true
      end
    end

    it 'UserStory以外では エラーを返す' do
      task_issue = Issue.create!(
        project: project,
        tracker: task_tracker,
        status: status_new,
        subject: 'Task',
        author: user,
        priority: priority
      )

      result = described_class.ensure_test_exists_for_ready_state(task_issue)

      expect(result[:error]).to eq('UserStoryではありません')
    end
  end

  describe '.find_existing_test' do
    context 'Testが存在する場合' do
      let!(:test_issue) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Test Issue',
          author: user,
          parent: user_story,
          priority: priority
        )
      end

      it '既存のTestを返す' do
        result = described_class.find_existing_test(user_story)
        expect(result).to eq(test_issue)
      end
    end

    context 'Testが存在しない場合' do
      it 'nilを返す' do
        result = described_class.find_existing_test(user_story)
        expect(result).to be_nil
      end
    end

    context '複数の子要素が存在する場合' do
      let!(:task_issue) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Task Issue',
          author: user,
          parent: user_story,
          priority: priority
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
          priority: priority
        )
      end

      it 'Testトラッカーの子要素のみを返す' do
        result = described_class.find_existing_test(user_story)
        expect(result).to eq(test_issue)
      end
    end
  end

  describe 'バージョン伝播処理' do
    context 'UserStoryにバージョンが設定されていない場合' do
      let!(:user_story_no_version) do
        Issue.create!(
          project: project,
          tracker: user_story_tracker,
          status: status_new,
          subject: 'UserStory without version',
          author: user,
          priority: priority
        )
      end

      it 'Testにもバージョンは設定されない' do
        result = described_class.generate_test_for_user_story(user_story_no_version)
        test_issue = result[:test_issue]

        expect(test_issue.fixed_version).to be_nil
      end
    end
  end

  describe 'トランザクション制御' do
    it 'blocks関係作成でエラーが発生した場合、Testの作成もロールバックされる' do
      allow(IssueRelation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(IssueRelation.new))

      initial_count = Issue.where(tracker: test_tracker).count
      result = described_class.generate_test_for_user_story(user_story)

      expect(result[:error]).to be_present
      expect(Issue.where(tracker: test_tracker).count).to eq(initial_count)
    end
  end

  describe 'TEMPLATE_CONFIGSの検証' do
    it '正しいテンプレート構造を持っている' do
      template = described_class::TEMPLATE_CONFIGS[:default]

      expect(template[:subject_template]).to include('%{user_story_subject}')
      expect(template[:description_template]).to include('%{user_story_subject}')
      expect(template[:description_template]).to include('受入条件:')
    end
  end
end