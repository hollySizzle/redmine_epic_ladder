# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::VersionController, type: :controller do
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

  let(:version_v1) { FactoryBot.create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }
  let(:version_v2) { FactoryBot.create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 10, 20)) }

  let(:task_tracker) { FactoryBot.create(:task_tracker) }
  let(:user_story_tracker) { FactoryBot.create(:user_story_tracker) }
  let(:feature_tracker) { FactoryBot.create(:feature_tracker) }

  before do
    User.current = user
    member # Ensure membership is created
    project.trackers << [task_tracker, user_story_tracker, feature_tracker]
    # ログイン状態をシミュレート
    allow_any_instance_of(ApplicationController).to receive(:find_current_user).and_return(user)
    session[:user_id] = user.id
  end

  describe 'PATCH #update' do
    context 'Task単体のVersion変更' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1) }

      it 'Taskのみバージョンを変更できる' do
        patch :update, params: { id: task.id, fixed_version_id: version_v2.id }

        task.reload
        expect(task.fixed_version_id).to eq(version_v2.id)
        expect(task.start_date).to eq(Date.new(2025, 10, 10)) # v1.0の期日（直前のバージョン）
        expect(task.due_date).to eq(Date.new(2025, 10, 20))   # v2.0の期日
        expect(user_story.reload.fixed_version_id).to eq(version_v1.id) # 親は変更されない
        expect(flash[:warning]).to be_present # 親とのズレを警告
        expect(response).to redirect_to(issue_path(task))
      end

      it 'バージョンを未設定に変更できる' do
        patch :update, params: { id: task.id, fixed_version_id: '' }

        task.reload
        expect(task.fixed_version_id).to be_nil
        expect(task.start_date).to be_nil # バージョンなし→日付も未設定
        expect(task.due_date).to be_nil
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '親UserStoryも一緒に変更' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1) }

      it 'TaskとUserStory両方のバージョンを変更できる' do
        patch :update, params: {
          id: task.id,
          fixed_version_id: version_v2.id,
          update_parent_version: '1'
        }

        task.reload
        user_story.reload

        expect(task.fixed_version_id).to eq(version_v2.id)
        expect(task.start_date).to eq(Date.new(2025, 10, 10))
        expect(task.due_date).to eq(Date.new(2025, 10, 20))

        expect(user_story.fixed_version_id).to eq(version_v2.id)
        expect(user_story.start_date).to eq(Date.new(2025, 10, 10)) # 親も日付更新
        expect(user_story.due_date).to eq(Date.new(2025, 10, 20))

        expect(flash[:notice]).to include('v2.0')
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '親と兄弟issue（Task/Bug/Test）も一緒に変更' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task1) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, subject: 'Task1') }
      let(:task2) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, subject: 'Task2') }
      let(:bug) { FactoryBot.create(:bug, project: project, parent: user_story, fixed_version: version_v1, subject: 'Bug1') }
      let(:test) { FactoryBot.create(:test, project: project, parent: user_story, fixed_version: version_v1, subject: 'Test1') }

      let(:bug_tracker) { FactoryBot.create(:bug_tracker) }
      let(:test_tracker) { FactoryBot.create(:test_tracker) }

      before do
        project.trackers << [bug_tracker, test_tracker]
        # 全てのissueを作成
        task1
        task2
        bug
        test
      end

      it 'Task1を変更すると、親UserStoryと兄弟（Task2, Bug, Test）も全て変更される' do
        patch :update, params: {
          id: task1.id,
          fixed_version_id: version_v2.id,
          update_parent_version: '1'
        }

        # 全てリロード
        task1.reload
        task2.reload
        bug.reload
        test.reload
        user_story.reload

        # Task1（操作対象）
        expect(task1.fixed_version_id).to eq(version_v2.id)
        expect(task1.start_date).to eq(Date.new(2025, 10, 10))
        expect(task1.due_date).to eq(Date.new(2025, 10, 20))

        # 親UserStory
        expect(user_story.fixed_version_id).to eq(version_v2.id)
        expect(user_story.start_date).to eq(Date.new(2025, 10, 10))
        expect(user_story.due_date).to eq(Date.new(2025, 10, 20))

        # 兄弟Task2
        expect(task2.fixed_version_id).to eq(version_v2.id)
        expect(task2.start_date).to eq(Date.new(2025, 10, 10))
        expect(task2.due_date).to eq(Date.new(2025, 10, 20))

        # 兄弟Bug
        expect(bug.fixed_version_id).to eq(version_v2.id)
        expect(bug.start_date).to eq(Date.new(2025, 10, 10))
        expect(bug.due_date).to eq(Date.new(2025, 10, 20))

        # 兄弟Test
        expect(test.fixed_version_id).to eq(version_v2.id)
        expect(test.start_date).to eq(Date.new(2025, 10, 10))
        expect(test.due_date).to eq(Date.new(2025, 10, 20))

        # フラッシュメッセージに総数と兄弟数が含まれる
        expect(flash[:notice]).to include('5') # 計5件（task1 + user_story + task2 + bug + test）
        expect(flash[:notice]).to include('3') # 兄弟3件（task2 + bug + test）
        expect(response).to redirect_to(issue_path(task1))
      end
    end

    context 'UserStoryのVersion変更' do
      let(:feature) { FactoryBot.create(:feature, project: project, fixed_version: version_v1) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature, fixed_version: version_v1) }

      it 'UserStoryのバージョンを変更できる' do
        patch :update, params: { id: user_story.id, fixed_version_id: version_v2.id }

        user_story.reload
        expect(user_story.fixed_version_id).to eq(version_v2.id)
        expect(user_story.start_date).to eq(Date.new(2025, 10, 10))
        expect(user_story.due_date).to eq(Date.new(2025, 10, 20))
        expect(feature.reload.fixed_version_id).to eq(version_v1.id) # 親は変更されない
        expect(response).to redirect_to(issue_path(user_story))
      end
    end

    context '親が存在しない場合' do
      let(:task) { FactoryBot.create(:task, project: project, fixed_version: version_v1) }

      it 'Taskのみバージョンを変更できる（警告なし）' do
        patch :update, params: { id: task.id, fixed_version_id: version_v2.id }

        task.reload
        expect(task.fixed_version_id).to eq(version_v2.id)
        expect(task.start_date).to eq(Date.new(2025, 10, 10))
        expect(task.due_date).to eq(Date.new(2025, 10, 20))
        expect(flash[:warning]).to be_nil # 親がいないので警告なし
        expect(flash[:notice]).to be_present
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '権限がない場合' do
      let(:other_user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:task, project: project) }

      before do
        User.current = other_user # 権限のないユーザーに切り替え
        # セッションも切り替える
        allow_any_instance_of(ApplicationController).to receive(:find_current_user).and_return(other_user)
        session[:user_id] = other_user.id
      end

      it '403エラーを返す' do
        patch :update, params: { id: task.id, fixed_version_id: version_v2.id }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context '不正なIssue IDの場合' do
      it '404エラーを返す' do
        patch :update, params: { id: 999999, fixed_version_id: version_v2.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'Setting.parent_issue_dates = "derived"の場合（デフォルト）' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task1) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, start_date: Date.new(2025, 10, 1), due_date: Date.new(2025, 10, 5)) }
      let(:task2) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, start_date: Date.new(2025, 10, 15), due_date: Date.new(2025, 10, 19)) }

      before do
        Setting.parent_issue_dates = 'derived'
        task1
        task2
      end

      it '親の日付は子から自動計算され、手動設定は無視される' do
        patch :update, params: {
          id: task1.id,
          fixed_version_id: version_v2.id,
          update_parent_version: '1'
        }

        task1.reload
        task2.reload
        user_story.reload

        # 子issueは更新される
        expect(task1.start_date).to eq(Date.new(2025, 10, 10))
        expect(task1.due_date).to eq(Date.new(2025, 10, 20))
        expect(task2.start_date).to eq(Date.new(2025, 10, 10))
        expect(task2.due_date).to eq(Date.new(2025, 10, 20))

        # 親の日付は子から自動計算される
        expect(user_story.start_date).to eq(Date.new(2025, 10, 10)) # min(task1, task2)
        expect(user_story.due_date).to eq(Date.new(2025, 10, 20))   # max(task1, task2)
      end
    end

    context 'Setting.parent_issue_dates = "independent"の場合' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1) }

      before do
        Setting.parent_issue_dates = 'independent'
      end

      after do
        Setting.parent_issue_dates = 'derived' # デフォルトに戻す
      end

      it '親の日付も明示的に設定される' do
        patch :update, params: {
          id: task.id,
          fixed_version_id: version_v2.id,
          update_parent_version: '1'
        }

        task.reload
        user_story.reload

        expect(task.fixed_version_id).to eq(version_v2.id)
        expect(task.start_date).to eq(Date.new(2025, 10, 10))
        expect(task.due_date).to eq(Date.new(2025, 10, 20))

        # independent設定の場合、親の日付も明示的に設定される
        expect(user_story.fixed_version_id).to eq(version_v2.id)
        expect(user_story.start_date).to eq(Date.new(2025, 10, 10))
        expect(user_story.due_date).to eq(Date.new(2025, 10, 20))
      end
    end

    context 'バージョンなし → バージョンありへの変更' do
      let(:task) { FactoryBot.create(:task, project: project, fixed_version: nil) }

      it 'バージョンと日付が設定される' do
        # version_v1, version_v2が存在することを明示的に確保
        version_v1
        version_v2

        patch :update, params: { id: task.id, fixed_version_id: version_v2.id }

        task.reload
        expect(task.fixed_version_id).to eq(version_v2.id)
        # version_v2より前のversion_v1が存在するので、開始日は version_v1.effective_date
        expect(task.start_date).to eq(Date.new(2025, 10, 10)) # version_v1の期日
        expect(task.due_date).to eq(Date.new(2025, 10, 20))   # version_v2の期日
      end
    end

    context 'クローズ済みissueのバージョン変更' do
      let(:closed_status) { IssueStatus.where(is_closed: true).first || IssueStatus.create!(name: 'Closed', is_closed: true) }
      let(:task) do
        t = FactoryBot.build(:task, project: project, fixed_version: version_v1)
        t.status = closed_status
        t.save!
        t
      end

      it 'クローズ済みでもバージョン変更できる' do
        expect(task.closed?).to be true # 前提条件確認

        patch :update, params: { id: task.id, fixed_version_id: version_v2.id }

        task.reload
        expect(task.fixed_version_id).to eq(version_v2.id)
        expect(task.start_date).to eq(Date.new(2025, 10, 10))
        expect(task.due_date).to eq(Date.new(2025, 10, 20))
        expect(task.closed?).to be true # クローズ状態が維持される
      end
    end

    context 'Journal記録の確認' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, fixed_version: version_v1) }
      let(:task1) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, subject: 'Task1') }
      let(:task2) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1, subject: 'Task2') }

      before do
        task1
        task2
      end

      it '全てのissueにJournalが作成される' do
        expect {
          patch :update, params: {
            id: task1.id,
            fixed_version_id: version_v2.id,
            update_parent_version: '1'
          }
        }.to change { Journal.count }.by(3) # task1 + user_story + task2

        # 各issueのJournalを確認
        task1.reload
        task2.reload
        user_story.reload

        expect(task1.journals.last.details.map(&:prop_key)).to include('fixed_version_id', 'start_date', 'due_date')
        expect(task2.journals.last.details.map(&:prop_key)).to include('fixed_version_id', 'start_date', 'due_date')
        expect(user_story.journals.last.details.map(&:prop_key)).to include('fixed_version_id')
      end
    end
  end
end
