# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::CardsController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_kanban_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:test_tracker) { create(:test_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }

  before do
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
    member # ensure member exists
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'POST #create (Feature作成)' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let(:version) { create(:version, project: project) }

    let(:valid_params) do
      {
        project_id: project.id,
        feature: {
          subject: 'New Feature',
          description: 'Feature description',
          parent_id: epic.id,
          fixed_version_id: version.id,
          assigned_to_id: user.id
        }
      }
    end

    it 'creates new feature' do
      expect {
        post :create, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_entity' => include(
            'subject' => 'New Feature',
            'parent_epic_id' => epic.id.to_s
          )
        )
      )
    end

    it 'creates feature even with invalid parent_id (Redmine behavior)' do
      invalid_params = valid_params.deep_dup
      invalid_params[:feature][:parent_id] = 99999

      expect {
        post :create, params: invalid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe 'POST #create_user_story' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:feature) { create(:feature, project: project, parent: epic, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        feature_id: feature.id,
        user_story: {
          subject: 'New User Story',
          description: 'User story description',
          assigned_to_id: user.id
        }
      }
    end

    it 'creates new user story' do
      expect {
        post :create_user_story, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_entity' => include(
            'subject' => 'New User Story',
            'parent_feature_id' => feature.id.to_s
          )
        )
      )
    end

    it 'inherits version from parent feature' do
      version = create(:version, project: project)
      feature.update!(fixed_version: version)

      post :create_user_story, params: valid_params

      new_story = Issue.last
      expect(new_story.fixed_version).to eq(version)
    end

    it 'uses client-specified version when provided' do
      version1 = create(:version, project: project, name: 'v1.0')
      version2 = create(:version, project: project, name: 'v2.0')
      feature.update!(fixed_version: version1)

      params_with_version = valid_params.deep_merge({
        user_story: { fixed_version_id: version2.id }
      })

      post :create_user_story, params: params_with_version

      new_story = Issue.last
      expect(new_story.fixed_version).to eq(version2) # version1ではなくversion2
    end
  end

  describe 'POST #create_task' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        task: {
          subject: 'New Task',
          description: 'Task description',
          assigned_to_id: user.id,
          estimated_hours: 4
        }
      }
    end

    it 'creates new task' do
      expect {
        post :create_task, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_entity' => include(
            'subject' => 'New Task'
          )
        )
      )
    end

    context '親UserStoryに日付が設定されている場合' do
      let!(:user_story_with_dates) do
        create(:user_story, project: project, author: user,
               start_date: Date.new(2025, 9, 30),
               due_date: Date.new(2025, 12, 31))
      end

      it '親UserStoryの開始日・終了日を継承する' do
        params = valid_params.merge(user_story_id: user_story_with_dates.id)

        post :create_task, params: params

        new_task = Issue.last
        expect(new_task.start_date).to eq(Date.new(2025, 9, 30))
        expect(new_task.due_date).to eq(Date.new(2025, 12, 31))
      end

      it 'API responseに開始日・終了日が含まれる' do
        params = valid_params.merge(user_story_id: user_story_with_dates.id)

        post :create_task, params: params

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json).to include(
          'success' => true,
          'data' => include(
            'created_entity' => include(
              'subject' => 'New Task',
              'start_date' => '2025-09-30',
              'due_date' => '2025-12-31'
            )
          )
        )
      end
    end

    context '親UserStoryに日付が未設定の場合' do
      it 'Taskの日付もnilのまま' do
        post :create_task, params: valid_params

        new_task = Issue.last
        expect(new_task.start_date).to be_nil
        expect(new_task.due_date).to be_nil
      end
    end
  end

  describe 'POST #create_test' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        test: {
          subject: 'New Test',
          description: 'Test description',
          assigned_to_id: user.id
        }
      }
    end

    it 'creates new test' do
      expect {
        post :create_test, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_entity' => include(
            'subject' => 'New Test'
          )
        )
      )
    end

    context '親UserStoryに日付が設定されている場合' do
      let!(:user_story_with_dates) do
        create(:user_story, project: project, author: user,
               start_date: Date.new(2025, 9, 30),
               due_date: Date.new(2025, 12, 31))
      end

      it '親UserStoryの開始日・終了日を継承する' do
        params = valid_params.merge(user_story_id: user_story_with_dates.id)

        post :create_test, params: params

        new_test = Issue.last
        expect(new_test.start_date).to eq(Date.new(2025, 9, 30))
        expect(new_test.due_date).to eq(Date.new(2025, 12, 31))
      end
    end

    context '親UserStoryに日付が未設定の場合' do
      it 'Testの日付もnilのまま' do
        post :create_test, params: valid_params

        new_test = Issue.last
        expect(new_test.start_date).to be_nil
        expect(new_test.due_date).to be_nil
      end
    end
  end

  describe 'POST #create_bug' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        bug: {
          subject: 'New Bug',
          description: 'Bug description',
          assigned_to_id: user.id,
          priority_id: IssuePriority.default.id
        }
      }
    end

    it 'creates new bug' do
      expect {
        post :create_bug, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_entity' => include(
            'subject' => 'New Bug'
          )
        )
      )
    end

    context '親UserStoryに日付が設定されている場合' do
      let!(:user_story_with_dates) do
        create(:user_story, project: project, author: user,
               start_date: Date.new(2025, 9, 30),
               due_date: Date.new(2025, 12, 31))
      end

      it '親UserStoryの開始日・終了日を継承する' do
        params = valid_params.merge(user_story_id: user_story_with_dates.id)

        post :create_bug, params: params

        new_bug = Issue.last
        expect(new_bug.start_date).to eq(Date.new(2025, 9, 30))
        expect(new_bug.due_date).to eq(Date.new(2025, 12, 31))
      end
    end

    context '親UserStoryに日付が未設定の場合' do
      it 'Bugの日付もnilのまま' do
        post :create_bug, params: valid_params

        new_bug = Issue.last
        expect(new_bug.start_date).to be_nil
        expect(new_bug.due_date).to be_nil
      end
    end
  end
end
