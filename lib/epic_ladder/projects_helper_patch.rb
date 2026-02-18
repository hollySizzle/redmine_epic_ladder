# frozen_string_literal: true

module EpicLadder
  # ProjectsHelperにパッチを当てて、プロジェクト設定にEpic Ladderタブを追加
  # Redmine標準のproject_settings_tabsを拡張する方式
  # 参考: redmine_wiki_extensions プラグイン
  module ProjectsHelperPatch
    def project_settings_tabs
      tabs = super

      # Epic Ladderモジュールが有効な場合のみタブを追加
      if @project.module_enabled?(:epic_ladder)
        tabs << {
          name: 'epic_ladder',
          action: :manage_epic_ladder,
          partial: 'epic_ladder/project_settings/show',
          label: :label_epic_ladder_settings
        }
      end

      tabs
    end
  end
end

ProjectsHelper.prepend(EpicLadder::ProjectsHelperPatch)
