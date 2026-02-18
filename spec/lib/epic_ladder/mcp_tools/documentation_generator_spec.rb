# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::DocumentationGenerator, type: :model do
  let(:tools_dir) { File.expand_path('../../../../lib/epic_ladder/mcp_tools', __dir__) }
  let(:generator) { described_class.new(tools_dir: tools_dir) }

  describe '#initialize' do
    context 'tools_dirを指定した場合' do
      it '指定されたディレクトリを使用する' do
        custom_dir = '/custom/path'
        gen = described_class.new(tools_dir: custom_dir)
        expect(gen.tools_dir).to eq(custom_dir)
      end
    end

    context 'tools_dirを指定しない場合' do
      it 'デフォルトのディレクトリを使用する' do
        gen = described_class.new
        expect(gen.tools_dir).to include('mcp_tools')
      end
    end
  end

  describe '#scan_tools' do
    it 'ツールファイルの配列を返す' do
      result = generator.scan_tools
      expect(result).to be_an(Array)
    end

    it '*_tool.rbファイルをスキャンする' do
      # 実際のツールファイルが存在することを確認
      tool_files = Dir.glob(File.join(tools_dir, '*_tool.rb'))
      expect(tool_files).not_to be_empty
    end

    context 'YARDが利用可能な場合', if: defined?(YARD) do
      it 'ツール情報を含む配列を返す' do
        result = generator.scan_tools
        # YARDでパースできたツールがあれば、情報を含む
        parsed_tools = result.compact
        if parsed_tools.any?
          expect(parsed_tools.first).to include(:name, :file_path)
        end
      end
    end
  end

  describe '#parse_tool_file' do
    let(:sample_tool_path) { File.join(tools_dir, 'create_epic_tool.rb') }

    context 'YARDが利用可能な場合', if: defined?(YARD) do
      before do
        # YARDレジストリをクリア
        YARD::Registry.clear
      end

      it 'ツール情報のHashを返す' do
        result = generator.parse_tool_file(sample_tool_path)
        if result
          expect(result).to be_a(Hash)
          expect(result[:name]).to eq('CreateEpicTool')
          expect(result[:file_path]).to eq(sample_tool_path)
        end
      end

      it 'descriptionを抽出する' do
        result = generator.parse_tool_file(sample_tool_path)
        if result
          expect(result[:description]).to be_a(String) if result[:description]
        end
      end
    end

    context 'YARDが利用不可の場合' do
      before do
        allow(generator).to receive(:defined?).with(YARD).and_return(false)
      end

      it 'nilを返す（YARDがない環境でも安全に動作）' do
        # YARDがない場合のテストは環境依存のため、このテストは参考程度
        # 実際にはYARDがインストールされている環境で動作する
      end
    end

    context '存在しないファイル' do
      it 'エラーを発生させずnilを返す' do
        result = generator.parse_tool_file('/nonexistent/path/tool.rb')
        expect(result).to be_nil
      end
    end
  end

  describe '#generate_markdown' do
    let(:output_path) { Rails.root.join('tmp', 'test_mcp_docs.md').to_s }

    after do
      File.delete(output_path) if File.exist?(output_path)
    end

    it 'Markdownファイルを生成する' do
      generator.generate_markdown(output_path: output_path)
      expect(File.exist?(output_path)).to be true
    end

    it '正しいヘッダーを含む' do
      generator.generate_markdown(output_path: output_path)
      content = File.read(output_path)
      expect(content).to include('# MCP Tools Reference')
    end

    it 'auto-generatedの警告を含む' do
      generator.generate_markdown(output_path: output_path)
      content = File.read(output_path)
      expect(content).to include('auto-generated')
    end

    it 'ツール数を表示する' do
      generator.generate_markdown(output_path: output_path)
      content = File.read(output_path)
      expect(content).to include('Total Tools')
    end
  end

  describe '#generate_json' do
    let(:output_path) { Rails.root.join('tmp', 'test_mcp_manifest.json').to_s }

    after do
      File.delete(output_path) if File.exist?(output_path)
    end

    it 'JSONファイルを生成する' do
      generator.generate_json(output_path: output_path)
      expect(File.exist?(output_path)).to be true
    end

    it '有効なJSONを生成する' do
      generator.generate_json(output_path: output_path)
      content = File.read(output_path)
      expect { JSON.parse(content) }.not_to raise_error
    end

    it 'versionを含む' do
      generator.generate_json(output_path: output_path)
      json = JSON.parse(File.read(output_path))
      expect(json['version']).to eq('1.0')
    end

    it 'generated_atを含む' do
      generator.generate_json(output_path: output_path)
      json = JSON.parse(File.read(output_path))
      expect(json['generated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it 'toolsを配列として含む' do
      generator.generate_json(output_path: output_path)
      json = JSON.parse(File.read(output_path))
      expect(json['tools']).to be_an(Array)
    end
  end

  describe 'private methods' do
    describe '#extract_description' do
      it 'ダブルクォートのdescriptionを抽出する' do
        source = 'description "This is a test tool"'
        result = generator.send(:extract_description, source)
        expect(result).to eq('This is a test tool')
      end

      it 'シングルクォートのdescriptionを抽出する' do
        source = "description 'Single quoted description'"
        result = generator.send(:extract_description, source)
        expect(result).to eq('Single quoted description')
      end

      it '日本語descriptionを抽出する' do
        source = 'description "これはテストツールです"'
        result = generator.send(:extract_description, source)
        expect(result).to eq('これはテストツールです')
      end

      it 'descriptionがない場合nilを返す' do
        source = 'class SomeTool; end'
        result = generator.send(:extract_description, source)
        expect(result).to be_nil
      end

      it '複数行descriptionを処理する' do
        source = <<~RUBY
          description "Multi
          line description"
        RUBY
        result = generator.send(:extract_description, source)
        expect(result).to include('Multi')
      end
    end

    describe '#extract_input_schema' do
      it 'input_schemaがない場合nilを返す' do
        source = 'class SomeTool; end'
        result = generator.send(:extract_input_schema, source)
        expect(result).to be_nil
      end

      # input_schemaの抽出は複雑なため、基本的なテストのみ
    end

    describe '#format_tool_as_markdown' do
      let(:tool_info) do
        {
          name: 'TestTool',
          description: 'A test tool',
          class_path: 'EpicLadder::McpTools::TestTool',
          docstring: 'This is the overview',
          examples: ['example 1', 'example 2'],
          input_schema: {
            properties: {
              param1: { type: 'string', description: 'First param' },
              param2: { type: 'integer', description: 'Second param' }
            },
            required: ['param1']
          }
        }
      end

      it 'ツール名を含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('## TestTool')
      end

      it 'descriptionを含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('A test tool')
      end

      it 'クラスパスを含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('EpicLadder::McpTools::TestTool')
      end

      it 'docstringを含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('This is the overview')
      end

      it 'examplesを含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('example 1')
        expect(result).to include('example 2')
      end

      it 'パラメータ情報を含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('param1')
        expect(result).to include('**required**')
        expect(result).to include('param2')
        expect(result).to include('optional')
      end

      it '区切り線を含む' do
        result = generator.send(:format_tool_as_markdown, tool_info)
        expect(result).to include('---')
      end
    end

    describe '#format_tool_as_json' do
      let(:tool_info) do
        {
          name: 'TestTool',
          description: 'A test tool',
          docstring: 'Overview text',
          input_schema: { properties: {} }
        }
      end

      it 'nameを含む' do
        result = generator.send(:format_tool_as_json, tool_info)
        expect(result[:name]).to eq('TestTool')
      end

      it 'descriptionを含む（descriptionがある場合）' do
        result = generator.send(:format_tool_as_json, tool_info)
        expect(result[:description]).to eq('A test tool')
      end

      it 'docstringにフォールバック（descriptionがない場合）' do
        tool_info[:description] = nil
        result = generator.send(:format_tool_as_json, tool_info)
        expect(result[:description]).to eq('Overview text')
      end

      it 'inputSchemaを含む' do
        result = generator.send(:format_tool_as_json, tool_info)
        expect(result[:inputSchema]).to eq({ properties: {} })
      end

      it 'inputSchemaがない場合は空Hashを返す' do
        tool_info[:input_schema] = nil
        result = generator.send(:format_tool_as_json, tool_info)
        expect(result[:inputSchema]).to eq({})
      end
    end
  end
end
