# 🎯 Release Kanban テスト実行ガイド

## 📋 クイックスタート

```bash
# テスト戦略の確認（必読）
cat vibes/docs/rules/testing/kanban_test_strategy.md

# 環境セットアップ（初回のみ）
bundle install
npm install
npx playwright install chromium

# RSpec テスト実行
bundle exec rspec                    # 全テスト
bundle exec rspec spec/models        # Model テスト
bundle exec rspec spec/services      # Service テスト
bundle exec rspec spec/requests      # Request/API テスト
bundle exec rspec spec/system        # System テスト

# Playwright テスト実行
npx playwright test                  # 全 E2E テスト
npx playwright test --headed         # ブラウザ表示付き
npx playwright test grid-layout      # Grid レイアウト専用

# 開発用高速テスト
bundle exec rspec --tag ~slow        # 遅いテスト除外
bundle exec rspec --fail-fast        # 最初の失敗で停止

# カバレッジ計測
COVERAGE=true bundle exec rspec
```

## 📊 詳細情報

**テスト戦略・規約**: `vibes/docs/rules/testing/kanban_test_strategy.md`

### 🎯 テスト構造

```
spec/
├── models/kanban/                     # Model テスト (25%)
├── services/kanban/                   # Service テスト (20%)
├── requests/kanban/                   # Request/API テスト (20%)
├── integration/kanban/                # Integration テスト (25%)
├── system/kanban/                     # System/E2E テスト (10%)
├── factories/                         # FactoryBot 定義
├── support/                           # テストヘルパー
└── rails_helper.rb                    # RSpec 設定

playwright/
├── tests/                             # Playwright E2E テスト
│   ├── grid-layout.spec.js           # Grid レイアウトテスト
│   └── visual-regression.spec.js     # ビジュアル回帰テスト
└── playwright.config.js               # Playwright 設定
```

### 📈 成功基準

- **カバレッジ**: Critical 100%、High 90%、Medium 80%、全体 85%以上
- **パフォーマンス**: API応答 <200ms、N+1問題禁止、UI反応 <16ms
- **Grid レイアウト**: オーバーフロー 0件、レスポンシブ対応
- **CI成功率**: 95%以上

## 🚀 開発ワークフロー

### 開発前チェック
```bash
bundle exec rspec spec/models spec/services
```

### 機能開発中
```bash
# 関連テストのみ実行
bundle exec rspec spec/models/kanban/tracker_hierarchy_spec.rb
```

### コミット前チェック
```bash
bundle exec rspec                        # 全 RSpec テスト
npx playwright test --project=chromium   # E2E テスト
```

### リリース前チェック
```bash
COVERAGE=true bundle exec rspec          # カバレッジ付き全テスト
npx playwright test --project=chromium --project=firefox --project=webkit  # 全ブラウザ
```

## 🔧 環境セットアップ詳細

### 1. Ruby 環境

```bash
# Gemfile にテスト用 Gem を追加
group :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'simplecov', '~> 0.22', require: false
  gem 'bullet', '~> 7.1'
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver', '~> 4.15'
end

# インストール
bundle install

# RSpec 初期化
rails generate rspec:install
```

### 2. Playwright 環境

```bash
# package.json 作成
npm init -y

# Playwright インストール
npm install -D @playwright/test
npx playwright install chromium firefox webkit

# 設定ファイル生成
npx playwright init
```

### 3. データベース設定

```bash
# テストDB作成
RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:migrate
```

## 📝 テストパターン例

### Model Spec

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
end
```

### Request Spec

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
    end
  end
end
```

### Playwright Grid Layout Test

```javascript
// playwright/tests/grid-layout.spec.js
import { test, expect } from '@playwright/test';

test('grid要素がオーバーフローしていない', async ({ page }) => {
  await page.goto('http://localhost:3000/kanban');

  const metrics = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('.grid-item')).map(el => ({
      id: el.id,
      isOverflowing: el.scrollWidth > el.clientWidth ||
                     el.scrollHeight > el.clientHeight
    }));
  });

  const overflowing = metrics.filter(m => m.isOverflowing);
  expect(overflowing).toHaveLength(0);
});
```

## 🐛 トラブルシューティング

### RSpec でテストが失敗する

```bash
# データベースをリセット
RAILS_ENV=test bundle exec rails db:drop db:create db:migrate

# キャッシュをクリア
bundle exec rails tmp:clear

# Bundler を更新
bundle update
```

### Playwright でブラウザが起動しない

```bash
# ブラウザを再インストール
npx playwright install --force chromium

# 依存関係をインストール（Linux）
npx playwright install-deps
```

### カバレッジが正しく計測されない

```bash
# coverage/ ディレクトリを削除
rm -rf coverage/

# カバレッジ付きで再実行
COVERAGE=true bundle exec rspec
```

## 📚 参考ドキュメント

- **テスト戦略規約**: `vibes/docs/rules/testing/kanban_test_strategy.md`
- **技術アーキテクチャ**: `vibes/docs/rules/technical_architecture_standards.md`
- **RSpec 公式**: https://rspec.info/
- **Playwright 公式**: https://playwright.dev/
- **FactoryBot 公式**: https://github.com/thoughtbot/factory_bot

## 🎯 重要な変更点（Test::Unit からの移行）

### 削除されたもの
- ❌ `test/` ディレクトリ（Test::Unit）
- ❌ `test/fixtures/` （Fixtures）
- ❌ `rake redmine:plugins:test` コマンド
- ❌ `test/test_helper.rb`

### 追加されたもの
- ✅ `spec/` ディレクトリ（RSpec）
- ✅ `spec/factories/` （FactoryBot）
- ✅ `bundle exec rspec` コマンド
- ✅ `playwright/` ディレクトリ（Playwright）
- ✅ `spec/rails_helper.rb`

### コマンド対応表

| 旧（Test::Unit） | 新（RSpec） |
|---------------|-----------|
| `rake redmine:plugins:test:units` | `bundle exec rspec spec/models spec/services` |
| `rake redmine:plugins:test:functionals` | `bundle exec rspec spec/requests` |
| `rake redmine:plugins:test:integration` | `bundle exec rspec spec/integration` |
| `rake redmine:plugins:test:system` | `bundle exec rspec spec/system` + `npx playwright test` |
| `rake redmine:plugins:test` | `bundle exec rspec` |

---

**⚠️ 重要**: テスト実装・修正時は必ず `vibes/docs/rules/testing/kanban_test_strategy.md` を参照してテストピラミッド原則に従ってください

*RSpec + Playwright によるモダンで強力なテスト環境*