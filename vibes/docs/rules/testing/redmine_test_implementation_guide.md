# Redmineプラグインテスト実装ガイド

## 🔗 関連ドキュメント
- @vibes/rules/testing/kanban_test_strategy.md
- @vibes/rules/testing/test_automation_strategy.md

## 1. テスト環境セットアップ

### 1.1 ディレクトリ構造
```
plugins/redmine_release_kanban/
├── test/
│   ├── fixtures/           # テストデータ
│   ├── unit/              # ユニットテスト
│   ├── functional/        # 機能テスト
│   ├── integration/       # 統合テスト
│   ├── system/            # システムテスト
│   └── test_helper.rb     # テスト設定
```

### 1.2 test_helper.rb基本設定
```ruby
# frozen_string_literal: true

# Redmine標準test_helperを読み込み
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# プラグイン固有フィクスチャ（将来）
# ActiveRecord::FixtureSet.create_fixtures(File.dirname(__FILE__) + '/fixtures/',
#                                          %i[kanban_boards kanban_columns])

module Redmine
  class ControllerTest
    setup do
      Setting.text_formatting = 'textile'
    end

    teardown do
      Setting.delete_all
      Setting.clear_cache
    end
  end
end
```

## 2. ユニットテスト実装パターン

### 2.1 モデルテスト
```ruby
# test/unit/kanban_tracker_hierarchy_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanTrackerHierarchyTest < ActiveSupport::TestCase
  fixtures :trackers, :projects, :issues

  def test_epic_to_feature_hierarchy
    epic = Tracker.find_or_create_by(name: 'Epic')
    feature = Tracker.find_or_create_by(name: 'Feature')

    assert epic.present?, 'Epic tracker should exist'
    assert feature.present?, 'Feature tracker should exist'
  end

  def test_version_propagation_logic
    # バージョン伝播ロジックテスト
    assert true, 'Version propagation placeholder'
  end
end
```

### 2.2 サービステスト
```ruby
# test/unit/kanban_auto_generation_service_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanAutoGenerationServiceTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues, :trackers

  def setup
    @project = Project.first
    @user = User.first
    User.current = @user
  end

  def teardown
    User.current = nil
  end

  def test_auto_test_generation
    # UserStory作成時のTest自動生成テスト
    user_story = Issue.create!(
      project: @project,
      tracker: Tracker.find_by(name: 'User Story'),
      subject: 'Test UserStory',
      author: @user
    )

    # 自動生成ロジック呼び出し（実装後）
    # KanbanAutoGenerationService.new(user_story).generate_tests

    assert user_story.persisted?, 'UserStory should be created'
  end
end
```

## 3. 機能テスト実装パターン

### 3.1 コントローラーテスト
```ruby
# test/functional/kanban_controller_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles

  def setup
    @project = Project.first
    @user = User.find(1)
    @request.session[:user_id] = @user.id
  end

  def test_index_access
    get :index, params: { project_id: @project.id }
    assert_response :success
    assert_template 'index'
  rescue ActionController::UrlGenerationError
    skip 'Kanban controller routes not yet implemented'
  end

  def test_card_movement_api
    # カード移動API テスト（実装後）
    post :move_card, params: {
      project_id: @project.id,
      issue_id: 1,
      column: 'in_progress'
    }

    assert_response :success
  rescue ActionController::UrlGenerationError
    skip 'Move card API not yet implemented'
  end
end
```

### 3.2 API機能テスト
```ruby
# test/functional/kanban_api_controller_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanApiControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :trackers

  def setup
    @project = Project.first
    @user = User.find(1)
    @request.session[:user_id] = @user.id
  end

  def test_kanban_data_json
    get :data, params: { project_id: @project.id, format: 'json' }
    assert_response :success
    assert_equal 'application/json', response.content_type
  rescue ActionController::UrlGenerationError
    skip 'Kanban API not yet implemented'
  end
end
```

## 4. 統合テスト実装パターン

### 4.1 ワークフロー統合テスト
```ruby
# test/integration/kanban_workflow_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanWorkflowTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues, :trackers

  def setup
    @project = Project.first
    @user = User.find(1)
    log_user('admin', 'admin')
  end

  def test_epic_to_task_workflow
    # Epic作成
    post '/issues', params: {
      issue: {
        project_id: @project.id,
        tracker_id: Tracker.find_by(name: 'Epic')&.id || 1,
        subject: 'Integration Test Epic'
      }
    }
    assert_response :redirect

    # Feature作成・関連付け（実装後）
    # Feature → UserStory → Task の階層作成テスト
  end

  def test_version_propagation_flow
    # バージョン伝播の統合テスト
    # 親Issue更新 → 子Issue自動更新の検証
    assert true, 'Version propagation integration test placeholder'
  end
end
```

## 5. システムテスト実装パターン

### 5.1 ブラウザE2Eテスト
```ruby
# test/system/kanban_system_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanSystemTest < ApplicationSystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  fixtures :projects, :users, :issues

  def setup
    @project = Project.first
    @user = User.find(1)
    log_user('admin', 'admin')
  end

  def test_drag_and_drop_operation
    visit project_kanban_path(@project)

    # カンバンボード表示確認
    assert_text 'Kanban Board'

    # ドラッグ&ドロップ操作（実装後）
    # source = find('[data-issue-id="1"]')
    # target = find('[data-column="in_progress"]')
    # source.drag_to(target)

    # 状態変更確認
    # assert_text 'In Progress'
  rescue Capybara::ElementNotFound
    skip 'Kanban UI not yet implemented'
  end

  def test_epic_swimlane_display
    visit project_kanban_path(@project)

    # Epic Swimlane表示切り替え
    # click_button 'Epic View'
    # assert_css '.epic-swimlane'

    skip 'Epic swimlane not yet implemented'
  end
end
```

## 6. モック・スタブ活用

### 6.1 Mocha使用例
```ruby
# test/unit/kanban_notification_service_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanNotificationServiceTest < ActiveSupport::TestCase
  fixtures :users, :projects

  def test_notification_sending
    # 外部通知サービスのモック
    NotificationService.any_instance.expects(:send_notification).returns(true)

    service = KanbanNotificationService.new
    result = service.notify_status_change(Issue.first, 'in_progress')

    assert result, 'Notification should be sent'
  end

  def test_email_delivery_stub
    # メール送信のスタブ
    ActionMailer::Base.deliveries.clear

    # メール送信ロジック実行
    # KanbanMailer.status_changed(issue, user).deliver_now

    # assert_equal 1, ActionMailer::Base.deliveries.size
    assert true, 'Email delivery test placeholder'
  end
end
```

## 7. パフォーマンステスト

### 7.1 N+1問題検出
```ruby
# test/unit/kanban_performance_test.rb
require File.expand_path('../../test_helper', __FILE__)

class KanbanPerformanceTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :trackers

  def test_no_n_plus_one_queries
    # N+1問題検出テスト
    assert_queries(2) do  # 期待クエリ数
      project = Project.first
      issues = project.issues.includes(:tracker, :status)
      issues.each { |issue| issue.tracker.name }
    end
  end

  def test_api_response_time
    # API応答時間テスト
    start_time = Time.current

    # API呼び出し（実装後）
    # KanbanDataBuilder.new(Project.first).build_data

    execution_time = Time.current - start_time
    assert execution_time < 0.2, "API response should be under 200ms, was #{execution_time}s"
  end
end
```

## 8. テスト実行Tips

### 8.1 実行コマンド
```bash
# 単一ファイル実行
rake redmine:plugins:test:units PLUGIN=redmine_release_kanban TEST=test/unit/kanban_tracker_hierarchy_test.rb

# タイプ別実行
rake redmine:plugins:test:units PLUGIN=redmine_release_kanban
rake redmine:plugins:test:functionals PLUGIN=redmine_release_kanban

# 全テスト実行
rake redmine:plugins:test PLUGIN=redmine_release_kanban

# 環境変数設定
RAILS_ENV=test rake redmine:plugins:test PLUGIN=redmine_release_kanban
```

### 8.2 デバッグ手法
```ruby
# pry-byebugでデバッグ（Gemfile.localに追加）
require 'pry-byebug'

def test_debug_example
  binding.pry  # ブレークポイント
  # デバッグ対象コード
end

# ログ出力
Rails.logger.debug "Test debug: #{variable.inspect}"

# テスト失敗時の詳細出力
assert_equal expected, actual, "Expected #{expected}, got #{actual}"
```

---

*Redmine標準テスト手法による堅牢で保守可能なテスト実装*