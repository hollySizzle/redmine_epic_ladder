# frozen_string_literal: true

namespace :redmine_epic_ladder do
  desc 'Build frontend assets (requires npm)'
  task :build do
    plugin_dir = 'plugins/redmine_epic_ladder'

    # npm環境チェック
    unless system('which npm > /dev/null 2>&1')
      puts "⚠️  npm not found in PATH"
      puts "   This task requires npm to build frontend assets."
      puts "   If you cloned this plugin from Git, pre-built assets should already be included."
      puts "   In that case, you can skip this task and just restart Rails."
      exit 1
    end

    puts "Building frontend assets..."
    Dir.chdir(plugin_dir) do
      if system('npm run build:prod')
        puts "✅ Build completed successfully"
        puts "   Output: #{plugin_dir}/assets/build/"
      else
        puts "❌ Build failed"
        exit 1
      end
    end
  end

  desc 'Deploy assets to public directory'
  task :deploy do
    source = Rails.root.join('plugins', 'redmine_epic_ladder', 'assets', 'build')
    dest = Rails.public_path.join('plugin_assets', 'redmine_epic_ladder')

    unless Dir.exist?(source)
      puts "❌ Build directory not found: #{source}"
      puts "   Run 'rake redmine_epic_ladder:build' first (requires npm)"
      puts "   Or clone the plugin with pre-built assets included."
      exit 1
    end

    puts "Deploying assets from #{source} to #{dest}..."
    FileUtils.mkdir_p(dest)

    # 古いファイルを削除
    FileUtils.rm_rf(Dir.glob("#{dest}/*"))

    # 新しいファイルをコピー
    FileUtils.cp_r(Dir.glob("#{source}/*"), dest)

    deployed_count = Dir.glob("#{dest}/*").size
    puts "✅ Deployed #{deployed_count} files"

    # 配信されたファイル一覧を表示
    puts "\nDeployed files:"
    Dir.glob("#{dest}/*").sort.each do |file|
      size = File.size(file)
      size_kb = (size / 1024.0).round(1)
      puts "  - #{File.basename(file)} (#{size_kb} KB)"
    end
  end

  desc 'Build and deploy assets in one step'
  task :assets => [:build, :deploy]

  desc 'Show asset deployment status'
  task :status do
    source = Rails.root.join('plugins', 'redmine_epic_ladder', 'assets', 'build')
    dest = Rails.public_path.join('plugin_assets', 'redmine_epic_ladder')

    puts "=== Epic Grid Asset Status ==="
    puts ""
    puts "Source directory (Git-managed):"
    puts "  Path: #{source}"
    if Dir.exist?(source)
      files = Dir.glob("#{source}/*")
      puts "  Status: ✅ Exists (#{files.size} files)"
      files.sort.each do |file|
        mtime = File.mtime(file).strftime('%Y-%m-%d %H:%M:%S')
        size_kb = (File.size(file) / 1024.0).round(1)
        puts "    - #{File.basename(file)} (#{size_kb} KB, modified: #{mtime})"
      end
    else
      puts "  Status: ❌ Not found"
    end

    puts ""
    puts "Deployment directory (Redmine public):"
    puts "  Path: #{dest}"
    if Dir.exist?(dest)
      files = Dir.glob("#{dest}/*")
      puts "  Status: ✅ Exists (#{files.size} files)"
      files.sort.each do |file|
        mtime = File.mtime(file).strftime('%Y-%m-%d %H:%M:%S')
        size_kb = (File.size(file) / 1024.0).round(1)
        puts "    - #{File.basename(file)} (#{size_kb} KB, modified: #{mtime})"
      end
    else
      puts "  Status: ❌ Not found"
    end

    puts ""
    puts "Recommendations:"
    if !Dir.exist?(source)
      puts "  ⚠️  Run 'rake redmine_epic_ladder:build' to create assets (requires npm)"
    elsif !Dir.exist?(dest)
      puts "  ⚠️  Run 'rake redmine_epic_ladder:deploy' to deploy assets"
      puts "      Or restart Rails server (automatic deployment)"
    else
      source_mtime = Dir.glob("#{source}/*").map { |f| File.mtime(f) }.max
      dest_mtime = Dir.glob("#{dest}/*").map { |f| File.mtime(f) }.max rescue nil

      if dest_mtime && source_mtime > dest_mtime
        puts "  ⚠️  Source is newer than deployment"
        puts "      Run 'rake redmine_epic_ladder:deploy' or restart Rails"
      else
        puts "  ✅ Assets are up to date"
      end
    end
  end
end
