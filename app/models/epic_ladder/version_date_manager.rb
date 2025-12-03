# frozen_string_literal: true

module EpicLadder
  # バージョン変更時の日付自動設定管理
  # Epic Ladder上でチケットをバージョン間で移動した際に、
  # バージョンの期日に基づいて開始日・終了日を自動設定する
  class VersionDateManager
    # バージョン変更時に影響を受けるissueの数を計算
    #
    # @param issue [Issue] 対象のチケット
    # @param update_parent [Boolean] 親Issueも同時に更新するか
    # @return [Hash] { total: Integer, issue_ids: Array<Integer>, parent_id: Integer|nil, sibling_ids: Array<Integer> }
    #
    # @example
    #   impact = VersionDateManager.calculate_impact(task, update_parent: true)
    #   impact[:total]       # => 5 (task + parent + 3 siblings)
    #   impact[:issue_ids]   # => [116, 114, 117, 118, 119]
    #   impact[:parent_id]   # => 114
    #   impact[:sibling_ids] # => [117, 118, 119]
    def self.calculate_impact(issue, update_parent: false)
      impact = {
        total: 1,
        issue_ids: [issue.id],
        parent_id: nil,
        sibling_ids: []
      }

      if update_parent && issue.parent
        impact[:parent_id] = issue.parent.id
        impact[:issue_ids] << issue.parent.id
        impact[:total] += 1

        # 兄弟issueをカウント
        sibling_ids = issue.parent.children.where.not(id: issue.id).pluck(:id)
        impact[:sibling_ids] = sibling_ids
        impact[:issue_ids].concat(sibling_ids)
        impact[:total] += sibling_ids.size
      end

      impact
    end
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
    # - 開始日 = 新バージョンより期日が早い最も近い（直前の）バージョンの期日
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

      # 開始日 = 新バージョンより早い最も近い（直前の）バージョンの期日
      earlier_version = versions
                          .where('effective_date < ?', new_version.effective_date)
                          .last  # .first から .last に変更（最も近いバージョン）

      start_date = earlier_version&.effective_date || new_version.effective_date

      { start_date: start_date, due_date: due_date }
    end

    # バージョン変更＋日付自動設定を一括実行（共通メソッド）
    #
    # @param issue [Issue] 対象のチケット
    # @param new_version_id [String, Integer, nil] 新しいバージョンID（空文字列の場合はnil扱い）
    # @param update_parent [Boolean] 親Issueも同時に更新するか（デフォルト: false）
    # @return [Hash] { issue: Issue, parent: Issue|nil, siblings: Array<Issue>, dates: Hash|nil, parent_dates: Hash|nil }
    #
    # @example
    #   result = VersionDateManager.change_version_with_dates(task, '2', update_parent: true)
    #   result[:issue]        # 更新されたIssue
    #   result[:parent]       # 更新された親Issue（存在する場合）
    #   result[:siblings]     # 更新された兄弟Issue（update_parent=trueの場合）
    #   result[:dates]        # 計算された日付 { start_date:, due_date: }
    #   result[:parent_dates] # 親の日付（存在する場合）
    #
    # ロジック:
    # 1. Issueのバージョン・開始日・期日を更新
    # 2. update_parent=trueの場合:
    #    - 兄弟Issue（同じ親の子issue）を先に更新
    #    - 親Issueを最後に更新（子の日付更新後に親を更新することで、Redmineの自動計算を考慮）
    # 3. Redmine標準のJournal記録を生成
    def self.change_version_with_dates(issue, new_version_id, update_parent: false)
      new_version_id = nil if new_version_id.blank?
      new_version = new_version_id ? Version.find(new_version_id) : nil

      # 実際に変更があったかを追跡するために changed フラグを追加
      result = {
        issue: issue,
        parent: nil,
        siblings: [],           # 実際に変更があった兄弟のみ
        dates: nil,
        parent_dates: nil,
        issue_changed: false,   # 対象issueが変更されたか
        parent_changed: false   # 親が変更されたか
      }

      ActiveRecord::Base.transaction do
        # Issue本体の日付計算（reloadする前に計算）
        dates = update_dates_for_version_change(issue, new_version)
        result[:dates] = dates

        # lock_versionを最新にするためリロード（init_journalの前に実行）
        issue.reload

        # 変更前のバージョンIDを保存
        original_version_id = issue.fixed_version_id

        # Issue更新
        issue.init_journal(User.current)
        issue.safe_attributes = {
          'fixed_version_id' => new_version_id,
          'start_date' => dates&.dig(:start_date),
          'due_date' => dates&.dig(:due_date)
        }
        issue.save!

        # 実際に変更があったかを記録
        result[:issue_changed] = (original_version_id.to_s != new_version_id.to_s)

        # 親も更新
        if update_parent && issue.parent
          # 兄弟issue（同じ親の子issue）を先に更新
          # （親の日付が子から自動計算される場合を考慮し、子を先に更新）
          siblings = issue.parent.children.where.not(id: issue.id)
          siblings.each do |sibling|
            sibling_dates = update_dates_for_version_change(sibling, new_version)

            sibling.reload

            # 変更前のバージョンIDを保存
            sibling_original_version_id = sibling.fixed_version_id

            sibling.init_journal(User.current)
            sibling.safe_attributes = {
              'fixed_version_id' => new_version_id,
              'start_date' => sibling_dates&.dig(:start_date),
              'due_date' => sibling_dates&.dig(:due_date)
            }
            sibling.save!

            # 実際に変更があった兄弟のみを追加
            if sibling_original_version_id.to_s != new_version_id.to_s
              result[:siblings] << sibling
            end
          end

          # 親を最後に更新
          parent_dates = update_dates_for_version_change(issue.parent, new_version)
          result[:parent_dates] = parent_dates

          issue.parent.reload # 親もリロード（init_journalの前に実行）

          # 変更前のバージョンIDを保存
          parent_original_version_id = issue.parent.fixed_version_id

          issue.parent.init_journal(User.current)
          # 親の日付更新設定を考慮
          # dates_derived? = true の場合、日付は子から自動計算されるため設定しない
          # dates_derived? = false の場合、独立した日付を設定可能
          parent_attributes = { 'fixed_version_id' => new_version_id }
          unless issue.parent.dates_derived?
            parent_attributes['start_date'] = parent_dates&.dig(:start_date)
            parent_attributes['due_date'] = parent_dates&.dig(:due_date)
          end

          issue.parent.safe_attributes = parent_attributes
          issue.parent.save!

          # 実際に変更があった場合のみ parent を設定
          if parent_original_version_id.to_s != new_version_id.to_s
            result[:parent] = issue.parent
            result[:parent_changed] = true
          end
        end
      end

      result
    end
  end
end
