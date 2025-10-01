# カンバンテスト戦略

## 関連ドキュメント
- @vibes/rules/technical_architecture_standards.md
- @vibes/rules/testing/test_automation_strategy.md
- @vibes/docs/temps/playwright-rspec-setup.md

## 1. 技術スタック

### 1.1 採用技術

| 技術 | バージョン | 用途 | 備考 |
|------|-----------|------|------|
| **RSpec** | 6.x+ | BDD テストフレームワーク | Rails 統合 |
| **FactoryBot** | 6.x+ | テストデータビルダー | factory_girl 非推奨 |
| **Playwright** | 1.55+ | E2E/システムテスト | Pure Playwright 方式 |
| **playwright-ruby-client** | 1.55+ | Ruby バインディング | Capybara 不使用 |
| **DatabaseCleaner** | 2.1+ | DB トランザクション管理 | `:truncation` 戦略 |
| **SimpleCov** | 0.22+ | カバレッジ計測 | JSON レポート出力 |

### 1.2 アーキテクチャ選択：Pure Playwright 方式

**❌ 不採用：Capybara + Playwright Driver**
```ruby
# Capybara DSL を使うと i18n エラーが発生
visit '/login'
fill_in 'username', with: 'testuser'
# => I18n::ArgumentError: Object must be a Date, DateTime or Time object
```

**✅ 採用：Pure Playwright（Capybara 不使用）**
```ruby
# Rails サーバーを手動管理、Playwright API 直接使用
@playwright_page.goto('/login')
@playwright_page.fill('input[name="username"]', 'testuser')
# => i18n 問題なし、通常の HTTP リクエストとして処理
```

**理由**：
- Capybara サーバー（別プロセス）で `Redmine::I18n` が正しく読み込まれない
- ビューの `l(:field_login)` が `I18n.localize`（日付フォーマット）として誤解釈される
- Pure Playwright なら通常の Rails リクエストとして処理され、i18n が正常動作

### 1.3 環境構築

**自動セットアップ（推奨）**
```bash
cd /usr/src/redmine/plugins/redmine_release_kanban
./bin/setup_test_env.sh
```

**実行内容**：
1. Ruby/Bundler チェック
2. factory_girl アンインストール
3. 他プラグイン Gemfile 無効化
4. RSpec gem インストール
5. RSpec 設定ファイル確認
6. Node.js/npm チェック
7. Playwright インストール（Chromium）
8. **テストDB 自動セットアップ**
9. **ポート 3001 クリーンアップ**

**手動セットアップ**
```bash
# Ruby gem インストール
cd /usr/src/redmine
bundle install

# Playwright インストール
cd plugins/redmine_release_kanban
npm install
npx playwright install chromium

# テストDB 準備
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:create db:migrate
RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data
```

### 1.4 factory_girl 無効化

**背景**
- 他プラグイン（redmine_app_notifications, easy_gantt）が factory_girl 4.9.0 使用
- Rails 7.2+ で `ActiveSupport::Deprecation.warn` が private になり非互換
- 本プラグインでは FactoryBot 6.x のみ使用

**実装**
```ruby
# spec/rails_helper.rb（冒頭）
ENV['DISABLE_FACTORY_GIRL'] = '1'
require 'factory_bot_rails'

# factory_girl の ActiveSupport::Deprecation.warn をパッチ
module ActiveSupport
  class Deprecation
    class << self
      def warn(message = nil, callstack = nil)
        return if @silenced
        Rails.logger.warn("[DEPRECATION] #{message}") if Rails.logger && message
      end
    end
  end
end
```

**制約**
- 他プラグインテスト実行不可（本プラグイン開発では不要）
- setup_test_env.sh で自動処理済み

## 2. テストピラミッド

```
      /\      System (Playwright) 10%
     /  \     Integration 25%
    /    \    Request 20%
   /      \   Service 20%
  /________\  Model 25%
```

| タイプ | 配置 | 実行コマンド | 対象 | 推奨度 |
|--------|------|-------------|------|-------|
| Model | `spec/models/` | `rspec spec/models` | モデル・バリデーション | ★★★★★ |
| Service | `spec/services/` | `rspec spec/services` | ビジネスロジック | ★★★★★ |
| Request | `spec/requests/` | `rspec spec/requests` | API・コントローラー | ★★★★☆ |
| Integration | `spec/integration/` | `rspec spec/integration` | 機能統合 | ★★★☆☆ |
| System | `spec/system/` | `rspec spec/system` | E2E/UI 操作 | ★★★★☆ |

## 3. カンバン機能別テスト要件

### 3.1 Critical（100%カバレッジ必須）
- **TrackerHierarchy** - Epic→Feature→UserStory→Task/Test制約
- **VersionPropagation** - 親→子バージョン伝播
- **StateTransition** - カラム移動状態制御
- **Grid Layout** - CSS/レイアウトはみ出し検証

### 3.2 High（90%カバレッジ目標）
- **TestGeneration** - UserStory→Test自動生成
- **ValidationGuard** - 3層ガード検証
- **BlocksRelation** - blocks関係管理
- **DragAndDrop** - UI楽観的更新

### 3.3 Medium（80%カバレッジ目標）
- **EpicSwimlane** - 表示切り替え
- **PermissionControl** - ロール別制限
- **SearchFilter** - 検索・フィルタリング

## 4. Pure Playwright System テスト実装

### 4.1 rails_helper.rb 設定

```ruby
# Pure Playwright Ruby Client（Capybara 不使用）
require 'playwright'

RSpec.configure do |config|
  # サーバーを全テストで共有（高速化）
  config.before(:suite) do
    if RSpec.configuration.files_to_run.any? { |f| f.include?('spec/system') }
      @shared_server_port = ENV['TEST_PORT'] || 3001

      # 既存プロセスクリーンアップ
      system("lsof -ti:#{@shared_server_port} | xargs kill -9 2>/dev/null")
      sleep 0.5

      puts "\n[INFO] 共有 Rails サーバーを起動中（ポート: #{@shared_server_port}）..."

      @shared_server_pid = fork do
        ENV['RAILS_ENV'] = 'test'
        exec("bundle exec rails s -p #{@shared_server_port} -e test > log/test_server.log 2>&1")
      end

      # サーバー起動待機
      max_wait = 30
      start_time = Time.now
      loop do
        break if system("curl -s http://localhost:#{@shared_server_port} > /dev/null 2>&1")
        if Time.now - start_time > max_wait
          Process.kill('TERM', @shared_server_pid) rescue nil
          raise "Rails server failed to start within #{max_wait} seconds"
        end
        sleep 0.5
      end

      puts "[INFO] ✅ Rails サーバー起動完了（PID: #{@shared_server_pid}）\n"

      $shared_server_port = @shared_server_port
      $shared_server_pid = @shared_server_pid
    end
  end

  config.after(:suite) do
    if $shared_server_pid
      puts "\n[INFO] 共有 Rails サーバーを停止中..."
      Process.kill('TERM', $shared_server_pid) rescue nil
      Process.wait($shared_server_pid) rescue nil
      puts "[INFO] ✅ Rails サーバー停止完了\n"
    end
  end

  config.around(:each, type: :system) do |example|
    server_port = $shared_server_port || 3001

    Playwright.create(playwright_cli_executable_path: File.expand_path('../node_modules/.bin/playwright', __dir__)) do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        @playwright_page = browser.new_page(baseURL: "http://localhost:#{server_port}")
        @playwright_page.context.set_default_timeout(10000)

        begin
          example.run
        ensure
          # 失敗時スクリーンショット
          if example.exception
            screenshot_dir = Rails.root.join('tmp', 'playwright_screenshots')
            FileUtils.mkdir_p(screenshot_dir)
            screenshot_path = screenshot_dir.join("#{example.full_description.parameterize}_#{Time.now.to_i}.png")
            @playwright_page.screenshot(path: screenshot_path.to_s)
            puts "\n[Screenshot] #{screenshot_path}"
          end
        end
      end
    end
  end
end
```

### 4.2 DatabaseCleaner 設定

```ruby
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.allow_remote_database_url = true

    # Redmine default data を保護
    protected_tables = %w[
      roles trackers issue_statuses enumerations
      workflows custom_fields settings groups_users
    ]

    DatabaseCleaner.strategy = :truncation, { except: protected_tables }
    DatabaseCleaner.clean_with(:truncation, { except: protected_tables })
  end

  config.around(:each) do |example|
    protected_tables = %w[
      roles trackers issue_statuses enumerations
      workflows custom_fields settings groups_users
    ]

    if example.metadata[:type] == :system
      # System spec: 別プロセスから見えるように truncation
      DatabaseCleaner.strategy = :truncation, { except: protected_tables }
    else
      # 通常の spec: 高速な transaction
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

### 4.3 System テスト例

```ruby
RSpec.describe 'Kanban Grid Layout Measurement', type: :system do
  let(:project) { create(:project, identifier: 'test-kanban') }
  let(:user) { create(:user, login: 'testuser', password: 'password123', admin: true) }

  before(:each) do
    # プロジェクト・権限設定
    project.trackers << epic_tracker
    project.enabled_modules.create!(name: 'kanban')

    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [:view_issues, :add_issues, :view_kanban]
      r.assignable = true
    end
    Member.create!(user: user, project: project, roles: [role])

    # テストデータ作成
    @epic = create(:issue, project: project, tracker: epic_tracker)

    # Playwright API でログイン
    @playwright_page.goto('/login', timeout: 30000)
    @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil
    @playwright_page.fill('input[name="username"]', user.login)
    @playwright_page.fill('input[name="password"]', 'password123')
    @playwright_page.click('input#login-submit')

    # ログイン成功確認
    @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

    # カンバンページ遷移
    @playwright_page.goto("/projects/#{project.identifier}/kanban", timeout: 30000)
    @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil
    @playwright_page.wait_for_selector('.kanban-grid-body', timeout: 15000)
  end

  it 'validates grid structure and cell counts' do
    grid_metrics = @playwright_page.evaluate(<<~JS)
      (() => {
        const grid = document.querySelector('.kanban-grid-body');
        if (!grid) return null;

        const computedStyle = window.getComputedStyle(grid);
        return {
          declaredColumns: parseInt(grid.style.getPropertyValue('--grid-columns')) || 0,
          declaredRows: parseInt(grid.style.getPropertyValue('--grid-rows')) || 0,
          computedColumns: computedStyle.gridTemplateColumns.split(' ').length,
          computedRows: computedStyle.gridTemplateRows.split(' ').length
        };
      })();
    JS

    expect(grid_metrics).not_to be_nil
    expect(grid_metrics['declaredColumns']).to be > 0
    expect(grid_metrics['declaredRows']).to be > 0
  end
end
```

## 5. 実行戦略

### 5.1 コマンド体系

**System テスト（Playwright）**
```bash
cd /usr/src/redmine

# 全 System テスト
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system --format documentation

# 特定のテスト
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system/kanban/grid_layout_measurement_spec.rb:59

# スクリーンショット確認
ls -lt tmp/playwright_screenshots/

# ポートクリーンアップ（失敗時）
lsof -ti:3001 | xargs kill -9
```

**RSpec テスト（その他）**
```bash
cd /usr/src/redmine

# 全テスト
bundle exec rspec plugins/redmine_release_kanban/spec

# レイヤー別
bundle exec rspec plugins/redmine_release_kanban/spec/models
bundle exec rspec plugins/redmine_release_kanban/spec/services
bundle exec rspec plugins/redmine_release_kanban/spec/requests

# オプション
bundle exec rspec --tag ~slow               # 遅いテスト除外
bundle exec rspec --fail-fast               # 最初の失敗で停止
COVERAGE=true bundle exec rspec             # カバレッジ計測
```

### 5.2 開発ワークフロー

```bash
# 1. 環境セットアップ（初回のみ）
cd /usr/src/redmine/plugins/redmine_release_kanban
./bin/setup_test_env.sh

# 2. 開発前チェック（高速）
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models \
                  plugins/redmine_release_kanban/spec/services

# 3. 機能開発中（関連テスト）
bundle exec rspec plugins/redmine_release_kanban/spec/models/kanban/tracker_hierarchy_spec.rb

# 4. コミット前チェック（全テスト）
bundle exec rspec plugins/redmine_release_kanban/spec

# 5. リリース前チェック（カバレッジ）
COVERAGE=true bundle exec rspec plugins/redmine_release_kanban/spec
```

## 6. RSpec テストパターン

### 6.1 Model Spec

```ruby
# spec/models/kanban/tracker_hierarchy_spec.rb
require 'rails_helper'

RSpec.describe Kanban::TrackerHierarchy, type: :model do
  describe '.tracker_names' do
    it 'Epic→Feature→UserStory→Task/Test の階層を返す' do
      expect(described_class.tracker_names).to eq(
        ['Epic', 'Feature', 'User Story', 'Task', 'Test']
      )
    end
  end

  describe '.parent_trackers' do
    it 'Task の親は User Story' do
      expect(described_class.parent_trackers('Task')).to include('User Story')
    end
  end
end
```

### 6.2 Service Spec

```ruby
# spec/services/kanban/auto_generation_service_spec.rb
require 'rails_helper'

RSpec.describe Kanban::AutoGenerationService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:user_story) { create(:issue, tracker: create(:tracker, name: 'User Story')) }

  describe '#generate_tests' do
    it 'UserStory から Test チケットを自動生成する' do
      service = described_class.new(user_story)

      expect { service.generate_tests }.to change { Issue.count }.by(1)

      test_issue = Issue.last
      expect(test_issue.tracker.name).to eq('Test')
      expect(test_issue.parent_id).to eq(user_story.id)
    end
  end
end
```

### 6.3 Request Spec

```ruby
# spec/requests/kanban/kanban_controller_spec.rb
require 'rails_helper'

RSpec.describe 'Kanban API', type: :request do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET /projects/:project_id/kanban' do
    it 'カンバンボードを表示する' do
      get project_kanban_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Kanban Board')
    end
  end
end
```

## 7. テストデータ管理

### 7.1 FactoryBot 定義

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:login) { |n| "user#{n}" }
    sequence(:firstname) { |n| "First#{n}" }
    sequence(:lastname) { |n| "Last#{n}" }
    sequence(:mail) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    status { User::STATUS_ACTIVE }
    admin { false }
    language { 'en' }

    # セキュリティ通知メール無効化
    after(:build) do |user|
      def user.deliver_security_notification
        # スキップ
      end
    end

    trait :admin do
      admin { true }
    end
  end
end

# spec/factories/issues.rb
FactoryBot.define do
  factory :issue do
    project
    tracker
    author { create(:user) }
    subject { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    status { IssueStatus.first }

    trait :epic do
      tracker { Tracker.find_or_create_by!(name: 'Epic') }
    end

    trait :feature do
      tracker { Tracker.find_or_create_by!(name: 'Feature') }
      association :parent, factory: [:issue, :epic]
    end
  end
end
```

## 8. 品質基準

### 8.1 カバレッジ
- Critical: 100%、High: 90%、Medium: 80%
- 全体平均: 85%以上
- SimpleCov による自動計測

### 8.2 パフォーマンス
- API応答: <200ms
- N+1問題: 禁止（bullet gem 使用）
- UI反応: <16ms（Playwright 測定）
- Grid レイアウト: オーバーフロー 0件

### 8.3 データ整合性
- **FactoryBot** でテストデータ生成
- **DatabaseCleaner** でトランザクション制御
- **Redmine default data** を保護（roles, trackers, issue_statuses など）

## 9. トラブルシューティング

### 9.1 i18n エラー

**症状**
```
I18n::ArgumentError: Object must be a Date, DateTime or Time object. :field_login given.
```

**原因**
- Capybara を使用している
- Capybara サーバー（別プロセス）で `Redmine::I18n` が正しく読み込まれない

**解決**
- ✅ Pure Playwright 方式を使用（本戦略で採用済み）
- ❌ Capybara は使わない

### 9.2 factory_girl エラー

**症状**
```
NoMethodError: private method `warn' called for class ActiveSupport::Deprecation
```

**解決**
- rails_helper.rb で自動パッチ済み
- setup_test_env.sh で自動処理済み

### 9.3 ポート衝突

**症状**
```
Address already in use - bind(2) for "0.0.0.0" port 3001
```

**解決**
```bash
lsof -ti:3001 | xargs kill -9
```

### 9.4 RSpec 実行時に gem not found

**症状**
```
can't find executable rspec for gem rspec-core
```

**解決**
```bash
# 必ず Redmine ルートから実行
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec
```

### 9.5 スクリーンショットが見つからない

**場所**
```bash
ls -lt /usr/src/redmine/tmp/playwright_screenshots/
```

**確認**
- テストが失敗した場合のみ保存
- `[Screenshot]` で出力パスが表示される

## 10. 参考資料

- [Playwright Ruby Client](https://github.com/YusukeIwaki/playwright-ruby-client)
- [RSpec Rails](https://rspec.info/features/6-0/rspec-rails/)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)
- [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner)
- [SimpleCov](https://github.com/simplecov-ruby/simplecov)

---

**Vibes準拠 - Pure Playwright + RSpec テスト戦略 v2.0**