# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateEpicTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:epic],
      default_status: IssueStatus.first
    )
  end

  before do
    member # ensure member exists
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
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
      it 'creates an Epic successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'ユーザー動線',
          description: 'ユーザー動線に関するEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['epic_id']).to be_present
        expect(response_text['subject']).to eq('ユーザー動線')

        # Epicが実際に作成されたか確認
        epic = Issue.find(response_text['epic_id'])
        expect(epic.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:epic])
        expect(epic.subject).to eq('ユーザー動線')
        expect(epic.description).to eq('ユーザー動線に関するEpic')
      end

      it 'creates an Epic with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          subject: 'テストEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Epic to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストEpic',
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        epic = Issue.find(response_text['epic_id'])
        expect(epic.assigned_to).to eq(user)
      end

      it 'assigns Epic to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストEpic',
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        epic = Issue.find(response_text['epic_id'])
        expect(epic.fixed_version).to eq(version)
      end

      it 'handles special characters in subject and description' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'Epic with <special> & "characters" + \'quotes\'',
          description: 'Description with <html>, &amp;, "double", \'single\' quotes',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        epic = Issue.find(response_text['epic_id'])
        expect(epic.subject).to eq('Epic with <special> & "characters" + \'quotes\'')
        expect(epic.description).to include('<html>')
        expect(epic.description).to include('&amp;')
      end

      it 'handles Japanese characters and emojis' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'ユーザー体験改善 🚀✨',
          description: '日本語の説明文です。絵文字も使えます 👍🎉',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        epic = Issue.find(response_text['epic_id'])
        expect(epic.subject).to eq('ユーザー体験改善 🚀✨')
        expect(epic.description).to include('日本語の説明文')
        expect(epic.description).to include('👍🎉')
      end

      it 'uses subject as description when description is omitted' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'Epic without description',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        epic = Issue.find(response_text['epic_id'])
        expect(epic.description).to eq('Epic without description')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          subject: 'テストEpic',
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
          subject: 'テストEpic',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when Epic tracker not configured' do
        # Epicトラッカーをプロジェクトから削除
        project.trackers.delete(epic_tracker)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストEpic',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('トラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Epic')
      expect(described_class.description).to include('top-level category')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :subject, :version_id)
      expect(schema.instance_variable_get(:@required)).to include(:subject)
    end
  end
end
