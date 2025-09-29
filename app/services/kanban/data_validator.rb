# frozen_string_literal: true

module Kanban
  # データ検証システム
  # 階層構造・循環参照・整合性の包括的チェック機能
  class DataValidator
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :project, :user, :options

    # 検証結果データ構造
    class ValidationResult
      attr_accessor :valid, :errors, :warnings, :performance_metrics

      def initialize
        @valid = true
        @errors = []
        @warnings = []
        @performance_metrics = {}
      end

      def add_error(field, code, message, severity = 'error')
        @errors << {
          field: field,
          code: code,
          message: message,
          severity: severity
        }
        @valid = false if severity == 'error'
      end

      def add_warning(field, code, message)
        @warnings << {
          field: field,
          code: code,
          message: message,
          severity: 'warning'
        }
      end

      def success?
        @valid && @errors.empty?
      end

      def as_json
        {
          valid: @valid,
          success: success?,
          errors: @errors,
          warnings: @warnings,
          performance_metrics: @performance_metrics
        }
      end
    end

    def initialize(project:, user: nil, options: {})
      @project = project
      @user = user || User.current
      @options = options.with_indifferent_access
    end

    # メイン検証メソッド
    def validate_project_hierarchy
      result = ValidationResult.new

      benchmark_time = Benchmark.realtime do
        # 1. 権限チェック
        validate_permissions(result)
        return result unless result.success?

        # 2. 階層構造検証
        validate_hierarchy_structure(result)

        # 3. 循環参照検証
        validate_circular_references(result)

        # 4. Version整合性検証
        validate_version_consistency(result)

        # 5. データ整合性検証
        validate_data_consistency(result)

        # 6. パフォーマンス検証
        validate_query_performance(result)
      end

      result.performance_metrics[:total_validation_time] = benchmark_time.round(3)
      result
    end

    # 単一Issue検証
    def validate_issue(issue)
      result = ValidationResult.new

      benchmark_time = Benchmark.realtime do
        validate_issue_hierarchy(issue, result)
        validate_issue_relationships(issue, result)
        validate_issue_version_consistency(issue, result)
        validate_issue_status_transitions(issue, result)
      end

      result.performance_metrics[:issue_validation_time] = benchmark_time.round(3)
      result
    end

    # 階層構造の包括検証
    def validate_hierarchy_integrity
      result = ValidationResult.new

      epics = load_epics_efficiently

      epics.each do |epic|
        validate_epic_structure(epic, result)

        feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
        user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]

        epic.children.each do |feature|
          next unless feature.tracker.name == feature_tracker_name

          validate_feature_structure(feature, result)

          feature.children.each do |user_story|
            next unless user_story.tracker.name == user_story_tracker_name

            validate_user_story_structure(user_story, result)
          end
        end
      end

      result
    end

    private

    # 権限チェック
    def validate_permissions(result)
      unless @user.allowed_to?(:view_issues, @project)
        result.add_error('user', 'permission_denied', 'プロジェクトの閲覧権限がありません')
      end
    end

    # 階層構造検証
    def validate_hierarchy_structure(result)
      issues_with_invalid_hierarchy = []

      @project.issues.includes(:tracker, :parent => :tracker).each do |issue|
        next unless TrackerHierarchy.kanban_tracker?(issue.tracker.name)

        if issue.parent && !TrackerHierarchy.valid_parent?(issue.tracker, issue.parent.tracker)
          issues_with_invalid_hierarchy << {
            issue_id: issue.id,
            issue_subject: issue.subject,
            issue_tracker: issue.tracker.name,
            parent_tracker: issue.parent.tracker.name,
            expected_parents: TrackerHierarchy.rules.dig(issue.tracker.name, :parents) || []
          }
        end
      end

      if issues_with_invalid_hierarchy.any?
        result.add_error(
          'hierarchy',
          'invalid_parent_child',
          "不正な親子関係が#{issues_with_invalid_hierarchy.count}件検出されました",
          'error'
        )
        result.performance_metrics[:invalid_hierarchy_issues] = issues_with_invalid_hierarchy
      end
    end

    # 循環参照検証
    def validate_circular_references(result)
      visited = Set.new
      rec_stack = Set.new
      circular_issues = []

      @project.issues.includes(:parent).each do |issue|
        next if visited.include?(issue.id)

        if has_circular_reference?(issue, visited, rec_stack, [])
          circular_issues << {
            issue_id: issue.id,
            issue_subject: issue.subject,
            cycle_path: find_cycle_path(issue)
          }
        end
      end

      if circular_issues.any?
        result.add_error(
          'circular_reference',
          'cycle_detected',
          "循環参照が#{circular_issues.count}件検出されました",
          'error'
        )
        result.performance_metrics[:circular_reference_issues] = circular_issues
      end
    end

    # Version整合性検証
    def validate_version_consistency(result)
      inconsistent_versions = []

      # Epic → Feature → UserStory の Version継承チェック
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      epics_with_version = @project.issues
                                  .joins(:tracker)
                                  .where(trackers: { name: epic_tracker_name })
                                  .where.not(fixed_version_id: nil)
                                  .includes(children: [:tracker, :fixed_version])

      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]

      epics_with_version.each do |epic|
        epic.children.each do |feature|
          next unless feature.tracker.name == feature_tracker_name

          if feature.fixed_version_id && feature.fixed_version_id != epic.fixed_version_id
            inconsistent_versions << {
              parent_id: epic.id,
              parent_subject: epic.subject,
              parent_version: epic.fixed_version&.name,
              child_id: feature.id,
              child_subject: feature.subject,
              child_version: feature.fixed_version&.name,
              level: 'Epic-Feature'
            }
          end

          # Feature → UserStory の Version継承チェック
          feature.children.each do |user_story|
            next unless user_story.tracker.name == user_story_tracker_name

            expected_version_id = feature.fixed_version_id || epic.fixed_version_id

            if user_story.fixed_version_id && user_story.fixed_version_id != expected_version_id
              inconsistent_versions << {
                parent_id: feature.id,
                parent_subject: feature.subject,
                parent_version: feature.fixed_version&.name || epic.fixed_version&.name,
                child_id: user_story.id,
                child_subject: user_story.subject,
                child_version: user_story.fixed_version&.name,
                level: 'Feature-UserStory'
              }
            end
          end
        end
      end

      if inconsistent_versions.any?
        result.add_warning(
          'version_consistency',
          'version_mismatch',
          "Version不整合が#{inconsistent_versions.count}件検出されました"
        )
        result.performance_metrics[:version_inconsistencies] = inconsistent_versions
      end
    end

    # データ整合性検証
    def validate_data_consistency(result)
      # 孤立したIssue検証
      orphaned_issues = find_orphaned_issues
      if orphaned_issues.any?
        result.add_warning(
          'data_consistency',
          'orphaned_issues',
          "孤立したIssueが#{orphaned_issues.count}件検出されました"
        )
        result.performance_metrics[:orphaned_issues] = orphaned_issues
      end

      # 重複したIssue検証
      duplicate_subjects = find_duplicate_subjects
      if duplicate_subjects.any?
        result.add_warning(
          'data_consistency',
          'duplicate_subjects',
          "重複した件名が#{duplicate_subjects.count}件検出されました"
        )
        result.performance_metrics[:duplicate_subjects] = duplicate_subjects
      end

      # 必須フィールド検証
      issues_missing_required_fields = find_issues_missing_required_fields
      if issues_missing_required_fields.any?
        result.add_error(
          'data_consistency',
          'missing_required_fields',
          "必須フィールド不足のIssueが#{issues_missing_required_fields.count}件検出されました"
        )
        result.performance_metrics[:missing_required_fields] = issues_missing_required_fields
      end
    end

    # N+1クエリパフォーマンス検証
    def validate_query_performance(result)
      # 効率的なデータ読み込みのテスト
      query_metrics = {}

      # Epic読み込みクエリ数測定
      epic_query_count = measure_query_count do
        load_epics_efficiently.limit(10).to_a
      end
      query_metrics[:epic_load_queries] = epic_query_count

      # 統計計算クエリ数測定
      stats_query_count = measure_query_count do
        epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
        epic = @project.issues.joins(:tracker).where(trackers: { name: epic_tracker_name }).first
        StatisticsEngine.calculate_epic_statistics(epic) if epic
      end
      query_metrics[:statistics_calculation_queries] = stats_query_count

      result.performance_metrics[:query_metrics] = query_metrics

      # N+1クエリの警告
      if epic_query_count > 5
        result.add_warning(
          'performance',
          'potential_n_plus_1',
          "Epicデータ読み込みでN+1クエリの可能性があります（#{epic_query_count}クエリ実行）"
        )
      end
    end

    # 個別Issue検証メソッド群
    def validate_issue_hierarchy(issue, result)
      if issue.parent && !TrackerHierarchy.valid_parent?(issue.tracker, issue.parent.tracker)
        result.add_error(
          'issue_hierarchy',
          'invalid_parent',
          "Issue##{issue.id}の親子関係が不正です（#{issue.tracker.name} → #{issue.parent.tracker.name}）"
        )
      end
    end

    def validate_issue_relationships(issue, result)
      # blocks関係の妥当性チェック
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      test_tracker_name = Kanban::TrackerHierarchy.tracker_names[:test]

      if issue.tracker.name == user_story_tracker_name
        test_children = issue.children.joins(:tracker).where(trackers: { name: test_tracker_name })

        test_children.each do |test|
          blocks_relation = IssueRelation.find_by(
            issue_from_id: test.id,
            issue_to_id: issue.id,
            relation_type: 'blocks'
          )

          unless blocks_relation
            result.add_warning(
              'issue_relationships',
              'missing_blocks_relation',
              "Test##{test.id}からUserStory##{issue.id}へのblocks関係が不足しています"
            )
          end
        end
      end
    end

    def validate_issue_version_consistency(issue, result)
      if issue.parent && issue.parent.fixed_version_id &&
         issue.fixed_version_id != issue.parent.fixed_version_id

        result.add_warning(
          'issue_version',
          'version_mismatch',
          "Issue##{issue.id}のVersionが親Issue##{issue.parent_id}と不整合です"
        )
      end
    end

    def validate_issue_status_transitions(issue, result)
      # UserStoryのステータス遷移制約チェック
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      task_tracker_name = Kanban::TrackerHierarchy.tracker_names[:task]

      if issue.tracker.name == user_story_tracker_name && issue.status.name.in?(['Testing', 'Resolved'])
        incomplete_tasks = issue.children
                               .joins(:tracker, :status)
                               .where(trackers: { name: task_tracker_name })
                               .where.not(issue_statuses: { is_closed: true })

        if incomplete_tasks.any?
          result.add_error(
            'status_transition',
            'blocked_by_incomplete_tasks',
            "UserStory##{issue.id}に未完了のTaskがあるため、ステータス遷移が制限されます"
          )
        end
      end
    end

    # ユーティリティメソッド群
    def load_epics_efficiently
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      @project.issues
              .includes(
                :tracker, :status, :assigned_to, :fixed_version,
                children: [
                  :tracker, :status, :assigned_to, :fixed_version,
                  { children: [:tracker, :status, :assigned_to, :fixed_version] }
                ]
              )
              .joins(:tracker)
              .where(trackers: { name: epic_tracker_name })
    end

    def has_circular_reference?(issue, visited, rec_stack, path)
      return false if visited.include?(issue.id)

      visited.add(issue.id)
      rec_stack.add(issue.id)
      path.push(issue.id)

      if issue.parent
        if rec_stack.include?(issue.parent_id)
          return true # 循環検出
        elsif has_circular_reference?(issue.parent, visited, rec_stack, path)
          return true
        end
      end

      rec_stack.delete(issue.id)
      path.pop
      false
    end

    def find_cycle_path(issue)
      path = []
      current = issue
      visited = Set.new

      while current && !visited.include?(current.id)
        visited.add(current.id)
        path << { id: current.id, subject: current.subject }
        current = current.parent
      end

      if current
        cycle_start = path.find_index { |item| item[:id] == current.id }
        path[cycle_start..-1] if cycle_start
      else
        path
      end
    end

    def find_orphaned_issues
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      orphaned_tracker_names = [tracker_names[:feature], tracker_names[:user_story],
                                tracker_names[:task], tracker_names[:test], tracker_names[:bug]]

      @project.issues
              .joins(:tracker)
              .where(trackers: { name: orphaned_tracker_names })
              .where(parent_id: nil)
              .pluck(:id, :subject, :tracker_id)
              .map { |id, subject, tracker_id|
                {
                  issue_id: id,
                  subject: subject,
                  tracker_name: Tracker.find(tracker_id).name
                }
              }
    end

    def find_duplicate_subjects
      @project.issues
              .group(:subject)
              .having('COUNT(*) > 1')
              .count
              .map { |subject, count| { subject: subject, count: count } }
    end

    def find_issues_missing_required_fields
      issues_missing_fields = []

      @project.issues.includes(:tracker).each do |issue|
        missing_fields = []

        missing_fields << 'subject' if issue.subject.blank?
        missing_fields << 'status' unless issue.status
        missing_fields << 'tracker' unless issue.tracker
        task_tracker_name = Kanban::TrackerHierarchy.tracker_names[:task]
        test_tracker_name = Kanban::TrackerHierarchy.tracker_names[:test]
        missing_fields << 'assigned_to' if issue.tracker.name.in?([task_tracker_name, test_tracker_name]) && issue.assigned_to_id.nil?

        if missing_fields.any?
          issues_missing_fields << {
            issue_id: issue.id,
            tracker_name: issue.tracker&.name,
            missing_fields: missing_fields
          }
        end
      end

      issues_missing_fields
    end

    def measure_query_count(&block)
      query_count = 0

      callback = lambda do |name, started, finished, unique_id, data|
        query_count += 1 if data[:sql] && !data[:name]&.include?('SCHEMA')
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
      query_count
    end

    def validate_epic_structure(epic, result)
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]

      unless epic.tracker.name == epic_tracker_name
        result.add_error('epic_structure', 'invalid_tracker', "Issue##{epic.id}はEpicトラッカーではありません")
        return
      end

      non_feature_children = epic.children.joins(:tracker).where.not(trackers: { name: feature_tracker_name })
      if non_feature_children.any?
        result.add_error(
          'epic_structure',
          'invalid_children',
          "Epic##{epic.id}にFeature以外の子要素があります: #{non_feature_children.pluck(:id).join(', ')}"
        )
      end
    end

    def validate_feature_structure(feature, result)
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]

      unless feature.tracker.name == feature_tracker_name
        result.add_error('feature_structure', 'invalid_tracker', "Issue##{feature.id}はFeatureトラッカーではありません")
        return
      end

      unless feature.parent&.tracker&.name == epic_tracker_name
        result.add_error(
          'feature_structure',
          'missing_epic_parent',
          "Feature##{feature.id}の親がEpicではありません"
        )
      end

      non_user_story_children = feature.children.joins(:tracker).where.not(trackers: { name: user_story_tracker_name })
      if non_user_story_children.any?
        result.add_warning(
          'feature_structure',
          'unexpected_children',
          "Feature##{feature.id}にUserStory以外の子要素があります: #{non_user_story_children.pluck(:id).join(', ')}"
        )
      end
    end

    def validate_user_story_structure(user_story, result)
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      test_tracker_name = Kanban::TrackerHierarchy.tracker_names[:test]

      unless user_story.tracker.name == user_story_tracker_name
        result.add_error('user_story_structure', 'invalid_tracker', "Issue##{user_story.id}はUserStoryトラッカーではありません")
        return
      end

      unless user_story.parent&.tracker&.name == feature_tracker_name
        result.add_error(
          'user_story_structure',
          'missing_feature_parent',
          "UserStory##{user_story.id}の親がFeatureではありません"
        )
      end

      # Test存在チェック
      test_children = user_story.children.joins(:tracker).where(trackers: { name: test_tracker_name })
      if test_children.empty?
        result.add_warning(
          'user_story_structure',
          'missing_test',
          "UserStory##{user_story.id}にTestが不足しています"
        )
      end
    end
  end
end