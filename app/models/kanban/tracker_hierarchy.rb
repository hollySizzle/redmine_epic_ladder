# frozen_string_literal: true

module Kanban
  # トラッカー階層制約管理
  # Epic→Feature→UserStory→Task/Test 4段階構造の制約とリレーション自動管理
  class TrackerHierarchy
    # プラグイン設定からトラッカー名を取得
    def self.tracker_names
      @tracker_names ||= begin
        settings = Setting.plugin_redmine_release_kanban || {}
        {
          epic: settings['epic_tracker'] || 'Epic',
          feature: settings['feature_tracker'] || 'Feature',
          user_story: settings['user_story_tracker'] || 'UserStory',
          task: settings['task_tracker'] || 'Task',
          test: settings['test_tracker'] || 'Test',
          bug: settings['bug_tracker'] || 'Bug'
        }
      end
    end

    # 設定キャッシュをクリア（設定変更時に呼び出す）
    def self.clear_cache!
      @tracker_names = nil
      @rules = nil
    end

    # 階層制約ルール定義（設定値から動的生成）
    def self.rules
      @rules ||= begin
        names = tracker_names
        {
          names[:epic] => { children: [names[:feature]], parents: [] },
          names[:feature] => { children: [names[:user_story]], parents: [names[:epic]] },
          names[:user_story] => { children: [names[:task], names[:test], names[:bug]], parents: [names[:feature]] },
          names[:task] => { children: [], parents: [names[:user_story]] },
          names[:test] => { children: [], parents: [names[:user_story]] },
          names[:bug] => { children: [], parents: [names[:user_story], names[:feature]] }
        }.freeze
      end
    end

    # 親子関係の妥当性を検証
    def self.valid_parent?(child_tracker, parent_tracker)
      return false unless child_tracker && parent_tracker

      rules.dig(child_tracker.name, :parents)&.include?(parent_tracker.name) || false
    end

    # 指定トラッカーに許可された子トラッカーを取得
    def self.allowed_children(tracker_name)
      rules.dig(tracker_name, :children) || []
    end

    # 階層レベルを取得
    def self.level(tracker_name)
      names = tracker_names
      level_map = {
        names[:epic] => 1,
        names[:feature] => 2,
        names[:user_story] => 3
      }
      level_map.fetch(tracker_name, 4)
    end

    # 階層構造を検証
    def self.validate_hierarchy(issue)
      return true unless issue.parent

      valid_parent?(issue.tracker, issue.parent.tracker)
    end

    # 設定されたトラッカー名一覧を取得
    def self.configured_tracker_names
      tracker_names.values
    end

    # 指定されたトラッカーがカンバン管理対象かチェック
    def self.kanban_tracker?(tracker_name)
      configured_tracker_names.include?(tracker_name)
    end
  end
end