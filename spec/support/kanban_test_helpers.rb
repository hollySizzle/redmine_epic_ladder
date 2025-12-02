# frozen_string_literal: true

# Release Kanban プラグインのテストヘルパー
# 7つのコンポーネントのテスト支援機能を提供
module KanbanTestHelpers
  # ===== テストデータ生成 =====

  # プロジェクトとユーザーの基本セットアップ
  def setup_kanban_project
    @project = Project.create!(
      name: 'Test Kanban Project',
      identifier: 'test-kanban',
      description: 'Test project for Release Kanban'
    )

    @user = User.create!(
      login: 'kanban_user',
      firstname: 'Kanban',
      lastname: 'User',
      mail: 'kanban@example.com',
      status: User::STATUS_ACTIVE
    )

    # プロジェクトメンバーとして追加
    Member.create!(
      project: @project,
      user: @user,
      roles: [Role.find_by(name: 'Manager') || create_test_role]
    )

    User.current = @user
  end

  # 必要なトラッカーを作成
  def setup_kanban_trackers
    @trackers = {}
    %w[Epic Feature UserStory Task Test Bug].each_with_index do |name, index|
      @trackers[name.downcase.to_sym] = Tracker.create!(
        name: name,
        position: index + 1,
        is_in_chlog: false,
        is_in_roadmap: true
      )
    end
    @trackers
  end

  # 必要なステータスを作成
  def setup_kanban_statuses
    @statuses = {}
    status_configs = [
      { name: 'New', is_closed: false },
      { name: 'Open', is_closed: false },
      { name: 'Ready', is_closed: false },
      { name: 'In Progress', is_closed: false },
      { name: 'Review', is_closed: false },
      { name: 'Ready for Test', is_closed: false },
      { name: 'Testing', is_closed: false },
      { name: 'QA', is_closed: false },
      { name: 'Resolved', is_closed: true },
      { name: 'Closed', is_closed: true }
    ]

    status_configs.each_with_index do |config, index|
      @statuses[config[:name].downcase.gsub(/\s+/, '_').to_sym] = IssueStatus.create!(
        name: config[:name],
        position: index + 1,
        is_closed: config[:is_closed]
      )
    end
    @statuses
  end

  # バージョンを作成
  def setup_kanban_versions
    @versions = {}
    ['v1.0', 'v1.1', 'v2.0'].each do |version_name|
      @versions[version_name.gsub('.', '_').to_sym] = Version.create!(
        project: @project,
        name: version_name,
        description: "Test version #{version_name}",
        effective_date: 1.month.from_now
      )
    end
    @versions
  end

  # 階層構造のイシューを作成
  def create_kanban_hierarchy
    setup_kanban_trackers
    setup_kanban_statuses

    # Epic作成
    @epic = Issue.create!(
      project: @project,
      tracker: @trackers[:epic],
      status: @statuses[:open],
      subject: 'Test Epic',
      description: 'Test Epic for Release Kanban',
      author: @user,
      priority: IssuePriority.first || create_test_priority
    )

    # Feature作成
    @feature = Issue.create!(
      project: @project,
      tracker: @trackers[:feature],
      status: @statuses[:in_progress],
      subject: 'Test Feature',
      description: 'Test Feature for Release Kanban',
      author: @user,
      parent: @epic,
      priority: IssuePriority.first || create_test_priority
    )

    # UserStory作成
    @user_story = Issue.create!(
      project: @project,
      tracker: @trackers[:userstory],
      status: @statuses[:ready],
      subject: 'Test UserStory',
      description: 'Test UserStory for Release Kanban',
      author: @user,
      parent: @feature,
      assigned_to: @user,
      priority: IssuePriority.first || create_test_priority
    )

    # Task作成
    @task = Issue.create!(
      project: @project,
      tracker: @trackers[:task],
      status: @statuses[:new],
      subject: 'Test Task',
      description: 'Test Task for Release Kanban',
      author: @user,
      parent: @user_story,
      assigned_to: @user,
      priority: IssuePriority.first || create_test_priority
    )

    # Test作成
    @test_issue = Issue.create!(
      project: @project,
      tracker: @trackers[:test],
      status: @statuses[:new],
      subject: 'Test: Test UserStory',
      description: 'Test issue for UserStory',
      author: @user,
      parent: @user_story,
      priority: IssuePriority.first || create_test_priority
    )

    {
      epic: @epic,
      feature: @feature,
      user_story: @user_story,
      task: @task,
      test: @test_issue
    }
  end

  # ===== APIテスト支援 =====

  # APIクライアントのモック
  def mock_api_client(project_id)
    double('ApiClient').tap do |client|
      allow(client).to receive(:getKanbanData).and_return(mock_kanban_data)
      allow(client).to receive(:transitionIssue).and_return({ success: true })
      allow(client).to receive(:testConnection).and_return({ status: 'ok' })
    end
  end

  # モックカンバンデータ
  def mock_kanban_data
    {
      project: { id: @project&.id || 1, name: 'Test Project' },
      columns: [
        { id: 'backlog', title: 'バックログ', statuses: ['New', 'Open'] },
        { id: 'in_progress', title: '進行中', statuses: ['In Progress'] },
        { id: 'done', title: '完了', statuses: ['Resolved', 'Closed'] }
      ],
      issues: [
        {
          id: 1,
          subject: 'Test Issue',
          tracker: 'UserStory',
          status: 'New',
          column: 'backlog'
        }
      ],
      statistics: { by_tracker: { UserStory: 1 } },
      metadata: { total_issues: 1 }
    }
  end

  # ===== 検証ヘルパー =====

  # TrackerHierarchy の検証
  def verify_tracker_hierarchy(child_tracker, parent_tracker)
    EpicLadder::TrackerHierarchy.valid_parent?(child_tracker, parent_tracker)
  end

  # StateTransition の検証
  def verify_state_transition(issue, target_column)
    result = Kanban::StateTransitionService.transition_to_column(issue, target_column)
    !result[:error]
  end

  # リリース準備度の検証
  def verify_release_readiness(user_story)
    result = Kanban::ValidationGuardService.validate_release_readiness(user_story)
    result[:release_ready]
  end

  # ===== クリーンアップ =====

  def cleanup_kanban_test_data
    # リレーションを削除
    IssueRelation.where(issue_from: [@epic, @feature, @user_story, @task, @test_issue]).delete_all if defined?(@epic)
    IssueRelation.where(issue_to: [@epic, @feature, @user_story, @task, @test_issue]).delete_all if defined?(@epic)

    # イシューを削除
    [@test_issue, @task, @user_story, @feature, @epic].compact.each(&:destroy)

    # その他のリソースを削除
    @versions&.values&.each(&:destroy)
    @project&.destroy
    @user&.destroy unless @user&.login == 'admin' # adminユーザーは削除しない
  end

  private

  def create_test_role
    Role.create!(
      name: 'Test Kanban Role',
      position: 1,
      assignable: true,
      permissions: [:view_issues, :edit_issues, :add_issues, :delete_issues, :manage_versions]
    )
  end

  def create_test_priority
    IssuePriority.create!(
      name: 'Normal',
      position: 1,
      is_default: true
    )
  end
end

# RSpecの設定に組み込み
RSpec.configure do |config|
  config.include KanbanTestHelpers

  # テスト前後の処理
  config.before(:each, type: :feature) do
    setup_kanban_project
  end

  config.after(:each, type: :feature) do
    cleanup_kanban_test_data
  end
end