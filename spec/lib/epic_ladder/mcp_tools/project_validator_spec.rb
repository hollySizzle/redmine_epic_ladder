# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ProjectValidator, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
  end

  describe '.resolve_project_id' do
    context '明示的なproject_idが指定された場合' do
      it '指定されたproject_idを返す' do
        result = described_class.resolve_project_id('my-project')
        expect(result).to eq('my-project')
      end

      it '数値IDでも文字列として返す' do
        result = described_class.resolve_project_id('123')
        expect(result).to eq('123')
      end

      it '空白を含む識別子も処理する' do
        result = described_class.resolve_project_id('  my-project  ')
        expect(result).to eq('  my-project  ')
      end
    end

    context 'project_idがnilの場合' do
      it 'server_contextのdefault_projectを返す' do
        server_context = { default_project: 'default-proj' }
        result = described_class.resolve_project_id(nil, server_context: server_context)
        expect(result).to eq('default-proj')
      end

      it 'server_contextがnilの場合はnilを返す' do
        result = described_class.resolve_project_id(nil, server_context: nil)
        expect(result).to be_nil
      end

      it 'server_contextが空Hashの場合はnilを返す' do
        result = described_class.resolve_project_id(nil, server_context: {})
        expect(result).to be_nil
      end

      it 'server_contextにdefault_projectがない場合はnilを返す' do
        server_context = { user: user }
        result = described_class.resolve_project_id(nil, server_context: server_context)
        expect(result).to be_nil
      end

      it 'server_contextのdefault_projectが空文字の場合はnilを返す' do
        server_context = { default_project: '' }
        result = described_class.resolve_project_id(nil, server_context: server_context)
        expect(result).to be_nil
      end
    end

    context '空文字の場合' do
      it 'server_contextのdefault_projectにフォールバック' do
        server_context = { default_project: 'fallback-proj' }
        result = described_class.resolve_project_id('', server_context: server_context)
        expect(result).to eq('fallback-proj')
      end

      it 'server_contextもない場合はnilを返す' do
        result = described_class.resolve_project_id('')
        expect(result).to be_nil
      end
    end

    context '優先順位のテスト' do
      it 'project_idがserver_contextより優先される' do
        server_context = { default_project: 'default-proj' }
        result = described_class.resolve_project_id('explicit-proj', server_context: server_context)
        expect(result).to eq('explicit-proj')
      end
    end
  end

  describe '.mcp_enabled?' do
    context 'グローバル設定が有効な場合' do
      before do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '1' }
      end

      it 'trueを返す' do
        expect(described_class.mcp_enabled?).to be true
      end
    end

    context 'グローバル設定が無効な場合' do
      before do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '0' }
      end

      it 'falseを返す' do
        expect(described_class.mcp_enabled?).to be false
      end
    end

    context 'グローバル設定がない場合' do
      before do
        Setting.plugin_redmine_epic_ladder = {}
      end

      it 'falseを返す' do
        expect(described_class.mcp_enabled?).to be false
      end
    end

    context 'プラグイン設定自体がnilの場合' do
      before do
        Setting.plugin_redmine_epic_ladder = nil
      end

      it 'falseを返す' do
        expect(described_class.mcp_enabled?).to be false
      end
    end
  end

  describe '.project_allowed?' do
    context 'プロジェクトでMCPが有効な場合' do
      before do
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
      end

      it 'trueを返す' do
        expect(described_class.project_allowed?(project)).to be true
      end
    end

    context 'プロジェクトでMCPが無効な場合' do
      before do
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: false)
      end

      it 'falseを返す' do
        expect(described_class.project_allowed?(project)).to be false
      end
    end

    context 'プロジェクト設定がない場合' do
      it 'グローバル設定にフォールバック（デフォルトはfalse）' do
        expect(described_class.project_allowed?(project)).to be false
      end
    end
  end

  describe '.project_not_allowed_response' do
    it 'MCP::Tool::Responseオブジェクトを返す' do
      result = described_class.project_not_allowed_response(project)
      expect(result).to be_a(MCP::Tool::Response)
    end

    it '正しいJSON構造を持つ' do
      result = described_class.project_not_allowed_response(project)
      json = JSON.parse(result.content.first[:text])

      expect(json['success']).to be false
      expect(json['error']).to include('MCP APIが許可されていません')
      expect(json['error']).to include(project.identifier)
    end

    it 'プロジェクト識別子を含む' do
      result = described_class.project_not_allowed_response(project)
      json = JSON.parse(result.content.first[:text])

      expect(json['details']['project_id']).to eq(project.identifier)
    end

    it 'ヒントを含む' do
      result = described_class.project_not_allowed_response(project)
      json = JSON.parse(result.content.first[:text])

      expect(json['details']['hint']).to include('Epic Ladder')
      expect(json['details']['hint']).to include('MCP API')
    end

    it '日本語プロジェクト名でも動作する' do
      japanese_project = create(:project, identifier: 'nihongo-proj', name: '日本語プロジェクト')
      result = described_class.project_not_allowed_response(japanese_project)
      json = JSON.parse(result.content.first[:text])

      expect(json['details']['project_id']).to eq('nihongo-proj')
    end
  end

  describe '.mcp_disabled_response' do
    it 'MCP::Tool::Responseオブジェクトを返す' do
      result = described_class.mcp_disabled_response
      expect(result).to be_a(MCP::Tool::Response)
    end

    it '正しいJSON構造を持つ' do
      result = described_class.mcp_disabled_response
      json = JSON.parse(result.content.first[:text])

      expect(json['success']).to be false
      expect(json['error']).to include('MCP APIが無効')
    end

    it '管理画面での設定方法を案内する' do
      result = described_class.mcp_disabled_response
      json = JSON.parse(result.content.first[:text])

      expect(json['error']).to include('管理画面')
    end
  end

  describe '統合テスト' do
    context 'グローバル有効、プロジェクト有効' do
      before do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '1' }
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
      end

      it 'MCPが利用可能' do
        expect(described_class.mcp_enabled?).to be true
        expect(described_class.project_allowed?(project)).to be true
      end
    end

    context 'グローバル無効、プロジェクト有効' do
      before do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '0' }
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
      end

      it 'グローバルが無効でもプロジェクト単位では有効' do
        expect(described_class.mcp_enabled?).to be false
        expect(described_class.project_allowed?(project)).to be true
      end
    end

    context 'グローバル有効、プロジェクト無効' do
      before do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '1' }
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: false)
      end

      it 'プロジェクト単位で無効化される' do
        expect(described_class.mcp_enabled?).to be true
        expect(described_class.project_allowed?(project)).to be false
      end
    end
  end
end
