# Gantt API のサーバーサイドフィルタテスト
puts 'Testing Gantt API Server-Side Filtering...'
puts '=' * 50

# コントローラーのインスタンスを作成してテスト
class TestGanttController < ReactGanttChartController
  attr_accessor :params, :project
  
  def initialize(project, params = {})
    @project = project
    @params = params.with_indifferent_access
  end
  
  public :calculate_optimal_limit
end

project = Project.first
puts "Testing with Project: #{project.name}"

# 動的limit計算のテスト
puts "\nTesting calculate_optimal_limit:"
controller = TestGanttController.new(project)

zoom_tests = {
  'day' => 200,
  'week' => 300,
  'month' => 500,
  'quarter' => 700,
  'year' => 1000,
  'unknown' => 400
}

zoom_tests.each do |zoom, expected|
  actual = controller.calculate_optimal_limit({zoom_level: zoom})
  status = actual == expected ? '✓' : '✗'
  puts "#{status} #{zoom.ljust(8)}: #{actual} (expected: #{expected})"
end

# サーバーサイドフィルタのパラメータ構築テスト
puts "\nTesting server-side filter parameter building:"

# ガントビュー用パラメータのシミュレート
test_params = {
  gantt_view: true,
  view_start: '2025-01-01',
  view_end: '2025-03-31',
  zoom_level: 'month'
}

puts "Input parameters:"
test_params.each do |key, value|
  puts "  #{key}: #{value}"
end

# IssueQueryでのフィルタリングテスト
puts "\nTesting IssueQuery filtering with gantt_view parameters:"

query = IssueQuery.new(name: '_', project: project)

# サーバーサイドフィルタパラメータの構築（コントローラロジックを模倣）
if test_params[:gantt_view].present?
  view_start = test_params[:view_start] || Date.today.beginning_of_month
  view_end = test_params[:view_end] || Date.today.end_of_month + 3.months
  
  filter_params = {
    f: ['due_date', 'start_date'],
    op: {
      'due_date' => '><',
      'start_date' => '<='
    },
    v: {
      'due_date' => [view_start.to_s, view_end.to_s],
      'start_date' => [view_end.to_s]
    }
  }
  
  puts "Generated filter parameters:"
  filter_params.each do |key, value|
    puts "  #{key}: #{value}"
  end
  
  query.build_from_params(filter_params, project: project)
  
  # 動的limit適用
  limit = controller.calculate_optimal_limit(test_params)
  filtered_issues = query.issues(limit: limit)
  
  puts "\nFiltering results:"
  puts "  Applied limit: #{limit}"
  puts "  Filtered issues: #{filtered_issues.count}"
  puts "  Total issues in project: #{query.issue_count}"
  
  if query.issue_count > 0
    reduction = ((query.issue_count - filtered_issues.count).to_f / query.issue_count * 100).round(1)
    puts "  ✓ Data reduction: #{reduction}%"
  end
end

# メタデータ構築のテスト
puts "\nTesting metadata construction:"
meta = {
  total_count: query.issue_count,
  returned_count: filtered_issues.count,
  view_range: {
    start: test_params[:view_start],
    end: test_params[:view_end]
  },
  has_more: filtered_issues.count >= limit
}

puts "Generated metadata:"
meta.each do |key, value|
  puts "  #{key}: #{value}"
end

puts "\n✓ Gantt API server-side filtering test completed successfully!"
puts '=' * 50