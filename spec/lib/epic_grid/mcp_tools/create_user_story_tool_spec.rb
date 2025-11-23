# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::CreateUserStoryTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:feature_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:feature],
      default_status: IssueStatus.first
    )
  end
  let(:parent_feature) { create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature') }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a UserStory successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: '申込画面を作る',
          parent_feature_id: parent_feature.id.to_s,
          description: '申込画面を作成するUserStory',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['user_story_id']).to be_present
        expect(response_text['subject']).to eq('申込画面を作る')

        # UserStoryが実際に作成されたか確認
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.tracker.name).to eq(EpicGrid::TrackerHierarchy.tracker_names[:user_story])
        expect(user_story.subject).to eq('申込画面を作る')
        expect(user_story.description).to eq('申込画面を作成するUserStory')
        expect(user_story.parent).to eq(parent_feature)
      end

      it 'creates a UserStory with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns UserStory to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.assigned_to).to eq(user)
      end

      it 'assigns UserStory to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.fixed_version).to eq(version)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('プロジェクトが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('UserStory作成権限がありません')
      end

      it 'returns error when UserStory tracker not configured' do
        # UserStoryトラッカーを完全に削除
        Tracker.where(name: EpicGrid::TrackerHierarchy.tracker_names[:user_story]).destroy_all

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('UserStoryトラッカーが設定されていません')
      end

      it 'returns error when parent feature not found' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親Featureが見つかりません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('UserStory')
      expect(described_class.description).to include('ユーザの要求')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :subject, :parent_feature_id)
      expect(schema.instance_variable_get(:@required)).to include(:project_id, :subject, :parent_feature_id)
    end
  end
end
