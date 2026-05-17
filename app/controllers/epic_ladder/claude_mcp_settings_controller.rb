# frozen_string_literal: true

require_relative '../../../lib/epic_ladder/claude_mcp_oauth_application'

module EpicLadder
  class ClaudeMcpSettingsController < ApplicationController
    layout 'admin'

    before_action :require_admin
    before_action :load_application

    def show; end

    def create
      if @application
        flash[:notice] = l(:notice_epic_ladder_claude_mcp_already_exists)
      else
        @application = ClaudeMcpOauthApplication.create!
        flash[:notice] = l(:notice_successful_create)
        flash[:claude_mcp_client_secret] = @application.plaintext_secret
      end

      redirect_to epic_ladder_claude_mcp_settings_path
    end

    def recreate
      @application = ClaudeMcpOauthApplication.recreate!
      flash[:notice] = l(:notice_successful_create)
      flash[:claude_mcp_client_secret] = @application.plaintext_secret

      redirect_to epic_ladder_claude_mcp_settings_path
    end

    def destroy
      ClaudeMcpOauthApplication.destroy!
      flash[:notice] = l(:notice_successful_delete)

      redirect_to epic_ladder_claude_mcp_settings_path
    end

    def check
      @connection_checks = ClaudeMcpOauthApplication.connection_checks(request)
      render :show
    end

    private

    def load_application
      @application = ClaudeMcpOauthApplication.application
      @mcp_endpoint = ClaudeMcpOauthApplication.mcp_endpoint(request)
      @fixed_scopes = ClaudeMcpOauthApplication.scope_string
      @configuration_matches = ClaudeMcpOauthApplication.configuration_matches?(@application)
      @client_secret = flash.delete(:claude_mcp_client_secret)
    end
  end
end
