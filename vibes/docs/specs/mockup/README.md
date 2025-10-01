# Nested Grid Mockup

Epic × Version Grid の4層ネスト構造を検証するためのモックアップアプリケーション

## 技術スタック

- **React 18** + **TypeScript**
- **Zustand** - 状態管理（正規化API対応）
- **Pragmatic Drag and Drop** (@atlaskit) - ドラッグ&ドロップ
- **MSW (Mock Service Worker) v2.11.3** - API モッキング
- **Vitest** + **Testing Library** - テスト
- **Webpack 5** - バンドル

## プロジェクト構成

```
mockup/
├── src/
│   ├── components/          # React コンポーネント
│   │   ├── EpicVersion/     # Epic × Version グリッド
│   │   ├── Feature/         # Feature カード
│   │   ├── UserStory/       # UserStory カード
│   │   ├── TaskTestBug/     # Task/Test/Bug アイテム
│   │   └── common/          # 共通コンポーネント
│   ├── hooks/               # カスタムフック
│   ├── mocks/               # MSW ハンドラー
│   ├── store/               # Zustand ストア
│   ├── types/               # TypeScript 型定義
│   └── App.tsx              # エントリーポイント
├── public/
│   └── mockServiceWorker.js # MSW Service Worker
└── tests/                   # テストファイル
```

## セットアップ

### 依存関係のインストール

```bash
npm install
```

### MSW Service Worker の初期化

```bash
npx msw init public/ --save
```

## 起動方法

### 開発サーバーの起動

```bash
npm run dev
```

または

```bash
npx webpack serve
```

ブラウザで http://localhost:8080 を開く

## テスト実行

### 全テスト実行

```bash
npm test
```

または

```bash
npm run test:run
```

### ウォッチモード

```bash
npm run test:watch
```

### UI モード

```bash
npm run test:ui
```

## アーキテクチャ

### データフロー（正規化API）

1. **MSW** が `/api/grid/1` リクエストをインターセプト
2. 正規化されたデータ構造（entities + grid）を返却
3. **Zustand Store** が正規化されたデータを保存
4. 各コンポーネントが **ID** を受け取り、ストアから直接データ取得

```typescript
// 正規化API レスポンス構造
{
  entities: {
    epics: { [id: string]: Epic },
    versions: { [id: string]: Version },
    features: { [id: string]: Feature },
    user_stories: { [id: string]: UserStory },
    tasks: { [id: string]: Task },
    tests: { [id: string]: Test },
    bugs: { [id: string]: Bug }
  },
  grid: {
    epic_order: string[],
    version_order: string[],
    cells: { epic_id: string, version_id: string, feature_ids: string[] }[]
  }
}
```

### コンポーネント設計

**ID ベースのプロパティ + ストアルックアップパターン**

```typescript
// ❌ 古いパターン（削除済み）
<FeatureCard feature={featureObject} />

// ✅ 新しいパターン（正規化API対応）
<FeatureCard featureId="f1" />

// コンポーネント内部
const FeatureCard: React.FC<{ featureId: string }> = ({ featureId }) => {
  const feature = useStore(state => state.entities.features[featureId]);
  // ...
};
```

**利点:**
- O(1) のデータアクセス（ハッシュマップ）
- データ変換オーバーヘッドなし
- 重複データなし（正規化）
- 再レンダリング最適化が容易

### ドラッグ&ドロップ

**Pragmatic Drag and Drop** を使用した4層ネスト対応

```typescript
// useDraggableAndDropTarget カスタムフック
const ref = useDraggableAndDropTarget({
  type: 'feature-card',  // ドラッグ可能アイテムのタイプ
  id: 'f1',              // アイテムID
  onDrop: (sourceData) => {
    // ドロップ時の処理
  }
});

return <div ref={ref} {...props} />;
```

**対応タイプ:**
- `feature-card` - Feature カード
- `user-story` - UserStory カード
- `task` - Task アイテム
- `test` - Test アイテム
- `bug` - Bug アイテム

### 状態管理

**Zustand ストア** (`src/store/useStore.ts`)

```typescript
interface StoreState {
  // 正規化データ
  entities: {
    epics: Record<string, Epic>;
    versions: Record<string, Version>;
    features: Record<string, FeatureCardData>;
    user_stories: Record<string, UserStoryData>;
    tasks: Record<string, TaskData>;
    tests: Record<string, TestData>;
    bugs: Record<string, BugData>;
  };

  // グリッド構造
  grid: {
    epic_order: string[];
    version_order: string[];
    cells: GridCell[];
  };

  // ローディング状態
  isLoading: boolean;
  error: string | null;

  // アクション
  fetchGridData: (projectId: string) => Promise<void>;
  reorderFeatures: (sourceId: string, targetId: string, targetData: any) => void;
  reorderUserStories: (sourceId: string, targetId: string, targetData: any) => void;
  // ... その他の並び替えアクション
}
```

## 検証項目

- ✅ 4層ネスト構造の描画（Epic → Version → Feature → UserStory → Task/Test/Bug）
- ✅ 各レベルでのドラッグ&ドロップ
- ✅ 正規化APIとの連携
- ✅ MSW による API モッキング
- ✅ Zustand による状態管理
- ✅ TypeScript 型安全性
- ✅ テストカバレッジ（31 tests）

## トラブルシューティング

### ポートが使用中の場合

別のポートで起動:

```bash
npx webpack serve --port 8081
```

### MSW が動作しない場合

Service Worker を再初期化:

```bash
npx msw init public/ --save
```

### テストが失敗する場合

キャッシュをクリア:

```bash
npm run test:run -- --clearCache
```

## 参考リンク

- [Pragmatic Drag and Drop Documentation](https://atlassian.design/components/pragmatic-drag-and-drop/about)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [MSW Documentation](https://mswjs.io/)
- [Vitest Documentation](https://vitest.dev/)
