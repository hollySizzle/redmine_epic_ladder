# frozen_string_literal: true

class CreateEpicGridMcpToolHints < ActiveRecord::Migration[6.1]
  def change
    create_table :epic_grid_mcp_tool_hints do |t|
      t.references :project, null: false, foreign_key: true
      t.string :tool_key, null: false, limit: 50
      t.text :hint_text
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :epic_grid_mcp_tool_hints, [:project_id, :tool_key], unique: true, name: 'idx_mcp_tool_hints_project_tool'
  end
end
