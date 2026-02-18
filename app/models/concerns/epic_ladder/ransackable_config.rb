# frozen_string_literal: true

module EpicLadder
  # Ransack設定モジュール
  # Ransack 4.x のセキュリティ要件に対応し、検索可能な属性と関連を明示的に定義
  module RansackableConfig
    extend ActiveSupport::Concern

    class_methods do
      # 検索可能な属性のホワイトリスト
      # @return [Array<String>] 検索可能な属性名の配列
      def ransackable_attributes(_auth_object = nil)
        %w[
          id
          subject
          description
          status_id
          tracker_id
          assigned_to_id
          fixed_version_id
          parent_id
          priority_id
          estimated_hours
          done_ratio
          start_date
          due_date
          created_on
          updated_on
        ]
      end

      # 検索可能な関連のホワイトリスト
      # @return [Array<String>] 検索可能な関連名の配列
      def ransackable_associations(_auth_object = nil)
        %w[
          tracker
          status
          assigned_to
          fixed_version
          parent
          children
          project
        ]
      end

      # ソート可能な属性のホワイトリスト
      # @return [Array<String>] ソート可能な属性名の配列
      def ransortable_attributes(_auth_object = nil)
        %w[
          id
          subject
          status_id
          tracker_id
          assigned_to_id
          fixed_version_id
          priority_id
          start_date
          due_date
          created_on
          updated_on
        ]
      end
    end
  end
end
