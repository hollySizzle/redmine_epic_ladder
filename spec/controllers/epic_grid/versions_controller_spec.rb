# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EpicGrid::GridController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_kanban_permissions, permissions: [:view_issues, :manage_versions]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'POST #create_version' do
    let(:valid_params) do
      {
        project_id: project.id,
        version: {
          name: 'v1.0.0',
          description: 'Version 1.0.0 release',
          effective_date: '2025-12-31',
          status: 'open'
        }
      }
    end

    it 'creates new version' do
      expect {
        post :create_version, params: valid_params
      }.to change(Version, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'created_version' => include(
            'name' => 'v1.0.0',
            'description' => 'Version 1.0.0 release'
          )
        )
      )
    end

    it 'returns MSW-compliant response structure' do
      post :create_version, params: valid_params

      json = JSON.parse(response.body)
      expect(json['data']).to include(
        'created_version',
        'grid_updates'
      )

      expect(json['data']['grid_updates']).to include(
        'new_column_added' => true,
        'column_position'
      )
    end

    it 'validates required name field' do
      invalid_params = valid_params.deep_dup
      invalid_params[:version][:name] = ''

      post :create_version, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error when version name already exists' do
      create(:version, project: project, name: 'v1.0.0')

      post :create_version, params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json['error']).to include('バージョン名が既に存在します')
    end

    context 'when user lacks manage_versions permission' do
      let(:unauthorized_role) { create(:role, permissions: [:view_issues]) }
      let(:unauthorized_member) { create(:member, project: project, user: user, roles: [unauthorized_role]) }

      before do
        member.destroy
        unauthorized_member
      end

      it 'returns 403 forbidden' do
        post :create_version, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'includes grid impact metadata' do
      post :create_version, params: valid_params

      json = JSON.parse(response.body)
      expect(json['data']).to include(
        'metadata' => include(
          'grid_cache_invalidated' => true,
          'requires_full_reload'
        )
      )
    end
  end
end
