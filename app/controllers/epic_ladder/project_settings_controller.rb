# frozen_string_literal: true

module EpicLadder
  # プロジェクト単位のEpic Ladder設定コントローラー
  # プロジェクト設定の「Epic Ladder」タブから呼び出される
  class ProjectSettingsController < ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize

    # 設定可能なキー一覧
    PERMITTED_KEYS = %w[
      epic_tracker feature_tracker user_story_tracker
      task_tracker test_tracker bug_tracker
      hierarchy_guide_enabled mcp_enabled
    ].freeze

    def update
      @setting = EpicLadder::ProjectSetting.for_project(@project)

      update_settings

      if @setting.save
        # キャッシュをクリア
        EpicLadder::TrackerHierarchy.clear_cache!

        Rails.logger.info "[EpicLadder] Project setting updated: project_id=#{@project.id}"
        flash[:notice] = l(:notice_successful_update)
      else
        Rails.logger.error "[EpicLadder] Failed to save project setting: #{@setting.errors.full_messages.join(', ')}"
        flash[:error] = l(:error_epic_ladder_settings_save_failed, errors: @setting.errors.full_messages.join(', '))
      end

      redirect_to settings_project_path(@project, tab: 'epic_ladder')
    end

    private

    def update_settings
      setting_params = params[:epic_ladder_project_setting] || {}

      PERMITTED_KEYS.each do |key|
        value = setting_params[key]

        # 空文字列はnilに変換（グローバル設定にフォールバック）
        if value.blank?
          @setting.send("#{key}=", nil)
        elsif %w[hierarchy_guide_enabled mcp_enabled].include?(key)
          # Boolean型の処理
          @setting.send("#{key}=", value == '1')
        else
          # String型の処理（トラッカー名）
          @setting.send("#{key}=", value)
        end
      end
    end
  end
end
