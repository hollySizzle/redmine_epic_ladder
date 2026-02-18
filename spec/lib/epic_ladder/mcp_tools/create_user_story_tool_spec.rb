# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateUserStoryTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:parent_feature) { create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature') }

  before do
    member # ensure member exists
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
      'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
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
      it 'creates a UserStory successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: '申込画面を作る',
          parent_feature_id: parent_feature.id.to_s,
          description: '申込画面を作成するUserStory',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['user_story_id']).to be_present
        expect(response_text['subject']).to eq('申込画面を作る')

        # UserStoryが実際に作成されたか確認
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:user_story])
        expect(user_story.subject).to eq('申込画面を作る')
        expect(user_story.description).to eq('申込画面を作成するUserStory')
        expect(user_story.parent).to eq(parent_feature)
      end

      it 'creates a UserStory with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns UserStory to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.assigned_to).to eq(user)
      end

      it 'assigns UserStory to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.fixed_version).to eq(version)
      end

      it 'handles special characters in subject and description' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'UserStory with <special> & "characters"',
          parent_feature_id: parent_feature.id.to_s,
          description: 'Description with <html> & "quotes"',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.subject).to eq('UserStory with <special> & "characters"')
        expect(user_story.description).to include('<html>')
      end

      it 'handles Japanese characters and emojis' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'ユーザー登録フォーム 📝',
          parent_feature_id: parent_feature.id.to_s,
          description: '新規ユーザーが登録できるようにする 🎉',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        user_story = Issue.find(response_text['user_story_id'])
        expect(user_story.subject).to eq('ユーザー登録フォーム 📝')
        expect(user_story.description).to include('🎉')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
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
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when UserStory tracker not configured' do
        # UserStoryトラッカーをプロジェクトから削除
        project.trackers.delete(user_story_tracker)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: parent_feature.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('トラッカーが設定されていません')
      end

      it 'returns error when parent feature not found' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケットが見つかりません')
      end

      it 'returns error when parent is Epic instead of Feature (hierarchy violation)' do
        epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Parent Epic')

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストUserStory',
          parent_feature_id: epic.id.to_s,
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
      expect(described_class.description).to include('UserStory')
      expect(described_class.description).to include('user requirement')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :subject, :parent_feature_id, :version_id)
      expect(schema.instance_variable_get(:@required)).to include(:subject, :parent_feature_id)
    end
  end
end
