# frozen_string_literal: true

module EpicGrid
  # Version変更クイックアクション用コントローラー
  class VersionController < ApplicationController
    before_action :find_issue
    before_action :authorize_update

    # PATCH /epic_grid/issues/:id/update_version
    def update
      new_version_id = params[:fixed_version_id].presence
      update_parent = params[:update_parent_version] == '1'

      # VersionDateManagerで一括更新（バージョン＋開始日＋期日）
      result = EpicGrid::VersionDateManager.change_version_with_dates(
        @issue,
        new_version_id,
        update_parent: update_parent
      )

      # フラッシュメッセージの構築
      if update_parent && result[:parent]
        flash[:notice] = l(
          :notice_epic_grid_version_updated_with_parent,
          issue: "##{@issue.id}",
          parent: "##{result[:parent].id}",
          version: new_version&.name || l(:label_none)
        )
      else
        # 親とズレている場合は警告
        if @issue.parent && @issue.parent.fixed_version_id != new_version_id.to_i
          flash[:warning] = l(
            :warning_epic_grid_version_mismatch_with_parent,
            parent: "##{@issue.parent.id}",
            parent_version: @issue.parent.fixed_version&.name || l(:label_none)
          )
        else
          flash[:notice] = l(:notice_epic_grid_version_updated)
        end
      end

      redirect_to issue_path(@issue)
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = l(:error_epic_grid_version_update_failed, error: e.message)
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

    def new_version
      return nil if params[:fixed_version_id].blank?

      @new_version ||= Version.find_by(id: params[:fixed_version_id])
    end
  end
end
