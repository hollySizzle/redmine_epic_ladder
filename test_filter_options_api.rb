#!/usr/bin/env ruby
# encoding: utf-8

# フィルタオプションAPI動作確認スクリプト

begin
  # テスト用プロジェクトの確認
  project = Project.find_by(identifier: 'space-mine')
  unless project
    puts "❌ プロジェクト 'space-mine' が見つかりません"
    exit 1
  end
  
  puts "=== フィルタオプションAPI動作確認 ==="
  puts "プロジェクト: #{project.name}"
  
  # 1. トラッカーオプション確認
  puts "\n--- トラッカーオプション ---"
  trackers = project.trackers.pluck(:id, :name).map { |id, name|
    { value: id.to_s, label: name }
  }
  puts "利用可能なトラッカー数: #{trackers.size}"
  trackers.each { |t| puts "  - #{t[:label]} (ID: #{t[:value]})" }
  
  # 2. ステータスオプション確認
  puts "\n--- ステータスオプション ---"
  statuses = IssueStatus.sorted.pluck(:id, :name).map { |id, name|
    { value: id.to_s, label: name }
  }
  puts "利用可能なステータス数: #{statuses.size}"
  statuses.each { |s| puts "  - #{s[:label]} (ID: #{s[:value]})" }
  
  # 3. 担当者オプション確認
  puts "\n--- 担当者オプション ---"
  assigned_to = project.assignable_users.pluck(:id, :name).map { |id, name|
    { value: id.to_s, label: name }
  }
  puts "利用可能な担当者数: #{assigned_to.size}"
  assigned_to.each { |u| puts "  - #{u[:label]} (ID: #{u[:value]})" }
  
  # 4. API形式での出力確認
  puts "\n--- 完全なfilter_optionsオブジェクト ---"
  filter_options = {
    trackers: trackers,
    statuses: statuses,
    assigned_to: assigned_to
  }
  
  puts "JSON形式:"
  puts JSON.pretty_generate(filter_options)
  
  # 5. 実際のIssueとの対応確認
  puts "\n--- 実際のチケットとの対応確認 ---"
  issues = project.issues.limit(5).includes(:tracker, :status, :assigned_to)
  puts "チケット例（最初の5件）:"
  issues.each do |issue|
    puts "  ID:#{issue.id} トラッカー:#{issue.tracker.name} ステータス:#{issue.status.name} 担当者:#{issue.assigned_to&.name || '未割当'}"
  end
  
  puts "\n✅ フィルタオプション動作確認完了"
  
rescue => e
  puts "❌ エラーが発生しました: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end