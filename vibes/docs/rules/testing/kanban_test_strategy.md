# カンバンテスト戦略（Redmine標準）

## 🔗 関連ドキュメント
- @vibes/rules/technical_architecture_standards.md
- @vibes/rules/testing/redmine_test_implementation_guide.md
- @vibes/rules/testing/test_automation_strategy.md

## 1. テスト技術スタック

### 1.1 採用フレームワーク
- **Test::Unit** - Redmine標準
- **Mocha** - モック・スタブ
- **Minitest** - Rails7.x標準
- **ActionDispatch::IntegrationTest** - 統合テスト
- **Capybara** - システムテスト

### 1.2 選択理由
```
✅ Redmine公式サポート・環境統一
✅ redmine:plugins:testタスク完全対応
✅ 学習コスト削減・メンテナンス簡素化
❌ RSpec/FactoryBot依存排除
```

## 2. テストピラミッド

```
      /\      System（10%）
     /  \     Integration（30%）
    /    \    Functional（25%）
   /      \   Unit（35%）
  /________\
```

| タイプ | 配置 | 実行コマンド | 対象 |
|--------|------|-------------|------|
| Unit | `test/unit/` | `rake redmine:plugins:test:units` | モデル・サービス・ヘルパー |
| Functional | `test/functional/` | `rake redmine:plugins:test:functionals` | コントローラー・API |
| Integration | `test/integration/` | `rake redmine:plugins:test:integration` | リクエスト〜DB |
| System | `test/system/` | `rake redmine:plugins:test:system` | E2E・ブラウザ操作 |

## 3. カンバン機能別テスト要件

### 3.1 Critical（100%カバレッジ必須）
- **TrackerHierarchy** - Epic→Feature→UserStory→Task/Test制約
- **VersionPropagation** - 親→子バージョン伝播
- **StateTransition** - カラム移動状態制御

### 3.2 High（90%カバレッジ目標）
- **TestGeneration** - UserStory→Test自動生成
- **ValidationGuard** - 3層ガード検証
- **BlocksRelation** - blocks関係管理

### 3.3 Medium（80%カバレッジ目標）
- **DragAndDrop** - UI楽観的更新
- **EpicSwimlane** - 表示切り替え
- **PermissionControl** - ロール別制限

## 4. 品質基準

### 4.1 カバレッジ
- Critical: 100%、High: 90%、Medium: 80%
- 全体平均: 85%以上

### 4.2 パフォーマンス
- API応答: <200ms、N+1問題: 禁止、UI反応: <16ms

### 4.3 データ管理
- Fixtures活用、FactoryBot不使用、トランザクション制御

## 5. 実行戦略

### 5.1 フェーズ別
```bash
./bin/test_runner.sh phase1  # Critical
./bin/test_runner.sh phase2  # High
./bin/test_runner.sh phase3  # Integration
./bin/test_runner.sh phase4  # System
./bin/test_runner.sh quick   # 開発用
./bin/test_runner.sh full    # 全体
```

### 5.2 開発ワークフロー
```bash
rake redmine:plugins:test:units PLUGIN=redmine_release_kanban      # 機能開発
rake redmine:plugins:test:functionals PLUGIN=redmine_release_kanban # API変更
rake redmine:plugins:test PLUGIN=redmine_release_kanban             # リリース前
```

## 6. 障害対策

### 6.1 環境問題
- factory_girl依存 → Redmine標準フィクスチャ
- rspec依存 → Test::Unit統一
- SimpleCov設定 → 基本カバレッジのみ

### 6.2 プラグイン固有
- フィクスチャ競合 → test_helper.rb適切読み込み
- 権限テスト → User.current設定・teardown
- DBトランザクション → use_transactional_tests = true

---

*Redmine標準手法でカンバン品質保証と開発効率を両立*