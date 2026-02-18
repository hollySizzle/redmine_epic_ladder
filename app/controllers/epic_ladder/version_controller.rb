# frozen_string_literal: true

module EpicLadder
  # Version変更クイックアクション用コントローラー
  class VersionController < ApplicationController
    before_action :find_issue
    before_action :authorize_update

    # PATCH /epic_ladder/issues/:id/update_version
    def update
      new_version_id = params[:fixed_version_id].presence
      update_parent = params[:update_parent_version] == '1'

      # VersionDateManagerで一括更新（バージョン＋開始日＋期日＋子への伝播）
      result = EpicLadder::VersionDateManager.change_version_with_dates(
        @issue,
        new_version_id,
        update_parent: update_parent,
        propagate_to_children: true
      )

      # フラッシュメッセージの構築
      # 実際に変更があったissueの総数を計算（子を含む）
      total_count = 0
      total_count += 1 if result[:issue_changed]              # 対象issue
      total_count += 1 if result[:parent_changed]             # 親
      total_count += result[:siblings].size                   # 兄弟
      total_count += result[:children].size                   # 子

      # 子の情報（常に追加）
      children_info = if result[:children].any?
                       " " + l(:notice_epic_ladder_children_updated, count: result[:children].size)
                     else
                       ""
                     end

      if result[:parent_update_skipped]
        # 親がFeature/Epicのため更新がスキップされた場合
        if result[:children].any?
          flash[:notice] = l(:notice_epic_ladder_version_updated_with_count, count: total_count) + children_info
        else
          flash[:notice] = l(:notice_epic_ladder_version_updated)
        end
        # 親とバージョンが異なる場合も警告しない（Feature/Epicは別管理が正常）
      elsif update_parent && (result[:parent_changed] || result[:siblings].any?)
        # update_parent=true かつ 親または兄弟に実際の変更があった場合
        sibling_info = if result[:siblings].any?
                        " " + l(:notice_epic_ladder_siblings_updated, count: result[:siblings].size)
                      else
                        ""
                      end

        # 親が変更された場合のみ親情報を表示
        if result[:parent_changed]
          flash[:notice] = l(
            :notice_epic_ladder_version_updated_with_parent,
            issue: "##{@issue.id}",
            parent: "##{result[:parent].id}",
            version: new_version&.name || l(:label_none),
            total: total_count
          ) + sibling_info + children_info
        else
          # 親は変更なし、兄弟のみ変更があった場合
          flash[:notice] = l(:notice_epic_ladder_version_updated) + sibling_info + children_info
        end
      else
        # 親とズレている場合は警告（親がUserStoryの場合のみ）
        if @issue.parent &&
           EpicLadder::VersionDateManager.should_update_parent_and_siblings?(@issue) &&
           @issue.parent.fixed_version_id != new_version_id.to_i
          flash[:warning] = l(
            :warning_epic_ladder_version_mismatch_with_parent,
            parent: "##{@issue.parent.id}",
            parent_version: @issue.parent.fixed_version&.name || l(:label_none)
          )
        else
          if result[:children].any?
            flash[:notice] = l(:notice_epic_ladder_version_updated_with_count, count: total_count) + children_info
          else
            flash[:notice] = l(:notice_epic_ladder_version_updated)
          end
        end
      end

      redirect_to issue_path(@issue)
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = l(:error_epic_ladder_version_update_failed, error: e.message)
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
