# frozen_string_literal: true

require 'rack/mock'
require 'stringio'

module EpicLadder
  # Fixed OAuth application profile for Claude Web Custom Connector.
  class ClaudeMcpOauthApplication
    APP_NAME = 'Claude Web MCP'
    REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback'
    SCOPES = %w[
      view_project
      view_issues
      add_issues
      edit_issues
      add_issue_notes
      manage_versions
      manage_issue_relations
      add_subprojects
    ].freeze

    class << self
      def application
        Doorkeeper::Application.find_by(name: APP_NAME)
      end

      def create!
        Setting.rest_api_enabled = '1'

        Doorkeeper::Application.create!(
          name: APP_NAME,
          redirect_uri: REDIRECT_URI,
          scopes: scope_string,
          confidential: true
        )
      end

      def destroy!
        application&.destroy!
      end

      def recreate!
        destroy!
        create!
      end

      def update_configuration!
        app = application
        return create! unless app

        Setting.rest_api_enabled = '1'
        app.update!(
          redirect_uri: REDIRECT_URI,
          scopes: scope_string,
          confidential: true
        )
        app
      end

      def scope_string
        SCOPES.join(' ')
      end

      def mcp_endpoint(request = nil)
        host = Setting.host_name.presence || request&.host_with_port
        host = host.to_s.sub(%r{\Ahttps?://}, '')
        "https://#{host}/mcp/rpc"
      end

      def configuration_matches?(app = application)
        return false unless app

        app.name == APP_NAME &&
          app.redirect_uri == REDIRECT_URI &&
          app.scopes.to_s.split.sort == SCOPES.sort &&
          app.confidential?
      end

      def connection_checks(request = nil)
        mock = Rack::MockRequest.new(Rails.application)
        env = mock_request_env(request)

        protected_resource = mock.get('/.well-known/oauth-protected-resource/mcp/rpc', env)
        auth_server = mock.get('/.well-known/oauth-authorization-server', env)
        unauthenticated_rpc = mock.post(
          '/mcp/rpc',
          env.merge(
            'CONTENT_TYPE' => 'application/json',
            'rack.input' => StringIO.new({ jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json)
          )
        )

        [
          {
            name: '/.well-known/oauth-protected-resource/mcp/rpc',
            ok: protected_resource.status == 200,
            status: protected_resource.status
          },
          {
            name: '/.well-known/oauth-authorization-server',
            ok: auth_server.status == 200,
            status: auth_server.status
          },
          {
            name: '/mcp/rpc unauthenticated challenge',
            ok: unauthenticated_rpc.status == 401 &&
                unauthenticated_rpc['WWW-Authenticate'].to_s.include?('oauth-protected-resource/mcp/rpc'),
            status: unauthenticated_rpc.status,
            www_authenticate: unauthenticated_rpc['WWW-Authenticate']
          }
        ]
      end

      private

      def mock_request_env(request = nil)
        host = Setting.host_name.presence || request&.host_with_port || 'localhost'
        host = host.to_s.sub(%r{\Ahttps?://}, '').sub(%r{/.*\z}, '')

        {
          'HTTP_HOST' => host,
          'HTTPS' => 'on',
          'rack.url_scheme' => 'https'
        }
      end
    end
  end
end
