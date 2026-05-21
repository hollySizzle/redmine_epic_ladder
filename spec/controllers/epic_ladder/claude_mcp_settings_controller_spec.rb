# frozen_string_literal: true

require_relative '../../rails_helper'
require_relative '../../../lib/epic_ladder/claude_mcp_oauth_application'

RSpec.describe EpicLadder::ClaudeMcpSettingsController, type: :controller do
  routes { RedmineApp::Application.routes }

  let(:admin) { create(:user, :admin) }

  let(:application) do
    double(
      id: 10,
      uid: 'client-id',
      redirect_uri: EpicLadder::ClaudeMcpOauthApplication::REDIRECT_URI,
      scopes: EpicLadder::ClaudeMcpOauthApplication.scope_string,
      confidential?: true,
      plaintext_secret: 'client-secret'
    )
  end

  before do
    User.current = admin
    @request.session[:user_id] = admin.id
    allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:application).and_return(nil)
    allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:configuration_matches?).and_return(false)
    allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:mcp_endpoint).and_return('https://redmine.example.com/mcp/rpc')
  end

  describe 'GET #show' do
    it 'loads the fixed connector settings for admins' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:application).and_return(application)
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:configuration_matches?).and_return(true)

      get :show

      expect(response).to have_http_status(:ok)
      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:application)
      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:mcp_endpoint)
      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:configuration_matches?).with(application)
    end

    it 'denies non-admin users' do
      user = create(:user)
      User.current = user
      @request.session[:user_id] = user.id

      get :show

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #create' do
    it 'creates the OAuth application and stores the one-time secret in flash' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:create!).and_return(application)

      post :create

      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:create!)
      expect(session[:claude_mcp_client_secret]).to eq('client-secret')
      expect(response).to redirect_to(epic_ladder_claude_mcp_settings_path)
    end

    it 'does not create duplicates when the application already exists' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:application).and_return(application)
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:create!)

      post :create

      expect(EpicLadder::ClaudeMcpOauthApplication).not_to have_received(:create!)
      expect(session[:claude_mcp_client_secret]).to be_blank
    end
  end

  describe 'POST #recreate' do
    it 'replaces the OAuth application and exposes a new one-time secret' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:recreate!).and_return(application)

      post :recreate

      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:recreate!)
      expect(session[:claude_mcp_client_secret]).to eq('client-secret')
      expect(response).to redirect_to(epic_ladder_claude_mcp_settings_path)
    end
  end

  describe 'PATCH #update' do
    it 'updates the existing OAuth application settings without recreating the secret' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:update_configuration!).and_return(application)

      patch :update

      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:update_configuration!)
      expect(session[:claude_mcp_client_secret]).to be_blank
      expect(response).to redirect_to(epic_ladder_claude_mcp_settings_path)
    end
  end

  describe 'one-time client secret display' do
    it 'loads the secret from session once without exposing the flash object' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:application).and_return(application)
      session[:claude_mcp_client_secret] = 'client-secret'

      get :show

      expect(controller.instance_variable_get(:@client_secret)).to eq('client-secret')
      expect(controller.instance_variable_get(:@client_secret)).not_to be_a(ActionDispatch::Flash::FlashHash)
      expect(session[:claude_mcp_client_secret]).to be_nil
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the OAuth application' do
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:destroy!)

      delete :destroy

      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:destroy!)
      expect(response).to redirect_to(epic_ladder_claude_mcp_settings_path)
    end
  end

  describe 'POST #check' do
    it 'renders connection check results' do
      checks = [
        { name: '/.well-known/oauth-protected-resource/mcp/rpc', ok: true, status: 200 },
        { name: '/.well-known/oauth-authorization-server', ok: true, status: 200 },
        { name: '/mcp/rpc unauthenticated challenge', ok: true, status: 401 }
      ]
      allow(EpicLadder::ClaudeMcpOauthApplication).to receive(:connection_checks).and_return(checks)

      post :check

      expect(response).to have_http_status(:ok)
      expect(EpicLadder::ClaudeMcpOauthApplication).to have_received(:connection_checks)
    end
  end
end
