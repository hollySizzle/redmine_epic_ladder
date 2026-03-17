# frozen_string_literal: true

class AddInquiryFeatureIdToProjectSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :epic_ladder_project_settings, :inquiry_feature_id, :integer, null: true
  end
end
