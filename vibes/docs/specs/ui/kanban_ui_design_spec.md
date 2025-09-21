# カンバンUI設計仕様書

## 🔗 関連ドキュメント
- @vibes/rules/technical_architecture_standards.md

## 1. レイアウト設計

### カンバンボード構造
```
┌─────────────────────────────────────────────┐
│ [Backlog-1] [Backlog-2] [Icebox] [+新規]    │ ← VersionBar
├─────────────────────────────────────────────┤
│     │ ToDo │ In Prog │ Ready │ Released     │
├─────┼──────┼─────────┼───────┼──────────────┤
│Epic1│[Card]│ [Card]  │[Card] │              │ ← Swimlane
├─────┼──────┼─────────┼───────┼──────────────┤
│Epic2│[Card]│         │       │ [Card]       │
└─────┴──────┴─────────┴───────┴──────────────┘
```

### コンポーネント階層
```
KanbanApp
├── VersionBar
├── KanbanBoard
│   ├── SwimlaneHeader
│   └── CardGrid → DraggableCard
└── BatchActionPanel
```

## 2. ドラッグ&ドロップ仕様

### 操作パターン
- **列間移動**: ステータス変更
- **バージョン割当**: VersionBarドロップ
- **順序変更**: 同列内優先度調整

### 実装
```javascript
const handleDragEnd = (event) => {
  const { active, over } = event;
  if (over.type === 'column') moveCard(active.id, over.id);
  else if (over.type === 'version') assignVersion(active.id, over.id);
};
```

## 3. リアルタイム更新

### 楽観的UI更新
```javascript
const optimisticUpdate = async (cardId, newColumn) => {
  updateUI(cardId, newColumn);
  try { await api.moveCard(cardId, newColumn); }
  catch (error) { rollbackUI(cardId); showError(error.message); }
};
```

### 同期設定
- **更新間隔**: 30秒
- **競合解決**: 最新操作優先
- **エラー処理**: ロールバック + 通知

## 4. カード表示

### 構成要素
- **タイトル**: Issue subject
- **ID**: #番号
- **担当者**: アバター
- **ステータス**: 色付きバッジ
- **優先度**: アイコン

### 階層色分け
- **Epic**: 青
- **Feature**: 緑
- **UserStory**: 黄
- **Task/Test**: 白

## 5. インタラクション

### カード操作
- **クリック**: 詳細モーダル
- **ダブルクリック**: Redmine編集画面
- **右クリック**: コンテキストメニュー

### 一括操作
- **選択**: Ctrl+クリック
- **一括移動**: BatchActionPanel
- **一括割当**: 複数選択 + ドロップ

---

*React+@dnd-kit使用、Redmine標準UIとの整合性保持*