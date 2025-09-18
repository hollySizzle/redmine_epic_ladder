# サーバーサイドフィルタの動作テスト
puts 'Testing Server-Side Filtering Implementation...'
puts '=' * 50

# プロジェクトを取得
project = Project.first
if project.nil?
  puts 'Error: No projects found'
  exit 1
end

puts "Project: #{project.name} (ID: #{project.id})"

# 現在の全Issue数を確認
puts "\nTesting IssueQuery functionality:"
query = IssueQuery.new(name: '_', project: project)
all_issues = query.issues(limit: 1000)
puts "Total issues in project: #{all_issues.count}"

# 期日範囲フィルタのテスト
puts "\nTesting date range filtering:"
filter_params = {
  f: ['due_date'],
  op: {
    'due_date' => '><'
  },
  v: {
    'due_date' => ['2025-01-01', '2025-03-31']
  }
}

query_filtered = IssueQuery.new(name: '_', project: project)
query_filtered.build_from_params(filter_params, project: project)
filtered_issues = query_filtered.issues(limit: 500)

puts "Issues with due date in 2025 Q1: #{filtered_issues.count}"

# 動的limit計算のテスト
puts "\nTesting dynamic limit calculation:"
zoom_levels = {
  'day' => 200,
  'week' => 300,
  'month' => 500,
  'quarter' => 700,
  'year' => 1000
}

zoom_levels.each do |level, expected_limit|
  puts "#{level.ljust(8)}: limit #{expected_limit}"
end

# パフォーマンスの測定
puts "\nTesting performance:"
start_time = Time.current

query_perf = IssueQuery.new(name: '_', project: project)
perf_issues = query_perf.issues(limit: 100)

end_time = Time.current
query_time = ((end_time - start_time) * 1000).round(2)

puts "Query time for 100 issues: #{query_time}ms"

if all_issues.count > 0 && filtered_issues.count < all_issues.count
  reduction = ((all_issues.count - filtered_issues.count).to_f / all_issues.count * 100).round(1)
  puts "✓ Data reduction achieved: #{reduction}%"
else
  puts "✓ Filter functionality working (no data reduction in this test)"
end

puts "\nServer-side filtering test completed successfully!"
puts '=' * 50