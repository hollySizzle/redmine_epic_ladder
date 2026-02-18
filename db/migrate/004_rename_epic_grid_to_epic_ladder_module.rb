# frozen_string_literal: true

# enabled_modules テーブルの name を epic_grid → epic_ladder に変更するマイグレーション
# プロジェクトで有効化されているモジュール名を更新する
class RenameEpicGridToEpicLadderModule < ActiveRecord::Migration[6.1]
  def up
    # enabled_modules テーブルの name カラムを更新
    execute <<-SQL.squish
      UPDATE enabled_modules
      SET name = 'epic_ladder'
      WHERE name = 'epic_grid'
    SQL

    count = connection.select_value("SELECT COUNT(*) FROM enabled_modules WHERE name = 'epic_ladder'")
    Rails.logger.info "[EpicLadder] ✅ Updated #{count} project(s) module name: epic_grid → epic_ladder"
  end

  def down
    execute <<-SQL.squish
      UPDATE enabled_modules
      SET name = 'epic_grid'
      WHERE name = 'epic_ladder'
    SQL

    count = connection.select_value("SELECT COUNT(*) FROM enabled_modules WHERE name = 'epic_grid'")
    Rails.logger.info "[EpicLadder] ↩️ Reverted #{count} project(s) module name: epic_ladder → epic_grid"
  end
end
