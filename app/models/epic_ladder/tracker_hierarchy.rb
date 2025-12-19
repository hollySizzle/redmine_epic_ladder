# frozen_string_literal: true

module EpicLadder
  # トラッカー階層制約管理
  # Epic→Feature→UserStory→Task/Test 4段階構造の制約とリレーション自動管理
  # プロジェクト単位で設定可能（未設定時はグローバル設定にフォールバック）
  class TrackerHierarchy
    # プロジェクトのトラッカー名を取得（フォールバック付き）
    # @param project [Project, nil] プロジェクト（nilの場合はグローバル設定）
    # @return [Hash] トラッカー名マッピング
    def self.tracker_names(project = nil)
      if project
        ProjectSetting.tracker_names(project)
      else
        global_tracker_names
      end
    end

    # グローバル設定からトラッカー名を取得（後方互換用）
    # @return [Hash] トラッカー名マッピング
    def self.global_tracker_names
      @global_tracker_names ||= begin
        settings = Setting.plugin_redmine_epic_ladder || {}
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
      @global_tracker_names = nil
      @global_rules = nil
    end

    # 階層制約ルール定義（プロジェクト単位で動的生成）
    # @param project [Project, nil] プロジェクト
    # @return [Hash] 階層制約ルール
    def self.rules(project = nil)
      names = tracker_names(project)
      {
        names[:epic] => { children: [names[:feature]], parents: [] },
        names[:feature] => { children: [names[:user_story]], parents: [names[:epic]] },
        names[:user_story] => { children: [names[:task], names[:test], names[:bug]], parents: [names[:feature]] },
        names[:task] => { children: [], parents: [names[:user_story]] },
        names[:test] => { children: [], parents: [names[:user_story]] },
        names[:bug] => { children: [], parents: [names[:user_story], names[:feature]] }
      }.freeze
    end

    # 親子関係の妥当性を検証
    # @param child_tracker [Tracker] 子トラッカー
    # @param parent_tracker [Tracker] 親トラッカー
    # @param project [Project, nil] プロジェクト
    # @return [Boolean] 妥当な場合true
    def self.valid_parent?(child_tracker, parent_tracker, project = nil)
      return false unless child_tracker && parent_tracker

      rules(project).dig(child_tracker.name, :parents)&.include?(parent_tracker.name) || false
    end

    # 指定トラッカーに許可された子トラッカーを取得
    # @param tracker_name [String] トラッカー名
    # @param project [Project, nil] プロジェクト
    # @return [Array<String>] 許可された子トラッカー名
    def self.allowed_children(tracker_name, project = nil)
      rules(project).dig(tracker_name, :children) || []
    end

    # ルートトラッカー名を返す
    # @param project [Project, nil] プロジェクト
    # @return [String] ルートトラッカー名
    def self.root_tracker(project = nil)
      tracker_names(project)[:epic]
    end

    # 指定トラッカーの子トラッカー一覧を返す
    # @param tracker_name [String] トラッカー名
    # @param project [Project, nil] プロジェクト
    # @return [Array<String>] 子トラッカー名一覧
    def self.children_trackers(tracker_name, project = nil)
      allowed_children(tracker_name, project)
    end

    # 階層レベルを取得 (0-based index)
    # @param tracker_name [String] トラッカー名
    # @param project [Project, nil] プロジェクト
    # @return [Integer, nil] 階層レベル
    def self.level(tracker_name, project = nil)
      names = tracker_names(project)
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
    # @param issue [Issue] 検証対象のチケット
    # @return [Boolean] 妥当な場合true
    def self.validate_hierarchy(issue)
      return true unless issue.parent

      valid_parent?(issue.tracker, issue.parent.tracker, issue.project)
    end

    # 設定されたトラッカー名一覧を取得
    # @param project [Project, nil] プロジェクト
    # @return [Array<String>] トラッカー名一覧
    def self.configured_tracker_names(project = nil)
      tracker_names(project).values
    end

    # 指定されたトラッカーがカンバン管理対象かチェック
    # @param tracker_name [String] トラッカー名
    # @param project [Project, nil] プロジェクト
    # @return [Boolean] カンバン管理対象の場合true
    def self.kanban_tracker?(tracker_name, project = nil)
      configured_tracker_names(project).include?(tracker_name)
    end

    # ========================================
    # 設計書準拠の拡張機能（Service層へ移管）
    # ========================================

    # プロジェクト全体の階層検証（統計情報付き）
    def self.validate_project_hierarchy(project)
      HierarchyManager.validate_hierarchy(
        project.issues
               .joins(:tracker)
               .where(trackers: { name: configured_tracker_names(project) })
               .includes(:tracker, :parent => :tracker, children: :tracker)
      )
    end

    # 孤立したIssueの検出
    def self.find_orphaned_issues(project)
      names = tracker_names(project)
      project.issues
             .joins(:tracker)
             .where(trackers: { name: [names[:feature], names[:user_story],
                                       names[:task], names[:test], names[:bug]] })
             .where(parent_id: nil)
             .includes(:tracker)
    end

    # 不完全な階層構造の検出
    def self.find_incomplete_hierarchies(project)
      incomplete = []
      names = tracker_names(project)

      # Feature without UserStories
      features_without_stories = project.issues
                                       .joins(:tracker)
                                       .where(trackers: { name: names[:feature] })
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
                            .where(trackers: { name: names[:user_story] })
                            .includes(:tracker, children: :tracker)

      user_stories.each do |story|
        has_tasks = story.children.any? { |child| child.tracker.name == names[:task] }
        has_tests = story.children.any? { |child| child.tracker.name == names[:test] }

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
