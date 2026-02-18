# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::BaseHelper, type: :model do
  # ダミークラスでincludeしてテスト
  let(:dummy_class) do
    Class.new do
      include EpicLadder::McpTools::BaseHelper
    end
  end
  let(:helper) { dummy_class.new }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    # MCP APIを有効化
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '#resolve_project_id' do
    context '明示的なproject_idが指定された場合' do
      it '指定されたproject_idを返す' do
        result = helper.resolve_project_id('my-project')
        expect(result).to eq('my-project')
      end

      it '数値IDでも文字列として返す' do
        result = helper.resolve_project_id('123')
        expect(result).to eq('123')
      end
    end

    context 'project_idがnilの場合' do
      it 'server_contextのdefault_projectを返す' do
        server_context = { default_project: 'default-proj' }
        result = helper.resolve_project_id(nil, server_context: server_context)
        expect(result).to eq('default-proj')
      end

      it 'server_contextがnilの場合はnilを返す' do
        result = helper.resolve_project_id(nil, server_context: nil)
        expect(result).to be_nil
      end

      it 'server_contextが空Hashの場合はnilを返す' do
        result = helper.resolve_project_id(nil, server_context: {})
        expect(result).to be_nil
      end

      it 'server_contextにdefault_projectがない場合はnilを返す' do
        server_context = { user: user }
        result = helper.resolve_project_id(nil, server_context: server_context)
        expect(result).to be_nil
      end
    end

    context '空文字の場合' do
      it 'server_contextのdefault_projectにフォールバック' do
        server_context = { default_project: 'fallback-proj' }
        result = helper.resolve_project_id('', server_context: server_context)
        expect(result).to eq('fallback-proj')
      end
    end
  end

  describe '#find_project' do
    context '識別子で検索' do
      it 'プロジェクトを見つける' do
        result = helper.find_project(project.identifier)
        expect(result).to eq(project)
      end

      it '存在しない識別子の場合はnilを返す' do
        result = helper.find_project('non-existent-project')
        expect(result).to be_nil
      end
    end

    context '数値IDで検索' do
      it 'プロジェクトを見つける' do
        result = helper.find_project(project.id.to_s)
        expect(result).to eq(project)
      end

      it '存在しないIDの場合はnilを返す' do
        result = helper.find_project('999999')
        expect(result).to be_nil
      end
    end

    context 'nilの場合' do
      it 'nilを返す' do
        result = helper.find_project(nil)
        expect(result).to be_nil
      end
    end
  end

  describe '#project_allowed?' do
    context 'MCPが有効なプロジェクト' do
      it 'trueを返す' do
        # beforeで既に有効化されている
        expect(helper.project_allowed?(project)).to be true
      end
    end

    context 'MCPが無効なプロジェクト' do
      it 'falseを返す' do
        setting = EpicLadder::ProjectSetting.find_by(project: project)
        setting.update!(mcp_enabled: false)
        expect(helper.project_allowed?(project)).to be false
      end
    end
  end

  describe '#resolve_and_validate_project' do
    context '正常系' do
      it 'プロジェクトを返す' do
        result = helper.resolve_and_validate_project(project.identifier)
        expect(result[:project]).to eq(project)
        expect(result[:error]).to be_nil
      end

      it 'server_contextからプロジェクトを解決できる' do
        server_context = { default_project: project.identifier }
        result = helper.resolve_and_validate_project(nil, server_context: server_context)
        expect(result[:project]).to eq(project)
        expect(result[:error]).to be_nil
      end
    end

    context 'project_idが指定されていない場合' do
      it 'エラーを返す' do
        result = helper.resolve_and_validate_project(nil)
        expect(result[:project]).to be_nil
        expect(result[:error]).to include('プロジェクトIDが指定されていません')
      end
    end

    context 'プロジェクトが存在しない場合' do
      it 'エラーを返す' do
        result = helper.resolve_and_validate_project('non-existent')
        expect(result[:project]).to be_nil
        expect(result[:error]).to include('プロジェクトが見つかりません')
      end
    end

    context 'MCPが無効なプロジェクトの場合' do
      it 'エラーを返す' do
        setting = EpicLadder::ProjectSetting.find_by(project: project)
        setting.update!(mcp_enabled: false)
        result = helper.resolve_and_validate_project(project.identifier)
        expect(result[:project]).to be_nil
        expect(result[:error]).to include('MCP APIが許可されていません')
        expect(result[:details]).to include(:hint)
      end
    end
  end

  describe '#find_tracker' do
    let(:epic_tracker) { find_or_create_epic_tracker }

    before { epic_tracker }

    context '存在するトラッカータイプ' do
      it 'トラッカーを返す' do
        result = helper.find_tracker(:epic)
        expect(result).to eq(epic_tracker)
      end
    end

    context '存在しないトラッカータイプ' do
      it 'nilを返す' do
        result = helper.find_tracker(:unknown_type)
        expect(result).to be_nil
      end
    end
  end

  describe '#find_tracker_for_project' do
    let(:epic_tracker) { find_or_create_epic_tracker }

    context 'プロジェクトにトラッカーが設定されている場合' do
      before do
        project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
      end

      it 'トラッカーを返す' do
        result = helper.find_tracker_for_project(:epic, project)
        expect(result).to eq(epic_tracker)
      end
    end

    context 'プロジェクトにトラッカーが設定されていない場合' do
      before do
        project.trackers.delete(epic_tracker)
      end

      it 'nilを返す' do
        result = helper.find_tracker_for_project(:epic, project)
        expect(result).to be_nil
      end
    end

    context 'トラッカー自体が存在しない場合' do
      it 'nilを返す' do
        result = helper.find_tracker_for_project(:unknown_type, project)
        expect(result).to be_nil
      end
    end
  end

  describe '#error_response' do
    it 'MCP::Tool::Responseオブジェクトを返す' do
      result = helper.error_response('エラーメッセージ')
      expect(result).to be_a(MCP::Tool::Response)
    end

    it '正しいJSON構造を持つ' do
      result = helper.error_response('テストエラー', { code: 'TEST_ERROR' })
      json = JSON.parse(result.content.first[:text])

      expect(json['success']).to be false
      expect(json['error']).to eq('テストエラー')
      expect(json['details']['code']).to eq('TEST_ERROR')
    end

    it '日本語メッセージを正しく処理する' do
      result = helper.error_response('プロジェクトが見つかりません')
      json = JSON.parse(result.content.first[:text])

      expect(json['error']).to eq('プロジェクトが見つかりません')
    end

    it '特殊文字を含むメッセージを処理する' do
      special_message = 'エラー: "value" <tag> & 特殊文字'
      result = helper.error_response(special_message)
      json = JSON.parse(result.content.first[:text])

      expect(json['error']).to eq(special_message)
    end

    it '空のdetailsでも動作する' do
      result = helper.error_response('エラー', {})
      json = JSON.parse(result.content.first[:text])

      expect(json['details']).to eq({})
    end

    it '長文メッセージを処理する' do
      long_message = 'エラー' * 1000
      result = helper.error_response(long_message)
      json = JSON.parse(result.content.first[:text])

      expect(json['error']).to eq(long_message)
    end
  end

  describe '#success_response' do
    it 'MCP::Tool::Responseオブジェクトを返す' do
      result = helper.success_response
      expect(result).to be_a(MCP::Tool::Response)
    end

    it '正しいJSON構造を持つ' do
      result = helper.success_response({ id: 1, name: 'test' })
      json = JSON.parse(result.content.first[:text])

      expect(json['success']).to be true
      expect(json['id']).to eq(1)
      expect(json['name']).to eq('test')
    end

    it 'データなしでも動作する' do
      result = helper.success_response
      json = JSON.parse(result.content.first[:text])

      expect(json['success']).to be true
    end

    it '日本語データを正しく処理する' do
      result = helper.success_response({ message: '作成成功', project_name: 'テストプロジェクト' })
      json = JSON.parse(result.content.first[:text])

      expect(json['message']).to eq('作成成功')
      expect(json['project_name']).to eq('テストプロジェクト')
    end

    it 'ネストしたデータ構造を処理する' do
      nested_data = {
        issue: {
          id: 1,
          children: [
            { id: 2, name: 'child1' },
            { id: 3, name: 'child2' }
          ]
        }
      }
      result = helper.success_response(nested_data)
      json = JSON.parse(result.content.first[:text])

      expect(json['issue']['id']).to eq(1)
      expect(json['issue']['children'].length).to eq(2)
    end

    it '配列データを処理する' do
      result = helper.success_response({ items: [1, 2, 3] })
      json = JSON.parse(result.content.first[:text])

      expect(json['items']).to eq([1, 2, 3])
    end
  end
end
