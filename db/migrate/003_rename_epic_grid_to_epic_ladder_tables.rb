# frozen_string_literal: true

# テーブル名を epic_grid_* から epic_ladder_* に変更するマイグレーション
# 本番環境で既存データを保持したままリネームする
class RenameEpicGridToEpicLadderTables < ActiveRecord::Migration[6.1]
  def up
    # epic_grid_project_settings → epic_ladder_project_settings
    if table_exists?(:epic_grid_project_settings) && !table_exists?(:epic_ladder_project_settings)
      rename_table :epic_grid_project_settings, :epic_ladder_project_settings
      Rails.logger.info '[EpicLadder] ✅ Renamed epic_grid_project_settings → epic_ladder_project_settings'
    end

    # epic_grid_mcp_tool_hints → epic_ladder_mcp_tool_hints
    if table_exists?(:epic_grid_mcp_tool_hints) && !table_exists?(:epic_ladder_mcp_tool_hints)
      rename_table :epic_grid_mcp_tool_hints, :epic_ladder_mcp_tool_hints
      Rails.logger.info '[EpicLadder] ✅ Renamed epic_grid_mcp_tool_hints → epic_ladder_mcp_tool_hints'
    end
  end

  def down
    # epic_ladder_project_settings → epic_grid_project_settings
    if table_exists?(:epic_ladder_project_settings) && !table_exists?(:epic_grid_project_settings)
      rename_table :epic_ladder_project_settings, :epic_grid_project_settings
      Rails.logger.info '[EpicLadder] ↩️ Reverted epic_ladder_project_settings → epic_grid_project_settings'
    end

    # epic_ladder_mcp_tool_hints → epic_grid_mcp_tool_hints
    if table_exists?(:epic_ladder_mcp_tool_hints) && !table_exists?(:epic_grid_mcp_tool_hints)
      rename_table :epic_ladder_mcp_tool_hints, :epic_grid_mcp_tool_hints
      Rails.logger.info '[EpicLadder] ↩️ Reverted epic_ladder_mcp_tool_hints → epic_grid_mcp_tool_hints'
    end
  end
end
