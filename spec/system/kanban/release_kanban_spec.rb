# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release Kanban System', type: :system, js: true do
  include KanbanTestHelpers

  let!(:admin_user) { User.create!(login: 'admin', firstname: 'Admin', lastname: 'User', mail: 'admin@test.com', status: User::STATUS_ACTIVE, admin: true) }
  let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE, admin: false) }
  let!(:project) { Project.create!(name: 'Release Kanban Project', identifier: 'release-kanban-test') }

  # ステータス作成
  let!(:status_new) { IssueStatus.create!(name: 'New', is_closed: false, position: 1) }
  let!(:status_open) { IssueStatus.create!(name: 'Open', is_closed: false, position: 2) }
  let!(:status_ready) { IssueStatus.create!(name: 'Ready', is_closed: false, position: 3) }
  let!(:status_in_progress) { IssueStatus.create!(name: 'In Progress', is_closed: false, position: 4) }
  let!(:status_review) { IssueStatus.create!(name: 'Review', is_closed: false, position: 5) }
  let!(:status_testing) { IssueStatus.create!(name: 'Testing', is_closed: false, position: 6) }
  let!(:status_resolved) { IssueStatus.create!(name: 'Resolved', is_closed: true, position: 7) }
  let!(:status_closed) { IssueStatus.create!(name: 'Closed', is_closed: true, position: 8) }

  # 優先度作成
  let!(:priority_normal) { IssuePriority.create!(name: 'Normal', position: 1, is_default: true) }
  let!(:priority_high) { IssuePriority.create!(name: 'High', position: 2) }

  # トラッカー作成
  let!(:epic_tracker) { Tracker.create!(name: 'Epic', position: 1, is_in_chlog: false) }
  let!(:feature_tracker) { Tracker.create!(name: 'Feature', position: 2, is_in_chlog: false) }
  let!(:user_story_tracker) { Tracker.create!(name: 'UserStory', position: 3, is_in_chlog: false) }
  let!(:task_tracker) { Tracker.create!(name: 'Task', position: 4, is_in_chlog: false) }
  let!(:test_tracker) { Tracker.create!(name: 'Test', position: 5, is_in_chlog: false) }
  let!(:bug_tracker) { Tracker.create!(name: 'Bug', position: 6, is_in_chlog: false) }

  # バージョン作成
  let!(:version_v1) { Version.create!(project: project, name: 'v1.0', effective_date: 1.month.from_now) }
  let!(:version_v2) { Version.create!(project: project, name: 'v2.0', effective_date: 2.months.from_now) }

  # ロール作成
  let!(:role) { Role.create!(name: 'Kanban Manager', permissions: [:view_issues, :edit_issues, :add_issues, :delete_issues, :manage_versions, :view_kanban, :manage_kanban]) }

  before do
    # プロジェクトにトラッカーを関連付け
    project.trackers = [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]

    # プロジェクトメンバーとして追加
    Member.create!(
      project: project,
      user: user,
      roles: [role]
    )

    # ワークフロー設定
    all_trackers = [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
    all_statuses = [status_new, status_open, status_ready, status_in_progress, status_review, status_testing, status_resolved, status_closed]

    all_trackers.each do |tracker|
      all_statuses.each do |from_status|
        all_statuses.each do |to_status|
          WorkflowTransition.find_or_create_by(
            tracker: tracker,
            role: role,
            old_status: from_status,
            new_status: to_status
          )
        end
      end
    end

    # 階層構造のイシューを作成
    @epic = Issue.create!(
      project: project,
      tracker: epic_tracker,
      status: status_open,
      subject: 'User Authentication Epic',
      description: 'Epic for user authentication features',
      author: user,
      priority: priority_normal
    )

    @feature = Issue.create!(
      project: project,
      tracker: feature_tracker,
      status: status_in_progress,
      subject: 'Login Feature',
      description: 'User login functionality',
      author: user,
      parent: @epic,
      priority: priority_normal
    )

    @user_story = Issue.create!(
      project: project,
      tracker: user_story_tracker,
      status: status_ready,
      subject: 'User can login with email and password',
      description: 'As a user, I want to login with my email and password',
      author: user,
      parent: @feature,
      assigned_to: user,
      priority: priority_normal
    )

    @task = Issue.create!(
      project: project,
      tracker: task_tracker,
      status: status_new,
      subject: 'Implement login form validation',
      description: 'Add client-side validation to login form',
      author: user,
      parent: @user_story,
      assigned_to: user,
      priority: priority_normal
    )

    # Capibaraドライバー設定
    Capybara.default_driver = :selenium_chrome_headless
    Capybara.javascript_driver = :selenium_chrome_headless

    # ユーザーログイン
    login_as(user)
  end

  def login_as(user)
    visit '/login'
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'admin'  # デフォルトパスワード
    click_button 'Login'
  end

  describe 'カンバンボードの基本表示' do
    scenario 'ユーザーがカンバンページにアクセスする' do
      visit "/projects/#{project.identifier}/kanban"

      # ページタイトルの確認
      expect(page).to have_content('Release Kanban')

      # Epic Swimlaneの表示確認
      expect(page).to have_selector('.epic-swimlane', text: 'User Authentication Epic')

      # カンバンカラムの表示確認
      expect(page).to have_selector('.kanban-column[data-column-id="backlog"]')
      expect(page).to have_selector('.kanban-column[data-column-id="ready"]')
      expect(page).to have_selector('.kanban-column[data-column-id="in_progress"]')
      expect(page).to have_selector('.kanban-column[data-column-id="review"]')
      expect(page).to have_selector('.kanban-column[data-column-id="testing"]')
      expect(page).to have_selector('.kanban-column[data-column-id="done"]')

      # イシューカードの表示確認
      expect(page).to have_selector('.issue-card[data-tracker="UserStory"]', text: 'User can login with email and password')
      expect(page).to have_selector('.issue-card[data-tracker="Task"]', text: 'Implement login form validation')
    end

    scenario 'カードの階層情報が正しく表示される' do
      visit "/projects/#{project.identifier}/kanban"

      # UserStoryカードの階層情報
      within('.issue-card[data-tracker="UserStory"]') do
        expect(page).to have_content('UserStory')
        expect(page).to have_content(@user_story.subject)
        expect(page).to have_selector('.hierarchy-level-3')
      end

      # Taskカードの階層情報
      within('.issue-card[data-tracker="Task"]') do
        expect(page).to have_content('Task')
        expect(page).to have_content(@task.subject)
        expect(page).to have_selector('.hierarchy-level-4')
      end
    end
  end

  describe 'ドラッグ&ドロップによる状態遷移' do
    scenario 'ユーザーがカードをドラッグ&ドロップで移動する' do
      visit "/projects/#{project.identifier}/kanban"

      # UserStoryカードをin_progressカラムに移動
      user_story_card = find('.issue-card[data-tracker="UserStory"]')
      in_progress_column = find('.kanban-column[data-column-id="in_progress"]')

      user_story_card.drag_to(in_progress_column)

      # 状態が更新されることを確認
      expect(page).to have_content('In Progress'), 'カードの状態が更新されるべき'

      # データベースの状態も更新されることを確認
      @user_story.reload
      expect(@user_story.status.name).to eq('In Progress')
    end

    scenario 'ブロック条件があるカードは移動が制限される' do
      visit "/projects/#{project.identifier}/kanban"

      # 未完了のTaskがあるUserStoryをdoneカラムに移動しようとする
      user_story_card = find('.issue-card[data-tracker="UserStory"]')
      done_column = find('.kanban-column[data-column-id="done"]')

      user_story_card.drag_to(done_column)

      # エラーメッセージが表示される
      expect(page).to have_content('未完了のTask'), 'ブロック条件のエラーメッセージが表示されるべき'

      # 状態は変更されない
      @user_story.reload
      expect(@user_story.status.name).not_to eq('Resolved')
    end
  end

  describe 'Test自動生成機能' do
    scenario 'UserStoryからTestを自動生成する' do
      visit "/projects/#{project.identifier}/kanban"

      # UserStoryカード内のTest作成ボタンをクリック
      within('.issue-card[data-tracker="UserStory"]') do
        click_button 'Test作成'
      end

      # Testカードが生成されることを確認
      expect(page).to have_selector('.issue-card[data-tracker="Test"]')

      # 作成されたTestカードの内容確認
      within('.issue-card[data-tracker="Test"]') do
        expect(page).to have_content('Test: User can login with email and password')
      end

      # データベースにTestが作成されることを確認
      test_issue = Issue.joins(:tracker).find_by(trackers: { name: 'Test' }, parent: @user_story)
      expect(test_issue).to be_present
      expect(test_issue.subject).to eq('Test: User can login with email and password')
    end

    scenario '既存Testがある場合は新規作成されない' do
      # 事前にTestを作成
      existing_test = Issue.create!(
        project: project,
        tracker: test_tracker,
        status: status_new,
        subject: 'Existing Test',
        author: user,
        parent: @user_story,
        priority: priority_normal
      )

      visit "/projects/#{project.identifier}/kanban"

      # Test作成ボタンをクリック
      within('.issue-card[data-tracker="UserStory"]') do
        click_button 'Test作成'
      end

      # 既存Testの情報が表示される
      expect(page).to have_content('既存のTestが存在します')

      # 新しいTestは作成されない
      test_count = Issue.joins(:tracker).where(trackers: { name: 'Test' }, parent: @user_story).count
      expect(test_count).to eq(1)
    end
  end

  describe 'バージョン管理機能' do
    scenario 'UserStoryにバージョンを割り当てる' do
      visit "/projects/#{project.identifier}/kanban"

      # UserStoryカードのバージョン選択
      within('.issue-card[data-tracker="UserStory"]') do
        select 'v1.0', from: 'version_select'
        click_button '適用'
      end

      # バージョンが表示される
      within('.issue-card[data-tracker="UserStory"]') do
        expect(page).to have_content('v1.0')
      end

      # 子Taskにもバージョンが伝播する
      @task.reload
      expect(@task.fixed_version).to eq(version_v1)

      # 子Taskカードにもバージョンが表示される
      within('.issue-card[data-tracker="Task"]') do
        expect(page).to have_content('v1.0')
      end
    end

    scenario 'バージョン変更が子要素に正しく伝播する' do
      # 事前にv1.0を設定
      @user_story.update!(fixed_version: version_v1)
      @task.update!(fixed_version: version_v1)

      visit "/projects/#{project.identifier}/kanban"

      # v2.0に変更
      within('.issue-card[data-tracker="UserStory"]') do
        select 'v2.0', from: 'version_select'
        click_button '適用'
      end

      # 変更が反映される
      @user_story.reload
      @task.reload
      expect(@user_story.fixed_version).to eq(version_v2)
      expect(@task.fixed_version).to eq(version_v2)
    end
  end

  describe 'リリース準備検証機能' do
    scenario 'リリース準備度の検証結果を表示する' do
      visit "/projects/#{project.identifier}/kanban"

      # UserStoryカードの検証ボタンをクリック
      within('.issue-card[data-tracker="UserStory"]') do
        click_button 'リリース検証'
      end

      # 検証結果モーダルが表示される
      expect(page).to have_selector('.validation-modal')

      # 3層ガードの検証結果が表示される
      within('.validation-modal') do
        expect(page).to have_content('Task完了検証')
        expect(page).to have_content('Test合格検証')
        expect(page).to have_content('重大Bug解決検証')

        # 未完了Taskがある場合の警告
        expect(page).to have_content('未完了のTask: Implement login form validation')
      end
    end

    scenario '全ての条件が満たされた場合のリリース準備完了' do
      # Taskを完了
      @task.update!(status: status_resolved)

      # Testを作成・完了
      test_issue = Issue.create!(
        project: project,
        tracker: test_tracker,
        status: status_resolved,
        subject: 'Test: User can login',
        author: user,
        parent: @user_story,
        priority: priority_normal
      )

      visit "/projects/#{project.identifier}/kanban"

      # 検証実行
      within('.issue-card[data-tracker="UserStory"]') do
        click_button 'リリース検証'
      end

      # リリース準備完了の表示
      within('.validation-modal') do
        expect(page).to have_content('3/3層のガードを通過')
        expect(page).to have_content('リリース準備完了')
        expect(page).to have_selector('.validation-success')
      end
    end
  end

  describe 'フィルタリング機能' do
    scenario 'トラッカーでフィルタリングする' do
      visit "/projects/#{project.identifier}/kanban"

      # トラッカーフィルターを選択
      check 'UserStory'
      uncheck 'Task'

      # UserStoryのみ表示される
      expect(page).to have_selector('.issue-card[data-tracker="UserStory"]')
      expect(page).not_to have_selector('.issue-card[data-tracker="Task"]')
    end

    scenario '担当者でフィルタリングする' do
      visit "/projects/#{project.identifier}/kanban"

      # 担当者フィルターを選択
      select user.name, from: 'assignee_filter'

      # 該当する担当者のカードのみ表示される
      expect(page).to have_selector('.issue-card[data-assignee="' + user.id.to_s + '"]')
    end

    scenario 'バージョンでフィルタリングする' do
      @user_story.update!(fixed_version: version_v1)

      visit "/projects/#{project.identifier}/kanban"

      # バージョンフィルターを選択
      select 'v1.0', from: 'version_filter'

      # 該当するバージョンのカードのみ表示される
      expect(page).to have_selector('.issue-card[data-version="' + version_v1.id.to_s + '"]')
    end
  end

  describe 'Epic Swimlane表示' do
    scenario 'Epicごとにグループ化されて表示される' do
      # 別のEpicとその配下を作成
      another_epic = Issue.create!(
        project: project,
        tracker: epic_tracker,
        status: status_open,
        subject: 'User Profile Epic',
        author: user,
        priority: priority_normal
      )

      another_feature = Issue.create!(
        project: project,
        tracker: feature_tracker,
        status: status_ready,
        subject: 'Profile Management',
        author: user,
        parent: another_epic,
        priority: priority_normal
      )

      visit "/projects/#{project.identifier}/kanban"

      # 各Epicのスイムレーンが表示される
      expect(page).to have_selector('.epic-swimlane', text: 'User Authentication Epic')
      expect(page).to have_selector('.epic-swimlane', text: 'User Profile Epic')

      # 各スイムレーン内に対応するFeatureが表示される
      within('.epic-swimlane', text: 'User Authentication Epic') do
        expect(page).to have_content('Login Feature')
      end

      within('.epic-swimlane', text: 'User Profile Epic') do
        expect(page).to have_content('Profile Management')
      end
    end

    scenario 'Epicが折りたたみ可能' do
      visit "/projects/#{project.identifier}/kanban"

      # Epicヘッダーをクリックして折りたたみ
      within('.epic-swimlane', text: 'User Authentication Epic') do
        click_button 'collapse-epic'
      end

      # コンテンツが非表示になる
      expect(page).not_to have_selector('.issue-card[data-tracker="UserStory"]', visible: true)

      # 再度クリックして展開
      within('.epic-swimlane', text: 'User Authentication Epic') do
        click_button 'expand-epic'
      end

      # コンテンツが再表示される
      expect(page).to have_selector('.issue-card[data-tracker="UserStory"]', visible: true)
    end
  end

  describe 'リアルタイム更新' do
    scenario '他のユーザーの変更がリアルタイムで反映される', :skip_ci do
      visit "/projects/#{project.identifier}/kanban"

      # 別セッションでUserStoryの状態を変更
      using_session('other_user') do
        @user_story.update!(status: status_in_progress)
      end

      # WebSocketまたはポーリングによって変更が反映される
      expect(page).to have_content('In Progress'), wait: 5
    end
  end

  describe 'パフォーマンステスト' do
    scenario '大量のイシューでもページが高速で読み込まれる', :performance do
      # 100個のUserStoryを作成
      100.times do |i|
        Issue.create!(
          project: project,
          tracker: user_story_tracker,
          status: status_new,
          subject: "UserStory #{i}",
          author: user,
          parent: @feature,
          priority: priority_normal
        )
      end

      start_time = Time.current
      visit "/projects/#{project.identifier}/kanban"

      # ページ読み込み完了を待機
      expect(page).to have_selector('.kanban-container')

      load_time = Time.current - start_time
      expect(load_time).to be < 3 # 3秒以内での読み込み
    end
  end

  describe 'アクセシビリティ' do
    scenario 'キーボードナビゲーションが機能する' do
      visit "/projects/#{project.identifier}/kanban"

      # Tabキーでナビゲーション
      first('.issue-card').send_keys(:tab)
      expect(page).to have_selector('.issue-card:focus')

      # Enterキーでカード詳細を開く
      first('.issue-card').send_keys(:return)
      expect(page).to have_selector('.issue-detail-modal')
    end

    scenario 'スクリーンリーダー対応のARIA属性が設定されている' do
      visit "/projects/#{project.identifier}/kanban"

      # 重要な要素にARIA属性が設定されている
      expect(page).to have_selector('[role="main"]')
      expect(page).to have_selector('[aria-label]')
      expect(page).to have_selector('[aria-describedby]')
    end
  end

  describe 'モバイル対応' do
    scenario 'モバイルデバイスでの表示が適切', :mobile do
      # モバイルビューポートを設定
      page.driver.browser.manage.window.resize_to(375, 667)

      visit "/projects/#{project.identifier}/kanban"

      # レスポンシブデザインが適用される
      expect(page).to have_selector('.kanban-mobile-layout')

      # カードの詳細がモバイル用モーダルで表示される
      first('.issue-card').click
      expect(page).to have_selector('.mobile-card-modal')
    end
  end

  describe 'エラーハンドリング' do
    scenario 'ネットワークエラー時の適切な表示' do
      visit "/projects/#{project.identifier}/kanban"

      # ネットワーク障害をシミュレート
      page.evaluate_script('window.navigator.onLine = false')

      # カードを移動しようとする
      user_story_card = find('.issue-card[data-tracker="UserStory"]')
      in_progress_column = find('.kanban-column[data-column-id="in_progress"]')
      user_story_card.drag_to(in_progress_column)

      # エラーメッセージが表示される
      expect(page).to have_content('ネットワークエラーが発生しました')

      # 再試行ボタンが表示される
      expect(page).to have_button('再試行')
    end

    scenario 'データ読み込みエラー時のフォールバック表示' do
      # APIエラーをシミュレート
      allow(Kanban::ApiController).to receive(:kanban_data).and_raise(StandardError)

      visit "/projects/#{project.identifier}/kanban"

      # エラー状態の表示
      expect(page).to have_content('データの読み込みに失敗しました')
      expect(page).to have_button('再読み込み')
    end
  end
end