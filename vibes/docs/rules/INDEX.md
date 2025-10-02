# Redmine Release Kanban - 開発規約インデックス

## 📋 目次
- [Redmine Release Kanban - 開発規約インデックス](#redmine-release-kanban---開発規約インデックス) (L1-209)
  - [🎯 最優先ドキュメント (必読)](#-最優先ドキュメント-必読) (L5-11)
  - [📂 規約ドキュメント構成](#-規約ドキュメント構成) (L13-54)
    - [1. アーキテクチャ & 技術スタック](#1-アーキテクチャ--技術スタック) (L15-21)
    - [2. バックエンド実装規約](#2-バックエンド実装規約) (L23-29)
    - [3. AI協働規約](#3-ai協働規約) (L31-37)
    - [4. テスト戦略](#4-テスト戦略) (L39-45)
    - [5. ドキュメント規約](#5-ドキュメント規約) (L47-54)
  - [⚡ Quick Start](#-quick-start) (L56-86)
    - [フロントエンド開発](#フロントエンド開発) (L58-66)
    - [バックエンド開発](#バックエンド開発) (L68-80)
    - [カンバン表示確認](#カンバン表示確認) (L82-86)
  - [🔗 Code as Document 原則](#-code-as-document-原則) (L88-127)
    - [API仕様 = TypeScript型定義](#api仕様--typescript型定義) (L92-103)
    - [振る舞い仕様 = テストコード](#振る舞い仕様--テストコード) (L105-117)
    - [実装パターン = 実コード参照](#実装パターン--実コード参照) (L119-127)
  - [📈 ドキュメント削減実績](#-ドキュメント削減実績) (L129-141)
  - [🔍 ドキュメント検索](#-ドキュメント検索) (L143-171)
    - [目的別インデックス](#目的別インデックス) (L145-155)
    - [ドキュメント参照形式](#ドキュメント参照形式) (L157-171)
  - [🛠️ ドキュメント管理コマンド](#️-ドキュメント管理コマンド) (L173-185)
    - [目次自動更新](#目次自動更新) (L175-179)
    - [参照チェック](#参照チェック) (L181-185)
  - [🔗 外部リソース](#-外部リソース) (L187-209)

**Last Updated**: 2025/10/02

## 🎯 最優先ドキュメント (必読)

新規参加者は以下の順序で読んでください:

1. **API仕様 (SSoT)**: `@kanban/src/types/normalized-api.ts` - 全API型定義
2. **アーキテクチャ**: `@vibes/rules/technical_architecture_quickstart.md` - 4層階層、技術スタック
3. **テストコード**: `@kanban/src/**/*.test.tsx`, `spec/**/*_spec.rb` - 実行可能な仕様書

---

## 📂 規約ドキュメント構成

### 1. アーキテクチャ & 技術スタック

- **`technical_architecture_quickstart.md`** (60行)
  - 4層階層定義 (Epic→Feature→UserStory→Task)
  - レイヤーアーキテクチャ (UI→API→Service→Domain→DB)
  - 技術スタック (React 18, Rails 7, Webpack 5)
  - SSoT参照 (TypeScript型定義)

### 2. バックエンド実装規約

- **`backend_standards.md`** (170行)
  - Controller層の原則 (責務、セキュリティ、パフォーマンス)
  - Service層の原則 (単一責任、戻り値統一、冪等性)
  - 実装チェックリスト
  - 参照実装: `app/controllers/kanban/`, `app/services/kanban/`

### 3. AI協働規約

- **`ai_collaboration_redmine.md`** (120行)
  - 権限規定 (自立実行可/要相談/絶対禁止)
  - SSoT厳守 (型定義が唯一の真実)
  - 協働フロー (Phase 1〜5)
  - エスカレーション基準

### 4. テスト戦略

- **`testing_strategy.md`** (180行)
  - フロントエンド: Vitest + MSW (38 tests)
  - バックエンド: RSpec + Playwright (Pure方式)
  - カバレッジ要件 (Critical 100%, 全体85%)
  - パフォーマンス基準 (API<200ms, N+1禁止)

### 5. ドキュメント規約

- **`vibes_documentation_standards.md`** (15行)
  - ディレクトリ構成 (rules/specs/tasks/temps)
  - Code as Document原則
  - 責務分離

---

## ⚡ Quick Start

### フロントエンド開発

```bash
cd assets/javascripts/kanban

npm install              # 依存パッケージインストール
npm test                 # Vitest (38 tests)
npm run dev              # MSW モック起動 (http://localhost:9000)
npm run build            # 本番ビルド
```

### バックエンド開発

```bash
cd /usr/src/redmine

# 環境セットアップ (初回のみ)
./plugins/redmine_release_kanban/bin/setup_test_env.sh

# 開発サーバー起動
RAILS_ENV=development bundle exec rails s -p 3000

# テスト実行
bundle exec rspec plugins/redmine_release_kanban/spec
```

### カンバン表示確認

1. Redmine起動: `http://localhost:3000`
2. プロジェクト選択
3. カンバンタブをクリック

---

## 🔗 Code as Document 原則

本プロジェクトでは、**コードが仕様書**です:

### API仕様 = TypeScript型定義

```typescript
// SSoT: assets/javascripts/kanban/src/types/normalized-api.ts
export interface NormalizedAPIResponse {
  entities: {
    epics: Record<string, Epic>;
    versions: Record<string, Version>;
    features: Record<string, Feature>;
    // ...
  };
  grid: GridIndex;
  metadata: Metadata;
}
```

### 振る舞い仕様 = テストコード

```typescript
// 仕様書: assets/javascripts/kanban/src/components/EpicVersion/EpicVersionGrid.test.tsx
it('should have 4 columns for 3 versions', () => {
  const mockData = createMockData(3); // 3 versions
  render(<EpicVersionGrid />);

  // 期待される振る舞い
  expect(grid.style).toContain('repeat(3');
  expect(versionHeaders.length).toBe(3);
});
```

### 実装パターン = 実コード参照

- **Controller**: `app/controllers/kanban/`
- **Service**: `app/services/kanban/`
- **Component**: `assets/javascripts/kanban/src/components/`

---

## 📈 ドキュメント削減実績

**Before** (旧構成):
- 10ファイル、1,856行
- logics/ 配下に16ファイル (7,621行) のAPI仕様書
- 合計: **9,477行**

**After** (新構成):
- 5ファイル、545行 (規約)
- TypeScript型定義: 468行 (SSoT)
- テストコード: 38 tests (実行可能仕様)
- 合計: **1,013行** (89%削減)

---

## 🔍 ドキュメント検索

### 目的別インデックス

| やりたいこと | 参照先 |
|------------|--------|
| API仕様を確認したい | `@kanban/src/types/normalized-api.ts` |
| 4層階層を理解したい | `@vibes/rules/technical_architecture_quickstart.md` |
| Controllerを実装したい | `@vibes/rules/backend_standards.md` (Controller原則) |
| Serviceを実装したい | `@vibes/rules/backend_standards.md` (Service原則) |
| テストを書きたい | `@vibes/rules/testing_strategy.md` |
| AI協働方針を知りたい | `@vibes/rules/ai_collaboration_redmine.md` |

### ドキュメント参照形式

**Vibes規約**: `@vibes/` から始まる相対パス

```markdown
<!-- 正しい参照 -->
[技術アーキテクチャ](@vibes/rules/technical_architecture_quickstart.md)

<!-- 間違った参照 -->
[技術アーキテクチャ](../technical_architecture_quickstart.md)
```

---

## 🛠️ ドキュメント管理コマンド

### 目次自動更新

```bash
cd vibes/scripts
python3 main.py --direct doc --action update_all
```

### 参照チェック

```bash
python3 main.py --direct doc --action check_all
```

---

## 🔗 外部リソース

- **Redmine Plugin API**: https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial
- **React 18 Docs**: https://react.dev/
- **Zustand**: https://zustand-demo.pmnd.rs/
- **Playwright Ruby Client**: https://github.com/YusukeIwaki/playwright-ruby-client
- **RSpec**: https://rspec.info/features/6-0/rspec-rails/

---

**Note**: このドキュメントは最小限に保たれています。
詳細は型定義 (`src/types/`) とテストコード (`**/*.test.ts(x)`) を参照してください。
