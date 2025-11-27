# frozen_string_literal: true

module EpicGrid
  # プロジェクト単位のEpic Grid設定コントローラー
  # プロジェクト設定の「Epic Grid」タブから呼び出される
  class ProjectSettingsController < ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize

    def update
      @setting = EpicGrid::ProjectSetting.for_project(@project)
      @setting.mcp_enabled = params.dig(:epic_grid_project_setting, :mcp_enabled) == '1'

      if @setting.save
        Rails.logger.info "[EpicGrid] Project setting updated: project_id=#{@project.id}, mcp_enabled=#{@setting.mcp_enabled}"
        flash[:notice] = l(:notice_successful_update)
      else
        Rails.logger.error "[EpicGrid] Failed to save project setting: #{@setting.errors.full_messages.join(', ')}"
        flash[:error] = l(:error_epic_grid_settings_save_failed, errors: @setting.errors.full_messages.join(', '))
      end

      redirect_to settings_project_path(@project, tab: 'epic_grid')
    end
  end
end
