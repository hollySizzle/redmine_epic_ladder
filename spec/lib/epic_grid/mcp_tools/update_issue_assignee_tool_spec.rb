# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::UpdateIssueAssigneeTool, type: :model do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:another_member) { create(:member, project: project, user: another_user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:task) { create(:issue, project: project, tracker: task_tracker, assigned_to: user) }

  before do
    member # ensure member exists
    another_member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates issue assignee successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: another_user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_assignee']['id']).to eq(user.id.to_s)
        expect(response_text['new_assignee']['id']).to eq(another_user.id.to_s)

        # 担当者が実際に変更されたか確認
        task.reload
        expect(task.assigned_to).to eq(another_user)
      end

      it 'clears assignee when assigned_to_id is null' do
        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: 'null',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_assignee']).to be_nil

        # 担当者が実際にクリアされたか確認
        task.reload
        expect(task.assigned_to).to be_nil
      end

      it 'includes assignee details in response' do
        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: another_user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['new_assignee']['name']).to eq(another_user.name)
        expect(response_text['new_assignee']['login']).to eq(another_user.login)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          assigned_to_id: another_user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: another_user.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット編集権限がありません')
      end

      it 'returns error when assignee not found' do
        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('担当者が見つかりません')
      end

      it 'returns error when assignee is not a project member' do
        non_member = create(:user)

        result = described_class.call(
          issue_id: task.id.to_s,
          assigned_to_id: non_member.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('プロジェクトメンバーではありません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('担当者')
      expect(described_class.description).to include('変更')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :assigned_to_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :assigned_to_id)
    end
  end
end
