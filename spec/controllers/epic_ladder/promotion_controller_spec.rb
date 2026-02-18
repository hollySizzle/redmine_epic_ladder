# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::PromotionController, type: :controller do
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

  let(:version_v1) { FactoryBot.create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }

  let(:epic_tracker) { FactoryBot.create(:epic_tracker) }
  let(:feature_tracker) { FactoryBot.create(:feature_tracker) }
  let(:user_story_tracker) { FactoryBot.create(:user_story_tracker) }
  let(:task_tracker) { FactoryBot.create(:task_tracker) }
  let(:test_tracker) { FactoryBot.create(:test_tracker) }
  let(:bug_tracker) { FactoryBot.create(:bug_tracker) }

  before do
    User.current = user
    member
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
    allow_any_instance_of(ApplicationController).to receive(:find_current_user).and_return(user)
    session[:user_id] = user.id
  end

  describe 'PATCH #promote_to_user_story' do
    context '正常系: Taskからの昇格' do
      let(:epic) { FactoryBot.create(:epic, project: project) }
      let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature, fixed_version: version_v1) }
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1) }

      it 'トラッカーがUserStoryに変更される' do
        patch :promote_to_user_story, params: { id: task.id }

        task.reload
        expect(task.tracker.name).to eq(user_story_tracker.name)
      end

      it '親がFeature直下に付け替えられる' do
        patch :promote_to_user_story, params: { id: task.id }

        task.reload
        expect(task.parent_id).to eq(feature.id)
      end

      it 'バージョンが維持される' do
        patch :promote_to_user_story, params: { id: task.id }

        task.reload
        expect(task.fixed_version_id).to eq(version_v1.id)
      end

      it 'flash[:notice]が設定される' do
        patch :promote_to_user_story, params: { id: task.id }

        expect(flash[:notice]).to be_present
      end

      it 'issue_pathにリダイレクトされる' do
        patch :promote_to_user_story, params: { id: task.id }

        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '正常系: Bugからの昇格' do
      let(:epic) { FactoryBot.create(:epic, project: project) }
      let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature) }
      let(:bug) { FactoryBot.create(:bug, project: project, parent: user_story) }

      it 'トラッカーがUserStoryに変更され、親がFeature直下になる' do
        patch :promote_to_user_story, params: { id: bug.id }

        bug.reload
        expect(bug.tracker.name).to eq(user_story_tracker.name)
        expect(bug.parent_id).to eq(feature.id)
      end
    end

    context '正常系: Testからの昇格' do
      let(:epic) { FactoryBot.create(:epic, project: project) }
      let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature) }
      let(:test_issue) { FactoryBot.create(:test, project: project, parent: user_story) }

      it 'トラッカーがUserStoryに変更され、親がFeature直下になる' do
        patch :promote_to_user_story, params: { id: test_issue.id }

        test_issue.reload
        expect(test_issue.tracker.name).to eq(user_story_tracker.name)
        expect(test_issue.parent_id).to eq(feature.id)
      end
    end

    context '異常系: UserStoryトラッカーで実行' do
      let(:feature) { FactoryBot.create(:feature, project: project) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature) }

      it 'flash[:error]が設定されリダイレクトされる' do
        patch :promote_to_user_story, params: { id: user_story.id }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(issue_path(user_story))
      end
    end

    context '異常系: Featureトラッカーで実行' do
      let(:feature) { FactoryBot.create(:feature, project: project) }

      it 'flash[:error]が設定されリダイレクトされる' do
        patch :promote_to_user_story, params: { id: feature.id }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(issue_path(feature))
      end
    end

    context '異常系: 親USが存在しない' do
      let(:task) { FactoryBot.create(:task, project: project, parent: nil) }

      it 'flash[:error]が設定されリダイレクトされる' do
        patch :promote_to_user_story, params: { id: task.id }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '異常系: 親USの親Featureが存在しない' do
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: nil) }
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story) }

      it 'flash[:error]が設定されリダイレクトされる' do
        patch :promote_to_user_story, params: { id: task.id }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(issue_path(task))
      end
    end

    context '異常系: 権限なしユーザー' do
      let(:other_user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:task, project: project) }

      before do
        User.current = other_user
        allow_any_instance_of(ApplicationController).to receive(:find_current_user).and_return(other_user)
        session[:user_id] = other_user.id
      end

      it '403エラーを返す' do
        patch :promote_to_user_story, params: { id: task.id }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context '異常系: 不正なIssue ID' do
      it '404エラーを返す' do
        patch :promote_to_user_story, params: { id: 999999 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
