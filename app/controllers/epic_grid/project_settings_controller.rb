# frozen_string_literal: true

module EpicGrid
  # プロジェクト単位のEpic Grid設定コントローラー
  class ProjectSettingsController < ApplicationController
    before_action :find_project
    before_action :authorize

    def show
      @setting = EpicGrid::ProjectSetting.for_project(@project)
    end

    def update
      @setting = EpicGrid::ProjectSetting.for_project(@project)
      @setting.mcp_enabled = params[:epic_grid_project_setting][:mcp_enabled] == '1'

      if @setting.save
        flash[:notice] = l(:notice_successful_update)
      else
        flash[:error] = @setting.errors.full_messages.join(', ')
      end

      redirect_to settings_project_path(@project, tab: 'epic_grid')
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
