# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateVersionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :manage_versions]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    User.current = user

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'mcp_enabled' => '1'
    }

    # プロジェクト単位のMCP許可設定
    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a Version successfully' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'Sprint 2025-02',
          effective_date: '2025-02-28',
          description: 'Sprint 2025-02のリリース',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['version_id']).to be_present
        expect(response_text['name']).to eq('Sprint 2025-02')
        expect(response_text['effective_date']).to eq('2025-02-28')

        # Versionが実際に作成されたか確認
        version = Version.find(response_text['version_id'])
        expect(version.name).to eq('Sprint 2025-02')
        expect(version.description).to eq('Sprint 2025-02のリリース')
        expect(version.effective_date.to_s).to eq('2025-02-28')
        expect(version.status).to eq('open')
      end

      it 'creates a Version with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          name: 'テストVersion',
          effective_date: '2025-03-31',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'creates a Version with custom status' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'テストVersion',
          effective_date: '2025-03-31',
          status: 'locked',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        version = Version.find(response_text['version_id'])
        expect(version.status).to eq('locked')
      end

      it 'creates a Version with closed status' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'Closed Version',
          effective_date: '2025-03-31',
          status: 'closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        version = Version.find(response_text['version_id'])
        expect(version.status).to eq('closed')
      end

      it 'creates a Version with past effective_date' do
        # 過去日付でもバージョン作成は許可される（リリース済みの記録用途）
        result = described_class.call(
          project_id: project.identifier,
          name: 'Past Version',
          effective_date: '2020-01-01',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['effective_date']).to eq('2020-01-01')
      end

      it 'creates a Version without description' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'No Description Version',
          effective_date: '2025-06-30',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        version = Version.find(response_text['version_id'])
        expect(version.description).to be_nil
      end

      it 'uses default_project from server_context when project_id is omitted' do
        # X-Default-Projectヘッダーが設定されている場合のテスト
        context_with_default = { user: user, default_project: project.identifier }

        result = described_class.call(
          name: 'Default Project Version',
          effective_date: '2025-07-31',
          server_context: context_with_default
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          name: 'テストVersion',
          effective_date: '2025-03-31',
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
          name: 'テストVersion',
          effective_date: '2025-03-31',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Version作成権限がありません')
      end

      it 'returns error when effective_date is invalid' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'テストVersion',
          effective_date: 'invalid-date',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('無効な日付形式です')
      end

      it 'returns error when duplicate version name exists' do
        # 同一プロジェクト内で重複名のバージョン
        create(:version, project: project, name: 'Existing Version')

        result = described_class.call(
          project_id: project.identifier,
          name: 'Existing Version',
          effective_date: '2025-04-30',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Version作成に失敗しました')
      end

      it 'returns error with empty name' do
        result = described_class.call(
          project_id: project.identifier,
          name: '',
          effective_date: '2025-05-31',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
      end

      it 'returns error with invalid status' do
        result = described_class.call(
          project_id: project.identifier,
          name: 'Invalid Status Version',
          effective_date: '2025-06-30',
          status: 'invalid_status',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Version')
      expect(described_class.description).to include('release milestone')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :name, :effective_date)
      # project_idはDEFAULT_PROJECTがあれば省略可能なのでrequiredではない
      expect(schema.instance_variable_get(:@required)).to include(:name, :effective_date)
    end
  end
end
