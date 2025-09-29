# frozen_string_literal: true

module Kanban
  # Version整合性チェッカー
  # 階層間でのVersion継承・一貫性を検証
  class VersionConsistencyChecker
    class VersionMismatchError < StandardError; end
    class VersionInheritanceError < StandardError; end

    def self.check_consistency(hierarchy)
      new(hierarchy).check_consistency
    end

    def self.validate_version_inheritance(child_issue, parent_issue)
      new([child_issue, parent_issue]).validate_version_inheritance(child_issue, parent_issue)
    end

    def initialize(hierarchy)
      @hierarchy = hierarchy
      @consistency_report = {
        consistent: true,
        inconsistencies: [],
        statistics: {
          total_issues: 0,
          version_assigned_count: 0,
          inheritance_violations: 0,
          mismatch_violations: 0
        }
      }
    end

    def check_consistency
      begin
        # 1. Epic → Feature Version整合性チェック
        check_epic_feature_consistency

        # 2. Feature → UserStory Version整合性チェック
        check_feature_user_story_consistency

        # 3. UserStory → 子要素 Version整合性チェック
        check_user_story_child_consistency

        # 4. 統計情報更新
        update_statistics

        {
          success: true,
          data: @consistency_report
        }
      rescue => e
        Rails.logger.error "VersionConsistencyChecker error: #{e.message}"
        {
          success: false,
          error: e.message,
          error_code: 'VERSION_CONSISTENCY_ERROR'
        }
      end
    end

    def validate_version_inheritance(child_issue, parent_issue)
      return { valid: true, consistent: true } unless parent_issue&.fixed_version_id

      if child_issue.fixed_version_id.nil?
        {
          valid: false,
          consistent: false,
          error: 'version_missing',
          message: '親IssueのVersionが子Issueに継承されていません',
          parent_version: {
            id: parent_issue.fixed_version_id,
            name: parent_issue.fixed_version&.name
          },
          child_version: nil,
          recommendation: 'Version自動伝播を実行してください'
        }
      elsif child_issue.fixed_version_id != parent_issue.fixed_version_id
        {
          valid: false,
          consistent: false,
          error: 'version_mismatch',
          message: '子IssueのVersionが親Issueと異なります',
          parent_version: {
            id: parent_issue.fixed_version_id,
            name: parent_issue.fixed_version&.name
          },
          child_version: {
            id: child_issue.fixed_version_id,
            name: child_issue.fixed_version&.name
          },
          recommendation: 'Version整合性を修正してください'
        }
      else
        {
          valid: true,
          consistent: true,
          message: 'Version継承は正常です'
        }
      end
    end

    private

    def check_epic_feature_consistency
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]

      epic_collection.each do |epic|
        next unless epic.fixed_version_id

        epic.children.each do |feature|
          next unless feature.tracker.name == feature_tracker_name

          inheritance_result = validate_version_inheritance(feature, epic)

          unless inheritance_result[:consistent]
            add_inconsistency(
              type: inheritance_result[:error],
              parent_type: 'Epic',
              parent_id: epic.id,
              parent_subject: epic.subject,
              parent_version: inheritance_result[:parent_version],
              child_type: 'Feature',
              child_id: feature.id,
              child_subject: feature.subject,
              child_version: inheritance_result[:child_version],
              message: inheritance_result[:message],
              recommendation: inheritance_result[:recommendation]
            )
          end
        end
      end
    end

    def check_feature_user_story_consistency
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]

      feature_collection.each do |feature|
        # Featureに直接Versionが割り当てられているか、親EpicからVersion継承しているかチェック
        effective_version_id = feature.fixed_version_id || feature.parent&.fixed_version_id
        next unless effective_version_id

        feature.children.each do |user_story|
          next unless user_story.tracker.name == user_story_tracker_name

          # UserStoryのVersionが有効なVersionと一致するかチェック
          if user_story.fixed_version_id != effective_version_id
            version = Version.find_by(id: effective_version_id)
            add_inconsistency(
              type: 'version_mismatch',
              parent_type: 'Feature',
              parent_id: feature.id,
              parent_subject: feature.subject,
              parent_version: { id: effective_version_id, name: version&.name },
              child_type: 'UserStory',
              child_id: user_story.id,
              child_subject: user_story.subject,
              child_version: user_story.fixed_version_id ?
                { id: user_story.fixed_version_id, name: user_story.fixed_version&.name } : nil,
              message: 'UserStoryのVersionがFeatureの有効なVersionと異なります',
              recommendation: 'Version伝播サービスを実行してください'
            )
          end
        end
      end
    end

    def check_user_story_child_consistency
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      child_tracker_names = [tracker_names[:task], tracker_names[:test], tracker_names[:bug]]

      user_story_collection.each do |user_story|
        next unless user_story.fixed_version_id

        user_story.children.each do |child|
          next unless child_tracker_names.include?(child.tracker.name)

          inheritance_result = validate_version_inheritance(child, user_story)

          unless inheritance_result[:consistent]
            add_inconsistency(
              type: inheritance_result[:error],
              parent_type: 'UserStory',
              parent_id: user_story.id,
              parent_subject: user_story.subject,
              parent_version: inheritance_result[:parent_version],
              child_type: child.tracker.name,
              child_id: child.id,
              child_subject: child.subject,
              child_version: inheritance_result[:child_version],
              message: inheritance_result[:message],
              recommendation: inheritance_result[:recommendation]
            )
          end
        end
      end
    end

    def update_statistics
      total_issues = issue_collection.count
      version_assigned_count = issue_collection.count { |issue| issue.fixed_version_id.present? }

      @consistency_report[:statistics].merge!(
        total_issues: total_issues,
        version_assigned_count: version_assigned_count,
        inheritance_violations: @consistency_report[:inconsistencies].count { |inc| inc[:type] == 'version_missing' },
        mismatch_violations: @consistency_report[:inconsistencies].count { |inc| inc[:type] == 'version_mismatch' }
      )

      @consistency_report[:consistent] = @consistency_report[:inconsistencies].empty?
    end

    def add_inconsistency(inconsistency_data)
      @consistency_report[:inconsistencies] << inconsistency_data
      @consistency_report[:consistent] = false
    end

    def issue_collection
      @issue_collection ||= case @hierarchy
                           when ActiveRecord::Relation
                             @hierarchy.includes(:tracker, :fixed_version, :parent => :fixed_version, children: [:tracker, :fixed_version])
                           when Array
                             @hierarchy
                           else
                             [@hierarchy].flatten.compact
                           end
    end

    def epic_collection
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      @epic_collection ||= issue_collection.select { |issue| issue.tracker.name == epic_tracker_name }
    end

    def feature_collection
      feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
      @feature_collection ||= issue_collection.select { |issue| issue.tracker.name == feature_tracker_name }
    end

    def user_story_collection
      user_story_tracker_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
      @user_story_collection ||= issue_collection.select { |issue| issue.tracker.name == user_story_tracker_name }
    end

    # 自動修復機能（オプション）
    def self.auto_fix_inconsistencies(project, options = {})
      consistency_result = check_consistency(
        project.issues
               .joins(:tracker)
               .where(trackers: { name: Kanban::TrackerHierarchy.configured_tracker_names })
               .includes(:tracker, :fixed_version, :parent => :fixed_version, children: [:tracker, :fixed_version])
      )

      return { success: true, fixed_count: 0 } if consistency_result[:data][:consistent]

      fixed_count = 0

      consistency_result[:data][:inconsistencies].each do |inconsistency|
        if inconsistency[:type] == 'version_missing' && options[:auto_fix_missing]
          child = Issue.find_by(id: inconsistency[:child_id])
          parent = Issue.find_by(id: inconsistency[:parent_id])

          if child && parent && parent.fixed_version_id
            child.update!(fixed_version_id: parent.fixed_version_id)
            fixed_count += 1
            Rails.logger.info "Version自動修復: Issue##{child.id} → Version##{parent.fixed_version_id}"
          end
        end
      end

      {
        success: true,
        fixed_count: fixed_count,
        message: "#{fixed_count}件のVersion不整合を自動修復しました"
      }
    rescue => e
      Rails.logger.error "Version自動修復エラー: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'VERSION_AUTO_FIX_ERROR'
      }
    end

    # Version変更影響分析
    def self.analyze_version_change_impact(issue, new_version)
      impact_analysis = {
        affected_issues: [],
        propagation_required: false,
        risk_level: 'low',
        recommendations: []
      }

      # 子要素への影響分析
      affected_children = collect_all_children(issue)

      if affected_children.any?
        impact_analysis[:affected_issues] = affected_children.map do |child|
          {
            id: child.id,
            subject: child.subject,
            tracker: child.tracker.name,
            current_version_id: child.fixed_version_id,
            current_version_name: child.fixed_version&.name
          }
        end

        impact_analysis[:propagation_required] = true
        impact_analysis[:risk_level] = affected_children.count > 20 ? 'high' : 'medium'

        impact_analysis[:recommendations] << '子要素へのVersion伝播を実行してください'
        impact_analysis[:recommendations] << '影響範囲を確認してから実行することを推奨します' if impact_analysis[:risk_level] == 'high'
      end

      # 依存関係への影響分析
      blocked_issues = find_blocked_issues(issue)
      if blocked_issues.any?
        impact_analysis[:risk_level] = 'high'
        impact_analysis[:recommendations] << 'ブロックされているIssueのVersion整合性を確認してください'
      end

      {
        success: true,
        data: impact_analysis
      }
    rescue => e
      Rails.logger.error "Version変更影響分析エラー: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'VERSION_IMPACT_ANALYSIS_ERROR'
      }
    end

    def self.collect_all_children(issue, collected = [])
      issue.children.each do |child|
        collected << child
        collect_all_children(child, collected)
      end
      collected
    end

    def self.find_blocked_issues(issue)
      # issueがblockしているIssue一覧
      IssueRelation.where(issue_from_id: issue.id, relation_type: 'blocks')
                   .joins(:issue_to)
                   .includes(:issue_to)
                   .map(&:issue_to)
    end
  end
end