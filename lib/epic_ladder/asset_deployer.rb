# frozen_string_literal: true

module EpicLadder
  class AssetDeployer
    class << self
      def deploy_if_needed
        source_dir = Rails.root.join('plugins', 'redmine_epic_ladder', 'assets', 'build')
        dest_dir = Rails.public_path.join('plugin_assets', 'redmine_epic_ladder')

        # ビルド済みファイルが存在しない場合は警告のみ
        unless source_dir.exist?
          Rails.logger.warn "[EpicLadder::AssetDeployer] Build directory not found: #{source_dir}"
          Rails.logger.warn "[EpicLadder::AssetDeployer] Run 'npm run build:prod' to build assets"
          return
        end

        # 配信が必要かチェック
        if needs_deployment?(source_dir, dest_dir)
          deploy(source_dir, dest_dir)
        else
          Rails.logger.debug "[EpicLadder::AssetDeployer] Assets are already up to date"
        end
      end

      private

      def needs_deployment?(source_dir, dest_dir)
        # 配信ディレクトリが存在しない
        return true unless dest_dir.exist?

        # 配信ディレクトリが空
        return true if Dir.glob("#{dest_dir}/*").empty?

        # ソースファイルの方が新しい
        source_mtime = Dir.glob("#{source_dir}/*").map { |f| File.mtime(f) }.max
        dest_mtime = Dir.glob("#{dest_dir}/*").map { |f| File.mtime(f) }.max rescue Time.at(0)

        source_mtime > dest_mtime
      end

      def deploy(source_dir, dest_dir)
        begin
          # 配信ディレクトリを作成
          FileUtils.mkdir_p(dest_dir)

          # 既存ファイルを削除 (古いハッシュファイル対策)
          FileUtils.rm_rf(Dir.glob("#{dest_dir}/*"))

          # ビルド済みファイルをコピー
          FileUtils.cp_r(Dir.glob("#{source_dir}/*"), dest_dir)

          deployed_files = Dir.glob("#{dest_dir}/*")
          total_size = deployed_files.sum { |f| File.size(f) }
          total_size_mb = (total_size / 1024.0 / 1024.0).round(2)

          Rails.logger.info "[EpicLadder::AssetDeployer] ✅ Assets deployed"
          Rails.logger.info "[EpicLadder::AssetDeployer]    Source: #{source_dir}"
          Rails.logger.info "[EpicLadder::AssetDeployer]    Dest:   #{dest_dir}"
          Rails.logger.info "[EpicLadder::AssetDeployer]    Files:  #{deployed_files.size}"
          Rails.logger.info "[EpicLadder::AssetDeployer]    Size:   #{total_size_mb} MB"
        rescue => e
          Rails.logger.error "[EpicLadder::AssetDeployer] ❌ Failed to deploy assets: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end
  end
end
