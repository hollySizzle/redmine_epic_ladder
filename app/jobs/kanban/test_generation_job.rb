# frozen_string_literal: true

module Kanban
  # Test生成バックグラウンドJob
  # UserStory作成時のTest自動生成を非同期処理
  class TestGenerationJob < ApplicationJob
    queue_as :kanban_auto_generation

    def perform(user_story)
      result = TestGenerationService.generate_test_for_user_story(user_story)

      if result[:error]
        Rails.logger.error "Test生成Job失敗: UserStory##{user_story.id} - #{result[:error]}"
      else
        Rails.logger.info "Test生成Job完了: UserStory##{user_story.id} -> Test##{result[:test_issue]&.id}"
      end
    rescue => e
      Rails.logger.error "Test生成Job例外: UserStory##{user_story.id} - #{e.message}"
      raise e
    end
  end
end