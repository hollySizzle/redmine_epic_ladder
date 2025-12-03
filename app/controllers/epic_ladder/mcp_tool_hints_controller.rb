# frozen_string_literal: true

module EpicLadder
  # MCPツールヒント設定コントローラー
  # プロジェクト設定の「Epic Ladder」タブからヒント設定を保存する
  class McpToolHintsController < ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize

    def update
      errors = []

      params[:mcp_tool_hints]&.each do |tool_key, hint_params|
        next unless McpToolHint::MODIFYING_TOOLS.include?(tool_key)

        hint = McpToolHint.for_tool(@project, tool_key)
        hint.enabled = hint_params[:enabled] == '1'
        hint.hint_text = hint_params[:hint_text].presence

        unless hint.save
          errors << "#{tool_key}: #{hint.errors.full_messages.join(', ')}"
        end
      end

      if errors.empty?
        Rails.logger.info "[EpicLadder] MCP tool hints updated: project_id=#{@project.id}"
        flash[:notice] = l(:notice_epic_ladder_mcp_tool_hints_saved)
      else
        Rails.logger.error "[EpicLadder] Failed to save MCP tool hints: #{errors.join('; ')}"
        flash[:error] = l(:error_epic_ladder_mcp_tool_hints_save_failed, errors: errors.join('; '))
      end

      redirect_to settings_project_path(@project, tab: 'epic_ladder')
    end
  end
end
