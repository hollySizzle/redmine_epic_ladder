# frozen_string_literal: true

class AllowNullForMcpEnabled < ActiveRecord::Migration[6.1]
  def change
    # mcp_enabled に NULL を許可（未設定 = グローバル設定を使用）
    change_column_null :epic_ladder_project_settings, :mcp_enabled, true
    change_column_default :epic_ladder_project_settings, :mcp_enabled, nil
  end
end
