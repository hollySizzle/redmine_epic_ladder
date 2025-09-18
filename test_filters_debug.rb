#!/usr/bin/env ruby

# フィルター定義APIのデバッグスクリプト
puts "=== フィルター定義APIデバッグ ==="

begin
  project = Project.find_by(identifier: 'space-mine')
  if project
    puts "プロジェクト見つかりました: #{project.name}"
    
    # IssueQueryのインスタンス作成
    query = IssueQuery.new(project: project)
    puts "IssueQueryインスタンス作成完了"
    
    # available_filtersの取得
    available_filters = query.available_filters
    puts "available_filters取得完了: #{available_filters.keys.size}個のフィルター"
    
    # トラッカーフィルター確認
    if available_filters['tracker_id']
      puts "\nトラッカーフィルター詳細:"
      tracker_filter = available_filters['tracker_id']
      puts "  名前: #{tracker_filter[:name]}"
      puts "  タイプ: #{tracker_filter[:type]}"
      puts "  値の数: #{tracker_filter[:values]&.size || 0}"
      if tracker_filter[:values]
        puts "  値:"
        tracker_filter[:values].first(5).each do |label, value|
          puts "    - #{label} (#{value})"
        end
        puts "    ..." if tracker_filter[:values].size > 5
      end
    else
      puts "エラー: tracker_idフィルターが見つかりません"
    end
    
    # ステータスフィルター確認
    if available_filters['status_id']
      puts "\nステータスフィルター詳細:"
      status_filter = available_filters['status_id']
      puts "  名前: #{status_filter[:name]}"
      puts "  タイプ: #{status_filter[:type]}"
      puts "  値の数: #{status_filter[:values]&.size || 0}"
      if status_filter[:values]
        puts "  値:"
        status_filter[:values].first(5).each do |label, value|
          puts "    - #{label} (#{value})"
        end
        puts "    ..." if status_filter[:values].size > 5
      end
    else
      puts "エラー: status_idフィルターが見つかりません"
    end
    
    # format_filtersの動作テスト
    puts "\nformat_filtersのテスト:"
    formatted = {}
    available_filters.each do |field, options|
      formatted[field] = {
        name: options[:name],
        type: options[:type],
        values: options[:values] || []
      }
    end
    
    puts "フォーマット済みフィルター数: #{formatted.keys.size}"
    puts "主要フィルター:"
    ['tracker_id', 'status_id', 'assigned_to_id', 'priority_id'].each do |key|
      if formatted[key]
        puts "  #{key}: #{formatted[key][:name]} (#{formatted[key][:type]}) - #{formatted[key][:values]&.size || 0}個の選択肢"
      else
        puts "  #{key}: 見つかりません"
      end
    end
    
    # オペレータの確認
    puts "\nオペレータ情報:"
    puts "operatorLabels: #{Query.operators_labels.keys.first(5).join(', ')}..."
    puts "operatorByType keys: #{Query.operators_by_filter_type.keys.join(', ')}"
    
  else
    puts "エラー: プロジェクト 'space-mine' が見つかりません"
    puts "利用可能なプロジェクト:"
    Project.all.limit(5).each do |p|
      puts "  - #{p.identifier}: #{p.name}"
    end
  end

rescue => e
  puts "エラー発生: #{e.message}"
  puts "バックトレース:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
end