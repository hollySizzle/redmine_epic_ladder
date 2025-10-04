# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EpicGrid::CardsController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_kanban_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }

  before do
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker]
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
        subject: 'New Feature',
        description: 'Feature description',
        parent_epic_id: epic.id,
        fixed_version_id: version.id,
        assigned_to_id: user.id,
        priority_id: 4
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
          'feature' => include(
            'subject' => 'New Feature',
            'parent_id' => epic.id
          )
        )
      )
    end

    it 'returns error when parent epic not found' do
      post :create, params: valid_params.merge(parent_id: 99999)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create_user_story' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:feature) { create(:feature, project: project, parent: epic, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        feature_id: feature.id,
        subject: 'New User Story',
        description: 'User story description',
        assigned_to_id: user.id,
        estimated_hours: 8
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
          'user_story' => include(
            'subject' => 'New User Story',
            'parent_id' => feature.id
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
  end

  describe 'POST #create_task' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        subject: 'New Task',
        description: 'Task description',
        assigned_to_id: user.id,
        estimated_hours: 4
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
          'task' => include(
            'subject' => 'New Task',
            'parent_id' => user_story.id
          )
        )
      )
    end
  end

  describe 'POST #create_test' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        subject: 'New Test',
        description: 'Test description',
        assigned_to_id: user.id
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
          'test' => include(
            'subject' => 'New Test'
          )
        )
      )
    end
  end

  describe 'POST #create_bug' do
    let!(:user_story) { create(:user_story, project: project, author: user) }

    let(:valid_params) do
      {
        project_id: project.id,
        user_story_id: user_story.id,
        subject: 'New Bug',
        description: 'Bug description',
        assigned_to_id: user.id,
        severity: 'major'
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
          'bug' => include(
            'subject' => 'New Bug'
          )
        )
      )
    end
  end
end
