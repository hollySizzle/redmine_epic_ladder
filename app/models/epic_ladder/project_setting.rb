# frozen_string_literal: true

module EpicLadder
  # プロジェクト単位のEpic Grid設定
  # MCP APIアクセス許可などを管理
  class ProjectSetting < ActiveRecord::Base
    self.table_name = 'epic_ladder_project_settings'

    belongs_to :project

    validates :project_id, presence: true, uniqueness: true

    # プロジェクトの設定を取得（存在しなければデフォルト値で返す）
    # @param project [Project] プロジェクト
    # @return [EpicLadder::ProjectSetting] 設定オブジェクト
    def self.for_project(project)
      find_or_initialize_by(project: project)
    end

    # プロジェクトでMCPが有効かどうか
    # @param project [Project] プロジェクト
    # @return [Boolean] MCP有効の場合true
    def self.mcp_enabled?(project)
      setting = find_by(project: project)
      setting&.mcp_enabled || false
    end
  end
end
