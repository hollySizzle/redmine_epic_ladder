# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCP Tools Registry
    # lib/epic_grid/mcp_tools/ 配下の全ツールを自動検出・登録する
    #
    # @example
    #   # 全ツールクラスを取得
    #   Registry.all_tools
    #   # => [CreateTaskTool, CreateEpicTool, ...]
    #
    #   # ツール数を取得
    #   Registry.count
    #   # => 17
    class Registry
      class << self
        # 全ツールクラスを返す
        # @return [Array<Class>] MCP::Toolを継承するクラスの配列
        def all_tools
          scan_tool_files.map { |file| load_tool_class(file) }.compact
        end

        # ツール数を返す
        # @return [Integer] 登録されているツールの数
        def count
          all_tools.size
        end

        # ツール名の一覧を返す
        # @return [Array<String>] ツールクラス名の配列
        def tool_names
          all_tools.map { |klass| klass.name.demodulize }
        end

        private

        # ツールディレクトリ
        def tools_dir
          File.expand_path('../mcp_tools', __dir__)
        end

        # 全ツールファイルをスキャン
        # @return [Array<String>] *_tool.rb ファイルのパス配列
        def scan_tool_files
          Dir.glob(File.join(tools_dir, '*_tool.rb')).sort
        end

        # ツールファイルからクラスをロード
        # @param file_path [String] ツールファイルのパス
        # @return [Class, nil] ツールクラス、またはnil
        def load_tool_class(file_path)
          # ファイル名からクラス名を推測
          basename = File.basename(file_path, '.rb')
          class_name = basename.split('_').map(&:capitalize).join

          # クラスを取得
          full_class_name = "EpicGrid::McpTools::#{class_name}"
          klass = full_class_name.constantize

          # MCP::Toolを継承しているか確認
          if klass < MCP::Tool
            klass
          else
            Rails.logger.warn "#{full_class_name} is not a MCP::Tool subclass"
            nil
          end
        rescue NameError => e
          # constantizeが失敗した場合（クラスが存在しない）
          Rails.logger.warn "Could not load tool class from #{file_path}: #{e.message}"
          nil
        end
      end
    end
  end
end
