# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::CreateVersionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :manage_versions]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
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
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Version')
      expect(described_class.description).to include('リリース予定')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :name, :effective_date)
      expect(schema.instance_variable_get(:@required)).to include(:project_id, :name, :effective_date)
    end
  end
end
