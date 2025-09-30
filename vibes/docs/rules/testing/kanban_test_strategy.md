# カンバンテスト戦略

## 関連ドキュメント
- @vibes/rules/technical_architecture_standards.md
- @vibes/rules/testing/test_automation_strategy.md

## 1. 技術スタック

### 1.1 採用技術
- **RSpec 6.x** - BDD テストフレームワーク
- **FactoryBot 6.x** - テストデータビルダー（factory_girl 4.9.0 無効化）
- **Playwright 1.55+** - E2E/ビジュアルテスト
- **Capybara 3.x** - システムテスト補助
- **SimpleCov 0.22+** - カバレッジ計測

### 1.2 環境構築

**自動セットアップ**
```bash
./bin/setup_test_env.sh
```

**手動セットアップ**
```bash
# Ruby gem インストール
cd /usr/src/redmine
bundle install

# Node.js パッケージインストール
cd plugins/redmine_release_kanban
npm install
npx playwright install chromium
npx playwright install-deps chromium

# テストDB作成（オプション）
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:create
```

### 1.3 factory_girl 無効化

**背景**
- 他プラグイン（redmine_app_notifications, easy_gantt）が factory_girl 4.9.0 使用
- factory_girl は非推奨、Rails 7.2+ で `ActiveSupport::Deprecation.warn` エラー
- 本プラグインでは FactoryBot 6.x のみ使用

**実装**
```ruby
# spec/rails_helper.rb（冒頭）
ENV['DISABLE_FACTORY_GIRL'] = '1'

begin
  Object.send(:remove_const, :FactoryGirl) if defined?(FactoryGirl)
rescue => e
  # 無視
end
```

**制約**
- 他プラグインテスト実行不可（本プラグイン開発では不要）
- マイグレーション時に factory_girl エラー発生可能性（セットアップスクリプトでスキップ）

### 1.4 Test::Unit からの移行理由
```
❌ Test::Unit - Redmine 依存で柔軟性低い
❌ Fixtures - データ管理が硬直的
❌ Capybara 単独 - CSS 測定機能が弱い
✅ RSpec + Playwright - モダンで強力
```

## 2. テストピラミッド

```
      /\      E2E (Playwright) 10%
     /  \     Integration 25%
    /    \    Request 20%
   /      \   Service 20%
  /________\  Model 25%
```

| タイプ | 配置 | 実行コマンド | 対象 |
|--------|------|-------------|------|
| Model | `spec/models/` | `rspec spec/models` | モデル・バリデーション |
| Service | `spec/services/` | `rspec spec/services` | ビジネスロジック |
| Request | `spec/requests/` | `rspec spec/requests` | API・コントローラー |
| Integration | `spec/integration/` | `rspec spec/integration` | 機能統合 |
| E2E | `spec/system/` | `rspec spec/system` | UI/ブラウザ操作 |
| Visual | `playwright/tests/` | `npx playwright test` | CSS/レイアウト測定 |

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

## 4. 品質基準

### 4.1 カバレッジ
- Critical: 100%、High: 90%、Medium: 80%
- 全体平均: 85%以上
- SimpleCov による自動計測

### 4.2 パフォーマンス
- API応答: <200ms
- N+1問題: 禁止（bullet gem 使用）
- UI反応: <16ms（Playwright 測定）
- Grid レイアウト: オーバーフロー 0件

### 4.3 データ管理
- **FactoryBot** でテストデータ生成
- **Database Cleaner** でトランザクション制御
- **Faker** でリアルなダミーデータ

### 4.4 ビジュアル品質
- **Playwright Screenshot** 比較
- **CSS Grid Metrics** 定量測定
- **Responsive Design** チェック（モバイル/タブレット/デスクトップ）

## 5. 実行戦略

### 5.1 コマンド体系

**RSpec テスト（Redmine ルートから実行）**
```bash
cd /usr/src/redmine

# 全テスト
bundle exec rspec plugins/redmine_release_kanban/spec

# レイヤー別
bundle exec rspec plugins/redmine_release_kanban/spec/models
bundle exec rspec plugins/redmine_release_kanban/spec/services
bundle exec rspec plugins/redmine_release_kanban/spec/requests
bundle exec rspec plugins/redmine_release_kanban/spec/integration
bundle exec rspec plugins/redmine_release_kanban/spec/system

# 個別ファイル
bundle exec rspec plugins/redmine_release_kanban/spec/models/kanban/tracker_hierarchy_spec.rb

# オプション
bundle exec rspec --tag ~slow               # 遅いテスト除外
bundle exec rspec --fail-fast               # 最初の失敗で停止
COVERAGE=true bundle exec rspec             # カバレッジ計測
```

**Playwright テスト（プラグインルートから実行）**
```bash
cd /usr/src/redmine/plugins/redmine_release_kanban

# 全 E2E テスト
npx playwright test

# オプション
npx playwright test --headed                # ブラウザ表示
npx playwright test --project=chromium      # ブラウザ指定
npx playwright test grid-layout             # Grid レイアウト専用
npx playwright test --debug                 # デバッグモード
```

### 5.2 開発ワークフロー

```bash
# 環境セットアップ（初回のみ）
cd /usr/src/redmine/plugins/redmine_release_kanban
./bin/setup_test_env.sh

# 開発前チェック（高速）
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models \
                  plugins/redmine_release_kanban/spec/services

# 機能開発中（関連テスト）
bundle exec rspec plugins/redmine_release_kanban/spec/models/kanban/tracker_hierarchy_spec.rb

# コミット前チェック（全テスト）
bundle exec rspec plugins/redmine_release_kanban/spec
cd plugins/redmine_release_kanban && npx playwright test

# リリース前チェック（カバレッジ + 全ブラウザ）
cd /usr/src/redmine
COVERAGE=true bundle exec rspec plugins/redmine_release_kanban/spec
cd plugins/redmine_release_kanban
npx playwright test --project=chromium --project=firefox
```

## 6. Playwright Grid レイアウトテスト

### 6.1 CSS 測定テスト例

```javascript
// playwright/tests/grid-layout.spec.js
import { test, expect } from '@playwright/test';

test('grid要素がオーバーフローしていない', async ({ page }) => {
  await page.goto('http://localhost:3000/kanban');

  const metrics = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('.grid-item')).map(el => ({
      id: el.id,
      className: el.className,
      clientWidth: el.clientWidth,
      scrollWidth: el.scrollWidth,
      clientHeight: el.clientHeight,
      scrollHeight: el.scrollHeight,
      isOverflowing: el.scrollWidth > el.clientWidth ||
                     el.scrollHeight > el.clientHeight
    }));
  });

  const overflowing = metrics.filter(m => m.isOverflowing);
  expect(overflowing).toHaveLength(0);
});

test('レスポンシブデザイン検証', async ({ page }) => {
  // デスクトップ
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.goto('http://localhost:3000/kanban');
  await expect(page.locator('.kanban-board')).toBeVisible();

  // タブレット
  await page.setViewportSize({ width: 768, height: 1024 });
  await expect(page.locator('.kanban-board')).toBeVisible();

  // モバイル
  await page.setViewportSize({ width: 375, height: 667 });
  await expect(page.locator('.kanban-board')).toBeVisible();
});
```

### 6.2 Visual Regression テスト

```javascript
test('カンバンボードのビジュアル回帰テスト', async ({ page }) => {
  await page.goto('http://localhost:3000/kanban');

  // スクリーンショット比較
  await expect(page).toHaveScreenshot('kanban-board.png', {
    maxDiffPixels: 100  // 許容ピクセル差分
  });
});
```

## 7. RSpec テストパターン

### 7.1 Model Spec

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

### 7.2 Service Spec

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

### 7.3 Request Spec

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

  describe 'POST /projects/:project_id/kanban/move_card' do
    let(:issue) { create(:issue, project: project) }

    it 'カードを移動する' do
      post move_card_project_kanban_path(project), params: {
        issue_id: issue.id,
        column: 'in_progress'
      }

      expect(response).to have_http_status(:ok)
      expect(issue.reload.status.name).to eq('In Progress')
    end
  end
end
```

## 8. CI/CD 統合

### 8.1 GitHub Actions 設定

```yaml
# .github/workflows/test.yml
name: RSpec + Playwright Tests

on: [push, pull_request]

jobs:
  rspec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
          bundler-cache: true

      - name: Setup Test Environment
        run: |
          cd plugins/redmine_release_kanban
          ./bin/setup_test_env.sh

      - name: Run RSpec
        run: |
          cd /usr/src/redmine
          COVERAGE=true bundle exec rspec plugins/redmine_release_kanban/spec

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.json

  playwright:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install Playwright
        run: |
          cd plugins/redmine_release_kanban
          npm install
          npx playwright install chromium
          npx playwright install-deps chromium

      - name: Run Playwright Tests
        run: |
          cd plugins/redmine_release_kanban
          npx playwright test

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-results
          path: plugins/redmine_release_kanban/playwright-report/
```

## 9. テストデータ管理

### 9.1 FactoryBot 定義

```ruby
# spec/factories/issues.rb
FactoryBot.define do
  factory :issue do
    project
    tracker
    author { create(:user) }
    subject { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    status { IssueStatus.first || create(:issue_status) }

    trait :epic do
      tracker { create(:tracker, name: 'Epic') }
    end

    trait :feature do
      tracker { create(:tracker, name: 'Feature') }
      association :parent, factory: [:issue, :epic]
    end

    trait :user_story do
      tracker { create(:tracker, name: 'User Story') }
      association :parent, factory: [:issue, :feature]
    end
  end
end
```

## 10. パフォーマンステスト

### 10.1 N+1 検出

```ruby
# spec/requests/kanban/performance_spec.rb
require 'rails_helper'

RSpec.describe 'Kanban Performance', type: :request do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    create_list(:issue, 20, project: project)
    sign_in user
  end

  it 'N+1クエリが発生しない', :bullet do
    get project_kanban_path(project, format: :json)
    expect(response).to have_http_status(:ok)
  end

  it 'API応答が200ms以内' do
    start_time = Time.current
    get project_kanban_path(project, format: :json)
    response_time = Time.current - start_time

    expect(response_time).to be < 0.2
  end
end
```

## 11. トラブルシューティング

### 11.1 factory_girl エラー

**症状**
```
NoMethodError: private method `warn' called for class ActiveSupport::Deprecation
```

**原因**
- 他プラグインが factory_girl 4.9.0 使用
- Rails 7.2+ で非推奨メソッド使用

**解決**
- `spec/rails_helper.rb` で自動無効化済み
- セットアップスクリプトでマイグレーションスキップ

### 11.2 テストDB マイグレーションエラー

**症状**
- `rake db:migrate` 実行時に factory_girl エラー

**解決**
```bash
# マイグレーションは手動実行不要
# テストDB作成のみで RSpec 実行可能
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:create
bundle exec rspec plugins/redmine_release_kanban/spec
```

### 11.3 RSpec 実行時に gem not found

**症状**
```
can't find executable rspec for gem rspec-core
```

**原因**
- プラグインディレクトリから実行

**解決**
```bash
# 必ず Redmine ルートから実行
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec
```

### 11.4 Playwright ブラウザが起動しない

**症状**
- ヘッドレスブラウザエラー

**解決**
```bash
# ブラウザと依存関係を再インストール
cd /usr/src/redmine/plugins/redmine_release_kanban
npx playwright install chromium
npx playwright install-deps chromium
```

---

**Vibes準拠 - RSpec + Playwright テスト戦略**