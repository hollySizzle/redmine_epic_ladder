# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueProgressTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
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
        task.reload.update!(done_ratio: 50)

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

    context 'with decimal values' do
      it 'handles decimal progress value' do
        # 小数値が渡された場合の挙動（整数変換されるか、エラーになるか）
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 50.5,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # 小数値は整数に変換されて成功する場合
        if response_text['success']
          task.reload
          expect(task.done_ratio).to be_between(50, 51)
        else
          # エラーになる場合も許容
          expect(response_text['error']).to be_present
        end
      end
    end

    context 'with closed issue' do
      let(:closed_status) { create(:closed_status) }

      it 'allows updating progress of closed issue' do
        closed_task = create(:issue,
                             project: project,
                             tracker: task_tracker,
                             done_ratio: 50,
                             status: closed_status)

        result = described_class.call(
          issue_id: closed_task.id.to_s,
          progress: 100,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # Redmineコアでは通常、クローズ済みIssueの進捗率変更は可能
        expect(response_text['success']).to be true
        expect(response_text['new_progress']).to eq(100)

        closed_task.reload
        expect(closed_task.done_ratio).to eq(100)
      end
    end

    context 'with boundary values' do
      it 'accepts progress value of exactly 0' do
        task_with_progress = create(:issue, project: project, tracker: task_tracker, done_ratio: 50)

        result = described_class.call(
          issue_id: task_with_progress.id.to_s,
          progress: 0,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['new_progress']).to eq(0)
      end

      it 'accepts progress value of exactly 100' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 100,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['new_progress']).to eq(100)
      end

      it 'rejects progress value of -1' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: -1,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
      end

      it 'rejects progress value of 101' do
        result = described_class.call(
          issue_id: task.id.to_s,
          progress: 101,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
      end
    end

    context 'with same value' do
      it 'succeeds when setting progress to same value' do
        task_with_progress = create(:issue, project: project, tracker: task_tracker, done_ratio: 50)

        result = described_class.call(
          issue_id: task_with_progress.id.to_s,
          progress: 50,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['old_progress']).to eq(50)
        expect(response_text['new_progress']).to eq(50)
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('progress')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :progress)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :progress)
    end
  end
end
