# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ListStatusesTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    # MCP APIを有効化
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'without project_id (all statuses)' do
      it 'lists all statuses' do
        result = described_class.call(server_context: server_context)

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['statuses']).to be_an(Array)
        expect(response_text['statuses'].size).to eq(IssueStatus.count)
        expect(response_text['source']).to eq('all')
        expect(response_text).not_to have_key('project')
      end

      it 'returns statuses with all required fields' do
        result = described_class.call(server_context: server_context)

        response_text = JSON.parse(result.content.first[:text])
        status_data = response_text['statuses'].first

        expect(status_data).to have_key('id')
        expect(status_data).to have_key('name')
        expect(status_data).to have_key('is_closed')
        expect(status_data).to have_key('position')
        expect(status_data).to have_key('description')
      end

      it 'excludes closed statuses when include_closed is false' do
        result = described_class.call(
          include_closed: false,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        response_text['statuses'].each do |status|
          expect(status['is_closed']).to be false
        end
      end

      it 'includes closed statuses by default' do
        result = described_class.call(server_context: server_context)

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        closed_statuses = response_text['statuses'].select { |s| s['is_closed'] }
        expect(closed_statuses).not_to be_empty
      end

      it 'returns statuses sorted by position' do
        result = described_class.call(server_context: server_context)

        response_text = JSON.parse(result.content.first[:text])
        positions = response_text['statuses'].map { |s| s['position'] }

        expect(positions).to eq(positions.sort)
      end
    end

    context 'with project_id' do
      context 'when workflow is not configured (fallback)' do
        before do
          # ワークフローが存在しない状態にする
          WorkflowTransition.delete_all
        end

        it 'returns all statuses with fallback source' do
          result = described_class.call(
            project_id: project.identifier,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          expect(response_text['success']).to be true
          expect(response_text['project']['identifier']).to eq(project.identifier)
          expect(response_text['statuses'].size).to eq(IssueStatus.count)
          expect(response_text['source']).to eq('all (workflow not configured)')
        end
      end

      context 'when workflow is configured' do
        let(:tracker) { create(:epic_tracker) }
        let(:status_new) { IssueStatus.find_or_create_by!(name: 'WorkflowNew') { |s| s.is_closed = false } }
        let(:status_in_progress) { IssueStatus.find_or_create_by!(name: 'WorkflowInProgress') { |s| s.is_closed = false } }
        let(:status_closed) { IssueStatus.find_or_create_by!(name: 'WorkflowClosed') { |s| s.is_closed = true } }

        before do
          # 既存のワークフローをクリア
          WorkflowTransition.delete_all

          project.trackers << tracker unless project.trackers.include?(tracker)

          # ワークフロー設定
          WorkflowTransition.create!(
            tracker: tracker,
            role: role,
            old_status: status_new,
            new_status: status_in_progress
          )
          WorkflowTransition.create!(
            tracker: tracker,
            role: role,
            old_status: status_in_progress,
            new_status: status_closed
          )
        end

        it 'returns only statuses used in workflows' do
          result = described_class.call(
            project_id: project.identifier,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          expect(response_text['success']).to be true
          expect(response_text['source']).to eq('workflow')

          status_names = response_text['statuses'].map { |s| s['name'] }
          expect(status_names).to include('WorkflowNew', 'WorkflowInProgress', 'WorkflowClosed')
        end

        it 'excludes closed statuses from workflow when include_closed is false' do
          result = described_class.call(
            project_id: project.identifier,
            include_closed: false,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          expect(response_text['success']).to be true
          response_text['statuses'].each do |status|
            expect(status['is_closed']).to be false
          end
        end
      end

      it 'includes project information in response' do
        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['project']['id']).to eq(project.id.to_s)
        expect(response_text['project']['identifier']).to eq(project.identifier)
        expect(response_text['project']['name']).to eq(project.name)
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
        expect(response_text['error']).to include('プロジェクト閲覧権限がありません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('statuses')
    end

    it 'has optional input schema (no required fields)' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.properties).to include(:include_closed)
      expect(schema.instance_variable_get(:@required)).to eq([])
    end
  end
end
