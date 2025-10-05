# frozen_string_literal: true

# Redmine Epic Grid プラグイン初期化
# Concern の確実なロードを保証

module RedmineEpicGrid
  class << self
    def setup
      # Concern ファイルをrequire
      require_relative '../app/models/concerns/epic_grid/issue_extensions'
      require_relative '../app/models/concerns/epic_grid/project_extensions'

      # Redmine コアモデルにinclude
      Issue.include(EpicGrid::IssueExtensions) unless Issue.included_modules.include?(EpicGrid::IssueExtensions)
      Project.include(EpicGrid::ProjectExtensions) unless Project.included_modules.include?(EpicGrid::ProjectExtensions)

      Rails.logger.info '[EpicGrid] ✅ Model extensions loaded successfully'
    end
  end
end

# Railsアプリケーション起動時に実行
Rails.application.config.to_prepare do
  RedmineEpicGrid.setup
end
