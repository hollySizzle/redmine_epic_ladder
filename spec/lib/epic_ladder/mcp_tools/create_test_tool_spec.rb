# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateTestTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:test_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:test],
      default_status: IssueStatus.first
    )
  end
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:parent_user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory') }

  before do
    member # ensure member exists
    project.trackers << test_tracker unless project.trackers.include?(test_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a Test successfully' do
        result = described_class.call(
          project_id: project.identifier,
          description: '申込完了までのE2Eテスト',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['test_id']).to be_present
        expect(response_text['subject']).to be_present

        # Testが実際に作成されたか確認
        test = Issue.find(response_text['test_id'])
        expect(test.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:test])
        expect(test.description).to eq('申込完了までのE2Eテスト')
        expect(test.parent).to eq(parent_user_story)
      end

      it 'creates a Test with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          description: 'テストTest',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Test to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストTest',
          parent_user_story_id: parent_user_story.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        test = Issue.find(response_text['test_id'])
        expect(test.assigned_to).to eq(user)
      end

      it 'assigns Test to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストTest',
          parent_user_story_id: parent_user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        test = Issue.find(response_text['test_id'])
        expect(test.fixed_version).to eq(version)
      end

      it 'creates Test without parent_user_story_id (auto-inference)' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストTest',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          description: 'テストTest',
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
          description: 'テストTest',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when Test tracker not configured' do
        # Testトラッカーをプロジェクトから削除
        project.trackers.delete(test_tracker)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストTest',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('トラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Test')
      expect(described_class.description).to include('テストや検証')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :description)
      expect(schema.instance_variable_get(:@required)).to include(:description)
    end
  end
end
