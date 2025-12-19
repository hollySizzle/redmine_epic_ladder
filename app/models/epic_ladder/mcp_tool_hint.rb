# frozen_string_literal: true

module EpicLadder
  # MCPツールのプロジェクト固有ヒント設定
  # プロジェクトごとにMCPツールの追加説明（ヒント）を設定できる
  #
  # @example
  #   hint = EpicLadder::McpToolHint.for_tool(project, 'create_task')
  #   hint.hint_text = 'レビュー依頼時は@hollyをメンション'
  #   hint.save!
  #
  # @example ツールのdescriptionにヒントを付与
  #   description = EpicLadder::McpToolHint.build_description(
  #     project,
  #     'create_task',
  #     'Task（作業単位）チケットを作成します'
  #   )
  #   # => "Task（作業単位）チケットを作成します。【プロジェクト固有ルール】レビュー依頼時は@hollyをメンション"
  class McpToolHint < ActiveRecord::Base
    self.table_name = 'epic_ladder_mcp_tool_hints'

    HINT_TEXT_MAX_LENGTH = 500

    # データ変更系ツール（ヒント設定対象）
    MODIFYING_TOOLS = %w[
      create_epic
      create_feature
      create_user_story
      create_task
      create_bug
      create_test
      create_version
      assign_to_version
      move_to_next_version
      update_issue_status
      update_issue_progress
      update_issue_assignee
      add_issue_comment
    ].freeze

    belongs_to :project

    validates :project_id, presence: true
    validates :tool_key, presence: true, length: { maximum: 50 }
    validates :tool_key, uniqueness: { scope: :project_id }
    validates :tool_key, inclusion: { in: MODIFYING_TOOLS, message: '無効なツールキーです' }
    validates :hint_text, length: { maximum: HINT_TEXT_MAX_LENGTH }

    scope :enabled, -> { where(enabled: true) }
    scope :for_project, ->(project) { where(project: project) }

    # プロジェクトとツールキーで設定を取得（存在しなければ初期化）
    # @param project [Project] プロジェクト
    # @param tool_key [String] ツールキー（例: 'create_task'）
    # @return [EpicLadder::McpToolHint] ヒント設定オブジェクト
    def self.for_tool(project, tool_key)
      find_or_initialize_by(project: project, tool_key: tool_key)
    end

    # プロジェクトの有効なヒントを取得（グローバル設定へのフォールバック付き）
    # @param project [Project] プロジェクト
    # @param tool_key [String] ツールキー
    # @return [String, nil] ヒントテキスト（無効または未設定の場合nil）
    def self.hint_for(project, tool_key)
      # 1. プロジェクト固有の設定を確認
      project_hint = enabled.find_by(project: project, tool_key: tool_key)
      return project_hint.hint_text.presence if project_hint&.hint_text.present?

      # 2. グローバル設定にフォールバック
      global_hint_for(tool_key)
    end

    # グローバル設定からヒントを取得
    # @param tool_key [String] ツールキー
    # @return [String, nil] ヒントテキスト（無効または未設定の場合nil）
    def self.global_hint_for(tool_key)
      settings = Setting.plugin_redmine_epic_ladder || {}
      hints = settings['mcp_tool_hints'] || {}
      hint = hints[tool_key]

      return nil unless hint.is_a?(Hash)
      return nil unless hint['enabled'] == '1' || hint['enabled'] == true

      hint['hint_text'].presence
    end

    # ベースのdescriptionにヒントを付与
    # @param project [Project] プロジェクト
    # @param tool_key [String] ツールキー
    # @param base_description [String] ベースの説明文
    # @return [String] ヒント付きの説明文
    def self.build_description(project, tool_key, base_description)
      hint = hint_for(project, tool_key)
      return base_description if hint.blank?

      "#{base_description}【ルール】#{hint}"
    end

    # ツールキーの表示名を取得
    # @return [String] ツールの表示名
    def tool_display_name
      I18n.t("epic_ladder.mcp_tools.#{tool_key}", default: tool_key.titleize)
    end
  end
end
