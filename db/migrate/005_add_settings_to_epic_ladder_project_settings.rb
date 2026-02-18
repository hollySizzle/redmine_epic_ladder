# frozen_string_literal: true

class AddSettingsToEpicLadderProjectSettings < ActiveRecord::Migration[6.1]
  def change
    change_table :epic_ladder_project_settings, bulk: true do |t|
      # トラッカー名マッピング（nilの場合はグローバル設定にフォールバック）
      t.string :epic_tracker
      t.string :feature_tracker
      t.string :user_story_tracker
      t.string :task_tracker
      t.string :test_tracker
      t.string :bug_tracker

      # 機能フラグ（nilの場合はグローバル設定にフォールバック）
      t.boolean :hierarchy_guide_enabled
      # mcp_enabled は既存カラム
    end
  end
end
