require 'test_helper'

class GanttDataBuilderTest < ActiveSupport::TestCase
  def setup
    @project = Project.new(id: 1, name: 'Test Project', identifier: 'test-project')
    @user = User.new(id: 1, firstname: 'Test', lastname: 'User', login: 'testuser')
    @builder = RedmineReactGanttChart::GanttDataBuilder.new(@project, @user)
  end

  test 'should initialize with project and user' do
    assert_equal @project, @builder.project
    assert_equal @user, @builder.user
  end

  test 'should build gantt data from issues' do
    # モックissueを作成
    issue = Issue.new(
      id: 1,
      subject: 'Test Issue',
      start_date: Date.new(2024, 1, 1),
      due_date: Date.new(2024, 1, 5),
      done_ratio: 50,
      parent_id: nil,
      tracker_id: 1,
      status_id: 1,
      priority_id: 1,
      assigned_to_id: 1
    )
    
    # モックtracker, status, priorityを作成
    tracker = Tracker.new(id: 1, name: 'Bug')
    status = IssueStatus.new(id: 1, name: 'New')
    priority = IssuePriority.new(id: 1, name: 'Normal')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(@user)
    
    issues = [issue]
    
    result = @builder.build(issues)
    
    assert_equal 1, result[:tasks].length
    
    task = result[:tasks].first
    assert_equal 1, task[:id]
    assert_equal 'Test Issue', task[:text]
    assert_equal '2024-01-01', task[:start]
    assert_equal '2024-01-05', task[:end]
    assert_equal 0.5, task[:progress]
    assert_equal 0, task[:parent]
    assert_equal true, task[:editable]
    assert_equal false, task[:is_closed]
    assert_equal 'Bug', task[:tracker_name]
    assert_equal 'New', task[:status_name]
    assert_equal 'Normal', task[:priority_name]
    assert_equal 'Test User', task[:assignee]
    assert_equal '1', task[:issue_id]
  end

  test 'should handle parent-child relationships' do
    parent_issue = Issue.new(
      id: 1,
      subject: 'Parent Issue',
      start_date: Date.new(2024, 1, 1),
      due_date: Date.new(2024, 1, 10),
      done_ratio: 30,
      parent_id: nil
    )
    
    child_issue = Issue.new(
      id: 2,
      subject: 'Child Issue',
      start_date: Date.new(2024, 1, 3),
      due_date: Date.new(2024, 1, 7),
      done_ratio: 70,
      parent_id: 1
    )
    
    [parent_issue, child_issue].each do |issue|
      tracker = Tracker.new(id: 1, name: 'Task')
      status = IssueStatus.new(id: 1, name: 'In Progress')
      priority = IssuePriority.new(id: 1, name: 'Normal')
      
      issue.stubs(:tracker).returns(tracker)
      issue.stubs(:status).returns(status)
      issue.stubs(:priority).returns(priority)
      issue.stubs(:assigned_to).returns(@user)
    end
    
    issues = [parent_issue, child_issue]
    
    result = @builder.build(issues)
    
    assert_equal 2, result[:tasks].length
    
    parent_task = result[:tasks].find { |t| t[:id] == 1 }
    child_task = result[:tasks].find { |t| t[:id] == 2 }
    
    assert_equal 0, parent_task[:parent]
    assert_equal 1, child_task[:parent]
  end

  test 'should handle issues with custom fields' do
    issue = Issue.new(
      id: 1,
      subject: 'Issue with Custom Fields',
      start_date: Date.new(2024, 1, 1),
      due_date: Date.new(2024, 1, 5),
      done_ratio: 25
    )
    
    # モックカスタムフィールドを作成
    custom_field = CustomField.new(id: 1, name: 'Custom Field 1', field_format: 'string')
    custom_value = CustomValue.new(custom_field: custom_field, value: 'Custom Value')
    
    issue.stubs(:custom_field_values).returns([custom_value])
    
    # その他のモック設定
    tracker = Tracker.new(id: 1, name: 'Feature')
    status = IssueStatus.new(id: 1, name: 'Open')
    priority = IssuePriority.new(id: 1, name: 'High')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(@user)
    
    issues = [issue]
    
    result = @builder.build(issues)
    
    task = result[:tasks].first
    assert_not_nil task[:custom_fields]
    assert_equal 'Custom Value', task[:custom_fields]['cf_1'][:value]
    assert_equal 'Custom Field 1', task[:custom_fields]['cf_1'][:name]
    assert_equal 'string', task[:custom_fields]['cf_1'][:type]
  end

  test 'should handle closed issues' do
    issue = Issue.new(
      id: 1,
      subject: 'Closed Issue',
      start_date: Date.new(2024, 1, 1),
      due_date: Date.new(2024, 1, 5),
      done_ratio: 100
    )
    
    # クローズされたステータスをモック
    status = IssueStatus.new(id: 1, name: 'Closed', is_closed: true)
    tracker = Tracker.new(id: 1, name: 'Bug')
    priority = IssuePriority.new(id: 1, name: 'Normal')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(@user)
    
    issues = [issue]
    
    result = @builder.build(issues)
    
    task = result[:tasks].first
    assert_equal true, task[:is_closed]
    assert_equal 'Closed', task[:status_name]
  end

  test 'should handle missing dates' do
    issue = Issue.new(
      id: 1,
      subject: 'Issue without dates',
      start_date: nil,
      due_date: nil,
      done_ratio: 0
    )
    
    # モック設定
    tracker = Tracker.new(id: 1, name: 'Task')
    status = IssueStatus.new(id: 1, name: 'New')
    priority = IssuePriority.new(id: 1, name: 'Normal')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(@user)
    
    issues = [issue]
    
    result = @builder.build(issues)
    
    task = result[:tasks].first
    
    # デフォルト値が設定されることを確認
    assert_not_nil task[:start]
    assert_not_nil task[:end]
    assert task[:start] <= task[:end]
  end

  test 'should handle unassigned issues' do
    issue = Issue.new(
      id: 1,
      subject: 'Unassigned Issue',
      start_date: Date.new(2024, 1, 1),
      due_date: Date.new(2024, 1, 5),
      done_ratio: 0,
      assigned_to_id: nil
    )
    
    # モック設定
    tracker = Tracker.new(id: 1, name: 'Task')
    status = IssueStatus.new(id: 1, name: 'New')
    priority = IssuePriority.new(id: 1, name: 'Normal')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(nil)
    
    issues = [issue]
    
    result = @builder.build(issues)
    
    task = result[:tasks].first
    assert_equal '', task[:assignee]
  end

  test 'should build links from issue relations' do
    issue1 = Issue.new(id: 1, subject: 'Issue 1')
    issue2 = Issue.new(id: 2, subject: 'Issue 2')
    
    # モック関係を作成
    relation = IssueRelation.new(
      issue_from_id: 1,
      issue_to_id: 2,
      relation_type: 'precedes'
    )
    
    Issue.stubs(:find).returns(issue1)
    IssueRelation.stubs(:where).returns([relation])
    
    result = @builder.build([issue1, issue2])
    
    assert_equal 1, result[:links].length
    
    link = result[:links].first
    assert_equal 1, link[:source]
    assert_equal 2, link[:target]
    assert_equal '0', link[:type] # precedes relation
  end

  test 'should handle different relation types' do
    issue1 = Issue.new(id: 1, subject: 'Issue 1')
    issue2 = Issue.new(id: 2, subject: 'Issue 2')
    
    # 異なる関係タイプをテスト
    relation_types = {
      'precedes' => '0',
      'follows' => '0',
      'relates' => '0',
      'duplicates' => '0',
      'blocks' => '0',
      'blocked' => '0'
    }
    
    relation_types.each do |relation_type, expected_type|
      relation = IssueRelation.new(
        issue_from_id: 1,
        issue_to_id: 2,
        relation_type: relation_type
      )
      
      Issue.stubs(:find).returns(issue1)
      IssueRelation.stubs(:where).returns([relation])
      
      result = @builder.build([issue1, issue2])
      
      link = result[:links].first
      assert_equal expected_type, link[:type]
    end
  end

  test 'should validate task data' do
    # 無効なデータでのテスト
    issue = Issue.new(
      id: nil, # 無効なID
      subject: '', # 空の件名
      start_date: Date.new(2024, 1, 10),
      due_date: Date.new(2024, 1, 5), # 開始日より前の終了日
      done_ratio: 150 # 無効な進捗率
    )
    
    # モック設定
    tracker = Tracker.new(id: 1, name: 'Task')
    status = IssueStatus.new(id: 1, name: 'New')
    priority = IssuePriority.new(id: 1, name: 'Normal')
    
    issue.stubs(:tracker).returns(tracker)
    issue.stubs(:status).returns(status)
    issue.stubs(:priority).returns(priority)
    issue.stubs(:assigned_to).returns(@user)
    
    issues = [issue]
    
    # エラーが発生せずにデータが正規化されることを確認
    result = @builder.build(issues)
    
    task = result[:tasks].first
    assert_not_nil task[:id]
    assert_not_equal '', task[:text]
    assert task[:start] <= task[:end]
    assert task[:progress] >= 0
    assert task[:progress] <= 1
  end
end