# 🎯 Release Kanban テスト実行ガイド

## 📋 クイックスタート

```bash
# テスト戦略の確認（必読）
cat vibes/docs/rules/kanban_test_strategy.md

# 全テスト実行
./vibes/scripts/testing/test_runner.sh

# フェーズ別実行
./vibes/scripts/testing/test_runner.sh phase1  # モデル単体テスト
./vibes/scripts/testing/test_runner.sh phase2  # サービス層テスト
./vibes/scripts/testing/test_runner.sh phase3  # API統合テスト
./vibes/scripts/testing/test_runner.sh phase4  # System/E2Eテスト

# 目的別実行
./vibes/scripts/testing/test_runner.sh quick       # 高速テスト (Phase 1+2)
./vibes/scripts/testing/test_runner.sh unit        # 単体テスト (Phase 1+2)
./vibes/scripts/testing/test_runner.sh integration # 統合テスト (Phase 3)
./vibes/scripts/testing/test_runner.sh system      # システムテスト (Phase 4)
```

## 📊 詳細情報

**テスト戦略・規約**: `vibes/docs/rules/kanban_test_strategy.md`
**テスト実行スクリプト**: `vibes/scripts/testing/test_runner.sh`

### 🎯 テスト構造

```
spec/
├── models/kanban/                     # Phase 1: モデル単体テスト
├── services/kanban/                   # Phase 2: サービス層テスト
├── requests/kanban/                   # Phase 3: API統合テスト
├── controllers/                       # Phase 3: コントローラーテスト
├── integration/kanban/                # Phase 3: 統合テスト
└── system/kanban/                     # Phase 4: System/E2Eテスト
```

### 📈 成功基準

- カバレッジ: 各コンポーネント85%以上
- 実行時間: 全テスト5分以内
- CI成功率: 95%以上

---

**⚠️ 重要**: テスト実装・修正時は必ず `vibes/docs/rules/kanban_test_strategy.md` を参照してテストピラミッド原則に従ってください