# frozen_string_literal: true

# MCP OAuth Discovery Rejection Middleware
# Claude CodeがOAuth検出を試みるが、このサーバーはAPIキー認証のみをサポート
# OAuth discoveryリクエストに対して明示的に405を返す
class McpOAuthRejectionMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env['PATH_INFO']

    # OAuth discovery エンドポイントへのGETリクエストを検出
    if env['REQUEST_METHOD'] == 'GET' && oauth_discovery_path?(path)
      return [
        405, # Method Not Allowed
        {
          'Content-Type' => 'application/json',
          'Access-Control-Allow-Origin' => '*'
        },
        [JSON.generate({
          error: 'oauth_not_supported',
          message: 'This MCP server does not support OAuth authentication. Use X-Redmine-API-Key header for authentication.',
          mcp_endpoint: '/mcp/rpc'
        })]
      ]
    end

    @app.call(env)
  end

  private

  def oauth_discovery_path?(path)
    path.start_with?('/.well-known/oauth-authorization-server') ||
      path.start_with?('/.well-known/openid-configuration') ||
      path.start_with?('/.well-known/oauth-protected-resource') ||
      path.include?('/.well-known/')
  end
end

# Railsアプリケーションにミドルウェアを挿入
Rails.application.config.middleware.insert_before(
  Rack::Runtime,
  McpOAuthRejectionMiddleware
)
