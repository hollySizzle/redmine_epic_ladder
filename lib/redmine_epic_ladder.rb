# frozen_string_literal: true

# Redmine Epic Grid プラグイン初期化
# Concern の確実なロードを保証

module RedmineEpicLadder
  class << self
    def setup
      # Concern ファイルをrequire
      require_relative '../app/models/concerns/epic_ladder/issue_extensions'
      require_relative '../app/models/concerns/epic_ladder/project_extensions'

      # Redmine コアモデルにinclude
      Issue.include(EpicLadder::IssueExtensions) unless Issue.included_modules.include?(EpicLadder::IssueExtensions)
      Project.include(EpicLadder::ProjectExtensions) unless Project.included_modules.include?(EpicLadder::ProjectExtensions)

      Rails.logger.info '[EpicLadder] ✅ Model extensions loaded successfully'
    end
  end
end

# Railsアプリケーション起動時に実行
Rails.application.config.to_prepare do
  RedmineEpicLadder.setup
end
