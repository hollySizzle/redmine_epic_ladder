# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::AddRelatedIssueTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :manage_issue_relations]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:issue1) { create(:issue, project: project, tracker: task_tracker, subject: 'Issue 1') }
  let(:issue2) { create(:issue, project: project, tracker: task_tracker, subject: 'Issue 2') }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates relates relation by default' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['relation_type']).to eq('relates')
      end

      it 'creates blocks relation' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          relation_type: 'blocks',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['relation_type']).to eq('blocks')
      end

      it 'creates precedes relation' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          relation_type: 'precedes',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['relation_type']).to eq('precedes')
      end

      it 'returns all expected fields in response' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['relation_id']).to be_present
        expect(response_text['issue_id']).to eq(issue1.id.to_s)
        expect(response_text['related_issue_id']).to eq(issue2.id.to_s)
        expect(response_text['relation_type']).to be_present
        expect(response_text['actual_relation_type']).to be_present
        expect(response_text['actual_issue_from_id']).to be_present
        expect(response_text['actual_issue_to_id']).to be_present
        expect(response_text['issue_url']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue_id not found' do
        result = described_class.call(
          issue_id: '99999',
          related_issue_id: issue2.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
        expect(response_text['error']).to include('99999')
      end

      it 'returns error when related_issue_id not found' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
        expect(response_text['error']).to include('99999')
      end

      it 'returns error for invalid relation_type' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          relation_type: 'invalid_type',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('無効な関連タイプです')
      end

      it 'returns error when user lacks view_issues permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット閲覧権限がありません')
      end

      it 'returns error when user lacks manage_issue_relations permission' do
        view_only_role = create(:role, permissions: [:view_issues])
        view_only_user = create(:user)
        create(:member, project: project, user: view_only_user, roles: [view_only_role])
        view_only_context = { user: view_only_user }

        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: view_only_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('関連チケット管理権限がありません')
      end

      it 'returns error for duplicate relation' do
        # First call succeeds
        result1 = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: server_context
        )
        response1 = JSON.parse(result1.content.first[:text])
        expect(response1['success']).to be true

        # Second call with same parameters should fail
        result2 = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue2.id.to_s,
          server_context: server_context
        )
        response2 = JSON.parse(result2.content.first[:text])
        expect(response2['success']).to be false
      end
    end

    context 'edge cases' do
      it 'returns error for self-referencing relation' do
        result = described_class.call(
          issue_id: issue1.id.to_s,
          related_issue_id: issue1.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
      end
    end
  end

  describe 'tool metadata' do
    it 'has description containing relation' do
      expect(described_class.description).to include('relation')
    end

    it 'has required input schema fields' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :related_issue_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :related_issue_id)
    end
  end
end
