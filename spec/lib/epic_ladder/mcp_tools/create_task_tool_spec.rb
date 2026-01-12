# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateTaskTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:parent_user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory') }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
      'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
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
      it 'creates a Task successfully' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'カートのリファクタリング',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['task_id']).to be_present
        expect(response_text['subject']).to be_present

        # Taskが実際に作成されたか確認
        task = Issue.find(response_text['task_id'])
        expect(task.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:task])
        expect(task.description).to eq('カートのリファクタリング')
        expect(task.parent).to eq(parent_user_story)
      end

      it 'creates a Task with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Task to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        task = Issue.find(response_text['task_id'])
        expect(task.assigned_to).to eq(user)
      end

      it 'assigns Task to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        task = Issue.find(response_text['task_id'])
        expect(task.fixed_version).to eq(version)
      end

      it 'handles special characters in description' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'Task with <special> & "characters" in description',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        task = Issue.find(response_text['task_id'])
        expect(task.description).to include('<special>')
        expect(task.description).to include('&')
      end

      it 'handles Japanese characters and emojis' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'ショッピングカートのリファクタリング 🛒✨',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        task = Issue.find(response_text['task_id'])
        expect(task.description).to include('ショッピングカート')
        expect(task.description).to include('🛒')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
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
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when Task tracker not configured' do
        # Taskトラッカーをプロジェクトから削除
        project.trackers.delete(task_tracker)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('トラッカーが設定されていません')
      end

      it 'returns error when parent_user_story_id is missing' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: nil,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケット')
      end

      it 'returns error when parent is Feature instead of UserStory (hierarchy violation)' do
        feature = create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature')

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('階層違反')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Task')
      expect(described_class.description).to include('natural language')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :description, :parent_user_story_id, :version_id)
      required_fields = schema.instance_variable_get(:@required)
      expect(required_fields).to include(:description)
      expect(required_fields).to include(:parent_user_story_id)
      expect(required_fields).not_to include(:project_id)
    end
  end
end
