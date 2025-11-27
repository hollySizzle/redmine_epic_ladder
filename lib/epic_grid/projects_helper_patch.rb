# frozen_string_literal: true

module EpicGrid
  # ProjectsHelperにパッチを当てて、プロジェクト設定にEpic Gridタブを追加
  # Redmine標準のproject_settings_tabsを拡張する方式
  # 参考: redmine_wiki_extensions プラグイン
  module ProjectsHelperPatch
    def project_settings_tabs
      tabs = super

      # Epic Gridモジュールが有効な場合のみタブを追加
      if @project.module_enabled?(:epic_grid)
        tabs << {
          name: 'epic_grid',
          action: :manage_epic_grid,
          partial: 'epic_grid/project_settings/show',
          label: :label_epic_grid_settings
        }
      end

      tabs
    end
  end
end

ProjectsHelper.prepend(EpicGrid::ProjectsHelperPatch)
