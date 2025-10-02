# Release Kanban テスト実行ガイド

## クイックスタート

### 環境セットアップ（初回のみ）

**自動セットアップ（推奨）**
```bash
cd /usr/src/redmine/plugins/redmine_release_kanban
./bin/setup_test_env.sh
```

**手動セットアップ**
```bash
# Ruby gem
cd /usr/src/redmine
bundle install

# Node.js パッケージ
cd plugins/redmine_release_kanban
npm install
npx playwright install chromium
npx playwright install-deps chromium

# テストDB（オプション）
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:create
```

### RSpec テスト実行

**重要**: Redmine ルートディレクトリから実行

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
bundle exec rspec --tag ~slow          # 遅いテスト除外
bundle exec rspec --fail-fast          # 最初の失敗で停止
COVERAGE=true bundle exec rspec        # カバレッジ計測
```

### Playwright テスト実行

**重要**: プラグインディレクトリから実行

```bash
cd /usr/src/redmine/plugins/redmine_release_kanban

# 全 E2E テスト
npx playwright test

# オプション
npx playwright test --headed           # ブラウザ表示
npx playwright test --project=chromium # ブラウザ指定
npx playwright test grid-layout        # Grid レイアウト専用
npx playwright test --debug            # デバッグモード
```

## テスト構造

```
spec/
├── models/kanban/           # Model テスト (25%)
├── services/kanban/         # Service テスト (20%)
├── requests/kanban/         # Request/API テスト (20%)
├── integration/kanban/      # Integration テスト (25%)
├── system/kanban/           # System/E2E テスト (10%)
├── factories/               # FactoryBot 定義
├── support/                 # テストヘルパー
└── rails_helper.rb          # RSpec 設定（factory_girl 無効化含む）

playwright/
├── tests/                   # Playwright E2E テスト
│   ├── grid-layout.spec.js
│   └── visual-regression.spec.js
└── playwright.config.js
```

## 品質基準

- **カバレッジ**: Critical 100%、High 90%、Medium 80%、全体 85%以上
- **パフォーマンス**: API <200ms、N+1禁止、UI <16ms
- **Grid レイアウト**: オーバーフロー 0件
- **CI成功率**: 95%以上

## 開発ワークフロー

### 開発前チェック（高速）
```bash
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models \
                  plugins/redmine_release_kanban/spec/services
```

### 機能開発中（関連テスト）
```bash
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models/kanban/tracker_hierarchy_spec.rb
```

### コミット前チェック（全テスト）
```bash
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec

cd plugins/redmine_release_kanban
npx playwright test
```

### リリース前チェック（カバレッジ + 全ブラウザ）
```bash
cd /usr/src/redmine
COVERAGE=true bundle exec rspec plugins/redmine_release_kanban/spec

cd plugins/redmine_release_kanban
npx playwright test --project=chromium --project=firefox
```

## トラブルシューティング

### factory_girl エラー

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

### RSpec 実行時に gem not found

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

### テストDB マイグレーションエラー

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

### Playwright ブラウザが起動しない

**症状**
- ヘッドレスブラウザエラー

**解決**
```bash
# ブラウザと依存関係を再インストール
cd /usr/src/redmine/plugins/redmine_release_kanban
npx playwright install chromium
npx playwright install-deps chromium
```

## テストパターン例

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

## 参考ドキュメント

- **テスト戦略規約**: `vibes/docs/rules/testing/kanban_test_strategy.md`
- **技術アーキテクチャ**: `vibes/docs/rules/technical_architecture_standards.md`
- **RSpec 公式**: https://rspec.info/
- **Playwright 公式**: https://playwright.dev/
- **FactoryBot 公式**: https://github.com/thoughtbot/factory_bot

## Test::Unit からの移行

### コマンド対応表

| 旧（Test::Unit） | 新（RSpec + Playwright） |
|---------------|----------------------|
| `rake redmine:plugins:test:units` | `bundle exec rspec plugins/redmine_release_kanban/spec/models` |
| `rake redmine:plugins:test:functionals` | `bundle exec rspec plugins/redmine_release_kanban/spec/requests` |
| `rake redmine:plugins:test:integration` | `bundle exec rspec plugins/redmine_release_kanban/spec/integration` |
| `rake redmine:plugins:test:system` | `npx playwright test` |
| `rake redmine:plugins:test` | `bundle exec rspec plugins/redmine_release_kanban/spec` |

### 削除されたもの
- ❌ `test/` ディレクトリ
- ❌ `test/fixtures/`
- ❌ `test/test_helper.rb`

### 追加されたもの
- ✅ `spec/` ディレクトリ
- ✅ `spec/factories/` （FactoryBot）
- ✅ `playwright/` ディレクトリ
- ✅ `spec/rails_helper.rb` （factory_girl 無効化含む）
- ✅ `bin/setup_test_env.sh` （自動セットアップ）

---

**重要**: テスト実装時は `vibes/docs/rules/testing/kanban_test_strategy.md` を参照