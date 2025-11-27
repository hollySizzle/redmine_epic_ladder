# frozen_string_literal: true

class CreateEpicGridProjectSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :epic_grid_project_settings do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.boolean :mcp_enabled, default: false, null: false
      t.timestamps
    end
  end
end
