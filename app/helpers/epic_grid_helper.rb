# app/helpers/epic_grid_helper.rb
module EpicGridHelper
  # asset-manifest.jsonからハッシュ付きファイル名を取得
  def epic_grid_asset_path(asset_name)
    manifest_path = File.join(Rails.public_path, 'plugin_assets', 'redmine_epic_grid', 'asset-manifest.json')

    # manifest.jsonが存在しない場合はフォールバック（開発環境など）
    unless File.exist?(manifest_path)
      return "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_epic_grid/#{asset_name}"
    end

    begin
      manifest = JSON.parse(File.read(manifest_path))
      hashed_name = manifest[asset_name]

      if hashed_name
        # publicPathがすでに含まれている場合はそのまま、含まれていない場合は追加
        if hashed_name.start_with?('/plugin_assets/redmine_epic_grid/')
          "#{Redmine::Utils.relative_url_root}#{hashed_name}"
        else
          "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_epic_grid/#{hashed_name}"
        end
      else
        # manifestに含まれていない場合はフォールバック
        "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_epic_grid/#{asset_name}"
      end
    rescue JSON::ParserError, Errno::ENOENT => e
      Rails.logger.warn "[EpicGrid] Failed to load asset manifest: #{e.message}"
      "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_epic_grid/#{asset_name}"
    end
  end
end
