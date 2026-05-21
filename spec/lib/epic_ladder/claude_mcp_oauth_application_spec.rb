# frozen_string_literal: true

require_relative '../../rails_helper'
require_relative '../../../lib/epic_ladder/claude_mcp_oauth_application'

RSpec.describe EpicLadder::ClaudeMcpOauthApplication do
  describe '.create!' do
    let(:application) do
      double(
        name: 'Claude Web MCP',
        redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
        scopes: described_class.scope_string,
        confidential?: true,
        uid: 'client-id',
        plaintext_secret: 'client-secret'
      )
    end

    before do
      stub_const('Doorkeeper::Application', double('Doorkeeper::Application'))
      allow(Doorkeeper::Application).to receive(:create!).and_return(application)
    end

    it 'creates the fixed Claude Web MCP OAuth application' do
      app = described_class.create!

      expect(Doorkeeper::Application).to have_received(:create!).with(
        name: 'Claude Web MCP',
        redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
        scopes: 'view_project view_issues add_issues edit_issues add_issue_notes manage_versions manage_issue_relations add_subprojects',
        confidential: true
      )
      expect(app).to eq(application)
      expect(app.uid).to be_present
      expect(app.plaintext_secret).to be_present
    end

    it 'enables the Redmine REST API like the CLI helper does' do
      Setting.rest_api_enabled = '0'

      described_class.create!

      expect(Setting.rest_api_enabled?).to be true
    end
  end

  describe '.recreate!' do
    it 'replaces the existing application and returns a new secret' do
      stub_const('Doorkeeper::Application', double('Doorkeeper::Application'))
      existing = double("Doorkeeper::Application")
      new_app = double('Doorkeeper::Application', plaintext_secret: 'new-secret')

      allow(described_class).to receive(:application).and_return(existing)
      allow(existing).to receive(:destroy!)
      allow(Doorkeeper::Application).to receive(:create!).and_return(new_app)

      expect(described_class.recreate!).to eq(new_app)
      expect(existing).to have_received(:destroy!)
      expect(new_app.plaintext_secret).to be_present
    end
  end

  describe '.update_configuration!' do
    it 'updates the existing application in place' do
      existing = double('Doorkeeper::Application')

      allow(described_class).to receive(:application).and_return(existing)
      allow(existing).to receive(:update!).and_return(true)

      expect(described_class.update_configuration!).to eq(existing)
      expect(existing).to have_received(:update!).with(
        redirect_uri: described_class::REDIRECT_URI,
        scopes: described_class.scope_string,
        confidential: true
      )
    end
  end

  describe '.configuration_matches?' do
    it 'returns true for the fixed application' do
      app = double(
        name: described_class::APP_NAME,
        redirect_uri: described_class::REDIRECT_URI,
        scopes: described_class.scope_string,
        confidential?: true
      )

      expect(described_class.configuration_matches?(app)).to be true
    end

    it 'returns false for a mismatched application' do
      app = double(
        name: described_class::APP_NAME,
        redirect_uri: 'https://example.com/callback',
        scopes: described_class.scope_string,
        confidential?: true
      )

      expect(described_class.configuration_matches?(app)).to be false
    end

    it 'returns false when the add_subprojects scope is missing' do
      app = double(
        name: described_class::APP_NAME,
        redirect_uri: described_class::REDIRECT_URI,
        scopes: 'view_project view_issues add_issues edit_issues add_issue_notes manage_versions manage_issue_relations',
        confidential?: true
      )

      expect(described_class.configuration_matches?(app)).to be false
    end
  end

  describe '.connection_checks' do
    it 'checks OAuth metadata and unauthenticated MCP challenge' do
      checks = described_class.connection_checks

      expect(checks.map { |check| check[:ok] }).to all be(true)
      expect(checks.map { |check| check[:name] }).to include(
        '/.well-known/oauth-protected-resource/mcp/rpc',
        '/.well-known/oauth-authorization-server',
        '/mcp/rpc unauthenticated challenge'
      )
    end
  end
end
