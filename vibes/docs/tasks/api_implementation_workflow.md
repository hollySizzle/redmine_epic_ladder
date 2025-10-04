# API実装ワークフロー

**アーキテクチャ**: Rails API + React SPA + MSW + Zustand
**原則**: SSoT (TypeScript型定義) → MSW → Rails

---

## 実装ステップ

### 1. 型定義 (SSoT)
**場所**: `normalized-api.ts`

- Request型とResponse型のペアを定義
- 既存パターン (`MoveFeatureResponse`) を踏襲
- 完全正規化形式: `created_entity` + `updated_entities` + `grid_updates` + `meta`
- 関連エンティティの更新も含める (親の統計情報など)

### 2. MSWハンドラ
**場所**: `handlers.ts`

- RESTful URLでエンドポイント定義 (`POST /api/kanban/projects/:projectId/cards`)
- Rails APIと完全一致させる
- 親エンティティの存在確認
- 新規エンティティ作成・追加
- グリッドインデックス更新
- 親エンティティの統計情報自動更新
- タイムスタンプ更新
- 完全正規化レスポンス返却

### 3. API Client
**場所**: `kanban-api.ts`

- MSW/Rails API両対応のfetch関数実装
- エラーハンドリング統一 (`KanbanAPIError`)
- 型安全性確保 (Request/Response型を使用)
- JSDocコメント追加

### 4. Zustand統合
**場所**: `useStore.ts`

- `projectId`チェック
- API Client呼び出し
- 完全正規化データを`Object.assign`でマージ
- エラー時に`throw`して呼び出し元へ伝播

### 5. UI接続
**場所**: コンポーネント (`FeatureCardGrid.tsx`など)

- Zustandストアから関数取得
- ユーザー入力収集 (prompt/モーダル)
- API呼び出し
- エラーハンドリング (alertなど)

### 6. テスト
**場所**: `assets/javascripts/epic_grid/`

- 全テストパス必須 (`npm test`)
- 既存テストが壊れていないか確認

### 7. ブラウザ確認
- webpack dev server起動 (`npm run dev`)
- `http://localhost:9000` でアクセス (**localhost:3000 ではない**)
- 機能動作確認
- DevTools Network/Storeタブで状態確認

### 8. Rails実装 (将来)
**場所**: `app/controllers/kanban/cards_controller.rb`

- MSWハンドラと完全一致させる
- Service層で業務ロジック実装
- N+1対策 (includes/eager_load)
- 権限チェック (before_action)

---

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| デフォルトアラート表示 | 古いバンドル読み込み | `localhost:9000`でアクセス |
| webpack error | 間違ったディレクトリ | `assets/javascripts/epic_grid/`で実行 |
| テスト失敗 | 型定義とMSWの不整合 | `normalized-api.ts`と`handlers.ts`を照合 |
