# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::ListEpicsTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:epic],
      default_status: IssueStatus.first
    )
  end
  let(:open_status) { IssueStatus.create!(name: 'Open', is_closed: false) }
  let(:closed_status) { IssueStatus.create!(name: 'Closed', is_closed: true) }

  before do
    member # ensure member exists
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    open_status
    closed_status
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'lists all epics in project' do
        epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1', status: open_status)
        epic2 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 2', status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(2)
        expect(response_text['epics'].map { |e| e['id'] }).to include(epic1.id.to_s, epic2.id.to_s)
      end

      it 'filters epics by assignee' do
        assigned_epic = create(:issue, project: project, tracker: epic_tracker, assigned_to: user)
        create(:issue, project: project, tracker: epic_tracker) # unassigned epic

        result = described_class.call(
          project_id: project.identifier,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['epics'].first['id']).to eq(assigned_epic.id.to_s)
      end

      it 'filters epics by open status' do
        open_epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        create(:issue, project: project, tracker: epic_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'open',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['epics'].first['id']).to eq(open_epic.id.to_s)
      end

      it 'filters epics by closed status' do
        create(:issue, project: project, tracker: epic_tracker, status: open_status)
        closed_epic = create(:issue, project: project, tracker: epic_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['epics'].first['id']).to eq(closed_epic.id.to_s)
      end

      it 'limits the number of results' do
        5.times { |i| create(:issue, project: project, tracker: epic_tracker, subject: "Epic #{i}") }

        result = described_class.call(
          project_id: project.identifier,
          limit: 3,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(3)
      end

      it 'includes complete epic details' do
        epic = create(:issue,
          project: project,
          tracker: epic_tracker,
          subject: 'Test Epic',
          description: 'Test description',
          assigned_to: user,
          status: open_status
        )

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        epic_data = response_text['epics'].first

        expect(epic_data['subject']).to eq('Test Epic')
        expect(epic_data['status']['name']).to eq('Open')
        expect(epic_data['status']['is_closed']).to be false
        expect(epic_data['assigned_to']['id']).to eq(user.id.to_s)
      end

      it 'includes children count' do
        epic = create(:issue, project: project, tracker: epic_tracker)
        feature_tracker = Tracker.create!(name: EpicGrid::TrackerHierarchy.tracker_names[:feature], default_status: IssueStatus.first)
        project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
        create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        epic_data = response_text['epics'].first

        expect(epic_data['children_count']).to eq(2)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
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
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット閲覧権限がありません')
      end

      it 'returns error when Epic tracker not configured' do
        # Epicトラッカーを削除
        Tracker.where(name: EpicGrid::TrackerHierarchy.tracker_names[:epic]).destroy_all

        result = described_class.call(
          project_id: project.identifier,
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
      expect(described_class.description).to include('一覧')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.instance_variable_get(:@required)).to include(:project_id)
    end
  end
end
