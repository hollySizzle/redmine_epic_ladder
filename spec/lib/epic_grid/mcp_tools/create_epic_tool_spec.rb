# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::CreateEpicTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:epic],
      default_status: IssueStatus.first
    )
  end

  before do
    member # ensure member exists
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates an Epic successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'ユーザー動線',
          description: 'ユーザー動線に関するEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['epic_id']).to be_present
        expect(response_text['subject']).to eq('ユーザー動線')

        # Epicが実際に作成されたか確認
        epic = Issue.find(response_text['epic_id'])
        expect(epic.tracker.name).to eq(EpicGrid::TrackerHierarchy.tracker_names[:epic])
        expect(epic.subject).to eq('ユーザー動線')
        expect(epic.description).to eq('ユーザー動線に関するEpic')
      end

      it 'creates an Epic with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          subject: 'テストEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Epic to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストEpic',
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        epic = Issue.find(response_text['epic_id'])
        expect(epic.assigned_to).to eq(user)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          subject: 'テストEpic',
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
          subject: 'テストEpic',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Epic作成権限がありません')
      end

      it 'returns error when Epic tracker not configured' do
        # Epicトラッカーを削除
        project.trackers.delete(epic_tracker)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Epicトラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Epic')
      expect(described_class.description).to include('大分類')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema[:properties]).to include(:project_id, :subject)
      expect(schema[:required]).to include('project_id', 'subject')
    end
  end
end
