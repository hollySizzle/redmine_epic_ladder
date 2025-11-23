# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::UpdateIssueProgressTool, type: :model do
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
  let(:task) { create(:issue, project: project, tracker: task_tracker, done_ratio: 0) }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates issue progress successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 50,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_progress']).to eq(0)
        expect(response_text['new_progress']).to eq(50)

        # 進捗率が実際に変更されたか確認
        task.reload
        expect(task.done_ratio).to eq(50)
      end

      it 'updates issue progress to 100%' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 100,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_progress']).to eq(100)

        task.reload
        expect(task.done_ratio).to eq(100)
      end

      it 'updates issue progress to 0%' do
        task.update!(done_ratio: 50)

        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 0,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_progress']).to eq(0)

        task.reload
        expect(task.done_ratio).to eq(0)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          progress: 50,
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
          progress: 50,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット編集権限がありません')
      end

      it 'returns error when progress is out of range (negative)' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: -10,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('進捗率は0〜100の範囲で指定してください')
      end

      it 'returns error when progress is out of range (over 100)' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 150,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('進捗率は0〜100の範囲で指定してください')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('進捗率')
      expect(described_class.description).to include('更新')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :progress)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :progress)
    end
  end
end
