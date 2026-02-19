# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CopyIssueTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:version) { create(:version, project: project) }
  let(:parent_issue) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent US') }
  let(:source_issue) do
    create(:issue,
      project: project,
      tracker: task_tracker,
      subject: 'Source Issue Subject',
      description: 'Source Issue Description',
      parent: parent_issue,
      fixed_version: version,
      priority: IssuePriority.default || IssuePriority.first,
      author: user,
      assigned_to: user
    )
  end

  before do
    member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    Setting.plugin_redmine_epic_ladder = {
      'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
      'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      'mcp_enabled' => '1'
    }
    EpicLadder::TrackerHierarchy.clear_cache!
    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'copies issue with default attributes from source' do
        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true

        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.tracker).to eq(source_issue.tracker)
        expect(new_issue.subject).to eq(source_issue.subject)
        expect(new_issue.description).to eq(source_issue.description)
        expect(new_issue.parent).to eq(parent_issue)
        expect(new_issue.fixed_version).to eq(version)
        expect(new_issue.priority).to eq(source_issue.priority)
        expect(new_issue.assigned_to).to eq(user)
        expect(new_issue.done_ratio).to eq(0)
      end

      it 'overrides subject when specified' do
        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          subject: 'Overridden Subject',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.subject).to eq('Overridden Subject')
      end

      it 'overrides description when specified' do
        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          description: 'Overridden Description',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.description).to eq('Overridden Description')
      end

      it 'overrides parent_issue_id when specified' do
        other_parent = create(:issue, project: project, tracker: user_story_tracker, subject: 'Other Parent US')

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          parent_issue_id: other_parent.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.parent).to eq(other_parent)
      end

      it 'overrides version_id when specified' do
        other_version = create(:version, project: project)

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          version_id: other_version.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.fixed_version).to eq(other_version)
      end

      it 'assigns to specified user via assigned_to_id' do
        other_user = create(:user)
        create(:member, project: project, user: other_user, roles: [role])

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          assigned_to_id: other_user.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_issue = Issue.find(response['issue_id'])
        expect(new_issue.assigned_to).to eq(other_user)
      end

      it 'returns success response with expected fields' do
        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['issue_id']).to be_present
        expect(response['issue_url']).to be_present
        expect(response['subject']).to eq(source_issue.subject)
        expect(response['tracker']).to eq(task_tracker.name)
        expect(response['source_issue']).to include('id' => source_issue.id.to_s, 'subject' => source_issue.subject)
        expect(response['parent_issue']).to include('id' => parent_issue.id.to_s, 'subject' => parent_issue.subject)
        expect(response['version']).to include('id' => version.id.to_s, 'name' => version.name)
        expect(response['assigned_to']).to include('id' => user.id.to_s)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when source_issue_id not found' do
        result = described_class.call(
          source_issue_id: '999999',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('コピー元チケットが見つかりません')
      end

      it 'returns error when user lacks add_issues permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        # Ensure source_issue exists and is accessible but user has no permission to create
        source_issue

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          server_context: unauthorized_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
      end

      it 'returns error when MCP API is globally disabled' do
        Setting.plugin_redmine_epic_ladder = {
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'mcp_enabled' => '0'
        }

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('MCP API')
      end

      it 'returns error when project MCP is not allowed' do
        setting = EpicLadder::ProjectSetting.for_project(project)
        setting.mcp_enabled = false
        setting.save!

        result = described_class.call(
          source_issue_id: source_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('MCP API')
      end

      it 'returns error when user cannot view source issue in another project' do
        other_project = create(:project)
        other_project.trackers << task_tracker unless other_project.trackers.include?(task_tracker)
        other_issue = create(:issue, project: other_project, tracker: task_tracker, subject: 'Other Project Issue')

        # user has no membership in other_project so cannot view issues
        result = described_class.call(
          source_issue_id: other_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('閲覧権限')
      end
    end
  end

  describe 'tool metadata' do
    it 'has description containing Copies' do
      expect(described_class.description).to include('Copies')
    end

    it 'has source_issue_id as required in input schema' do
      schema = described_class.input_schema
      required_fields = schema.instance_variable_get(:@required)
      expect(required_fields).to include(:source_issue_id)
    end
  end
end
