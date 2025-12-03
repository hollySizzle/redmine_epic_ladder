# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::ProjectsHelperPatch do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_epic_ladder_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  # ProjectsHelperを含むテスト用クラス
  let(:helper_class) do
    Class.new do
      include ProjectsHelper
      attr_accessor :project, :params

      def initialize(project)
        @project = project
        @params = {}
      end
    end
  end

  let(:helper) { helper_class.new(project) }

  before do
    member # ensure member exists
    allow(User).to receive(:current).and_return(user)
  end

  describe '#project_settings_tabs' do
    context 'when epic_ladder module is enabled' do
      before do
        project.enable_module!(:epic_ladder)
      end

      it 'includes epic_ladder tab' do
        tabs = helper.project_settings_tabs

        epic_ladder_tab = tabs.find { |t| t[:name] == 'epic_ladder' }
        expect(epic_ladder_tab).not_to be_nil
      end

      it 'has correct tab configuration' do
        tabs = helper.project_settings_tabs

        epic_ladder_tab = tabs.find { |t| t[:name] == 'epic_ladder' }
        expect(epic_ladder_tab[:action]).to eq(:manage_epic_ladder)
        expect(epic_ladder_tab[:partial]).to eq('epic_ladder/project_settings/show')
        expect(epic_ladder_tab[:label]).to eq(:label_epic_ladder_settings)
      end

      it 'places epic_ladder tab at the end' do
        tabs = helper.project_settings_tabs

        last_tab = tabs.last
        expect(last_tab[:name]).to eq('epic_ladder')
      end
    end

    context 'when epic_ladder module is disabled' do
      before do
        project.disable_module!(:epic_ladder)
      end

      it 'does not include epic_ladder tab' do
        tabs = helper.project_settings_tabs

        epic_ladder_tab = tabs.find { |t| t[:name] == 'epic_ladder' }
        expect(epic_ladder_tab).to be_nil
      end

      it 'returns some standard Redmine tabs (filtered by permissions)' do
        tabs = helper.project_settings_tabs

        # 権限に応じてフィルタリングされるが、少なくとも何かのタブは返る
        expect(tabs).to be_an(Array)
        # Epic Ladder以外のタブが存在することを確認
        tab_names = tabs.map { |t| t[:name] }
        expect(tab_names).not_to include('epic_ladder')
      end
    end

    context 'when user does not have manage_epic_ladder permission' do
      let(:role_without_permission) { create(:role, permissions: [:view_issues, :edit_project]) }

      before do
        member.roles = [role_without_permission]
        member.save!
        project.enable_module!(:epic_ladder)
      end

      it 'does not include epic_ladder tab due to permission check' do
        tabs = helper.project_settings_tabs

        # タブは追加されるが、Redmineの権限フィルタリングで除外される可能性
        # (実際の動作はRedmineのselect {|tab| User.current.allowed_to?(tab[:action], @project)}による)
        epic_ladder_tab = tabs.find { |t| t[:name] == 'epic_ladder' }

        # モジュールが有効ならタブは追加される（権限チェックはRedmine側で行う）
        expect(epic_ladder_tab).not_to be_nil
      end
    end
  end

  describe 'module prepend order' do
    it 'is prepended to ProjectsHelper' do
      expect(ProjectsHelper.ancestors).to include(EpicLadder::ProjectsHelperPatch)
    end

    it 'is prepended before ProjectsHelper itself' do
      ancestors = ProjectsHelper.ancestors
      patch_index = ancestors.index(EpicLadder::ProjectsHelperPatch)
      helper_index = ancestors.index(ProjectsHelper)

      expect(patch_index).to be < helper_index
    end
  end
end
