# frozen_string_literal: true

begin
  require 'yard'
rescue LoadError
  # YARDがない場合（本番環境など）はスキップ
  Rails.logger.warn('[DocumentationGenerator] YARD gem not available - skipping documentation features') if defined?(Rails)
end
require 'json'

module EpicGrid
  module McpTools
    # MCP Tools Documentation Generator
    # Ruby DSL/YARDコメントをパースしてドキュメントを自動生成する
    #
    # @example
    #   generator = DocumentationGenerator.new
    #   generator.generate_markdown(output_path: 'docs/mcp_tools_reference.md')
    #   generator.generate_json(output_path: '.mcp-tools-manifest.json')
    class DocumentationGenerator
      attr_reader :tools_dir

      def initialize(tools_dir: nil)
        @tools_dir = tools_dir || File.expand_path('../mcp_tools', __dir__)
      end

      # 全ツールファイルをスキャン
      def scan_tools
        tool_files = Dir.glob(File.join(@tools_dir, '*_tool.rb'))
        tool_files.map { |file| parse_tool_file(file) }.compact
      end

      # 単一ツールファイルをパース
      def parse_tool_file(file_path)
        unless defined?(YARD)
          Rails.logger.warn('[DocumentationGenerator] YARD not available - cannot parse tools') if defined?(Rails)
          return nil
        end

        YARD.parse(file_path)

        # ファイル名からクラス名を推測
        basename = File.basename(file_path, '.rb')
        class_name = basename.split('_').map(&:capitalize).join

        # YARDレジストリからクラスを取得
        klass = YARD::Registry.at("EpicGrid::McpTools::#{class_name}")
        return nil unless klass

        # ソースコードから追加情報を抽出
        source = File.read(file_path)
        description = extract_description(source)
        input_schema = extract_input_schema(source)

        {
          name: class_name,
          file_path: file_path,
          class_path: klass.path,
          docstring: klass.docstring.to_s,
          examples: klass.tags(:example).map(&:text),
          description: description,
          input_schema: input_schema
        }
      end

      # Markdownドキュメント生成
      def generate_markdown(output_path:)
        tools = scan_tools

        markdown = <<~MARKDOWN
          # MCP Tools Reference

          This document is **auto-generated** from Ruby source code.
          Do not edit manually. Run `rake mcp:generate_docs` to regenerate.

          **Total Tools**: #{tools.size}

          ---

        MARKDOWN

        tools.each do |tool|
          markdown += format_tool_as_markdown(tool)
        end

        File.write(output_path, markdown)
        puts "✅ Generated Markdown: #{output_path}"
      end

      # JSONマニフェスト生成
      def generate_json(output_path:)
        tools = scan_tools

        manifest = {
          version: "1.0",
          generated_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
          tools: tools.map { |tool| format_tool_as_json(tool) }
        }

        File.write(output_path, JSON.pretty_generate(manifest))
        puts "✅ Generated JSON: #{output_path}"
      end

      private

      # descriptionを抽出（正規表現）
      def extract_description(source)
        # description "..." または description '...' を抽出
        # 改良版: 開始引用符と同じ種類の終了引用符を探す
        # ダブルクォートの場合
        match = source.match(/description\s+"([^"]+)"/m)
        return match[1].strip if match

        # シングルクォートの場合
        match = source.match(/description\s+'([^']+)'/m)
        match ? match[1].strip : nil
      end

      # input_schemaを抽出（Rubyコードとして評価）
      def extract_input_schema(source)
        # input_schema( ... ) のブロックを抽出
        match = source.match(/input_schema\s*\((.*?)\n\s*\)/m)
        return nil unless match

        schema_code = match[1].strip

        # 安全にハッシュをパースするため、evalの代わりにRipperを使うべきだが
        # 最小限の実装として、コードをそのまま評価する（要改善）
        begin
          eval("{#{schema_code}}")
        rescue StandardError => e
          Rails.logger.warn "Failed to parse input_schema: #{e.message}"
          nil
        end
      end

      # ツール情報をMarkdown形式にフォーマット
      def format_tool_as_markdown(tool)
        md = <<~MARKDOWN
          ## #{tool[:name]}

          **Description**: #{tool[:description] || 'N/A'}

          **Class**: `#{tool[:class_path]}`

        MARKDOWN

        # Docstring
        if tool[:docstring] && !tool[:docstring].empty?
          md += "**Overview**:\n\n#{tool[:docstring]}\n\n"
        end

        # Examples
        if tool[:examples] && tool[:examples].any?
          md += "**Examples**:\n\n"
          tool[:examples].each do |example|
            md += "```\n#{example}\n```\n\n"
          end
        end

        # Input Schema
        if tool[:input_schema]
          md += "**Parameters**:\n\n"
          if tool[:input_schema][:properties]
            tool[:input_schema][:properties].each do |name, prop|
              required = tool[:input_schema][:required]&.include?(name.to_s) ? '**required**' : 'optional'
              md += "- `#{name}` (#{prop[:type]}, #{required}): #{prop[:description]}\n"
            end
          end
          md += "\n"
        end

        md += "---\n\n"
        md
      end

      # ツール情報をJSON形式にフォーマット
      def format_tool_as_json(tool)
        {
          name: tool[:name],
          description: tool[:description] || tool[:docstring],
          inputSchema: tool[:input_schema] || {}
        }
      end
    end
  end
end
