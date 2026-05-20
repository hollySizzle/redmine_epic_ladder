# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateProjectTool, type: :model do
  let(:user) { create(:user) }
  let(:parent_project) { create(:project, name: 'Parent Project', identifier: 'parent-project') }
  let(:role) { create(:role, permissions: [:view_project, :add_subprojects]) }

  before do
    create(:member, project: parent_project, user: user, roles: [role])
    User.current = user
    Setting.plugin_redmine_epic_ladder = {
      'mcp_enabled' => '1',
      'mcp_project_creation_enabled' => '1',
      'mcp_project_creation_scope' => 'allowed_parents_only',
      'mcp_project_creation_allowed_parent_ids' => [parent_project.id.to_s],
      'mcp_project_creation_allow_root' => '0'
    }
  end

  describe '.call' do
    it 'creates a project under an allowed parent' do
      result = described_class.call(
        name: 'Child Project',
        identifier: 'child-project',
        parent_project_id: parent_project.identifier,
        description: 'Created via MCP',
        server_context: { user: user }
      )
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be true
      expect(response['project']['identifier']).to eq('child-project')
      expect(response['project']['parent']['identifier']).to eq(parent_project.identifier)

      project = Project.find_by!(identifier: 'child-project')
      expect(project.parent).to eq(parent_project)
      expect(EpicLadder::ProjectSetting.mcp_enabled?(project)).to be true
    end

    it 'generates an identifier when omitted' do
      result = described_class.call(
        name: 'Generated Identifier Project',
        parent_project_id: parent_project.identifier,
        server_context: { user: user }
      )
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be true
      expect(response['project']['identifier']).to eq('generated-identifier-project')
    end

    it 'rejects creation under a parent outside the configured allowlist' do
      other_parent = create(:project, name: 'Other Parent', identifier: 'other-parent')
      create(:member, project: other_parent, user: user, roles: [role])

      result = described_class.call(
        name: 'Blocked Child',
        identifier: 'blocked-child',
        parent_project_id: other_parent.identifier,
        server_context: { user: user }
      )
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be false
      expect(response['error']).to include('許可されていません')
      expect(Project.find_by(identifier: 'blocked-child')).to be_nil
    end

    it 'rejects when project creation is disabled' do
      Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
        'mcp_project_creation_enabled' => '0'
      )

      result = described_class.call(
        name: 'Disabled Project',
        identifier: 'disabled-project',
        parent_project_id: parent_project.identifier,
        server_context: { user: user }
      )
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be false
      expect(response['error']).to include('プロジェクト作成が無効')
    end

    it 'allows root creation only with root setting and Redmine global permission' do
      admin = create(:user, admin: true)
      Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
        'mcp_project_creation_scope' => 'redmine_permissions',
        'mcp_project_creation_allow_root' => '1'
      )

      result = described_class.call(
        name: 'Root Project',
        identifier: 'root-project-mcp',
        server_context: { user: admin }
      )
      response = JSON.parse(result.content.first[:text])

      expect(response['success']).to be true
      expect(Project.find_by!(identifier: 'root-project-mcp').parent).to be_nil
    end
  end
end
