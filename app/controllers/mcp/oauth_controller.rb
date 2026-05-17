# frozen_string_literal: true

module Mcp
  # OAuth metadata endpoints for Claude Web Custom Connector.
  class OauthController < ApplicationController
    MCP_SCOPES = %w[
      view_project
      view_issues
      add_issues
      edit_issues
      add_issue_notes
      manage_versions
      manage_issue_relations
    ].freeze

    skip_before_action :verify_authenticity_token
    skip_before_action :check_if_login_required
    before_action :set_cors_headers

    def protected_resource
      render json: {
        resource: "#{request.base_url}/mcp/rpc",
        authorization_servers: [
          "#{request.base_url}/.well-known/oauth-authorization-server"
        ]
      }
    end

    def authorization_server
      render json: {
        issuer: request.base_url,
        authorization_endpoint: "#{request.base_url}/authorize",
        token_endpoint: "#{request.base_url}/token",
        response_types_supported: ['code'],
        grant_types_supported: ['authorization_code', 'refresh_token'],
        code_challenge_methods_supported: ['S256'],
        token_endpoint_auth_methods_supported: ['client_secret_basic', 'client_secret_post'],
        scopes_supported: MCP_SCOPES
      }
    end

    private

    def set_cors_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
    end
  end
end
