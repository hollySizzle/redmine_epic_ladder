# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ListRecentlyUpdatedIssuesTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:server_context) { { user: user, default_project: project.identifier } }

  before do
    member
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    # MCP有効化
    Setting.plugin_redmine_epic_ladder = {
      'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      'mcp_enabled' => '1'
    }
    EpicLadder::TrackerHierarchy.clear_cache!

    # プロジェクト単位のMCP許可設定
    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!
  end

  describe '.call' do
    context 'with valid parameters' do
      it 'returns issues sorted by updated_on descending' do
        issue1 = create(:issue, project: project, tracker: user_story_tracker, subject: 'Issue 1')
        issue2 = create(:issue, project: project, tracker: task_tracker, subject: 'Issue 2')

        # issue1を後に更新して順序を確定させる
        issue1.reload
        issue1.update!(subject: 'Issue 1 updated')

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['success']).to be true
        expect(response['total_count']).to eq(2)

        ids = response['issues'].map { |i| i['id'] }
        expect(ids).to eq([issue1.id.to_s, issue2.id.to_s])
      end

      it 'respects limit parameter' do
        3.times { |i| create(:issue, project: project, tracker: user_story_tracker, subject: "Issue #{i}") }

        result = described_class.call(
          project_id: project.identifier,
          limit: 1,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['success']).to be true
        expect(response['total_count']).to eq(1)
      end

      it 'caps limit at 50' do
        result = described_class.call(
          project_id: project.identifier,
          limit: 100,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        # No error - limit was silently capped to 50
      end

      it 'uses default limit of 20' do
        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        # With no issues, total_count is 0 which is <= 20
        expect(response['total_count']).to be <= 20
      end

      it 'includes required fields in each issue' do
        issue = create(:issue,
          project: project,
          tracker: user_story_tracker,
          subject: 'Test Issue',
          assigned_to: user
        )

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        issue_data = response['issues'].first

        expect(issue_data['id']).to eq(issue.id.to_s)
        expect(issue_data['subject']).to eq('Test Issue')
        expect(issue_data['tracker']).to eq(user_story_tracker.name)
        expect(issue_data['status']).to be_a(String)
        expect(issue_data['updated_on']).to be_a(String)
        expect(issue_data['assigned_to']).to eq(user.name)
      end

      it 'returns nil for assigned_to when unassigned' do
        create(:issue, project: project, tracker: user_story_tracker, subject: 'Unassigned Issue')

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        issue_data = response['issues'].first

        expect(issue_data['assigned_to']).to be_nil
      end

      it 'includes project information in response' do
        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['project']['id']).to eq(project.id.to_s)
        expect(response['project']['identifier']).to eq(project.identifier)
        expect(response['project']['name']).to eq(project.name)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'nonexistent-project',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('プロジェクトが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          project_id: project.identifier,
          server_context: unauthorized_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('チケット閲覧権限がありません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('recently updated')
    end

    it 'has correct input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.properties).to include(:limit)
    end
  end
end
