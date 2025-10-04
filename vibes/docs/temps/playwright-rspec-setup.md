# Playwright + RSpec システムテスト環境構築ガイド

## 概要

Redmine プラグインで Playwright を使った E2E テストを RSpec と統合する方法。
Capybara の i18n 問題を回避するため、**Pure Playwright 方式**（Capybara を使わず手動で Rails サーバー管理）を採用。

## 環境構築

### 1. 依存関係のインストール

```bash
# Playwright CLI をインストール
cd plugins/redmine_epic_grid/
npm install --save-dev @playwright/test
npx playwright install chromium

# Ruby gem をインストール
bundle install
```

### 2. 必要な Gem

`Gemfile` に以下を追加（条件付き定義で重複回避）：

```ruby
group :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'playwright-ruby-client', '~> 1.55'
  # capybara-playwright-driver は不要（Pure Playwright 方式のため）
end
```

### 3. Redmine デフォルトデータの準備

```bash
RAILS_ENV=test bundle exec rake redmine:load_default_data
```

## テスト実行

### 基本コマンド

```bash
# 全テスト実行
cd /usr/src/redmine && AILS_ENV=test bundle exec rspec plugins/redmine_epic_grid/spec/system

# 特定のテスト実行
cd /usr/src/redmine/plugins/redmine_epic_grid/ && RAILS_ENV=test bundle exec rspec plugins/redmine_epic_grid/spec/system/kanban/grid_layout_measurement_spec.rb:59 --format documentation

# 失敗時のスクリーンショット確認
ls -lt tmp/playwright_screenshots/
```

### ポート衝突時のクリーンアップ

```bash
# ポート 3001 をクリーンアップ
lsof -ti:3001 | xargs kill -9
```

## 実装詳細

### rails_helper.rb の主要設定

```ruby
# Pure Playwright Ruby Client（Capybara 不使用）
require 'playwright'

RSpec.configure do |config|
  config.around(:each, type: :system) do |example|
    # Rails サーバーを起動
    @server_port = ENV['TEST_PORT'] || 3001

    # 既存のプロセスをクリーンアップ
    system("lsof -ti:#{@server_port} | xargs kill -9 2>/dev/null")
    sleep 0.5

    @server_pid = fork do
      ENV['RAILS_ENV'] = 'test'
      exec("bundle exec rails s -p #{@server_port} -e test > log/test_server.log 2>&1")
    end

    # サーバー起動待機
    max_wait = 30
    start_time = Time.now
    loop do
      break if system("curl -s http://localhost:#{@server_port} > /dev/null 2>&1")
      if Time.now - start_time > max_wait
        Process.kill('TERM', @server_pid) rescue nil
        raise "Rails server failed to start within #{max_wait} seconds"
      end
      sleep 0.5
    end

    # Playwright でブラウザ起動
    Playwright.create(playwright_cli_executable_path: File.expand_path('../node_modules/.bin/playwright', __dir__)) do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        @playwright_page = browser.new_page(baseURL: "http://localhost:#{@server_port}")
        @playwright_page.context.set_default_timeout(10000)

        begin
          example.run
        ensure
          # スクリーンショット保存（失敗時）
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

    # Rails サーバー停止
    Process.kill('TERM', @server_pid) rescue nil
    Process.wait(@server_pid) rescue nil
  end
end
```

### DatabaseCleaner 設定

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
      # System spec: 別プロセスから見えるように truncation 使用
      DatabaseCleaner.strategy = :truncation, { except: protected_tables }
    else
      # 通常の spec: 高速な transaction 使用
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

## テストコード例

```ruby
RSpec.describe 'Kanban Grid Layout Measurement', type: :system do
  let(:project) { create(:project, identifier: 'test-kanban') }
  let(:user) { create(:user, login: 'testuser', password: 'password123', admin: true) }

  before(:each) do
    # プロジェクト・権限設定
    project.trackers << epic_tracker
    project.enabled_modules.create!(name: 'kanban')

    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [:view_issues, :add_issues, :edit_issues, :view_kanban]
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

    # ログイン成功を確認
    @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

    # カンバンページに移動
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

    puts JSON.pretty_generate(grid_metrics)

    expect(grid_metrics).not_to be_nil
    expect(grid_metrics['declaredColumns']).to be > 0
    expect(grid_metrics['declaredRows']).to be > 0
  end
end
```

## 重要なポイント

### 1. Pure Playwright 方式を採用した理由

**問題**: Capybara を使うと、以下の i18n エラーが発生
```
I18n::ArgumentError: Object must be a Date, DateTime or Time object. :field_login given.
```

**原因**: Capybara サーバー（別プロセス）で `Redmine::I18n` が正しく読み込まれず、
ビューの `l(:field_login)` が `I18n.localize`（日付フォーマット）として解釈される。

**解決策**: Capybara を使わず、手動で Rails サーバーを管理することで、
通常の HTTP リクエストとして処理され、i18n が正しく機能する。

### 2. データベース管理

- **System spec**: `:truncation` 戦略（別プロセスから参照可能）
- **通常の spec**: `:transaction` 戦略（高速）
- **Redmine default data**: `except` で保護対象テーブルを指定

### 3. タイムアウト設定

- `goto()`: 30000ms（ページ読み込み）
- `wait_for_selector()`: 10000-15000ms（要素待機）
- `wait_for_load_state('networkidle')`: 10000ms + `rescue nil`（失敗しても無視）

### 4. スクリーンショット

失敗時に自動保存されるため、デバッグが容易：
```
tmp/playwright_screenshots/kanban-grid-layout-measurement-...-1759241016.png
```

## トラブルシューティング

### ポートが既に使用中

```bash
lsof -ti:3001 | xargs kill -9
```

### Rails サーバーが起動しない

```bash
# ログ確認
tail -f log/test_server.log

# 手動起動テスト
RAILS_ENV=test bundle exec rails s -p 3001
```

### i18n エラーが出る

- Capybara を使っていないか確認
- `rails_helper.rb` で Pure Playwright 方式を使用しているか確認

### テストが遅い

- `headless: false` にしてブラウザを表示し、何が起きているか確認
- タイムアウトを調整
- 不要な `wait_for_load_state()` を削除

## 参考資料

- [playwright-ruby-client](https://github.com/YusukeIwaki/playwright-ruby-client)
- [RSpec System Specs](https://rspec.info/features/6-0/rspec-rails/system-specs/)
- [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner)