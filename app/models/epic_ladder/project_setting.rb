# frozen_string_literal: true

module EpicLadder
  # プロジェクト単位のEpic Ladder設定
  # 未設定（nil）の項目はグローバル設定にフォールバック
  class ProjectSetting < ActiveRecord::Base
    include Redmine::SafeAttributes

    self.table_name = 'epic_ladder_project_settings'

    belongs_to :project

    validates :project_id, presence: true, uniqueness: true

    # Redmine標準のsafe_attributes
    safe_attributes 'epic_tracker', 'feature_tracker', 'user_story_tracker',
                    'task_tracker', 'test_tracker', 'bug_tracker',
                    'hierarchy_guide_enabled', 'mcp_enabled'

    # フォールバック対象の設定キー
    FALLBACK_KEYS = %w[
      epic_tracker feature_tracker user_story_tracker
      task_tracker test_tracker bug_tracker
      hierarchy_guide_enabled mcp_enabled
    ].freeze

    # プロジェクトの設定を取得（存在しなければデフォルト値で返す）
    # @param project [Project] プロジェクト
    # @return [EpicLadder::ProjectSetting] 設定オブジェクト
    def self.for_project(project)
      find_or_initialize_by(project: project)
    end

    # プロジェクト設定を取得（フォールバック付き）
    # @param project [Project] プロジェクト
    # @param key [String, Symbol] 設定キー
    # @return [Object] 設定値（プロジェクト設定 or グローバル設定）
    def self.get(project, key)
      key_str = key.to_s
      return global_setting(key_str) unless FALLBACK_KEYS.include?(key_str)

      setting = find_by(project: project)
      project_value = setting&.send(key_str)

      # nilの場合はグローバル設定にフォールバック
      project_value.nil? ? global_setting(key_str) : project_value
    end

    # プロジェクトでMCPが有効かどうか
    # @param project [Project] プロジェクト
    # @return [Boolean] MCP有効の場合true
    def self.mcp_enabled?(project)
      get(project, :mcp_enabled) == true || get(project, :mcp_enabled) == '1'
    end

    # プロジェクトで階層ガイドが有効かどうか
    # @param project [Project] プロジェクト
    # @return [Boolean] 階層ガイド有効の場合true
    def self.hierarchy_guide_enabled?(project)
      get(project, :hierarchy_guide_enabled) == true || get(project, :hierarchy_guide_enabled) == '1'
    end

    # プロジェクトのトラッカー名マッピングを取得
    # @param project [Project] プロジェクト
    # @return [Hash] トラッカー名マッピング
    def self.tracker_names(project)
      {
        epic: get(project, :epic_tracker) || 'Epic',
        feature: get(project, :feature_tracker) || 'Feature',
        user_story: get(project, :user_story_tracker) || 'UserStory',
        task: get(project, :task_tracker) || 'Task',
        test: get(project, :test_tracker) || 'Test',
        bug: get(project, :bug_tracker) || 'Bug'
      }
    end

    # グローバル設定を取得
    # @param key [String] 設定キー
    # @return [Object] グローバル設定値
    def self.global_setting(key)
      settings = Setting.plugin_redmine_epic_ladder || {}
      settings[key]
    end

    # 設定がグローバルからオーバーライドされているか確認
    # @param key [String, Symbol] 設定キー
    # @return [Boolean] オーバーライドされている場合true
    def overridden?(key)
      !send(key.to_s).nil?
    end

    # 全設定をグローバルにリセット
    def reset_to_global!
      FALLBACK_KEYS.each do |key|
        send("#{key}=", nil)
      end
      save!
    end
  end
end
