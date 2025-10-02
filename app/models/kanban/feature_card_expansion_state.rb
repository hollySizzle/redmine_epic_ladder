# app/models/kanban/feature_card_expansion_state.rb
# 設計仕様書準拠: @vibes/docs/logics/feature_card/feature_card_server_specification.md

module Kanban
  class FeatureCardExpansionState < ActiveRecord::Base
    self.table_name = 'feature_card_expansion_states'

    belongs_to :user, class_name: 'User'
    belongs_to :user_story, class_name: 'Issue', foreign_key: 'user_story_id'

    validates :user_id, presence: true
    validates :user_story_id, presence: true
    validates :expanded, inclusion: { in: [true, false] }
    validates :user_id, uniqueness: { scope: :user_story_id }

    # ユーザー別展開状態の取得・更新
    scope :for_user, ->(user) { where(user_id: user.id) }
    scope :expanded, -> { where(expanded: true) }
    scope :collapsed, -> { where(expanded: false) }

    class << self
      # ユーザーの展開状態をMap形式で取得
      def expansion_states_for_user(user)
        for_user(user).pluck(:user_story_id, :expanded).to_h
      end

      # 展開状態を一括更新
      def bulk_update_states(user, expansion_data)
        transaction do
          expansion_data.each do |user_story_id, expanded|
            find_or_initialize_by(user: user, user_story_id: user_story_id)
              .update!(expanded: expanded)
          end
        end
      end

      # 単一展開状態の切替
      def toggle_expansion(user, user_story_id)
        state = find_or_initialize_by(user: user, user_story_id: user_story_id)
        state.expanded = !state.expanded
        state.save!
        state.expanded
      end

      # 古い状態のクリーンアップ（定期実行用）
      def cleanup_old_states(days_ago = 30)
        where('updated_at < ?', days_ago.days.ago).delete_all
      end
    end

    # 展開状態の切替
    def toggle!
      update!(expanded: !expanded)
      expanded
    end

    # ログ用の表示
    def to_s
      "FeatureCardExpansionState(user: #{user.name}, user_story: #{user_story_id}, expanded: #{expanded})"
    end
  end
end