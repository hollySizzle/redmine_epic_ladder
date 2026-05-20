# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::SearchProjectsTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Alpha Project', identifier: 'alpha-project') }
  let(:other_project) { create(:project, name: 'Beta Project', identifier: 'beta-project') }
  let(:role) { create(:role, permissions: [:view_project, :view_issues, :add_subprojects]) }

  before do
    create(:member, project: project, user: user, roles: [role])
    create(:member, project: other_project, user: user, roles: [role])
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
    Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '1' }
    User.current = user
  end

  describe '.call' do
    it 'searches visible projects by name' do
      result = described_class.call(query: 'Alpha', server_context: { user: user })
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be true
      expect(response['projects'].map { |p| p['identifier'] }).to include('alpha-project')
      expect(response['projects'].map { |p| p['identifier'] }).not_to include('beta-project')
    end

    it 'returns MCP status and subproject capability' do
      result = described_class.call(query: 'Alpha', server_context: { user: user })
      project_payload = JSON.parse(result.content.first[:text])['projects'].first

      expect(project_payload['mcp_enabled']).to be true
      expect(project_payload['can_create_subproject']).to be true
    end

    it 'rejects when global MCP is disabled' do
      Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '0' }

      result = described_class.call(query: 'Alpha', server_context: { user: user })
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be false
      expect(response['error']).to include('MCP APIが無効')
    end
  end
end
