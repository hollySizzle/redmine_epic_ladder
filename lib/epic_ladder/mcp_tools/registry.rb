# frozen_string_literal: true

module EpicLadder
  module McpTools
    # MCP Tools Registry
    # lib/epic_ladder/mcp_tools/ 配下の全ツールを自動検出・登録する
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

        # ツールキーの一覧を返す（snake_case、_tool接尾辞なし）
        # @return [Array<String>] ツールキーの配列
        # @example
        #   Registry.tool_keys
        #   # => ["create_epic", "create_feature", "update_issue_status", ...]
        def tool_keys
          all_tools.map { |klass| class_to_tool_key(klass) }
        end

        # カテゴリ別にグループ化されたツールキーを返す
        # @return [Hash<Symbol, Array<String>>] カテゴリ => ツールキー配列
        # @example
        #   Registry.tools_by_category
        #   # => { create_issues: ["create_epic", ...], issue_operations: ["update_issue_status", ...], ... }
        def tools_by_category
          tool_keys.each_with_object({}) do |key, categories|
            category = categorize_tool(key)
            categories[category] ||= []
            categories[category] << key
          end
        end

        # カテゴリの順序（表示用）
        # @return [Array<Symbol>] カテゴリシンボルの配列
        def category_order
          %i[create_issues version_management issue_operations query_tools]
        end

        # 順序付きでカテゴリ別ツールを返す
        # @return [Array<Array>] [カテゴリ, ツールキー配列] の配列
        def tools_by_category_ordered
          by_category = tools_by_category
          category_order.filter_map do |cat|
            [cat, by_category[cat]] if by_category[cat]&.any?
          end
        end

        private

        # クラスからツールキーを生成
        # @param klass [Class] ツールクラス
        # @return [String] ツールキー（例: "create_epic"）
        def class_to_tool_key(klass)
          klass.name.demodulize.underscore.sub(/_tool$/, '')
        end

        # ツールキーからカテゴリを判定
        # @param key [String] ツールキー
        # @return [Symbol] カテゴリシンボル
        def categorize_tool(key)
          case key
          when /^create_(?!version)/
            :create_issues
          when /version/
            :version_management
          when /^(list_|get_)/
            :query_tools
          else
            :issue_operations
          end
        end

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
          full_class_name = "EpicLadder::McpTools::#{class_name}"
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
