# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

RSpec.describe Kanban::GridController, type: :controller do
  let(:project) { double('Project', id: 1, name: 'Test Project', identifier: 'test', description: 'Test Desc', created_on: Time.now) }
  let(:user) do
    pref = double('UserPreference', others: {}, time_zone: nil)
    allow(pref).to receive(:[]).and_return('')

    double('User',
      id: 1,
      login: 'testuser',
      admin?: true,
      allowed_to?: true,
      logged?: true,
      language: 'en',
      pref: pref
    )
  end

  before do
    # Controller の @project と User.current をモック化
    allow(controller).to receive(:find_project).and_return(true)
    controller.instance_variable_set(:@project, project)

    allow(User).to receive(:current).and_return(user)

    # ApplicationController の全ての before_action/after_action をスキップ
    allow(controller).to receive(:api_require_login).and_return(true)
    allow(controller).to receive(:authorize_kanban_access).and_return(true)
    allow(controller).to receive(:set_start_time).and_return(true)
    allow(controller).to receive(:log_performance_metrics).and_return(true)

    # ApplicationController の各種コールバックをスキップ
    allow(controller).to receive(:user_setup).and_return(true)
    allow(controller).to receive(:set_localization).and_return(true)
    allow(controller).to receive(:record_project_usage).and_return(true)
  end

  describe 'GET #show' do
    it 'MSW仕様に準拠したJSONを返す' do
      get :show, params: { project_id: project.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      # BaseApiController の統一レスポンス形式
      expect(json).to have_key('success')
      expect(json['success']).to be true
      expect(json).to have_key('data')
      expect(json).to have_key('meta')

      # MSW仕様に準拠したデータ構造
      data = json['data']
      expect(data).to have_key('entities')
      expect(data).to have_key('grid')
      expect(data).to have_key('metadata')
      expect(data).to have_key('statistics')

      # entities構造
      expect(data['entities']).to have_key('epics')
      expect(data['entities']).to have_key('versions')
      expect(data['entities']).to have_key('features')
      expect(data['entities']).to have_key('user_stories')
      expect(data['entities']).to have_key('tasks')
      expect(data['entities']).to have_key('tests')
      expect(data['entities']).to have_key('bugs')

      # grid構造
      expect(data['grid']).to have_key('index')
      expect(data['grid']).to have_key('epic_order')
      expect(data['grid']).to have_key('version_order')

      # metadata構造
      expect(data['metadata']).to have_key('project')
      expect(data['metadata']).to have_key('user_permissions')
      expect(data['metadata']).to have_key('api_version')

      # statistics構造
      expect(data['statistics']).to have_key('overview')
      expect(data['statistics']).to have_key('by_version')
      expect(data['statistics']).to have_key('by_status')
      expect(data['statistics']).to have_key('by_tracker')
    end
  end
end
