# frozen_string_literal: true

# Epic Grid Plugin Initializer
#
# このinitializerはRails起動時に以下を実行します:
# 1. assets/build/ から public/plugin_assets/ へビルド済みファイルを自動配信
# 2. npm環境不要でプラグインをGitから直接インストール可能にする

Rails.application.config.after_initialize do
  next unless defined?(RedmineEpicGrid)

  source_dir = Rails.root.join('plugins', 'redmine_epic_grid', 'assets', 'build')
  dest_dir = Rails.public_path.join('plugin_assets', 'redmine_epic_grid')

  # ビルド済みファイルが存在する場合のみ配信
  if source_dir.exist?
    begin
      # 配信ディレクトリを作成
      FileUtils.mkdir_p(dest_dir)

      # 既存ファイルを削除してから新規コピー (クリーンデプロイ)
      # 古いハッシュファイルが残るのを防ぐ
      FileUtils.rm_rf(Dir.glob("#{dest_dir}/*"))

      # ビルド済みファイルをコピー
      FileUtils.cp_r(Dir.glob("#{source_dir}/*"), dest_dir)

      deployed_files = Dir.glob("#{dest_dir}/*").size
      Rails.logger.info "[EpicGrid] Assets deployed: #{deployed_files} files from #{source_dir} to #{dest_dir}"
    rescue => e
      Rails.logger.error "[EpicGrid] Failed to deploy assets: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  else
    Rails.logger.warn "[EpicGrid] Build directory not found: #{source_dir}"
    Rails.logger.warn "[EpicGrid] Run 'npm run build:prod' in plugin directory to build assets"
  end
end
