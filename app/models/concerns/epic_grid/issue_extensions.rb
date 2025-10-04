# frozen_string_literal: true

module EpicGrid
  module IssueExtensions
    extend ActiveSupport::Concern

    # ========================================
    # Feature移動 + Version伝播
    # ========================================

    # Feature を別の Epic とバージョンに移動
    # @param target_epic_id [Integer] 移動先のEpic ID
    # @param target_version_id [Integer, nil] 移動先のバージョンID
    def epic_grid_move_to_cell(target_epic_id, target_version_id)
      transaction do
        # 親とバージョンを更新
        self.parent_issue_id = target_epic_id
        self.fixed_version_id = target_version_id
        save!

        # 子要素にバージョンを伝播
        epic_grid_propagate_version_to_children(target_version_id)
      end
    end

    # 子孫全てにバージョンを伝播
    # @param version_id [Integer, nil] 伝播するバージョンID
    def epic_grid_propagate_version_to_children(version_id = nil)
      target_version_id = version_id || self.fixed_version_id

      descendants.find_each do |descendant|
        descendant.reload
        descendant.update!(fixed_version_id: target_version_id)
      end
    end

    # ========================================
    # MSW準拠のJSON出力
    # ========================================

    # 正規化されたJSON形式で出力
    # @return [Hash] MSW NormalizedAPIResponse準拠のHash
    def epic_grid_as_normalized_json
      {
        id: id.to_s,
        subject: subject,
        description: description,
        status: status.is_closed? ? 'closed' : 'open',
        fixed_version_id: fixed_version_id&.to_s,
        tracker_id: tracker_id,
        feature_ids: children.pluck(:id).map(&:to_s),
        created_on: created_on.iso8601,
        updated_on: updated_on.iso8601
      }
    end
  end
end
