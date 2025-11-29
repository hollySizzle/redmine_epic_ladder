# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::McpToolHintsController, type: :controller do
  routes { RedmineApp::Application.routes }

  let(:project) { create(:project) }
  let(:user) { create(:user, admin: true) }
  let(:role) { create(:role, permissions: [:view_epic_grid, :manage_epic_grid]) }

  before do
    # Enable epic_grid module for project
    project.enable_module!(:epic_grid)
    # Add user as member with role
    create(:member, project: project, user: user, roles: [role])
    # Login user
    User.current = user
    @request.session[:user_id] = user.id
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      it 'creates new hints' do
        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: {
            'create_task' => { enabled: '1', hint_text: 'タスク作成時のヒント' },
            'add_issue_comment' => { enabled: '1', hint_text: 'コメント追加時のヒント' }
          }
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_grid'))
        expect(flash[:notice]).to be_present

        hint1 = EpicGrid::McpToolHint.find_by(project: project, tool_key: 'create_task')
        expect(hint1.enabled).to be true
        expect(hint1.hint_text).to eq('タスク作成時のヒント')

        hint2 = EpicGrid::McpToolHint.find_by(project: project, tool_key: 'add_issue_comment')
        expect(hint2.enabled).to be true
        expect(hint2.hint_text).to eq('コメント追加時のヒント')
      end

      it 'updates existing hints' do
        existing = create(:mcp_tool_hint, project: project, tool_key: 'create_task', hint_text: '旧ヒント')

        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: {
            'create_task' => { enabled: '0', hint_text: '新ヒント' }
          }
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_grid'))
        existing.reload
        expect(existing.enabled).to be false
        expect(existing.hint_text).to eq('新ヒント')
      end

      it 'clears hint text when empty' do
        existing = create(:mcp_tool_hint, project: project, tool_key: 'create_task', hint_text: '既存ヒント')

        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: {
            'create_task' => { enabled: '1', hint_text: '' }
          }
        }

        existing.reload
        expect(existing.hint_text).to be_nil
      end
    end

    context 'with invalid tool_key' do
      it 'ignores invalid tool keys' do
        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: {
            'invalid_tool' => { enabled: '1', hint_text: '無効なツール' },
            'create_task' => { enabled: '1', hint_text: '有効なツール' }
          }
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_grid'))
        expect(EpicGrid::McpToolHint.find_by(project: project, tool_key: 'invalid_tool')).to be_nil
        expect(EpicGrid::McpToolHint.find_by(project: project, tool_key: 'create_task')).to be_present
      end
    end

    context 'without permission' do
      let(:user) { create(:user, admin: false) } # non-admin user
      let(:role) { create(:role, permissions: [:view_epic_grid]) } # no manage_epic_grid

      it 'denies access (403 or redirect)' do
        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: {
            'create_task' => { enabled: '1', hint_text: 'テスト' }
          }
        }

        # Redmine may return 403 or redirect depending on configuration
        expect(response.status).to be_in([302, 403])
        # Hint should not be created
        expect(EpicGrid::McpToolHint.find_by(project: project, tool_key: 'create_task')).to be_nil
      end
    end

    context 'with all modifying tools' do
      it 'can save hints for all tool types' do
        all_hints = EpicGrid::McpToolHint::MODIFYING_TOOLS.each_with_object({}) do |tool, hash|
          hash[tool] = { enabled: '1', hint_text: "#{tool}のヒント" }
        end

        patch :update, params: {
          project_id: project.identifier,
          mcp_tool_hints: all_hints
        }

        expect(response).to redirect_to(settings_project_path(project, tab: 'epic_grid'))

        EpicGrid::McpToolHint::MODIFYING_TOOLS.each do |tool|
          hint = EpicGrid::McpToolHint.find_by(project: project, tool_key: tool)
          expect(hint).to be_present, "Expected hint for #{tool} to exist"
          expect(hint.hint_text).to eq("#{tool}のヒント")
        end
      end
    end
  end
end
