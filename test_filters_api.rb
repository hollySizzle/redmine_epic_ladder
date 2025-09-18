#!/usr/bin/env ruby

# フィルター定義APIの完全テスト
puts "=== フィルター定義API完全テスト ==="

begin
  # プロジェクトを取得
  project = Project.find_by(identifier: 'space-mine')
  if !project
    puts "エラー: プロジェクト 'space-mine' が見つかりません"
    puts "利用可能なプロジェクト:"
    Project.all.limit(5).each do |p|
      puts "  - #{p.identifier}: #{p.name}"
    end
    exit 1
  end
  
  puts "プロジェクト: #{project.name}"
  
  # IssueQueryのインスタンス作成
  query = IssueQuery.new(project: project)
  
  # available_filtersの取得
  available_filters = query.available_filters
  puts "利用可能なフィルター数: #{available_filters.keys.size}"
  
  # 重要なフィルターをチェック
  important_filters = ['tracker_id', 'status_id', 'assigned_to_id', 'priority_id']
  
  important_filters.each do |filter_name|
    if available_filters[filter_name]
      filter_info = available_filters[filter_name]
      puts "\n--- #{filter_name} ---"
      puts "  名前: #{filter_info[:name]}"
      puts "  タイプ: #{filter_info[:type]}"
      puts "  値の有無: #{!filter_info[:values].nil?}"
      puts "  値の数: #{filter_info[:values]&.size || 0}"
      
      if filter_info[:values] && filter_info[:values].size > 0
        puts "  最初の5つの値:"
        filter_info[:values].first(5).each do |pair|
          if pair.is_a?(Array) && pair.size == 2
            puts "    - #{pair[0]} (#{pair[1]})"
          else
            puts "    - #{pair.inspect}"
          end
        end
      else
        puts "  値が空またはnull"
      end
    else
      puts "\n--- #{filter_name} ---"
      puts "  見つかりません"
    end
  end
  
  # format_filtersメソッドの模擬
  puts "\n=== format_filtersテスト ==="
  formatted = {}
  available_filters.each do |field, options|
    formatted[field] = {
      name: options[:name],
      type: options[:type],
      values: options[:values] || []
    }
  end
  
  puts "フォーマット後のフィルター数: #{formatted.keys.size}"
  
  # トラッカーの詳細チェック
  if formatted['tracker_id']
    tracker_info = formatted['tracker_id']
    puts "\nトラッカーフィルター詳細:"
    puts "  名前: #{tracker_info[:name]}"
    puts "  タイプ: #{tracker_info[:type]}"
    puts "  値の形式: #{tracker_info[:values].class}"
    puts "  値の数: #{tracker_info[:values].size}"
    
    if tracker_info[:values].size > 0
      puts "  値のサンプル:"
      tracker_info[:values].first(3).each_with_index do |val, idx|
        puts "    [#{idx}] #{val.inspect}"
      end
    end
  end
  
  # JSONシリアライゼーションテスト
  puts "\n=== JSONシリアライゼーションテスト ==="
  json_data = {
    operatorLabels: Query.operators_labels,
    operatorByType: Query.operators_by_filter_type,
    availableFilters: formatted
  }
  
  puts "operatorLabels keys: #{json_data[:operatorLabels].keys.first(5).join(', ')}..."
  puts "operatorByType keys: #{json_data[:operatorByType].keys.join(', ')}"
  puts "availableFilters keys: #{json_data[:availableFilters].keys.first(10).join(', ')}..."
  
  # tracker_idのoperatorByType確認
  if formatted['tracker_id']
    tracker_type = formatted['tracker_id'][:type]
    available_ops = json_data[:operatorByType][tracker_type]
    puts "\nトラッカーのオペレータ:"
    puts "  フィールドタイプ: #{tracker_type}"
    puts "  利用可能なオペレータ: #{available_ops&.join(', ') || 'なし'}"
  end

rescue => e
  puts "エラー発生: #{e.message}"
  puts "バックトレース:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end