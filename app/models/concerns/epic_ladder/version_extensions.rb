# frozen_string_literal: true

module EpicLadder
  # Version モデル拡張
  # Ransack検索対応: バージョン期日フィルタ用
  module VersionExtensions
    extend ActiveSupport::Concern

    class_methods do
      # Ransackで検索可能な属性を定義
      # @param _auth_object [Object] 認証オブジェクト（未使用）
      # @return [Array<String>] 検索可能な属性名の配列
      def ransackable_attributes(_auth_object = nil)
        %w[
          id
          name
          description
          effective_date
          status
          created_on
          updated_on
        ]
      end

      # Ransackで検索可能な関連を定義
      # @param _auth_object [Object] 認証オブジェクト（未使用）
      # @return [Array<String>] 検索可能な関連名の配列
      def ransackable_associations(_auth_object = nil)
        %w[
          project
        ]
      end
    end
  end
end
