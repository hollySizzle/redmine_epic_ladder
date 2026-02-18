# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe 'MSW Contract Compliance', type: :controller do
  # GridControllerのテスト
  describe EpicLadder::GridController do
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

    describe 'GET #show' do
      let!(:epic_tracker) { create(:epic_tracker) }
      let!(:version_open) { create(:version, project: project, status: 'open', name: 'v1.0') }
      let!(:version_closed) { create(:version, project: project, status: 'closed', name: 'v2.0') }

      before do
        project.trackers << epic_tracker
      end

      it 'conforms to MSW NORMALIZED_API_RESPONSE contract with exclude_closed_versions=true' do
        get :show, params: {
          project_id: project.id,
          exclude_closed_versions: 'true'
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)

        # MSW NormalizedAPIResponse形式の検証
        expect(response_body).to have_key(:entities)
        expect(response_body).to have_key(:grid)
        expect(response_body).to have_key(:metadata)
        expect(response_body).to have_key(:statistics)

        # closedバージョンが除外されていることを確認
        version_ids = response_body[:entities][:versions].keys.map(&:to_s)
        expect(version_ids).to include(version_open.id.to_s)
        expect(version_ids).not_to include(version_closed.id.to_s)
      end

      it 'conforms to MSW NORMALIZED_API_RESPONSE contract with exclude_closed_versions=false' do
        get :show, params: {
          project_id: project.id,
          exclude_closed_versions: 'false'
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)

        # すべてのバージョンが含まれることを確認
        version_ids = response_body[:entities][:versions].keys.map(&:to_s)
        expect(version_ids).to include(version_open.id.to_s)
        expect(version_ids).to include(version_closed.id.to_s)
      end
    end
  end

  # CardsControllerのテスト
  describe EpicLadder::CardsController do
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

    describe 'POST #create_test' do
      let(:test_feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Test Feature') }
      let(:test_user_story_tracker) { create(:user_story_tracker) }
      let(:test_tracker) { create(:test_tracker) }
      let(:test_user_story) { create(:issue, project: project, tracker: test_user_story_tracker, parent: test_feature, subject: 'Test User Story') }

      before do
        project.trackers << [test_user_story_tracker, test_tracker]
        test_user_story
      end

      it 'conforms to MSW CREATE_TEST_RESPONSE contract (nested format)' do
        post :create_test, params: {
          project_id: project.id,
          user_story_id: test_user_story.id,
          test: {
            subject: 'New Test',
            description: 'Test description'
          }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_TEST_RESPONSE)
      end

      it 'conforms to MSW CREATE_TEST_RESPONSE contract (flat format - actual frontend)' do
        post :create_test, params: {
          project_id: project.id,
          user_story_id: test_user_story.id,
          subject: 'New Test',
          description: 'Test description'
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_TEST_RESPONSE)
      end
    end

    describe 'POST #create_bug' do
      let(:bug_feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Bug Feature') }
      let(:bug_user_story_tracker) { create(:user_story_tracker) }
      let(:bug_tracker) { create(:bug_tracker) }
      let(:bug_user_story) { create(:issue, project: project, tracker: bug_user_story_tracker, parent: bug_feature, subject: 'Bug User Story') }

      before do
        project.trackers << [bug_user_story_tracker, bug_tracker]
        bug_user_story
      end

      it 'conforms to MSW CREATE_BUG_RESPONSE contract (nested format)' do
        post :create_bug, params: {
          project_id: project.id,
          user_story_id: bug_user_story.id,
          bug: {
            subject: 'New Bug',
            description: 'Bug description'
          }
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_BUG_RESPONSE)
      end

      it 'conforms to MSW CREATE_BUG_RESPONSE contract (flat format - actual frontend)' do
        post :create_bug, params: {
          project_id: project.id,
          user_story_id: bug_user_story.id,
          subject: 'New Bug',
          description: 'Bug description'
        }

        expect(response).to have_http_status(:created)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:CREATE_BUG_RESPONSE)
      end
    end
  end

  # GridController - UserStory移動テスト
  describe EpicLadder::GridController do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:role) { create(:role, permissions: [:view_issues, :edit_issues, :manage_versions]) }
    let(:member) { create(:member, project: project, user: user, roles: [role]) }
    let(:epic_tracker) { create(:epic_tracker) }
    let(:feature_tracker) { create(:feature_tracker) }
    let(:user_story_tracker) { create(:user_story_tracker) }
    let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic') }
    let(:source_feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Source Feature') }
    let(:target_feature) { create(:issue, project: project, tracker: feature_tracker, parent: epic, subject: 'Target Feature') }
    let(:user_story) { create(:issue, project: project, tracker: user_story_tracker, parent: source_feature, subject: 'Test User Story') }
    let(:version) { create(:version, project: project, name: 'v1.0.0') }

    before do
      member
      project.trackers << [epic_tracker, feature_tracker, user_story_tracker]
      epic
      source_feature
      target_feature
      user_story
      version
      allow(User).to receive(:current).and_return(user)
      @request.session[:user_id] = user.id
    end

    describe 'POST #move_user_story' do
      it 'conforms to MSW MOVE_USER_STORY_RESPONSE contract' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: target_feature.id,
          target_version_id: version.id
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:MOVE_USER_STORY_RESPONSE)

        # 基本的な検証
        expect(response_body[:success]).to eq(true)
        expect(response_body[:updated_entities][:user_stories]).to be_a(Hash)
        expect(response_body[:updated_entities][:features]).to be_a(Hash)
        expect(response_body[:updated_grid_index]).to be_a(Hash)
        expect(response_body[:propagation_result][:affected_issue_ids]).to be_an(Array)
        expect(response_body[:propagation_result][:conflicts]).to be_an(Array)
      end

      it 'handles version_id = null' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: target_feature.id,
          target_version_id: nil
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body).to conform_to_msw_contract(:MOVE_USER_STORY_RESPONSE)
      end

      it 'returns 404 for non-existent user_story' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: 99999,
          target_feature_id: target_feature.id,
          target_version_id: version.id
        }

        expect(response).to have_http_status(:not_found)
        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body[:success]).to eq(false)
        expect(response_body[:error][:code]).to eq('not_found')
      end

      it 'returns 404 for non-existent target_feature' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: 99999,
          target_version_id: version.id
        }

        expect(response).to have_http_status(:not_found)
        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body[:success]).to eq(false)
        expect(response_body[:error][:code]).to eq('not_found')
      end
    end

    describe 'POST #batch_update' do
      let(:epic_tracker) { create(:epic_tracker) }
      let(:feature_tracker) { create(:feature_tracker) }
      let(:user_story_tracker) { create(:user_story_tracker) }
      let(:version1) { create(:version, project: project, name: 'v1.0') }
      let(:version2) { create(:version, project: project, name: 'v2.0') }

      let(:epic1) { create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1') }
      let(:epic2) { create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 2') }

      let(:feature1) { create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 1', parent: epic1) }
      let(:feature2) { create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 2', parent: epic1) }

      let(:user_story1) do
        create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 1',
               parent: feature1, fixed_version: version1)
      end
      let(:user_story2) do
        create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 2',
               parent: feature1, fixed_version: version1)
      end

      before do
        [epic_tracker, feature_tracker, user_story_tracker].each do |tracker|
          project.trackers << tracker unless project.trackers.include?(tracker)
        end
        epic1
        epic2
        feature1
        feature2
        user_story1
        user_story2
        version1
        version2
      end

      it 'conforms to MSW BATCH_UPDATE_RESPONSE contract (UserStory moves only)' do
        post :batch_update, params: {
          project_id: project.id,
          moved_user_stories: [
            {
              id: user_story1.id.to_s,
              target_feature_id: feature2.id.to_s,
              target_version_id: version2.id.to_s
            },
            {
              id: user_story2.id.to_s,
              target_feature_id: feature2.id.to_s,
              target_version_id: nil
            }
          ]
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)

        # MSW契約確認
        expect(response_body).to include(:success, :updated_entities, :updated_grid_index)
        expect(response_body[:success]).to eq(true)

        # updated_entities構造確認（symbolize_names: trueなのでキーは全てシンボル）
        expect(response_body[:updated_entities]).to include(:user_stories, :features)
        expect(response_body[:updated_entities][:user_stories]).to have_key(user_story1.id.to_s.to_sym)
        expect(response_body[:updated_entities][:user_stories]).to have_key(user_story2.id.to_s.to_sym)
        expect(response_body[:updated_entities][:features]).to have_key(feature1.id.to_s.to_sym)
        expect(response_body[:updated_entities][:features]).to have_key(feature2.id.to_s.to_sym)

        # updated_grid_indexの部分更新確認（全セルではなく変更されたセルのみ）
        expect(response_body[:updated_grid_index]).to be_a(Hash)
        expect(response_body[:updated_grid_index].keys.length).to be > 0

        # UserStoryの移動確認
        user_story1.reload
        user_story2.reload
        expect(user_story1.parent_id).to eq(feature2.id)
        expect(user_story1.fixed_version_id).to eq(version2.id)
        expect(user_story2.parent_id).to eq(feature2.id)
        expect(user_story2.fixed_version_id).to be_nil
      end

      it 'conforms to MSW BATCH_UPDATE_RESPONSE contract (Epic/Version reorder)' do
        post :batch_update, params: {
          project_id: project.id,
          reordered_epics: [epic2.id.to_s, epic1.id.to_s],
          reordered_versions: [version2.id.to_s, version1.id.to_s]
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)

        # MSW契約確認
        expect(response_body).to include(:success, :updated_epic_order, :updated_version_order)
        expect(response_body[:success]).to eq(true)
        expect(response_body[:updated_epic_order]).to eq([epic2.id.to_s, epic1.id.to_s])
        expect(response_body[:updated_version_order]).to eq([version2.id.to_s, version1.id.to_s])
      end

      it 'conforms to MSW BATCH_UPDATE_RESPONSE contract (mixed operations)' do
        post :batch_update, params: {
          project_id: project.id,
          moved_user_stories: [
            {
              id: user_story1.id.to_s,
              target_feature_id: feature2.id.to_s,
              target_version_id: version2.id.to_s
            }
          ],
          reordered_epics: [epic2.id.to_s, epic1.id.to_s],
          reordered_versions: [version2.id.to_s, version1.id.to_s]
        }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)

        # MSW契約確認
        expect(response_body).to include(
          :success,
          :updated_entities,
          :updated_grid_index,
          :updated_epic_order,
          :updated_version_order
        )
        expect(response_body[:success]).to eq(true)

        # 各種更新の確認（symbolize_names: trueなのでキーは全てシンボル）
        expect(response_body[:updated_entities][:user_stories]).to have_key(user_story1.id.to_s.to_sym)
        expect(response_body[:updated_epic_order]).to eq([epic2.id.to_s, epic1.id.to_s])
        expect(response_body[:updated_version_order]).to eq([version2.id.to_s, version1.id.to_s])
      end

      it 'returns success even with empty request' do
        post :batch_update, params: { project_id: project.id }

        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body, symbolize_names: true)
        expect(response_body[:success]).to eq(true)
        expect(response_body[:updated_entities]).to eq({})
        expect(response_body[:updated_grid_index]).to eq({})
      end
    end
  end
end
