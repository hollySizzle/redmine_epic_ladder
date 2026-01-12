# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueStatusTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
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

    context 'with parent-child issue constraints' do
      let(:parent_issue) { create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Parent Task') }
      let(:child_issue) { create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Child Task', parent_issue_id: parent_issue.id) }

      before do
        # 親子関係を確立
        child_issue
        parent_issue.reload
      end

      describe 'closing parent with open subtasks' do
        it 'returns error when trying to close parent with open child' do
          result = described_class.call(
            issue_id: parent_issue.id.to_s,
            status_name: 'Closed',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])
          details = response_text['details'] || {}

          expect(response_text['success']).to be false
          expect(response_text['error']).to include('未完了の子チケット')
          expect(details['reason']).to eq('open_subtasks')
          expect(details['open_subtasks_count']).to eq(1)
          expect(details['open_subtasks']).to be_an(Array)
          expect(details['open_subtasks'].first['id']).to eq(child_issue.id.to_s)
          expect(details['hint']).to include('子チケットをクローズ')
        end

        it 'allows closing parent when all children are closed' do
          # 子チケットを先にクローズ
          child_issue.update!(status: closed_status)
          parent_issue.reload

          result = described_class.call(
            issue_id: parent_issue.id.to_s,
            status_name: 'Closed',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          expect(response_text['success']).to be true
          expect(response_text['new_status']['is_closed']).to be true

          parent_issue.reload
          expect(parent_issue.status).to eq(closed_status)
        end

        it 'returns multiple open subtasks info' do
          # 追加の子チケットを作成
          child_issue2 = create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Child Task 2', parent_issue_id: parent_issue.id)
          child_issue3 = create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Child Task 3', parent_issue_id: parent_issue.id)
          parent_issue.reload

          result = described_class.call(
            issue_id: parent_issue.id.to_s,
            status_name: 'Closed',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])
          details = response_text['details'] || {}

          expect(response_text['success']).to be false
          expect(details['open_subtasks_count']).to eq(3)
          expect(details['open_subtasks'].length).to eq(3)
        end
      end

      describe 'reopening child of closed parent' do
        before do
          # 子と親を両方クローズ
          child_issue.update!(status: closed_status)
          parent_issue.reload
          parent_issue.update!(status: closed_status)
        end

        it 'returns error when trying to reopen child of closed parent' do
          result = described_class.call(
            issue_id: child_issue.id.to_s,
            status_name: 'Open',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])
          details = response_text['details'] || {}

          expect(response_text['success']).to be false
          expect(response_text['error']).to include('親チケットがクローズ済み')
          expect(details['reason']).to eq('closed_parent')
          expect(details['parent_id']).to eq(parent_issue.id.to_s)
          expect(details['parent_subject']).to eq('Parent Task')
          expect(details['hint']).to include('親チケットを再オープン')
        end

        it 'allows reopening child when parent is reopened first' do
          # 親を先に再オープン
          parent_issue.update!(status: open_status)

          result = described_class.call(
            issue_id: child_issue.id.to_s,
            status_name: 'Open',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          expect(response_text['success']).to be true
          expect(response_text['new_status']['is_closed']).to be false

          child_issue.reload
          expect(child_issue.status).to eq(open_status)
        end
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('status')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :status_name)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :status_name)
    end
  end
end
