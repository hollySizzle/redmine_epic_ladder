# frozen_string_literal: true

module PerformanceHelpers
  # パフォーマンス測定用ヘルパー
  def measure_time
    start_time = Time.current
    yield
    Time.current - start_time
  end
  
  # シンプルなレスポンス時間測定
  def measure_response_time(&block)
    start_time = Time.current
    yield
    (Time.current - start_time) * 1000
  end
  
  # 大量のテストデータを効率的に作成
  def create_bulk_issues(count:, project:, user:, date_range: 365, options: {})
    # デフォルトオプション
    default_options = {
      tracker: project.trackers.first,
      status: IssueStatus.where(is_default: true).first || IssueStatus.first,
      priority: IssuePriority.where(is_default: true).first || IssuePriority.first
    }
    options = default_options.merge(options)
    
    issues_data = []
    
    count.times do |i|
      base_date = Date.today + (i % date_range).days
      
      issues_data << {
        project_id: project.id,
        tracker_id: options[:tracker].id,
        author_id: user.id,
        status_id: options[:status].id,
        priority_id: options[:priority].id,
        subject: "Bulk Issue #{i}",
        start_date: base_date,
        due_date: base_date + rand(1..14).days,
        estimated_hours: rand(1..40),
        done_ratio: [0, 25, 50, 75, 100].sample,
        created_on: Time.current - rand(30).days,
        updated_on: Time.current - rand(7).days
      }
    end
    
    # バルクインサートで高速化
    Issue.insert_all(issues_data)
    
    # 作成されたIssuesを返す
    Issue.where(project: project).order(id: :desc).limit(count)
  end
  
  # 日付範囲別のIssueを作成
  def create_issues_in_date_range(count:, project:, user:, start_date:, end_date:)
    date_span = (end_date - start_date).to_i
    return [] if date_span <= 0
    
    issues = []
    count.times do |i|
      issue_start = start_date + rand(date_span).days
      issue_end = issue_start + rand(1..30).days
      issue_end = [issue_end, end_date].min
      
      issues << Issue.create!(
        project: project,
        tracker: project.trackers.first,
        author: user,
        subject: "Range Issue #{i}",
        start_date: issue_start,
        due_date: issue_end,
        status: IssueStatus.first,
        priority: IssuePriority.first
      )
    end
    issues
  end
  
  # メモリ使用量を測定
  def measure_memory
    before = get_memory_usage
    yield
    after = get_memory_usage
    after - before
  end
  
  # データベースクエリ数を測定
  def measure_queries
    queries_count = 0
    callback = ->(name, started, finished, unique_id, payload) {
      queries_count += 1 if payload[:sql] !~ /^(BEGIN|COMMIT|ROLLBACK|RELEASE SAVEPOINT)/
    }
    
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      yield
    end
    
    queries_count
  end
  
  # シンプルな期待値チェック
  def expect_response_under(time_ms, &block)
    response_time = measure_response_time(&block)
    expect(response_time).to be < time_ms
    response_time
  end
  
  private
  
  def get_memory_usage
    if RUBY_PLATFORM =~ /linux/
      `ps -o rss= -p #{Process.pid}`.to_i
    else
      # Fallback for other platforms
      0
    end
  end
  
  def log_performance(data)
    puts "\n=== Performance Measurement ==="
    puts "Description: #{data[:description]}" if data[:description]
    puts "Wall Time: #{data[:wall_time].round(2)}ms"
    puts "CPU Time: #{data[:cpu_time].round(2)}ms"
    puts "Memory Delta: #{data[:memory_delta]}KB"
    puts "==============================\n"
  end
  
end

RSpec.configure do |config|
  config.include PerformanceHelpers
end