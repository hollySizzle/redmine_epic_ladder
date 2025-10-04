# frozen_string_literal: true

module EpicGrid
  # トラッカー階層制約管理
  # Epic→Feature→UserStory→Task/Test 4段階構造の制約とリレーション自動管理
  class TrackerHierarchy
    # プラグイン設定からトラッカー名を取得
    def self.tracker_names
      @tracker_names ||= begin
        settings = Setting.plugin_redmine_epic_grid || {}
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

    # ルートトラッカー名を返す
    def self.root_tracker
      tracker_names[:epic]
    end

    # 指定トラッカーの子トラッカー一覧を返す
    def self.children_trackers(tracker_name)
      allowed_children(tracker_name)
    end

    # 階層レベルを取得 (0-based index)
    def self.level(tracker_name)
      names = tracker_names
      level_map = {
        names[:epic] => 0,
        names[:feature] => 1,
        names[:user_story] => 2,
        names[:task] => 3,
        names[:test] => 3,
        names[:bug] => 3
      }
      level_map[tracker_name]
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

    # ========================================
    # 設計書準拠の拡張機能（Service層へ移管）
    # ========================================

    # プロジェクト全体の階層検証（統計情報付き）
    def self.validate_project_hierarchy(project)
      HierarchyManager.validate_hierarchy(
        project.issues
               .joins(:tracker)
               .where(trackers: { name: configured_tracker_names })
               .includes(:tracker, :parent => :tracker, children: :tracker)
      )
    end

    # 孤立したIssueの検出
    def self.find_orphaned_issues(project)
      project.issues
             .joins(:tracker)
             .where(trackers: { name: [tracker_names[:feature], tracker_names[:user_story],
                                     tracker_names[:task], tracker_names[:test], tracker_names[:bug]] })
             .where(parent_id: nil)
             .includes(:tracker)
    end

    # 不完全な階層構造の検出
    def self.find_incomplete_hierarchies(project)
      incomplete = []

      # Feature without UserStories
      features_without_stories = project.issues
                                       .joins(:tracker)
                                       .where(trackers: { name: tracker_names[:feature] })
                                       .left_joins(:children)
                                       .where(children_issues: { id: nil })
                                       .includes(:tracker)

      features_without_stories.each do |feature|
        incomplete << {
          issue: feature,
          type: 'feature_without_user_stories',
          message: 'UserStoryを持たないFeatureです'
        }
      end

      # UserStories without Tasks or Tests
      user_stories = project.issues
                            .joins(:tracker)
                            .where(trackers: { name: tracker_names[:user_story] })
                            .includes(:tracker, children: :tracker)

      user_stories.each do |story|
        has_tasks = story.children.any? { |child| child.tracker.name == tracker_names[:task] }
        has_tests = story.children.any? { |child| child.tracker.name == tracker_names[:test] }

        unless has_tasks
          incomplete << {
            issue: story,
            type: 'user_story_without_tasks',
            message: 'Taskを持たないUserStoryです'
          }
        end

        unless has_tests
          incomplete << {
            issue: story,
            type: 'user_story_without_tests',
            message: 'Testを持たないUserStoryです'
          }
        end
      end

      incomplete
    end
  end
end