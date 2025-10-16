# frozen_string_literal: true

module EpicGrid
  # バージョン変更時の日付自動設定管理
  # Epic Grid上でチケットをバージョン間で移動した際に、
  # バージョンの期日に基づいて開始日・終了日を自動設定する
  class VersionDateManager
    # バージョン変更時に開始日・終了日を自動計算
    #
    # @param issue [Issue] 対象のチケット
    # @param new_version [Version] 新しく割り当てられるバージョン
    # @return [Hash, nil] { start_date: Date, due_date: Date } または nil
    #
    # @example
    #   dates = VersionDateManager.update_dates_for_version_change(issue, version)
    #   issue.start_date = dates[:start_date]
    #   issue.due_date = dates[:due_date]
    #
    # ロジック:
    # - 終了日 = 新バージョンの期日
    # - 開始日 = 新バージョンより期日が早い最も早いバージョンの期日
    #           該当なしの場合は新バージョンの期日
    def self.update_dates_for_version_change(issue, new_version)
      return nil unless new_version
      return nil unless new_version.effective_date

      project = issue.project

      # プロジェクト内の期日が設定されている全バージョンを期日順に取得
      versions = project.versions
                        .where.not(effective_date: nil)
                        .order(:effective_date)

      # 終了日 = 新バージョンの期日
      due_date = new_version.effective_date

      # 開始日 = 新バージョンより早い最も早いバージョンの期日
      earlier_version = versions
                          .where('effective_date < ?', new_version.effective_date)
                          .first

      start_date = earlier_version&.effective_date || new_version.effective_date

      { start_date: start_date, due_date: due_date }
    end
  end
end
