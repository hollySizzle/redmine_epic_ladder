# frozen_string_literal: true

module Kanban
  # 階層構造管理サービス
  # Epic→Feature→UserStory→Task/Test/Bug の4層階層での親子関係・循環参照チェック
  class HierarchyManager
    class CircularReferenceError < StandardError; end
    class InvalidHierarchyError < StandardError; end
    class HierarchyDepthExceededError < StandardError; end

    MAX_HIERARCHY_DEPTH = 4

    def self.validate_hierarchy(data)
      new(data).validate_hierarchy
    end

    def self.check_circular_reference(issue)
      new([issue]).check_circular_reference(issue)
    end

    def self.validate_parent_child_types(child_tracker, parent_tracker)
      TrackerHierarchy.valid_parent?(child_tracker, parent_tracker)
    end

    def self.calculate_hierarchy_depth(issue)
      depth = 0
      current = issue

      while current.parent
        depth += 1
        current = current.parent
        break if depth > MAX_HIERARCHY_DEPTH # 無限ループ防止
      end

      depth + 1 # 自身も含める
    end

    def initialize(data)
      @data = data
      @validation_result = {
        valid: true,
        errors: [],
        warnings: [],
        statistics: {}
      }
    end

    def validate_hierarchy
      begin
        # 1. 階層構造検証
        validate_hierarchy_structure

        # 2. 循環参照検証
        detect_circular_references

        # 3. 階層深度検証
        validate_hierarchy_depths

        # 4. 型制約検証
        validate_type_constraints

        @validation_result
      rescue => e
        Rails.logger.error "HierarchyManager validation error: #{e.message}"
        {
          success: false,
          error: e.message,
          error_code: 'HIERARCHY_VALIDATION_ERROR'
        }
      end
    end

    def check_circular_reference(issue, visited = Set.new, path = [])
      return [] if visited.include?(issue.id)

      visited.add(issue.id)
      path.push(issue.id)

      if issue.parent
        if path.include?(issue.parent.id)
          # 循環参照検出
          cycle_start = path.index(issue.parent.id)
          return path[cycle_start..-1] + [issue.parent.id]
        else
          result = check_circular_reference(issue.parent, visited, path.dup)
          return result unless result.empty?
        end
      end

      []
    end

    private

    def validate_hierarchy_structure
      issues_with_invalid_hierarchy = []

      issue_collection.each do |issue|
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
        @validation_result[:valid] = false
        @validation_result[:errors] << {
          type: 'invalid_parent_child',
          count: issues_with_invalid_hierarchy.count,
          message: "不正な親子関係が#{issues_with_invalid_hierarchy.count}件検出されました",
          details: issues_with_invalid_hierarchy
        }
      end
    end

    def detect_circular_references
      visited = Set.new
      circular_issues = []

      issue_collection.each do |issue|
        next if visited.include?(issue.id)

        cycle_path = check_circular_reference(issue, Set.new, [])
        if cycle_path.any?
          circular_issues << {
            issue_id: issue.id,
            issue_subject: issue.subject,
            cycle_path: cycle_path
          }
        end
      end

      if circular_issues.any?
        @validation_result[:valid] = false
        @validation_result[:errors] << {
          type: 'circular_reference',
          count: circular_issues.count,
          message: "循環参照が#{circular_issues.count}件検出されました",
          details: circular_issues
        }
      end
    end

    def validate_hierarchy_depths
      issues_exceeding_depth = []

      issue_collection.each do |issue|
        depth = self.class.calculate_hierarchy_depth(issue)

        if depth > MAX_HIERARCHY_DEPTH
          issues_exceeding_depth << {
            issue_id: issue.id,
            issue_subject: issue.subject,
            current_depth: depth,
            max_depth: MAX_HIERARCHY_DEPTH
          }
        end
      end

      if issues_exceeding_depth.any?
        @validation_result[:valid] = false
        @validation_result[:errors] << {
          type: 'hierarchy_too_deep',
          count: issues_exceeding_depth.count,
          message: "階層深度超過が#{issues_exceeding_depth.count}件検出されました",
          details: issues_exceeding_depth
        }
      end
    end

    def validate_type_constraints
      constraint_violations = []
      tracker_names = Kanban::TrackerHierarchy.tracker_names

      # Epic → Feature制約チェック
      epics_with_non_features = epic_collection.select do |epic|
        epic.children.any? { |child| child.tracker.name != tracker_names[:feature] }
      end

      epics_with_non_features.each do |epic|
        invalid_children = epic.children.reject { |child| child.tracker.name == tracker_names[:feature] }
        constraint_violations << {
          constraint: 'epic_can_only_contain_features',
          issue_id: epic.id,
          issue_subject: epic.subject,
          violation_details: invalid_children.map { |child|
            { id: child.id, subject: child.subject, tracker: child.tracker.name }
          }
        }
      end

      # Feature → UserStory制約チェック
      features_with_non_stories = feature_collection.select do |feature|
        feature.children.any? { |child| child.tracker.name != tracker_names[:user_story] }
      end

      features_with_non_stories.each do |feature|
        invalid_children = feature.children.reject { |child| child.tracker.name == tracker_names[:user_story] }
        constraint_violations << {
          constraint: 'feature_can_only_contain_user_stories',
          issue_id: feature.id,
          issue_subject: feature.subject,
          violation_details: invalid_children.map { |child|
            { id: child.id, subject: child.subject, tracker: child.tracker.name }
          }
        }
      end

      if constraint_violations.any?
        @validation_result[:warnings] << {
          type: 'type_constraint_violations',
          count: constraint_violations.count,
          message: "型制約違反が#{constraint_violations.count}件検出されました",
          details: constraint_violations
        }
      end
    end

    def issue_collection
      @issue_collection ||= case @data
                           when ActiveRecord::Relation
                             @data.includes(:tracker, :parent => :tracker, children: :tracker)
                           when Array
                             @data
                           else
                             [@data].flatten.compact
                           end
    end

    def epic_collection
      @epic_collection ||= begin
        epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
        issue_collection.select { |issue| issue.tracker.name == epic_tracker_name }
      end
    end

    def feature_collection
      @feature_collection ||= begin
        feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
        issue_collection.select { |issue| issue.tracker.name == feature_tracker_name }
      end
    end
  end
end