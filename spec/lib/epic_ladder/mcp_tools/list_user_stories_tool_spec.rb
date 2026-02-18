# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ListUserStoriesTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:version) { create(:version, project: project, name: 'Version 1.0') }
  let(:open_status) { IssueStatus.find_or_create_by!(name: 'Open') { |s| s.is_closed = false } }
  let(:closed_status) { IssueStatus.find_or_create_by!(name: 'Closed') { |s| s.is_closed = true } }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    open_status
    closed_status

    # MCP API有効化
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
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'lists all user stories in project' do
        story1 = create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 1', status: open_status)
        story2 = create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 2', status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(2)
        expect(response_text['user_stories'].map { |s| s['id'] }).to include(story1.id.to_s, story2.id.to_s)
      end

      it 'filters user stories by version' do
        story_with_version = create(:issue, project: project, tracker: user_story_tracker, fixed_version: version)
        create(:issue, project: project, tracker: user_story_tracker) # story without version

        result = described_class.call(
          project_id: project.identifier,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['user_stories'].first['id']).to eq(story_with_version.id.to_s)
      end

      it 'filters user stories by assignee' do
        assigned_story = create(:issue, project: project, tracker: user_story_tracker, assigned_to: user)
        create(:issue, project: project, tracker: user_story_tracker) # unassigned story

        result = described_class.call(
          project_id: project.identifier,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['user_stories'].first['id']).to eq(assigned_story.id.to_s)
      end

      it 'filters user stories by open status' do
        open_story = create(:issue, project: project, tracker: user_story_tracker, status: open_status)
        create(:issue, project: project, tracker: user_story_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'open',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['user_stories'].first['id']).to eq(open_story.id.to_s)
      end

      it 'filters user stories by closed status' do
        create(:issue, project: project, tracker: user_story_tracker, status: open_status)
        closed_story = create(:issue, project: project, tracker: user_story_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['user_stories'].first['id']).to eq(closed_story.id.to_s)
      end

      it 'limits the number of results' do
        5.times { |i| create(:issue, project: project, tracker: user_story_tracker, subject: "Story #{i}") }

        result = described_class.call(
          project_id: project.identifier,
          limit: 3,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(3)
      end

      it 'includes complete user story details' do
        story = create(:issue,
          project: project,
          tracker: user_story_tracker,
          subject: 'Test Story',
          description: 'Test description',
          assigned_to: user,
          fixed_version: version,
          status: open_status
        )

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['user_stories'].first

        expect(story_data['subject']).to eq('Test Story')
        expect(story_data['status']['name']).to eq('Open')
        expect(story_data['version']['name']).to eq('Version 1.0')
        expect(story_data['assigned_to']['id']).to eq(user.id.to_s)
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

      it 'returns error when UserStory tracker not configured' do
        # UserStoryトラッカーを削除
        Tracker.where(name: EpicLadder::TrackerHierarchy.tracker_names[:user_story]).destroy_all

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('UserStoryトラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('UserStory')
    end

    it 'has optional input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      # project_idはDEFAULT_PROJECTがあれば省略可能
    end
  end
end
