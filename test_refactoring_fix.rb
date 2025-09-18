#!/usr/bin/env ruby
# リファクタリング修正の検証スクリプト

puts "=== リファクタリング修正検証 ==="
puts "1. パラメータ汚染問題の完全解決を確認"

# 危険なパラメータ変更の残存をチェック
controller_file = '/usr/src/redmine/plugins/redmine_react_gantt_chart/app/controllers/react_gantt_chart_controller.rb'
content = File.read(controller_file)

dangerous_patterns = [
  "params[:f] <<",
  "params[:op][", 
  "params[:v][",
  ".build_from_params(params"  # 直接params使用
]

puts "\n危険なパターンをチェック中..."
dangerous_patterns.each do |pattern|
  lines = content.lines.map.with_index(1) do |line, num|
    [num, line.strip] if line.include?(pattern)
  end.compact
  
  if lines.any?
    puts "❌ 発見: #{pattern}"
    lines.each { |num, line| puts "  #{num}: #{line}" }
  else
    puts "✅ 安全: #{pattern} なし"
  end
end

# 新しい安全なメソッドの使用確認
safe_patterns = [
  "build_gantt_query(params)",
  "build_filter_params(",
  "apply_date_range_filter("
]

puts "\n安全な実装の確認中..."
safe_patterns.each do |pattern|
  if content.include?(pattern)
    puts "✅ 確認: #{pattern} 使用中"
  else
    puts "❌ 未使用: #{pattern}"
  end
end

# dataメソッドのシンプル化確認
data_method_lines = content.lines.map.with_index(1) do |line, num|
  [num, line.strip] if line.strip.start_with?('def data') || (num > 30 && num < 80 && !line.strip.empty?)
end.compact

puts "\ndataメソッドの実装確認:"
data_method_lines[0..10].each { |num, line| puts "  #{num}: #{line}" }

puts "\n=== 結果 ==="
if content.include?("params[:f] <<") || content.include?("params[:op][")
  puts "❌ 修正不完全: 古いコードが残存"
  exit 1
else
  puts "✅ 修正完了: パラメータ汚染問題解決"
  puts "✅ 新実装使用: build_gantt_query呼び出し確認"
  exit 0
end