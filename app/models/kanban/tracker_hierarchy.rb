# frozen_string_literal: true

module Kanban
  # トラッカー階層制約管理
  # Epic→Feature→UserStory→Task/Test 4段階構造の制約とリレーション自動管理
  class TrackerHierarchy
    # 階層制約ルール定義
    RULES = {
      'Epic' => { children: ['Feature'], parents: [] },
      'Feature' => { children: ['UserStory'], parents: ['Epic'] },
      'UserStory' => { children: ['Task', 'Test', 'Bug'], parents: ['Feature'] },
      'Task' => { children: [], parents: ['UserStory'] },
      'Test' => { children: [], parents: ['UserStory'] },
      'Bug' => { children: [], parents: ['UserStory', 'Feature'] }
    }.freeze

    # 親子関係の妥当性を検証
    def self.valid_parent?(child_tracker, parent_tracker)
      return false unless child_tracker && parent_tracker

      RULES.dig(child_tracker.name, :parents)&.include?(parent_tracker.name) || false
    end

    # 指定トラッカーに許可された子トラッカーを取得
    def self.allowed_children(tracker_name)
      RULES.dig(tracker_name, :children) || []
    end

    # 階層レベルを取得
    def self.level(tracker_name)
      { 'Epic' => 1, 'Feature' => 2, 'UserStory' => 3 }.fetch(tracker_name, 4)
    end

    # 階層構造を検証
    def self.validate_hierarchy(issue)
      return true unless issue.parent

      valid_parent?(issue.tracker, issue.parent.tracker)
    end
  end
end