# frozen_string_literal: true

module Kanban
  # バージョン伝播サービス
  # UserStoryへのバージョン割当と子Task/Testへの自動伝播機能
  class VersionPropagationService
    # UserStoryから子要素へバージョンを伝播
    def self.propagate_to_children(user_story, version, options = {})
      return { error: 'UserStoryではありません' } unless user_story.tracker.name == 'UserStory'

      children = user_story.children.joins(:tracker)
                           .where(trackers: { name: ['Task', 'Test', 'Bug'] })
      propagation_mode = options[:mode] || :force_overwrite

      ActiveRecord::Base.transaction do
        children.each do |child|
          next if propagation_mode == :preserve_existing && child.fixed_version_id.present?

          child.update!(
            fixed_version_id: version&.id,
            updated_on: Time.current
          )

          log_propagation(user_story, child, version)
        end
      end

      { propagated_count: children.count, affected_issues: children.pluck(:id) }
    rescue => e
      { error: e.message }
    end

    # UserStoryの子要素からバージョンを削除
    def self.remove_version_from_children(user_story)
      children = user_story.children.joins(:tracker)
                           .where(trackers: { name: ['Task', 'Test', 'Bug'] })

      ActiveRecord::Base.transaction do
        children.update_all(
          fixed_version_id: nil,
          updated_on: Time.current.to_s(:db)
        )
      end

      { removed_count: children.count }
    rescue => e
      { error: e.message }
    end

    private

    def self.log_propagation(parent, child, version)
      Rails.logger.info(
        "Version propagated: UserStory##{parent.id} -> #{child.tracker.name}##{child.id}, " \
        "Version: #{version&.name || 'None'}"
      )
    end
  end
end