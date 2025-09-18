#!/usr/bin/env ruby
# デバッグスクリプト: 期日nullのタスクを確認

require File.expand_path('../../../config/environment', __FILE__)

project = Project.find_by(identifier: 'space-mine')
if project.nil?
  puts "プロジェクト 'space-mine' が見つかりません"
  exit
end

puts "=== プロジェクト: #{project.name} ==="
puts ""

# 期日がnullのタスクを検索
issues_with_null_due_date = project.issues.where(due_date: nil)
puts "期日がnullのタスク数: #{issues_with_null_due_date.count}"
puts ""

if issues_with_null_due_date.any?
  puts "期日がnullのタスク一覧:"
  issues_with_null_due_date.each do |issue|
    puts "- ##{issue.id}: #{issue.subject}"
    puts "  開始日: #{issue.start_date || 'なし'}"
    puts "  ステータス: #{issue.status.name}"
    puts ""
  end
else
  puts "期日がnullのタスクはありません"
end

# 期間フィルタリングのテスト
puts "\n=== 期間フィルタリングテスト ==="
view_start = Date.parse('2025-07-31')
view_end = nil  # 終了日なし

puts "フィルタ期間: #{view_start} 〜 #{view_end || '無制限'}"
puts ""

# 期日nullで開始日が期間内のタスクをカウント
filtered_issues = issues_with_null_due_date.select do |issue|
  next false if issue.start_date.nil?
  issue.start_date >= view_start
end

puts "フィルタ後のタスク数: #{filtered_issues.count}"
if filtered_issues.any?
  puts "表示されるべきタスク:"
  filtered_issues.each do |issue|
    puts "- ##{issue.id}: #{issue.subject} (開始日: #{issue.start_date})"
  end
end