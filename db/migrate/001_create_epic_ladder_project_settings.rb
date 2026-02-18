# frozen_string_literal: true

class CreateEpicLadderProjectSettings < ActiveRecord::Migration[6.1]
  def change
    # 新規インストール用: epic_ladder_project_settings テーブルを作成
    # 既存環境では003マイグレーションでリネームされるため、ここではスキップ
    return if table_exists?(:epic_ladder_project_settings) || table_exists?(:epic_grid_project_settings)

    create_table :epic_ladder_project_settings do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.boolean :mcp_enabled, default: false, null: false
      t.timestamps
    end
  end
end
