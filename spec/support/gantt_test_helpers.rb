# frozen_string_literal: true

module GanttTestHelpers
  # ガントチャート専用のテストヘルパー
  
  # コントローラーのテスト用パラメータを生成
  def gantt_params(overrides = {})
    default_params = {
      gantt_view: true,
      view_start: Date.today.to_s,
      view_end: (Date.today + 3.months).to_s,
      zoom_level: 'month'
    }
    default_params.merge(overrides)
  end
  
  # フィルタパラメータを生成
  def filter_params(filters = {})
    default_filters = {
      f: [],
      op: {},
      v: {}
    }
    
    filters.each do |field, config|
      default_filters[:f] << field.to_s
      default_filters[:op][field.to_s] = config[:operator]
      default_filters[:v][field.to_s] = config[:values]
    end
    
    default_filters
  end
  
  # 期日範囲フィルタ専用
  def date_range_filter(start_date, end_date)
    filter_params(
      due_date: { operator: '><', values: [start_date.to_s, end_date.to_s] },
      start_date: { operator: '<=', values: [end_date.to_s] }
    )
  end
  
  # レスポンスのJSON構造を検証
  def expect_valid_gantt_response(response)
    expect(response).to have_http_status(:success)
    
    json = JSON.parse(response.body)
    expect(json).to have_key('tasks')
    expect(json).to have_key('links')
    expect(json).to have_key('meta')
    expect(json).to have_key('permissions')
    
    # メタデータの検証
    expect(json['meta']).to include(
      'total_count',
      'returned_count',
      'view_range',
      'has_more'
    )
    
    # 権限情報の検証
    expect(json['permissions']).to include(
      'can_edit',
      'can_add',
      'can_delete',
      'readonly'
    )
    
    json
  end
  
  # パフォーマンス情報を含むレスポンスの検証
  def expect_performance_data(response)
    json = JSON.parse(response.body)
    expect(json).to have_key('performance')
    expect(json['performance']).to include('query_time', 'issue_count')
    json['performance']
  end
  
  # サーバーサイドフィルタの効果を検証
  def expect_server_side_filter_effect(response, original_count)
    json = JSON.parse(response.body)
    filtered_count = json['tasks'].size
    
    expect(filtered_count).to be <= original_count
    
    if original_count > 0
      reduction_percentage = ((original_count - filtered_count).to_f / original_count * 100).round(1)
      puts "Data reduction: #{reduction_percentage}% (#{original_count} -> #{filtered_count})"
    end
    
    json
  end
  
  # 動的limit計算のテスト
  def expect_zoom_level_limits
    expected_limits = {
      'day' => 200,
      'week' => 300,
      'month' => 500,
      'quarter' => 700,
      'year' => 1000
    }
    
    expected_limits.each do |zoom_level, expected_limit|
      yield zoom_level, expected_limit
    end
  end
  
  # IssueQueryの構築とテスト
  def build_test_query(project, params = {})
    query = IssueQuery.new(name: '_', project: project)
    
    # ガントビュー用フィルタを自動追加
    if params[:gantt_view]
      view_start = params[:view_start] || Date.today.beginning_of_month
      view_end = params[:view_end] || Date.today.end_of_month + 3.months
      
      enhanced_params = params.merge(
        f: (params[:f] || []) + ['due_date', 'start_date'],
        op: (params[:op] || {}).merge(
          'due_date' => '><',
          'start_date' => '<='
        ),
        v: (params[:v] || {}).merge(
          'due_date' => [view_start.to_s, view_end.to_s],
          'start_date' => [view_end.to_s]
        )
      )
      
      query.build_from_params(enhanced_params, project: project)
    else
      query.build_from_params(params, project: project)
    end
    
    query
  end
  
  # テスト用のIssueセットを作成（異なる日付範囲）
  def create_test_issue_set(project, user)
    today = Date.today
    
    # 範囲内のIssue
    in_range_issue = Issue.create!(
      project: project,
      tracker: project.trackers.first,
      author: user,
      subject: 'In Range Issue',
      start_date: today,
      due_date: today + 30.days,
      status: IssueStatus.first,
      priority: IssuePriority.first
    )
    
    # 範囲外のIssue（未来）
    future_issue = Issue.create!(
      project: project,
      tracker: project.trackers.first,
      author: user,
      subject: 'Future Issue',
      start_date: today + 180.days,
      due_date: today + 210.days,
      status: IssueStatus.first,
      priority: IssuePriority.first
    )
    
    # 範囲外のIssue（過去）
    past_issue = Issue.create!(
      project: project,
      tracker: project.trackers.first,
      author: user,
      subject: 'Past Issue',
      start_date: today - 180.days,
      due_date: today - 150.days,
      status: IssueStatus.first,
      priority: IssuePriority.first
    )
    
    # 日付なしのIssue
    no_date_issue = Issue.create!(
      project: project,
      tracker: project.trackers.first,
      author: user,
      subject: 'No Date Issue',
      status: IssueStatus.first,
      priority: IssuePriority.first
    )
    
    {
      in_range: in_range_issue,
      future: future_issue,
      past: past_issue,
      no_date: no_date_issue,
      all: [in_range_issue, future_issue, past_issue, no_date_issue]
    }
  end
  
  # APIレスポンスのパフォーマンス測定
  def measure_api_performance(controller, action, params = {})
    measure_performance("API #{controller}##{action}") do
      case action.to_s
      when 'data'
        get :data, params: params
      when 'filters'
        get :filters, params: params
      else
        send(action, params: params)
      end
    end
  end
  
  # テストデータのクリーンアップ
  def cleanup_test_data(project = nil)
    if project
      # 特定プロジェクトのテストデータのみクリーンアップ
      Issue.where(project: project, subject: /Test|Bulk|Range/).destroy_all
    else
      # 全テストデータをクリーンアップ
      Issue.where(subject: /Test|Bulk|Range/).destroy_all
    end
  end
  
  # コントローラーテスト用のセットアップ
  def setup_controller_test(user, project)
    @controller ||= ReactGanttChartController.new
    @controller.instance_variable_set(:@project, project)
    
    # セッションのセットアップ
    session[:user_id] = user.id if respond_to?(:session)
    
    @controller
  end
  
  # パフォーマンステスト用のベンチマーク期待値
  def expect_gantt_performance(&block)
    performance_data = measure_performance("Gantt Performance Test", &block)
    
    # 一般的な期待値
    expect(performance_data[:wall_time]).to be < 3000 # 3秒以内
    expect(performance_data[:memory_delta]).to be < 100_000 # 100MB以内
    
    performance_data
  end
  
  # JSON レスポンスのデバッグ出力
  def debug_gantt_response(response, title = "Gantt Response")
    return unless ENV['DEBUG_TESTS']
    
    puts "\n=== #{title} ==="
    if response.content_type&.include?('json')
      json = JSON.parse(response.body)
      puts "Tasks count: #{json['tasks']&.size || 0}"
      puts "Links count: #{json['links']&.size || 0}"
      puts "Meta: #{json['meta']}"
      puts "Performance: #{json['performance']}" if json['performance']
    else
      puts "Response: #{response.body[0..200]}..."
    end
    puts "=" * (title.length + 8)
  end
end

RSpec.configure do |config|
  config.include GanttTestHelpers
  
  # テスト後のクリーンアップ
  config.after(:each) do
    cleanup_test_data if respond_to?(:cleanup_test_data)
  end
end