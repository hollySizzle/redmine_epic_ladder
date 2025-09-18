#!/usr/bin/env ruby
# サーバーサイド期間フィルタリングのテストスクリプト

require 'date'
require 'json'

puts "=== サーバーサイド期間フィルタリングテスト ==="
puts ""

# プロジェクトIDと期間を設定
project_id = 'space-mine'
view_start = '2025-07-01'
view_end = '2025-12-31'

puts "テスト条件:"
puts "  プロジェクト: #{project_id}"
puts "  表示期間: #{view_start} 〜 #{view_end}"
puts ""

# Railsランナースクリプトを別ファイルに書き出す
runner_script = <<-'RUBY'
project = Project.find_by(identifier: 'space-mine')
if project.nil?
  puts "エラー: プロジェクト 'space-mine' が見つかりません"
  exit 1
end

# ReactGanttChartControllerのモック
controller_mock = Object.new
controller_mock.instance_variable_set(:@project, project)

# apply_date_range_filterメソッドを実行
query = IssueQuery.new(name: '_', project: project)

# フィルタ適用前のカウント
before_count = query.issue_count
puts "フィルタ適用前のタスク数: #{before_count}"

# 期間フィルタを適用（シンプル版）
view_start = Date.parse('2025-07-01')
view_end = Date.parse('2025-12-31')

# 期間フィルタをクエリに直接追加
query.add_filter("start_date", "<=", [view_end.to_s])
query.add_filter("due_date", ">=", [view_start.to_s])
after_count = query.issue_count
puts "期間フィルタ適用後のタスク数: #{after_count}"

# 実際のタスクを取得
issues = query.issues(limit: 100)

# 期間内のタスクを確認
in_period_tasks = issues.select do |issue|
  start_ok = issue.start_date.nil? || issue.start_date <= view_end
  end_ok = issue.due_date.nil? || issue.due_date >= view_start
  start_ok && end_ok
end

puts ""
puts "期間内のタスク数: #{in_period_tasks.size}"
puts ""

# サンプルタスクを表示
puts "サンプルタスク（最初の5件）:"
issues.first(5).each do |task|
  puts "  - ##{task.id} #{task.subject}"
  puts "    開始: #{task.start_date || 'なし'}, 終了: #{task.due_date || 'なし'}"
end

# バージョンサマリタスクの確認
version_ids = issues.map(&:fixed_version_id).compact.uniq
if version_ids.any?
  versions = Version.where(id: version_ids)
  puts ""
  puts "関連バージョン数: #{versions.count}"
  versions.each do |v|
    puts "  - #{v.name} (実効日: #{v.effective_date || 'なし'})"
  end
end

puts ""
puts "テスト完了"
RUBY

# 一時ファイルに書き出して実行
File.write('/tmp/test_runner.rb', runner_script)

# Railsランナーで実行
puts "実行中..."
puts ""
system("cd /usr/src/redmine && RAILS_ENV=production bundle exec rails runner /tmp/test_runner.rb")