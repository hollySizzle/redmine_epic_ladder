# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe 'MSW Contract Compliance', type: :controller do
  # GridControllerのテスト
  describe EpicGrid::GridController do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:role) { create(:role, permissions: [:view_issues, :add_issues, :manage_versions]) }
    let(:member) { create(:member, project: project, user: user, roles: [role]) }

    before do
      member
      allow(User).to receive(:current).and_return(user)
      @request.session[:user_id] = user.id
    end

    describe 'POST #create_epic' do
      let(:epic_tracker) { create(:epic_tracker) }

      before do
        project.trackers << epic_tracker
      end

      it 'conforms to MSW CREATE_EPIC_RESPONSE contract (nested format)' do
        post :create_epic, params: {
          project_id: project.id,
          epic: { subject: 'New Epic', description: 'Epic description' }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_EPIC_RESPONSE)
      end

      it 'conforms to MSW CREATE_EPIC_RESPONSE contract (flat format - actual frontend)' do
        post :create_epic, params: {
          project_id: project.id,
          subject: 'New Epic',
          description: 'Epic description'
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_EPIC_RESPONSE)
      end
    end

    describe 'POST #create_version' do
      it 'conforms to MSW CREATE_VERSION_RESPONSE contract (nested format)' do
        post :create_version, params: {
          project_id: project.id,
          version: { name: 'v1.0.0', description: 'First version', status: 'open' }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_VERSION_RESPONSE)
      end

      it 'conforms to MSW CREATE_VERSION_RESPONSE contract (flat format - actual frontend)' do
        post :create_version, params: {
          project_id: project.id,
          name: 'v1.0.0',
          description: 'First version',
          status: 'open'
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_VERSION_RESPONSE)
      end
    end
  end

  # CardsControllerのテスト
  describe EpicGrid::CardsController do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
    let(:member) { create(:member, project: project, user: user, roles: [role]) }
    let(:epic_tracker) { create(:epic_tracker) }
    let(:feature_tracker) { create(:feature_tracker) }
    let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic') }

    before do
      member
      project.trackers << [epic_tracker, feature_tracker]
      epic  # トラッカー追加後にepic作成
      allow(User).to receive(:current).and_return(user)
      @request.session[:user_id] = user.id
    end

    describe 'POST #create (Feature)' do
      it 'conforms to MSW CREATE_FEATURE_RESPONSE contract (nested format)' do
        post :create, params: {
          project_id: project.id,
          feature: {
            subject: 'New Feature',
            description: 'Feature description',
            parent_id: epic.id
          }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_FEATURE_RESPONSE)
      end

      it 'conforms to MSW CREATE_FEATURE_RESPONSE contract (flat format - actual frontend)' do
        post :create, params: {
          project_id: project.id,
          subject: 'New Feature',
          description: 'Feature description',
          parent_epic_id: epic.id
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_FEATURE_RESPONSE)
      end
    end

    describe 'POST #create_user_story' do
      let(:feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Test Feature') }
      let(:user_story_tracker) { create(:user_story_tracker) }

      before do
        project.trackers << user_story_tracker
        feature  # トラッカー追加後にfeature作成
      end

      it 'conforms to MSW CREATE_USER_STORY_RESPONSE contract (nested format)' do
        post :create_user_story, params: {
          project_id: project.id,
          feature_id: feature.id,
          user_story: {
            subject: 'New User Story',
            description: 'User story description'
          }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_USER_STORY_RESPONSE)
      end

      it 'conforms to MSW CREATE_USER_STORY_RESPONSE contract (flat format - actual frontend)' do
        post :create_user_story, params: {
          project_id: project.id,
          feature_id: feature.id,
          subject: 'New User Story',
          description: 'User story description'
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_USER_STORY_RESPONSE)
      end
    end

    describe 'POST #create_task' do
      let(:task_feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Task Feature') }
      let(:task_user_story_tracker) { create(:user_story_tracker) }
      let(:task_tracker) { create(:task_tracker) }
      let(:user_story) { create(:issue, project: project, tracker: task_user_story_tracker, parent: task_feature, subject: 'Test User Story') }

      before do
        project.trackers << [task_user_story_tracker, task_tracker]
        user_story  # トラッカー追加後にuser_story作成
      end

      it 'conforms to MSW CREATE_TASK_RESPONSE contract (nested format)' do
        post :create_task, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          task: {
            subject: 'New Task',
            description: 'Task description',
            estimated_hours: 5.0
          }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_TASK_RESPONSE)
      end

      it 'conforms to MSW CREATE_TASK_RESPONSE contract (flat format - actual frontend)' do
        post :create_task, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          subject: 'New Task',
          description: 'Task description',
          estimated_hours: 5.0
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_TASK_RESPONSE)
      end
    end
  end
end
