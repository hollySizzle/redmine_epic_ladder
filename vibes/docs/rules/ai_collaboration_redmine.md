# AIエージェント協働規約 (Redmine Plugin開発版)

## 🎯 基本方針

### 目的
AIエージェントとプロジェクトオーナーの効率的な協働体制を確立し、高品質な Redmine Plugin 開発を実現する。

### 原則
1. **選択肢提示必須**: AIは選択肢がある場合、必ず pro/con を提示してオーナーの判断を仰ぐ
2. **Code as Document 優先**: 型定義・テストコードが仕様、ドキュメントは最小限
3. **SSoT 厳守**: API仕様は TypeScript型定義 (`types/normalized-api.ts`) が唯一の真実

### 機能追加フロー
まずはフロントエンド改修→ MSW改修 → vitest改修･場合によっては新規テストの追加 → allgreen  にした後､バックエンドの改修に入ります｡
バックエンドはまず対象となるテストの改修･場合によっては新規テストの追加→ spec/support/msw_contracts.rb でmswとの統合テスト → バックエンドコード改修→allgreenとしてください

---

## 📂 設計書階層と責任分界

### SSoT (Single Source of Truth)

| 種別 | パス | 責任者 | AI権限 |
|------|------|--------|--------|
| **API型定義** | `assets/javascripts/epic_ladder/src/types/normalized-api.ts` | オーナー | 編集可 (要相談) |
| **API Endpoints** | `assets/javascripts/epic_ladder/src/types/api-endpoints.ts` | オーナー | 編集可 (要相談) |
| **テストコード** | `**/*.test.tsx`, `spec/**/*_spec.rb` | AI主導 | 自立実行可 |
| **アーキテクチャ規約** | `vibes/docs/rules/` | オーナー承認 | 提案可 |

### ドキュメント階層 (Vibes準拠)

| ディレクトリ | 役割 | AI権限 |
|-------------|------|--------|
| `vibes/docs/rules/` | プロジェクト規約 | 編集不可、提案のみ |
| `vibes/docs/specs/` | 技術仕様 | 編集可 (アーキテクチャ変更時のみ) |
| `vibes/docs/tasks/` | 作業手順書 | 自立作成・更新可 |
| `vibes/docs/temps/` | 一時ドキュメント | 自立作成・削除可 |

---

## 🔐 AIエージェント権限規定

### 自立実行可能範囲

**Rails実装**:
- Controller/Model/Service実装
- RSpec/Playwright テスト実装
- 既存アーキテクチャに準拠した実装

**React実装**:
- コンポーネント実装
- Vitest テスト実装
- Zustand ストア実装
- MSW モックハンドラ実装

**ドキュメント**:
- `vibes/docs/tasks/` 配下の作成・更新
- `vibes/docs/temps/` 配下の作成・削除
- テストコード内のコメント

### 要相談範囲 (許可後は実行可能)

**API仕様変更**:
- `types/normalized-api.ts` の型定義追加・変更
- `types/api-endpoints.ts` のエンドポイント追加
- レスポンス形式変更

**アーキテクチャ変更**:
- 新規レイヤー追加
- 新規技術スタック導入
- ディレクトリ構造変更

**規約変更**:
- `vibes/docs/rules/` 配下の編集
- コーディング規約追加・変更

### 絶対禁止範囲

- ❌ Redmine コア機能の変更
- ❌ Redmine データベーススキーマ変更 (マイグレーション禁止)
- ❌ 他プラグインの Gemfile 編集
- ❌ SSoT (型定義) を無視した実装

---

## 🔄 協働フロー

### Phase 1: 設計フェーズ

**責任者**: オーナー主導、AIサポート

1. オーナー: 要件定義・機能方針決定
2. AI: TypeScript型定義叩き台作成 (SSoT)
3. **チェックポイント**: オーナーによる型定義承認

### Phase 2: 実装設計フェーズ

**責任者**: AI主導、オーナー承認

1. AI: Controller/Service設計書作成
2. AI: テスト戦略提示 (RSpec + Playwright)
3. **チェックポイント**: オーナーによる設計承認

### Phase 3: 実装フェーズ

**責任者**: AI自立

1. AI: Rails実装 (Controller/Service/RSpec)
2. AI: React実装 (Component/Vitest)
3. **自動チェック**: RuboCop、Vitest、RSpec実行

### Phase 4: 手動検証フェーズ

**責任者**: オーナー

1. オーナー: ブラウザで実際の動作確認
2. オーナー: フィードバック (具体的修正指示)
3. **ループ**: 必要に応じて Phase 3 に戻る

### Phase 5: 統合テスト強化フェーズ

**責任者**: AI主導

1. AI: Playwright E2Eテスト追加
2. AI: RSpec統合テスト強化
3. **完了条件**: 手動テストなしでリリース可能な品質

---

## 🧪 テスト戦略との連携

### Code as Document 原則

**仕様書 = テストコード**:
- フロントエンド仕様: `**/*.test.tsx` (Vitest)
- バックエンド仕様: `spec/**/*_spec.rb` (RSpec)
- E2E仕様: `spec/system/**/*_spec.rb` (Playwright)

### AIによるテスト駆動開発

1. **Red**: 失敗するテストを先に書く
2. **Green**: 最小限の実装でテストを通す
3. **Refactor**: コード品質向上
4. **Document**: テストコードが仕様書として機能

---

## ⚠️ エラー時エスカレーション

### 即座停止が必要なケース

1. **SSoT不整合発見** - 型定義と実装が乖離している
2. **Redmineコア機能破壊** - 他プラグイン・Redmine標準機能に影響
3. **セキュリティ脆弱性** - 権限チェック漏れ、SQLインジェクションなど

### 3回連続失敗ルール

- 同一テストが3回連続で失敗 → 一旦停止、方針確認
- RuboCop違反が3回連続で解消しない → 規約確認、例外設定検討

---

## ✅ 実装チェックリスト

### 実装前チェック

- [ ] SSoT (型定義) を確認・理解した
- [ ] アーキテクチャ規約に準拠している
- [ ] テスト戦略を理解した
- [ ] 権限範囲内の作業である

### 実装後チェック

- [ ] RuboCop 違反なし
- [ ] Vitest 全テストパス
- [ ] RSpec 全テストパス
- [ ] N+1問題なし (Bullet確認)
- [ ] API応答200ms以内 (パフォーマンス要件)

### リリース前チェック

- [ ] Playwright E2Eテストパス
- [ ] カバレッジ基準達成 (Critical 100%, 全体85%)
- [ ] 手動テストで主要機能確認
- [ ] ドキュメント更新 (必要最小限)

---

## 🔗 関連ドキュメント

- **技術アーキテクチャ**: @vibes/rules/technical_architecture_quickstart.md
- **バックエンド規約**: @vibes/rules/backend_standards.md
- **テスト戦略**: @vibes/rules/testing_strategy.md
- **API型定義 (SSoT)**: @kanban/src/types/normalized-api.ts
