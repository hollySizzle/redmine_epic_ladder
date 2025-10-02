# カンバンテスト戦略

## 🎯 基本方針

### Code as Document
テストコードが仕様書です。ドキュメントではなく、**実行可能な仕様**として機能します。

### テストピラミッド

```
      /\      E2E (Playwright) 10%
     /  \     Integration 25%
    /    \    Request 20%
   /      \   Service 20%
  /________\  Model 25%
```

---

## 🛠️ 技術スタック

| 技術 | バージョン | 用途 |
|------|-----------|------|
| **RSpec** | 6.x+ | BDD フレームワーク |
| **FactoryBot** | 6.x+ | テストデータビルダー |
| **Playwright** | 1.55+ | E2E/システムテスト |
| **playwright-ruby-client** | 1.55+ | Ruby バインディング |
| **DatabaseCleaner** | 2.1+ | トランザクション管理 |
| **Vitest** | 2.1+ | React ユニット/統合テスト |
| **MSW** | 2.6+ | API モック |

---

## 🧪 フロントエンドテスト (Vitest + MSW)

### セットアップ

```bash
cd assets/javascripts/kanban
npm install
npm test              # 38 tests
npm run dev           # MSW モック起動
```

### テストファイル構成

```
assets/javascripts/kanban/src/
├── App.test.tsx                                      # 統合テスト
├── store/useStore.test.ts                           # ストアテスト
├── components/EpicVersion/EpicVersionGrid.test.tsx  # レイアウトテスト
└── mocks/__tests__/handlers.test.ts                 # API モックテスト
```

### テスト = 仕様書

**例**: Grid レイアウト仕様
```typescript
it('should have 4 columns for 3 versions', () => {
  // 3つのversionを持つデータをセットアップ
  const mockData = { /* ... */ };

  // グリッドをレンダリング
  render(<EpicVersionGrid />);

  // 期待される振る舞い (仕様)
  expect(grid.style).toContain('repeat(3');
  expect(versionHeaders.length).toBe(3);
});
```

---

## 🧪 バックエンドテスト (RSpec + Playwright)

### 環境セットアップ (自動)

```bash
cd /usr/src/redmine/plugins/redmine_release_kanban
./bin/setup_test_env.sh
```

**実行内容**:
1. Ruby/Bundler チェック
2. factory_girl アンインストール (Rails 7.2+ 互換性)
3. RSpec gem インストール
4. Playwright インストール (Chromium)
5. テストDB セットアップ
6. ポート 3001 クリーンアップ

### Pure Playwright 方式 (Capybara 不使用)

**採用理由**:
- Capybara サーバー (別プロセス) で `Redmine::I18n` が正しく読み込まれない
- ビューの `l(:field_login)` が `I18n.localize` (日付フォーマット) として誤解釈される
- Pure Playwright なら通常の Rails リクエストとして処理され、i18n が正常動作

**実装**: `spec/rails_helper.rb` を参照

---

## 📊 テストレイヤー別実行

### Model テスト (25%)

**対象**: モデル・バリデーション・関連

```bash
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models
```

**カバレッジ目標**: 90%以上

### Service テスト (20%)

**対象**: ビジネスロジック

```bash
bundle exec rspec plugins/redmine_release_kanban/spec/services
```

**カバレッジ目標**: 100% (Critical機能)

### Request テスト (20%)

**対象**: API・Controller

```bash
bundle exec rspec plugins/redmine_release_kanban/spec/requests
```

**パフォーマンス基準**: API応答 200ms以内、クエリ数 3以下

### Integration テスト (25%)

**対象**: 機能統合・ワークフロー

```bash
bundle exec rspec plugins/redmine_release_kanban/spec/integration
```

### System テスト (10%)

**対象**: E2E/UI 操作

```bash
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system
```

**Playwright 直接実行**: 失敗時スクリーンショット自動保存

---

## 🎯 カンバン機能別カバレッジ要件

### Critical (100% カバレッジ必須)

- **TrackerHierarchy** - Epic→Feature→UserStory→Task制約
- **VersionPropagation** - 親→子バージョン伝播
- **StateTransition** - カラム移動状態制御
- **Grid Layout** - CSS/レイアウト検証

### High (90% カバレッジ目標)

- **TestGeneration** - UserStory→Test自動生成
- **ValidationGuard** - 3層ガード検証
- **DragAndDrop** - UI楽観的更新

### Medium (80% カバレッジ目標)

- **EpicSwimlane** - 表示切り替え
- **PermissionControl** - ロール別制限

---

## 🚀 開発ワークフロー

### 開発前チェック (高速)

```bash
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec/models \
                  plugins/redmine_release_kanban/spec/services
```

### コミット前チェック (全テスト)

```bash
bundle exec rspec plugins/redmine_release_kanban/spec
```

### リリース前チェック (カバレッジ)

```bash
COVERAGE=true bundle exec rspec plugins/redmine_release_kanban/spec
```

---

## 📈 品質基準

### カバレッジ

- **Critical機能**: 100%
- **High機能**: 90%
- **Medium機能**: 80%
- **全体平均**: 85%以上

SimpleCov による自動計測。

### パフォーマンス

- **API応答**: <200ms
- **N+1問題**: 禁止 (Bullet gem 使用)
- **UI反応**: <16ms (60fps, Playwright測定)
- **Grid レイアウト**: オーバーフロー 0件

### データ整合性

- **FactoryBot**: テストデータ生成
- **DatabaseCleaner**: トランザクション制御
- **Redmine default data 保護**: roles, trackers, issue_statuses など

---

## 🔧 トラブルシューティング

### i18n エラー

**症状**: `I18n::ArgumentError: Object must be a Date, DateTime or Time object`

**解決**: ✅ Pure Playwright 方式を使用 (本戦略で採用済み)

### factory_girl エラー

**症状**: `NoMethodError: private method 'warn' called for class ActiveSupport::Deprecation`

**解決**: `rails_helper.rb` で自動パッチ済み、`setup_test_env.sh` で自動処理済み

### ポート衝突

**症状**: `Address already in use - bind(2) for "0.0.0.0" port 3001`

**解決**:
```bash
lsof -ti:3001 | xargs kill -9
```

### RSpec 実行時に gem not found

**解決**:
```bash
# 必ず Redmine ルートから実行
cd /usr/src/redmine
bundle exec rspec plugins/redmine_release_kanban/spec
```

---

## 🔗 関連ドキュメント

- **技術アーキテクチャ**: @vibes/rules/technical_architecture_quickstart.md
- **AI協働規約**: @vibes/rules/ai_collaboration_redmine.md
- **Grid測定戦略**: @vibes/specs/technical/grid_measurement_strategy.md
- **rails_helper実装**: `spec/rails_helper.rb`
- **Vitest設定**: `assets/javascripts/kanban/vitest.config.ts`

---

**Vibes準拠 - Pure Playwright + RSpec + Vitest テスト戦略**
