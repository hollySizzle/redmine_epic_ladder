# frozen_string_literal: true

module EpicLadder
  # Bug/Test/TaskをUserStoryに昇格させる共通ロジック
  # VersionDateManagerと同じアーキテクチャ: MCP/クイックアクション/Reactで共通利用
  #
  # B案: 新US作成+子付け替え型
  # - 新しいUserStoryをFeature配下に作成
  # - 対象issueの親を新USに付け替え
  # - 元の親USと新USをrelates関連で紐づけ
  class IssuePromoter
    # 昇格可能かバリデーション
    # @param issue [Issue] 対象チケット
    # @return [Hash] { valid: Boolean, error: String|nil }
    def self.validate_promotable(issue)
      tracker_names = TrackerHierarchy.tracker_names(issue.project)
      promotable_trackers = [tracker_names[:task], tracker_names[:bug], tracker_names[:test]]

      unless promotable_trackers.include?(issue.tracker.name)
        return { valid: false, error: I18n.t(:error_epic_ladder_promotion_invalid_tracker) }
      end

      parent_us = issue.parent
      unless parent_us && parent_us.tracker.name == tracker_names[:user_story]
        return { valid: false, error: I18n.t(:error_epic_ladder_promotion_no_parent_us) }
      end

      feature = parent_us.parent
      unless feature && feature.tracker.name == tracker_names[:feature]
        return { valid: false, error: I18n.t(:error_epic_ladder_promotion_no_parent_feature) }
      end

      { valid: true, error: nil }
    end

    # Bug/Test/TaskをUserStoryに昇格
    # @param issue [Issue] 対象チケット
    # @param user [User] 実行ユーザー
    # @param target_feature [Issue|nil] 新USの親Feature（省略時は元の親USの親Feature）
    # @param us_subject [String|nil] 新USの件名（省略時は元チケットの件名）
    # @return [Hash] { new_user_story: Issue, original_parent_us: Issue, relation: IssueRelation }
    def self.promote_to_user_story(issue, user:, target_feature: nil, us_subject: nil)
      tracker_names = TrackerHierarchy.tracker_names(issue.project)

      parent_us = issue.parent
      feature = target_feature || parent_us.parent
      subject = us_subject || issue.subject

      us_tracker = Tracker.find_by(name: tracker_names[:user_story])

      ActiveRecord::Base.transaction do
        # 1. Feature配下に新US作成
        new_us = Issue.new(
          project: issue.project,
          tracker: us_tracker,
          subject: subject,
          author: user,
          parent_id: feature.id,
          fixed_version: issue.fixed_version,
          priority: issue.priority,
          start_date: issue.start_date,
          due_date: issue.due_date
        )
        new_us.save!

        # 2. 対象issueの親を新USに付け替え
        issue.parent_id = new_us.id
        issue.save!

        # 3. 元の親USと新USを関連付け（relates）
        relation = IssueRelation.new(
          issue_from: parent_us,
          issue_to: new_us,
          relation_type: 'relates'
        )
        relation.save!

        {
          new_user_story: new_us,
          original_parent_us: parent_us,
          relation: relation
        }
      end
    end
  end
end
