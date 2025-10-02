# Nested Grid Mockup

Epic × Version Grid の4層ネスト構造を検証するモックアップ

## 技術スタック

- React 18 + TypeScript
- Zustand (状態管理)
- Pragmatic Drag and Drop (ドラッグ&ドロップ)
- MSW v2.11.3 (API モッキング)
- Vitest (テスト)
- Webpack 5 (バンドル)

## セットアップ

```bash
npm install
npx msw init public/ --save
```

## 起動方法

```bash
npm run dev
```

http://localhost:9000 を開く

## テスト実行

```bash
# 全テスト実行
npm run test:run

# ウォッチモード
npm run test:watch

# UI モード
npm run test:ui
```

## アーキテクチャ

### 正規化API

MSWが `/api/kanban/projects/:projectId/grid` をモック。正規化されたデータ構造を返す:

```typescript
{
  entities: {
    epics: { [id]: Epic },
    versions: { [id]: Version },
    features: { [id]: Feature },
    user_stories: { [id]: UserStory },
    tasks: { [id]: Task },
    tests: { [id]: Test },
    bugs: { [id]: Bug }
  },
  grid: {
    epic_order: string[],
    version_order: string[],
    index: { "epicId:versionId": string[] }
  }
}
```

### コンポーネント設計

ID ベースのプロパティ + ストアルックアップパターン:

```typescript
<FeatureCard featureId="f1" />

const FeatureCard: React.FC<{ featureId: string }> = ({ featureId }) => {
  const feature = useStore(state => state.entities.features[featureId]);
  // ...
};
```

### ドラッグ&ドロップ

Pragmatic Drag and Drop で4層ネスト対応:

- `feature-card` - Feature カード
- `user-story` - UserStory カード
- `task` / `test` / `bug` - 子アイテム

## トラブルシューティング

### ポート変更

```bash
npx webpack serve --port 8081
```

### MSW 再初期化

```bash
npx msw init public/ --save
```

### テストキャッシュクリア

```bash
npm run test:run -- --clearCache
```
