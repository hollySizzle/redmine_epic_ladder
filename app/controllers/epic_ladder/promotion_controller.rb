# frozen_string_literal: true

module EpicLadder
  # UserStoryへの昇格クイックアクション用コントローラー
  # ビジネスロジックはIssuePromoterに委譲（Fat Model, Skinny Controller）
  class PromotionController < ApplicationController
    before_action :find_issue
    before_action :authorize_update

    # PATCH /epic_ladder/issues/:id/promote_to_user_story
    def promote_to_user_story
      # バリデーション
      validation = IssuePromoter.validate_promotable(@issue)
      unless validation[:valid]
        flash[:error] = validation[:error]
        return redirect_to issue_path(@issue)
      end

      # IssuePromoterに委譲
      result = IssuePromoter.promote_to_user_story(@issue, user: User.current)

      flash[:notice] = l(:notice_epic_ladder_promoted_to_user_story)
      redirect_to issue_path(result[:new_user_story])
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
