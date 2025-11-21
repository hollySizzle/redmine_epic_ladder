# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::VersionController, type: :controller do
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

  let(:version_v1) { FactoryBot.create(:version, project: project, name: 'v1.0') }
  let(:version_v2) { FactoryBot.create(:version, project: project, name: 'v2.0') }

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
        expect(user_story.reload.fixed_version_id).to eq(version_v1.id) # 親は変更されない
        expect(flash[:warning]).to be_present # 親とのズレを警告
        expect(response).to redirect_to(issue_path(task))
      end

      it 'バージョンを未設定に変更できる' do
        patch :update, params: { id: task.id, fixed_version_id: '' }

        task.reload
        expect(task.fixed_version_id).to be_nil
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
        expect(user_story.fixed_version_id).to eq(version_v2.id)
        expect(flash[:notice]).to include('v2.0')
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context 'UserStoryのVersion変更' do
      let(:feature) { FactoryBot.create(:feature, project: project, fixed_version: version_v1) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature, fixed_version: version_v1) }

      it 'UserStoryのバージョンを変更できる' do
        patch :update, params: { id: user_story.id, fixed_version_id: version_v2.id }

        user_story.reload
        expect(user_story.fixed_version_id).to eq(version_v2.id)
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
  end
end
