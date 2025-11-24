# frozen_string_literal: true

namespace :mcp do
  desc "Generate MCP Tools documentation (Markdown + JSON)"
  task generate_docs: :environment do
    require_relative '../epic_grid/mcp_tools/documentation_generator'

    generator = EpicGrid::McpTools::DocumentationGenerator.new
    plugin_root = File.expand_path('../..', __dir__)

    # 出力先パス
    markdown_path = File.join(plugin_root, 'vibes/docs/specs/mcp_tools_reference.md')
    json_path = File.join(plugin_root, '.mcp-tools-manifest.json')

    # ディレクトリが存在しない場合は作成
    FileUtils.mkdir_p(File.dirname(markdown_path))

    # ドキュメント生成
    puts "🔍 Scanning MCP Tools..."
    generator.generate_markdown(output_path: markdown_path)
    generator.generate_json(output_path: json_path)

    puts "\n✅ Documentation generated successfully!"
    puts "   Markdown: #{markdown_path}"
    puts "   JSON: #{json_path}"
  end

  desc "List all MCP Tools"
  task list: :environment do
    require_relative '../epic_grid/mcp_tools/registry'

    puts "📋 MCP Tools (#{EpicGrid::McpTools::Registry.count} total)"
    puts "=" * 60

    EpicGrid::McpTools::Registry.all_tools.each_with_index do |tool, index|
      puts "#{index + 1}. #{tool.name.demodulize}"
    end
  end

  desc "Validate MCP Tools manifest"
  task validate: :environment do
    require_relative '../epic_grid/mcp_tools/registry'
    require 'json'

    plugin_root = File.expand_path('../..', __dir__)
    json_path = File.join(plugin_root, '.mcp-tools-manifest.json')

    unless File.exist?(json_path)
      puts "❌ Manifest not found: #{json_path}"
      puts "   Run 'rake mcp:generate_docs' first."
      exit 1
    end

    # JSONパース確認
    begin
      manifest = JSON.parse(File.read(json_path))
      puts "✅ Manifest is valid JSON"
      puts "   Version: #{manifest['version']}"
      puts "   Generated at: #{manifest['generated_at']}"
      puts "   Tools: #{manifest['tools'].size}"

      # Registryとの整合性チェック
      registry_count = EpicGrid::McpTools::Registry.count
      manifest_count = manifest['tools'].size

      if registry_count == manifest_count
        puts "\n✅ Manifest is in sync with Registry (#{registry_count} tools)"
      else
        puts "\n⚠️  Manifest out of sync!"
        puts "   Registry: #{registry_count} tools"
        puts "   Manifest: #{manifest_count} tools"
        puts "   Run 'rake mcp:generate_docs' to update."
        exit 1
      end
    rescue JSON::ParserError => e
      puts "❌ Invalid JSON: #{e.message}"
      exit 1
    end
  end
end
