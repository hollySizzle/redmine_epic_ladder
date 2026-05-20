# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe SettingsController, type: :controller do
  routes { RedmineApp::Application.routes }

  let(:admin) { create(:user, :admin) }
  let(:parent_project) { create(:project, name: 'Allowed Parent', identifier: 'allowed-parent') }
  let(:other_parent) { create(:project, name: 'Other Parent', identifier: 'other-parent') }

  before do
    User.current = admin
    @request.session[:user_id] = admin.id
  end

  describe 'POST #plugin for redmine_epic_ladder' do
    it 'persists MCP project creation settings' do
      post :plugin, params: {
        id: 'redmine_epic_ladder',
        settings: {
          mcp_enabled: '1',
          mcp_project_creation_enabled: '1',
          mcp_project_creation_scope: 'allowed_parents_only',
          mcp_project_creation_allowed_parent_ids: ['', parent_project.id.to_s, other_parent.id.to_s],
          mcp_project_creation_allow_root: '0'
        }
      }

      expect(response).to redirect_to('/settings/plugin/redmine_epic_ladder')

      settings = Setting.plugin_redmine_epic_ladder
      expect(settings['mcp_project_creation_enabled']).to eq('1')
      expect(settings['mcp_project_creation_scope']).to eq('allowed_parents_only')
      expect(settings['mcp_project_creation_allowed_parent_ids']).to match_array(['', parent_project.id.to_s, other_parent.id.to_s])
      expect(settings['mcp_project_creation_allow_root']).to eq('0')

      expect(EpicLadder::McpTools::ProjectValidator.project_creation_allowed_parent_ids).to match_array([parent_project.id, other_parent.id])
    end

    it 'persists unchecked project creation options as disabled values' do
      post :plugin, params: {
        id: 'redmine_epic_ladder',
        settings: {
          mcp_enabled: '1',
          mcp_project_creation_enabled: '0',
          mcp_project_creation_scope: 'disabled',
          mcp_project_creation_allowed_parent_ids: [''],
          mcp_project_creation_allow_root: '0'
        }
      }

      expect(response).to redirect_to('/settings/plugin/redmine_epic_ladder')

      settings = Setting.plugin_redmine_epic_ladder
      expect(settings['mcp_project_creation_enabled']).to eq('0')
      expect(settings['mcp_project_creation_scope']).to eq('disabled')
      expect(settings['mcp_project_creation_allow_root']).to eq('0')
      expect(EpicLadder::McpTools::ProjectValidator.project_creation_enabled?).to be false
    end
  end
end
