# frozen_string_literal: true

module EpicLadder
  # UserStoryへの昇格クイックアクション用コントローラー
  class PromotionController < ApplicationController
    before_action :find_issue
    before_action :authorize_update

    # PATCH /epic_ladder/issues/:id/promote_to_user_story
    def promote_to_user_story
      tracker_names = EpicLadder::TrackerHierarchy.tracker_names(@project)
      promotable_trackers = [tracker_names[:task], tracker_names[:bug], tracker_names[:test]]

      # 対象トラッカーの検証
      unless promotable_trackers.include?(@issue.tracker.name)
        flash[:error] = l(:error_epic_ladder_promotion_invalid_tracker)
        return redirect_to issue_path(@issue)
      end

      # 親UserStoryの検証
      parent_us = @issue.parent
      unless parent_us && parent_us.tracker.name == tracker_names[:user_story]
        flash[:error] = l(:error_epic_ladder_promotion_no_parent_us)
        return redirect_to issue_path(@issue)
      end

      # 親Featureの検証
      feature = parent_us.parent
      unless feature && feature.tracker.name == tracker_names[:feature]
        flash[:error] = l(:error_epic_ladder_promotion_no_parent_feature)
        return redirect_to issue_path(@issue)
      end

      # トラッカーをUserStoryに変更
      us_tracker = Tracker.find_by(name: tracker_names[:user_story])
      @issue.tracker = us_tracker

      # 親をFeature直下に付け替え
      @issue.parent_id = feature.id

      @issue.save!

      flash[:notice] = l(:notice_epic_ladder_promoted_to_user_story)
      redirect_to issue_path(@issue)
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = l(:error_epic_ladder_promotion_failed, error: e.message)
      redirect_to issue_path(@issue)
    end

    private

    def find_issue
      @issue = Issue.find(params[:id])
      @project = @issue.project
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_update
      unless User.current.allowed_to?(:edit_issues, @project)
        render_403
      end
    end
  end
end
