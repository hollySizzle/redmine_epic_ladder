# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateBugTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:bug_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:bug],
      default_status: IssueStatus.first
    )
  end
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:feature_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:feature],
      default_status: IssueStatus.first
    )
  end
  let(:parent_user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory') }

  before do
    member # ensure member exists
    project.trackers << bug_tracker unless project.trackers.include?(bug_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'bug_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:bug],
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
      it 'creates a Bug successfully' do
        result = described_class.call(
          project_id: project.identifier,
          description: '申込フォームのバリデーションが効かない',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['bug_id']).to be_present
        expect(response_text['subject']).to be_present

        # Bugが実際に作成されたか確認
        bug = Issue.find(response_text['bug_id'])
        expect(bug.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:bug])
        expect(bug.description).to eq('申込フォームのバリデーションが効かない')
        expect(bug.parent).to eq(parent_user_story)
      end

      it 'creates a Bug with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          description: 'テストBug',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Bug to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストBug',
          parent_user_story_id: parent_user_story.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        bug = Issue.find(response_text['bug_id'])
        expect(bug.assigned_to).to eq(user)
      end

      it 'assigns Bug to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストBug',
          parent_user_story_id: parent_user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        bug = Issue.find(response_text['bug_id'])
        expect(bug.fixed_version).to eq(version)
      end

      it 'handles special characters in description' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'Bug with <special> & "characters" causing issues',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        bug = Issue.find(response_text['bug_id'])
        expect(bug.description).to include('<special>')
        expect(bug.description).to include('&')
      end

      it 'handles Japanese characters and emojis' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'バリデーションエラーが表示されない 🐛',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        bug = Issue.find(response_text['bug_id'])
        expect(bug.description).to include('バリデーションエラー')
        expect(bug.description).to include('🐛')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          description: 'テストBug',
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
          description: 'テストBug',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when Bug tracker not configured' do
        # Bugトラッカーをプロジェクトから削除
        project.trackers.delete(bug_tracker)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストBug',
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
          description: 'テストBug',
          parent_user_story_id: nil,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケット')
      end

      it 'allows Bug under Feature (Bug can have UserStory or Feature as parent)' do
        feature = create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature')

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストBug under Feature',
          parent_user_story_id: feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        # Bug can be created under Feature (by design - see TrackerHierarchy.rules)
        expect(response_text['success']).to be true

        bug = Issue.find(response_text['bug_id'])
        expect(bug.parent).to eq(feature)
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Bug')
      expect(described_class.description).to include('defect')
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
