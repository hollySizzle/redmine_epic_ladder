# frozen_string_literal: true

# MCP OAuth Discovery Middleware
# Claude Web Custom Connector向けにOAuth discovery metadataを返す。
# 認可サーバー本体はRedmine 6.1のDoorkeeper OAuth2 Providerを使う。
class McpOAuthDiscoveryMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env['PATH_INFO']

    if env['REQUEST_METHOD'] == 'GET'
      request = Rack::Request.new(env)

      if protected_resource_metadata_path?(path)
        return json_response(protected_resource_metadata(request))
      end

      if authorization_server_metadata_path?(path)
        return json_response(authorization_server_metadata(request))
      end
    end

    @app.call(env)
  end

  private

  def protected_resource_metadata_path?(path)
    path == '/.well-known/oauth-protected-resource' ||
      path == '/.well-known/oauth-protected-resource/mcp/rpc'
  end

  def authorization_server_metadata_path?(path)
    path == '/.well-known/oauth-authorization-server'
  end

  def protected_resource_metadata(request)
    {
      resource: "#{request.base_url}/mcp/rpc",
      authorization_servers: [
        "#{request.base_url}/.well-known/oauth-authorization-server"
      ]
    }
  end

  def authorization_server_metadata(request)
    {
      issuer: request.base_url,
      authorization_endpoint: "#{request.base_url}/authorize",
      token_endpoint: "#{request.base_url}/token",
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code', 'refresh_token'],
      code_challenge_methods_supported: ['S256'],
      token_endpoint_auth_methods_supported: ['client_secret_basic', 'client_secret_post']
    }
  end

  def json_response(body)
    [
      200,
      {
        'Content-Type' => 'application/json',
        'Access-Control-Allow-Origin' => '*'
      },
      [JSON.generate(body)]
    ]
  end
end

# Railsアプリケーションにミドルウェアを挿入
Rails.application.config.middleware.insert_before(
  Rack::Runtime,
  McpOAuthDiscoveryMiddleware
)
