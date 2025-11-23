# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::UpdateIssueStatusTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:open_status) { IssueStatus.find_or_create_by!(name: 'Open') { |s| s.is_closed = false } }
  let(:in_progress_status) { IssueStatus.find_or_create_by!(name: 'In Progress') { |s| s.is_closed = false } }
  let(:closed_status) { IssueStatus.find_or_create_by!(name: 'Closed') { |s| s.is_closed = true } }
  let(:task) { create(:issue, project: project, tracker: task_tracker, status: open_status) }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    open_status
    in_progress_status
    closed_status
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates issue status successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          status_name: 'In Progress',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_status']['name']).to eq('Open')
        expect(response_text['new_status']['name']).to eq('In Progress')

        # ステータスが実際に変更されたか確認
        task.reload
        expect(task.status).to eq(in_progress_status)
      end

      it 'updates issue status to closed' do
        result = described_class.call(
          issue_id: task.id.to_s,
          status_name: 'Closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_status']['is_closed']).to be true

        # ステータスが実際にクローズされたか確認
        task.reload
        expect(task.status).to eq(closed_status)
        expect(task.status.is_closed).to be true
      end

      it 'finds status case-insensitively' do
        result = described_class.call(
          issue_id: task.id.to_s,
          status_name: 'closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        task.reload
        expect(task.status).to eq(closed_status)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          status_name: 'Closed',
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
          status_name: 'Closed',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット編集権限がありません')
      end

      it 'returns error when status not found' do
        result = described_class.call(
          issue_id: task.id.to_s,
          status_name: 'NonExistentStatus',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('ステータスが見つかりません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('ステータス')
      expect(described_class.description).to include('更新')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :status_name)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :status_name)
    end
  end
end
