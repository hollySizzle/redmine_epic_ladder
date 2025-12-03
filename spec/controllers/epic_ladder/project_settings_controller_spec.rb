# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::ProjectSettingsController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_epic_ladder_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    # Epic Ladderモジュールを有効化
    project.enable_module!(:epic_ladder)
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'PATCH #update' do
    context 'with valid permissions' do
      it 'updates mcp_enabled to true' do
        patch :update, params: {
          project_id: project.identifier,
          epic_ladder_project_setting: { mcp_enabled: '1' }
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_ladder'))
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))

        setting = EpicLadder::ProjectSetting.for_project(project)
        expect(setting.mcp_enabled).to be true
      end

      it 'updates mcp_enabled to false' do
        # 先にtrueに設定
        setting = EpicLadder::ProjectSetting.for_project(project)
        setting.update!(mcp_enabled: true)

        patch :update, params: {
          project_id: project.identifier,
          epic_ladder_project_setting: { mcp_enabled: '0' }
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_ladder'))
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))

        setting.reload
        expect(setting.mcp_enabled).to be false
      end

      it 'handles missing mcp_enabled parameter gracefully' do
        patch :update, params: {
          project_id: project.identifier,
          epic_ladder_project_setting: {}
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_ladder'))

        setting = EpicLadder::ProjectSetting.for_project(project)
        expect(setting.mcp_enabled).to be false
      end

      it 'handles completely missing epic_ladder_project_setting parameter' do
        patch :update, params: { project_id: project.identifier }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_ladder'))

        setting = EpicLadder::ProjectSetting.for_project(project)
        expect(setting.mcp_enabled).to be false
      end
    end

    context 'without permission' do
      let(:role_without_permission) { create(:role, permissions: [:view_issues]) }
      let(:member_without_permission) { create(:member, project: project, user: user, roles: [role_without_permission]) }

      before do
        member.destroy
        member_without_permission
      end

      it 'returns 403 Forbidden' do
        patch :update, params: {
          project_id: project.identifier,
          epic_ladder_project_setting: { mcp_enabled: '1' }
        }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when epic_ladder module is disabled' do
      before do
        project.disable_module!(:epic_ladder)
      end

      it 'returns 403 Forbidden' do
        patch :update, params: {
          project_id: project.identifier,
          epic_ladder_project_setting: { mcp_enabled: '1' }
        }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with invalid project' do
      it 'returns 404 Not Found' do
        patch :update, params: {
          project_id: 'nonexistent-project',
          epic_ladder_project_setting: { mcp_enabled: '1' }
        }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
