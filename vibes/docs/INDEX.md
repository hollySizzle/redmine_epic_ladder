# Redmine Release Kanban - Documentation Index

**Last Updated**: 2025/10/02

このプロジェクトはCode as Documentを採用しています。
詳細な仕様は型定義とテストコードを参照してください。

---

## 📚 Architecture Overview

### Frontend
- **Framework**: React 18 + TypeScript
- **State**: Zustand (normalized data structure)
- **Testing**: Vitest (38 tests)
- **D&D**: @atlaskit/pragmatic-drag-and-drop
- **Bundler**: Webpack 5

### Backend
- **Framework**: Rails 7 + Redmine Plugin
- **Testing**: RSpec

### API
- **Protocol**: REST JSON
- **Type Definition**: `assets/javascripts/kanban/src/types/normalized-api.ts` (SSoT)
- **Endpoints**: `assets/javascripts/kanban/src/types/api-endpoints.ts`

---

## 🎯 Single Source of Truth (SSoT)

### API仕様
すべてのAPI仕様はTypeScript型定義として管理されています：

```typescript
// Type definitions (SSoT)
assets/javascripts/kanban/src/types/
  ├── normalized-api.ts      // API型定義（エンティティ、リクエスト、レスポンス）
  └── api-endpoints.ts       // エンドポイント定義

// 使用例
import { NormalizedAPIResponse } from './types/normalized-api';
import { API_ENDPOINTS } from './types/api-endpoints';

const response = await fetch(API_ENDPOINTS.getGrid(projectId));
const data: NormalizedAPIResponse = await response.json();
```

### フロントエンド仕様
テストコードが仕様書です：

```typescript
// Test files (Specification)
assets/javascripts/kanban/src/
  ├── App.test.tsx                                      // 統合テスト
  ├── store/useStore.test.ts                           // ストアテスト
  ├── components/EpicVersion/EpicVersionGrid.test.tsx  // グリッドレイアウトテスト
  └── mocks/__tests__/handlers.test.ts                 // APIモックテスト
```

---

## 📖 ドキュメント構成

### 1. プロジェクト規約 (`rules/`)
- [AIエージェント協働規約](rules/ai_collaboration_standards.md)
- [技術アーキテクチャ規約](rules/technical_architecture_standards.md)
- [Vibesドキュメント規約](rules/vibes_documentation_standards.md)
- [カンバンテスト戦略規約](rules/testing/kanban_test_strategy.md)

### 2. 外部API参照 (`apis/`)
- Claude Code ベストプラクティス
- PlantUML 記法リファレンス

### 3. UI仕様 (`specs/`)
- [カンバンUI設計仕様書](specs/ui/kanban_ui_design_spec.md)
- モックアップ: `specs/mockup/` (実行可能なReactアプリ)

### 4. 廃止されたドキュメント
以下は削除されました（Code as Documentに移行）：
- ~~`logics/`~~ → 型定義とテストコードで代替

---

## 🚀 Quick Start

### フロントエンド開発
```bash
cd assets/javascripts/kanban

# 依存パッケージインストール
npm install

# 開発サーバー起動（MSWモック使用）
npm run dev

# テスト実行
npm test

# 本番ビルド
npm run build
```

### バックエンド開発
```bash
# Redmine起動
cd /usr/src/redmine
RAILS_ENV=development bundle exec rails s

# テスト実行
bundle exec rspec plugins/redmine_release_kanban/spec
```

---

## 📋 Code as Document Examples

### API仕様の確認方法
```typescript
// 1. IDEで型定義を開く
import { NormalizedAPIResponse } from './types/normalized-api';

// 2. Cmd/Ctrl + クリックで定義ジャンプ
// 3. 全フィールドがJSDocコメント付きで確認可能
```

### 振る舞い仕様の確認方法
```typescript
// テストコードを読む
it('should have 4 columns for 3 versions', () => {
  // 3つのversionを持つデータをセットアップ
  const mockData = { /* ... */ };

  // グリッドをレンダリング
  render(<EpicVersionGrid />);

  // 期待される振る舞い
  expect(grid.style).toContain('repeat(3');
  expect(versionHeaders.length).toBe(3);
});
```

---

## 🔗 Related Resources

- **Redmine Plugin API**: https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial
- **React 18 Docs**: https://react.dev/
- **Zustand**: https://zustand-demo.pmnd.rs/
- **Pragmatic D&D**: https://atlassian.design/components/pragmatic-drag-and-drop/

---

**Note**: このドキュメントは最小限に保たれています。
詳細は型定義（`src/types/`）とテストコード（`**/*.test.ts(x)`）を参照してください。
