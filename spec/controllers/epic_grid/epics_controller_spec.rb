# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EpicGrid::GridController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_kanban_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { create(:epic_tracker) }

  before do
    project.trackers << epic_tracker
    member
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'POST #create_epic' do
    let(:valid_params) do
      {
        project_id: project.id,
        epic: {
          subject: 'New Epic',
          description: 'Epic description',
          fixed_version_id: nil,
          status: 'open'
        }
      }
    end

    it 'creates new epic' do
      expect {
        post :create_epic, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include(
        'success' => true,
        'data' => include(
          'epic' => include(
            'subject' => 'New Epic',
            'tracker' => 'Epic'
          )
        )
      )
    end

    it 'returns MSW-compliant response structure' do
      post :create_epic, params: valid_params

      json = JSON.parse(response.body)
      expect(json['data']).to include(
        'epic',
        'grid_position',
        'affected_statistics'
      )
    end

    it 'validates required subject field' do
      invalid_params = valid_params.deep_dup
      invalid_params[:epic][:subject] = ''

      post :create_epic, params: invalid_params

      expect(response).to have_http_status(:bad_request)
    end

    context 'when user lacks add_issues permission' do
      let(:unauthorized_role) { create(:role, permissions: [:view_issues]) }
      let(:unauthorized_member) { create(:member, project: project, user: user, roles: [unauthorized_role]) }

      before do
        member.destroy
        unauthorized_member
      end

      it 'returns 403 forbidden' do
        post :create_epic, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when epic tracker is not configured' do
      before do
        project.trackers.clear
      end

      it 'returns configuration error' do
        post :create_epic, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error_code']).to eq('EPIC_TRACKER_NOT_FOUND')
      end
    end
  end
end
