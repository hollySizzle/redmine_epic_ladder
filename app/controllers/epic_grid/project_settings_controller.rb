# frozen_string_literal: true

module EpicGrid
  class ProjectSettingsController < ApplicationController
    before_action :find_project
    before_action :authorize

    def update
      @setting = EpicGrid::ProjectSetting.for_project(@project)
      @setting.mcp_enabled = params[:epic_grid_project_setting][:mcp_enabled] == '1'

      if @setting.save
        Rails.logger.info "[EpicGrid] Project setting updated: project_id=#{@project.id}, mcp_enabled=#{@setting.mcp_enabled}"

        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_update)
            redirect_to settings_project_path(@project)
          end
          format.js { head :ok }
          format.json { head :ok }
        end
      else
        Rails.logger.error "[EpicGrid] Failed to save project setting: #{@setting.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html do
            flash[:error] = "Epic Grid設定の保存に失敗しました: #{@setting.errors.full_messages.join(', ')}"
            redirect_to settings_project_path(@project)
          end
          format.js { head :unprocessable_entity }
          format.json { render json: { error: @setting.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize
      unless @project.module_enabled?(:epic_grid)
        render_403
        return false
      end

      unless User.current.allowed_to?(:manage_epic_grid, @project)
        render_403
        return false
      end
    end
  end
end
