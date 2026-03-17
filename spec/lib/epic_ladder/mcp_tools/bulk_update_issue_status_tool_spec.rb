# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::BulkUpdateIssueStatusTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:open_status) { IssueStatus.find_or_create_by!(name: 'Open') { |s| s.is_closed = false } }
  let(:in_progress_status) { IssueStatus.find_or_create_by!(name: 'In Progress') { |s| s.is_closed = false } }
  let(:closed_status) { IssueStatus.find_or_create_by!(name: 'Closed') { |s| s.is_closed = true } }
  let(:server_context) { { user: user } }

  before do
    member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    open_status
    in_progress_status
    closed_status
  end

  describe '.call' do
    context 'with valid parameters' do
      it 'updates multiple issues status at once' do
        issue1 = create(:issue, project: project, tracker: task_tracker, status: open_status)
        issue2 = create(:issue, project: project, tracker: task_tracker, status: open_status)
        issue3 = create(:issue, project: project, tracker: task_tracker, status: open_status)

        result = described_class.call(
          issue_ids: [issue1.id.to_s, issue2.id.to_s, issue3.id.to_s],
          status_name: 'In Progress',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['success']).to be true
        expect(response['succeeded']).to eq(3)
        expect(response['failed']).to eq(0)
        expect(response['total']).to eq(3)
        expect(response['results'].size).to eq(3)

        response['results'].each do |r|
          expect(r['success']).to be true
          expect(r['old_status']).to eq('Open')
          expect(r['new_status']).to eq('In Progress')
        end

        [issue1, issue2, issue3].each do |issue|
          issue.reload
          expect(issue.status).to eq(in_progress_status)
        end
      end
    end

    context 'with comment' do
      it 'creates journal entries with the comment' do
        issue1 = create(:issue, project: project, tracker: task_tracker, status: open_status)
        issue2 = create(:issue, project: project, tracker: task_tracker, status: open_status)

        result = described_class.call(
          issue_ids: [issue1.id.to_s, issue2.id.to_s],
          status_name: 'In Progress',
          comment: 'Bulk status update',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['succeeded']).to eq(2)

        [issue1, issue2].each do |issue|
          issue.reload
          journal = issue.journals.last
          expect(journal).not_to be_nil
          expect(journal.notes).to eq('Bulk status update')
          expect(journal.user).to eq(user)
        end
      end
    end

    context 'with partial failures' do
      it 'reports success and failure individually' do
        issue1 = create(:issue, project: project, tracker: task_tracker, status: open_status)
        non_existent_id = '999999'

        result = described_class.call(
          issue_ids: [issue1.id.to_s, non_existent_id],
          status_name: 'In Progress',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['success']).to be true
        expect(response['succeeded']).to eq(1)
        expect(response['failed']).to eq(1)
        expect(response['total']).to eq(2)

        success_result = response['results'].find { |r| r['issue_id'] == issue1.id.to_s }
        failure_result = response['results'].find { |r| r['issue_id'] == non_existent_id }

        expect(success_result['success']).to be true
        expect(failure_result['success']).to be false
        expect(failure_result['error']).to include('チケットが見つかりません')

        issue1.reload
        expect(issue1.status).to eq(in_progress_status)
      end
    end

    context 'when issue_ids exceeds 50' do
      it 'returns error' do
        ids = (1..51).map(&:to_s)

        result = described_class.call(
          issue_ids: ids,
          status_name: 'In Progress',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('50件以下')
      end
    end

    context 'when issue_ids is empty' do
      it 'returns error' do
        result = described_class.call(
          issue_ids: [],
          status_name: 'In Progress',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('issue_idsが空です')
      end
    end

    context 'when status does not exist' do
      it 'returns error' do
        issue1 = create(:issue, project: project, tracker: task_tracker, status: open_status)

        result = described_class.call(
          issue_ids: [issue1.id.to_s],
          status_name: 'NonExistentStatus',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('ステータスが見つかりません')
      end
    end

    context 'with closable? check' do
      it 'fails to close parent with open subtasks' do
        parent_issue = create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Parent')
        create(:issue, project: project, tracker: task_tracker, status: open_status, subject: 'Child', parent_issue_id: parent_issue.id)
        parent_issue.reload

        result = described_class.call(
          issue_ids: [parent_issue.id.to_s],
          status_name: 'Closed',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['succeeded']).to eq(0)
        expect(response['failed']).to eq(1)

        failed_result = response['results'].first
        expect(failed_result['success']).to be false
        expect(failed_result['error']).to include('未完了の子チケット')
      end
    end

    context 'without edit_issues permission' do
      it 'fails for all issues' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        issue1 = create(:issue, project: project, tracker: task_tracker, status: open_status)
        issue2 = create(:issue, project: project, tracker: task_tracker, status: open_status)

        result = described_class.call(
          issue_ids: [issue1.id.to_s, issue2.id.to_s],
          status_name: 'In Progress',
          server_context: unauthorized_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['succeeded']).to eq(0)
        expect(response['failed']).to eq(2)

        response['results'].each do |r|
          expect(r['success']).to be false
          expect(r['error']).to include('チケット編集権限がありません')
        end
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('multiple issues')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_ids, :status_name)
      expect(schema.instance_variable_get(:@required)).to include(:issue_ids, :status_name)
    end
  end
end
