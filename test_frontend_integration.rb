# フロントエンド・サーバーサイドフィルタ連携テスト
puts 'Testing Frontend-Server Integration...'
puts '=' * 50

# プロジェクトを取得
project = Project.first
if project.nil?
  puts 'Error: No projects found'
  exit 1
end

puts "Project: #{project.name} (ID: #{project.id})"

# ガントビューフィルタのテスト
puts "\nTesting gantt_view filtering:"

# パラメータの設定
gantt_view = true
view_start = '2025-01-01'
view_end = '2025-06-30'
zoom_level = 'month'

puts "gantt_view: #{gantt_view}"
puts "view_start: #{view_start}"
puts "view_end: #{view_end}"
puts "zoom_level: #{zoom_level}"

# IssueQueryを使用してフィルタを適用
query = IssueQuery.new(name: '_', project: project)

# 期日範囲フィルタの適用
if gantt_view && view_start && view_end
  filter_params = {
    f: ['due_date'],
    op: { 'due_date' => '><' },
    v: { 'due_date' => [view_start, view_end] }
  }
  query.build_from_params(filter_params, project: project)
end

# ズームレベル別のlimit設定
zoom_limits = {
  'day' => 200,
  'week' => 300, 
  'month' => 500,
  'quarter' => 700,
  'year' => 1000
}
limit = zoom_limits[zoom_level] || 500

puts "\nApplied limit: #{limit}"

# クエリの実行
start_time = Time.current
issues = query.issues(limit: limit)
end_time = Time.current
query_time = ((end_time - start_time) * 1000).round(2)

puts "\nResults:"
puts "- Returned issues: #{issues.count}"
puts "- Query time: #{query_time}ms"
puts "- Has more data: #{issues.count >= limit ? 'Yes' : 'No'}"

# メタデータの生成テスト
total_count = query.issue_count
has_more = issues.count < total_count

puts "\nMetadata:"
puts "- Total count: #{total_count}"
puts "- Returned count: #{issues.count}"
puts "- Has more: #{has_more}"
puts "- View range: #{view_start} to #{view_end}"

puts "\n✓ Frontend-Server Integration test completed!"
puts '=' * 50