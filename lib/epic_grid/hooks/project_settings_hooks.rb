# frozen_string_literal: true

module EpicGrid
  module Hooks
    # プロジェクト設定画面へのフック
    # Epic Grid MCP設定をプロジェクト設定のモジュールセクション後に追加
    class ProjectSettingsHooks < Redmine::Hook::ViewListener
      # プロジェクト作成/編集フォームの下部に表示（モジュール選択後）
      render_on :view_projects_form,
                partial: 'epic_grid/project_settings/mcp_settings'
    end
  end
end
