# frozen_string_literal: true

class CreateEpicLadderMcpToolHints < ActiveRecord::Migration[6.1]
  def change
    # 新規インストール用: epic_ladder_mcp_tool_hints テーブルを作成
    # 既存環境では003マイグレーションでリネームされるため、ここではスキップ
    return if table_exists?(:epic_ladder_mcp_tool_hints) || table_exists?(:epic_grid_mcp_tool_hints)

    create_table :epic_ladder_mcp_tool_hints do |t|
      t.references :project, null: false, foreign_key: true
      t.string :tool_key, null: false, limit: 50
      t.text :hint_text
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :epic_ladder_mcp_tool_hints, [:project_id, :tool_key], unique: true, name: 'idx_mcp_tool_hints_project_tool'
  end
end
