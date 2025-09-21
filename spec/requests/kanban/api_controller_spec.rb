# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::ApiController, type: :request do
  include KanbanTestHelpers

  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE, admin: false) }
  let!(:admin_user) { User.create!(login: 'admin', firstname: 'Admin', lastname: 'User', mail: 'admin@test.com', status: User::STATUS_ACTIVE, admin: true) }
  let!(:project) { Project.create!(name: 'Test Project', identifier: 'test-api-kanban') }

  # ステータス作成
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false) }
  let!(:status_open) { IssueStatus.create!(name: 'Open', is_closed: false) }
  let!(:status_ready) { IssueStatus.create!(name: 'Ready', is_closed: false) }
  let!(:status_in_progress) { IssueStatus.create!(name: 'In Progress', is_closed: false) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true) }
  let!(:status_closed) { IssueStatus.create!(name: 'Closed', is_closed: true) }

  # 優先度作成
  let!(:priority_normal) { IssuePriority.create!(name: 'Normal', position: 1, is_default: true) }
  let!(:priority_high) { IssuePriority.create!(name: 'High', position: 2) }

  # トラッカー作成
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 1, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 2, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 3, is_in_chlog: false) }

  # バージョン作成
  let!(:version_v1) { Version.create!(project: project, name: 'v1.0', effective_date: 1.month.from_now) }

  # ロールと権限設定
  let!(:role) { Role.create!(name: 'Kanban User', permissions: [:view_issues, :edit_issues, :add_issues, :delete_issues]) }

  # UserStory作成
  let!(:user_story) do
    Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_new,
      subject: 'Test UserStory',
      description: 'Test UserStory description',
      author: user,
      assigned_to: user,
      priority: priority_normal
    )
  end

  # Task作成
  let!(:task) do
    Issue.create!(
      project: project,
      tracker: task_tracker,
      status: status_new,
      subject: 'Test Task',
      author: user,
      parent: user_story,
      priority: priority_normal
    )
  end

  before do
    # プロジェクトメンバーとして追加
    Member.create!(
      project: project,
      user: user,
      roles: [role]
    )

    # トラッカーをプロジェクトに関連付け
    project.trackers = [user_story_tracker, task_tracker, test_tracker]

    # ワークフロー設定
    [user_story_tracker, task_tracker, test_tracker].each do |tracker|
      [status_new, status_open, status_ready, status_in_progress, status_resolved, status_closed].each do |from_status|
        [status_new, status_open, status_ready, status_in_progress, status_resolved, status_closed].each do |to_status|
          WorkflowTransition.find_or_create_by(
            tracker: tracker,
            role: role,
            old_status: from_status,
            new_status: to_status
          )
        end
      end
    end

    # ログイン
    User.current = user
  end

  describe 'GET /kanban/api/test_connection' do
    it '接続テストが成功する' do
      get '/kanban/api/test_connection'

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
      expect(json['user']).to eq(user.name)
      expect(json['version']).to eq('1.0.0-skeleton')
      expect(json['timestamp']).to be_present
    end

    it 'ログインしていなくても接続テストは成功する' do
      User.current = nil

      get '/kanban/api/test_connection'

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
      expect(json['user']).to be_nil
    end
  end

  describe 'GET /kanban/api/kanban_data' do
    context '正常ケース' do
      it '正しいJSON構造でカンバンデータを返す' do
        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        # プロジェクト情報
        expect(json['project']['id']).to eq(project.id)
        expect(json['project']['name']).to eq(project.name)
        expect(json['project']['identifier']).to eq(project.identifier)

        # カラム構造
        expect(json['columns']).to be_an(Array)
        expect(json['columns'].length).to eq(6)
        backlog_column = json['columns'].find { |c| c['id'] == 'backlog' }
        expect(backlog_column['title']).to eq('バックログ')
        expect(backlog_column['statuses']).to include('New', 'Open')

        # イシュー情報
        expect(json['issues']).to be_an(Array)
        expect(json['issues'].length).to eq(2) # UserStory + Task

        user_story_json = json['issues'].find { |i| i['id'] == user_story.id }
        expect(user_story_json['subject']).to eq('Test UserStory')
        expect(user_story_json['tracker']).to eq('UserStory')
        expect(user_story_json['status']).to eq('New')
        expect(user_story_json['hierarchy_level']).to eq(3)
        expect(user_story_json['column']).to eq('backlog')

        # 統計情報
        expect(json['statistics']['by_tracker']['UserStory']).to eq(1)
        expect(json['statistics']['by_tracker']['Task']).to eq(1)
        expect(json['statistics']['by_status']['New']).to eq(2)

        # メタデータ
        expect(json['metadata']['total_issues']).to eq(2)
        expect(json['metadata']['last_updated']).to be_present
      end

      it 'イシューのカラム判定が正しく動作する' do
        user_story.update!(status: status_ready)
        task.update!(status: status_in_progress)

        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        user_story_json = json['issues'].find { |i| i['id'] == user_story.id }
        expect(user_story_json['column']).to eq('ready')

        task_json = json['issues'].find { |i| i['id'] == task.id }
        expect(task_json['column']).to eq('in_progress')
      end

      it 'バージョン・担当者情報が含まれる' do
        user_story.update!(fixed_version: version_v1, assigned_to: user)

        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        user_story_json = json['issues'].find { |i| i['id'] == user_story.id }
        expect(user_story_json['fixed_version']).to eq('v1.0')
        expect(user_story_json['assigned_to']).to eq(user.name)
      end
    end

    context '権限・認証エラー' do
      it 'ログインしていない場合は認証エラー' do
        User.current = nil

        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'プロジェクトのview_issues権限がない場合はアクセス拒否' do
        # 権限のないロールに変更
        no_permission_role = Role.create!(name: 'No Permission', permissions: [])
        member = Member.find_by(user: user, project: project)
        member.update!(roles: [no_permission_role])

        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:forbidden)
      end

      it 'プロジェクトが存在しない場合は404' do
        get "/kanban/api/kanban_data", params: { project_id: 999999 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context '異常ケース' do
      it 'データベースエラーが発生した場合は500エラー' do
        allow(Project).to receive(:find).and_raise(StandardError.new('Database error'))

        get "/kanban/api/kanban_data", params: { project_id: project.id }

        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Database error')
      end
    end
  end

  describe 'POST /kanban/api/transition_issue' do
    context '正常ケース' do
      it 'UserStoryの状態遷移が成功する' do
        post "/kanban/api/transition_issue", params: {
          project_id: project.id,
          issue_id: user_story.id,
          target_column: 'ready'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['issue']['status']).to eq('Ready')
        expect(json['transition']['success']).to be true

        user_story.reload
        expect(user_story.status.name).to eq('Ready')
      end

      it '遷移履歴がレスポンスに含まれる' do
        post "/kanban/api/transition_issue", params: {
          project_id: project.id,
          issue_id: user_story.id,
          target_column: 'in_progress'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['transition']['old_status']).to eq('New')
        expect(json['transition']['new_status']).to be_in(['In Progress', 'Assigned'])
      end
    end

    context 'ブロック条件によるエラー' do
      let!(:incomplete_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Incomplete Task',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it 'ブロック条件違反時はエラーを返す' do
        post "/kanban/api/transition_issue", params: {
          project_id: project.id,
          issue_id: user_story.id,
          target_column: 'done'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('未完了のTask')
      end
    end

    context '異常ケース' do
      it 'イシューが存在しない場合は404エラー' do
        post "/kanban/api/transition_issue", params: {
          project_id: project.id,
          issue_id: 999999,
          target_column: 'ready'
        }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('イシューが見つかりません')
      end

      it '不正なカラム指定時はエラーを返す' do
        post "/kanban/api/transition_issue", params: {
          project_id: project.id,
          issue_id: user_story.id,
          target_column: 'invalid_column'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('不正なカラム')
      end
    end
  end

  describe 'POST /kanban/api/assign_version' do
    context '正常ケース' do
      it 'UserStoryにバージョンを割り当て、子要素に伝播する' do
        post "/kanban/api/assign_version", params: {
          project_id: project.id,
          issue_id: user_story.id,
          version_id: version_v1.id
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['issue']['fixed_version']).to eq('v1.0')
        expect(json['propagation']['propagated_count']).to eq(1) # Task

        task.reload
        expect(task.fixed_version).to eq(version_v1)
      end

      it 'バージョンnilで削除する' do
        user_story.update!(fixed_version: version_v1)
        task.update!(fixed_version: version_v1)

        post "/kanban/api/assign_version", params: {
          project_id: project.id,
          issue_id: user_story.id,
          version_id: ''
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['issue']['fixed_version']).to be_nil

        task.reload
        expect(task.fixed_version).to be_nil
      end
    end

    context '異常ケース' do
      it 'UserStory以外では エラーを返す' do
        post "/kanban/api/assign_version", params: {
          project_id: project.id,
          issue_id: task.id,
          version_id: version_v1.id
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UserStoryではありません')
      end

      it 'バージョンが存在しない場合は404エラー' do
        post "/kanban/api/assign_version", params: {
          project_id: project.id,
          issue_id: user_story.id,
          version_id: 999999
        }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('リソースが見つかりません')
      end
    end
  end

  describe 'POST /kanban/api/generate_test' do
    context '正常ケース' do
      it 'UserStoryに対してTestを自動生成する' do
        post "/kanban/api/generate_test", params: {
          project_id: project.id,
          user_story_id: user_story.id
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['test_issue']['subject']).to eq('Test: Test UserStory')
        expect(json['test_issue']['tracker']).to eq('Test')
        expect(json['relation_created']).to be true

        # 実際にTestが作成されているか確認
        test_issue = Issue.find(json['test_issue']['id'])
        expect(test_issue.parent).to eq(user_story)
        expect(test_issue.tracker.name).to eq('Test')
      end

      it '既存Testがある場合は新規作成しない' do
        existing_test = Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Existing Test',
          author: user,
          parent: user_story,
          priority: priority_normal
        )

        post "/kanban/api/generate_test", params: {
          project_id: project.id,
          user_story_id: user_story.id
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['test_issue']['id']).to eq(existing_test.id)
        expect(json['relation_created']).to be_nil
      end

      it 'forceフラグで既存Testを再作成する' do
        existing_test = Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_new,
          subject: 'Existing Test',
          author: user,
          parent: user_story,
          priority: priority_normal
        )

        post "/kanban/api/generate_test", params: {
          project_id: project.id,
          user_story_id: user_story.id,
          force: true
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['test_issue']['id']).not_to eq(existing_test.id)
        expect(json['test_issue']['subject']).to eq('Test: Test UserStory')
        expect(json['relation_created']).to be true
      end
    end

    context '異常ケース' do
      it 'UserStoryが存在しない場合は404エラー' do
        post "/kanban/api/generate_test", params: {
          project_id: project.id,
          user_story_id: 999999
        }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UserStoryが見つかりません')
      end

      it 'UserStory以外では エラーを返す' do
        post "/kanban/api/generate_test", params: {
          project_id: project.id,
          user_story_id: task.id
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UserStoryではありません')
      end
    end
  end

  describe 'GET /kanban/api/validate_release' do
    context '正常ケース' do
      let!(:completed_task) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_resolved,
          subject: 'Completed Task',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      let!(:passed_test) do
        Issue.create!(
          project: project,
          tracker: test_tracker,
          status: status_resolved,
          subject: 'Passed Test',
          author: user,
          parent: user_story,
          priority: priority_normal
        )
      end

      it 'リリース準備検証の結果を返す' do
        get "/kanban/api/validate_release", params: {
          project_id: project.id,
          user_story_id: user_story.id
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['release_ready']).to be true
        expect(json['summary']).to eq('3/3層のガードを通過')

        # 各層の検証結果
        expect(json['validation_results']['task_completion']['passed']).to be true
        expect(json['validation_results']['test_validation']['passed']).to be true
        expect(json['validation_results']['bug_resolution']['passed']).to be true
      end

      it 'ブロッキング要因がある場合は詳細を返す' do
        incomplete_task = Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: 'Incomplete Task',
          author: user,
          parent: user_story,
          priority: priority_normal
        )

        get "/kanban/api/validate_release", params: {
          project_id: project.id,
          user_story_id: user_story.id
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['release_ready']).to be false
        expect(json['blocking_issues']).not_to be_empty

        task_result = json['validation_results']['task_completion']
        expect(task_result['passed']).to be false
        expect(task_result['issues']).to have(1).item
        expect(task_result['issues'][0]['subject']).to eq('Incomplete Task')
      end
    end

    context '異常ケース' do
      it 'UserStoryが存在しない場合は404エラー' do
        get "/kanban/api/validate_release", params: {
          project_id: project.id,
          user_story_id: 999999
        }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UserStoryが見つかりません')
      end
    end
  end

  describe 'ルーティングの確認' do
    it '全てのAPIエンドポイントが正しくルーティングされる' do
      expect(get: '/kanban/api/test_connection').to route_to(
        controller: 'kanban/api',
        action: 'test_connection'
      )

      expect(get: '/kanban/api/kanban_data').to route_to(
        controller: 'kanban/api',
        action: 'kanban_data'
      )

      expect(post: '/kanban/api/transition_issue').to route_to(
        controller: 'kanban/api',
        action: 'transition_issue'
      )

      expect(post: '/kanban/api/assign_version').to route_to(
        controller: 'kanban/api',
        action: 'assign_version'
      )

      expect(post: '/kanban/api/generate_test').to route_to(
        controller: 'kanban/api',
        action: 'generate_test'
      )

      expect(get: '/kanban/api/validate_release').to route_to(
        controller: 'kanban/api',
        action: 'validate_release'
      )
    end
  end

  describe 'パフォーマンステスト', :performance do
    it '大量のイシューでもkanban_dataが高速に返される' do
      # 100個のイシューを作成
      100.times do |i|
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status_new,
          subject: "Task #{i}",
          author: user,
          priority: priority_normal
        )
      end

      expect do
        get "/kanban/api/kanban_data", params: { project_id: project.id }
      end.to perform_under(500).ms

      expect(response).to have_http_status(:success)
    end
  end

  describe 'セキュリティテスト' do
    it 'SQLインジェクションの脆弱性がない' do
      malicious_id = "1; DROP TABLE issues; --"

      get "/kanban/api/kanban_data", params: { project_id: malicious_id }

      # エラーは発生するが、SQLインジェクションは実行されない
      expect(response).to have_http_status(:not_found)
    end

    it 'XSS攻撃対策されている' do
      malicious_subject = "<script>alert('XSS')</script>"
      xss_issue = Issue.create!(
        project: project,
        tracker: user_story_tracker,
        status: status_new,
        subject: malicious_subject,
        author: user,
        priority: priority_normal
      )

      get "/kanban/api/kanban_data", params: { project_id: project.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      issue_json = json['issues'].find { |i| i['id'] == xss_issue.id }
      expect(issue_json['subject']).to eq(malicious_subject) # エスケープはフロントエンドで実施
    end
  end
end