# ネストGrid検証 - 技術検証環境

## 概要

Atlassian Pragmatic Drag and Drop を使用した4層ネストGrid構造の技術検証プロジェクト。

**検証目的**: Epic×Version Grid の中に FeatureCardGrid → UserStoryGrid → TaskGrid が4層ネストできるかを検証

## プロジェクト構成

```
vibes/docs/temps/
├── README.md                           # このファイル
├── webpack.config.js                   # Webpack設定
├── package.json                        # 依存関係（親ディレクトリ参照）
├── nested_grid_test_template.html      # HTMLテンプレート
├── src/
│   └── nested_grid_test.js            # メインJavaScript（Pragmatic D&D実装）
└── dist/                               # ビルド出力（自動生成）
    ├── index.html
    └── bundle.js
```

## 環境セットアップ

### 前提条件
- Node.js 18.x以上
- npm

### 依存パッケージ

```bash
# プラグインルートディレクトリでインストール済み
cd /usr/src/redmine/plugins/redmine_release_kanban
npm install
```

**主要パッケージ**:
- `@atlaskit/pragmatic-drag-and-drop@1.26.0`
- `@atlaskit/tokens`
- `@atlaskit/motion`
- `webpack@5.102.0`
- `webpack-dev-server`

## 開発サーバー起動

### 起動コマンド

```bash
cd /usr/src/redmine/plugins/redmine_release_kanban/vibes/docs/temps
npx webpack serve --config webpack.config.js --open
```

### アクセスURL

- **ローカル**: http://localhost:9000/
- **ネットワーク**: http://172.20.0.2:9000/ (コンテナ内)

### サーバー停止

```bash
# Ctrl+C でプロセス終了
# または、ポートをkillする場合
lsof -ti:9000 | xargs kill -9
```

## 機能一覧

### 実装済み機能

#### 1. 4層ネストGrid構造
- **レベル1**: Epic × Version Grid (最上位グリッド)
- **レベル2**: FeatureCardGrid (各セル内に配置)
- **レベル3**: UserStoryGrid (Feature Card内)
- **レベル4**: TaskGrid / TestGrid / BugGrid (UserStory内)

#### 2. ドラッグ&ドロップ
- **同じ親要素内**: スワップ（位置交換）
- **異なる親要素**: 移動（append）
- **視覚的フィードバック**: `.dragging` / `.over` クラス

#### 3. 空グリッド対応
- 各グリッドに「+ Add」ボタンを配置
- ボタンは常に末尾に固定（`order: 9999`）
- ドラッグ対象から除外

#### 4. イベントログ
- ✅ `Drop detected`: ドロップイベント検知
- ✨ `Elements swapped successfully`: スワップ成功
- 🚀 `Element moved to different parent successfully`: 移動成功
- 🎉 `Swap complete!` / `Move complete!`: 完了通知

## テスト手順

### テスト1: 同じVersion内でスワップ
1. Version-1の「登録画面」と「一覧画面」をドラッグ&ドロップ
2. **期待**: 位置が入れ替わる（スワップ）
3. **ログ**: `✨ Elements swapped successfully`

### テスト2: 異なるVersion間で移動
1. Version-1の「一覧画面」をVersion-2の「編集画面」にドラッグ&ドロップ
2. **期待**: Version-1から消えて、Version-2の「編集画面」の隣に移動
3. **ログ**: `🚀 Element moved to different parent successfully`

### テスト3: 空グリッドへの移動
1. Version-1の「登録画面」をVersion-3（空のグリッド）の「+ Add Feature」ボタンにドラッグ
2. **期待**: Feature Cardが移動し、ボタンは末尾に残る
3. **ログ**: `🎉 Move complete!`

### テスト4: ボタンの末尾固定
1. 任意のFeature Cardを移動
2. **期待**: ドロップ後、すべての「+ Add Feature」ボタンが各グリッドの末尾に配置される

## 技術仕様

### Pragmatic Drag and Drop API

```javascript
// draggable（ドラッグ可能要素）
draggable({
    element: el,
    getInitialData: () => ({ type: 'feature-card', featureId, instanceId }),
    onDragStart: () => el.classList.add('dragging'),
    onDrop: () => el.classList.remove('dragging'),
});

// dropTargetForElements（ドロップターゲット）
dropTargetForElements({
    element: el,
    getData: () => ({ featureId }),
    getIsSticky: () => true,
    canDrop: ({ source }) => source.data.type === 'feature-card',
    onDragEnter: () => el.classList.add('over'),
    onDragLeave: () => el.classList.remove('over'),
    onDrop: () => el.classList.remove('over'),
});

// monitorForElements（全体監視）
monitorForElements({
    canMonitor({ source }) {
        return source.data.instanceId === instanceId;
    },
    onDrop({ source, location }) {
        // スワップまたは移動処理
    }
});
```

### DOM操作ロジック

```javascript
// スワップ（同じ親要素内）
function swapElements(sourceEl, targetEl) {
    if (sourceEl.parentElement !== targetEl.parentElement) {
        return false; // 親が異なる場合はスワップ不可
    }
    // insertBefore()で位置を入れ替え
}

// 移動（異なる親要素へ）
function moveElement(sourceEl, targetEl) {
    const targetParent = targetEl.parentElement;
    // targetElの直後に挿入
}

// Addボタンを末尾に固定
function ensureAddButtonsAtEnd() {
    document.querySelectorAll('[data-add-button]').forEach(button => {
        const parent = button.parentElement;
        if (parent && parent.lastElementChild !== button) {
            parent.appendChild(button);
        }
    });
}
```

## Hot Module Replacement (HMR)

- ファイル変更時に自動リロード
- ブラウザのリロード不要で開発効率UP

## トラブルシューティング

### ポート衝突エラー

```bash
# エラー: Address already in use - bind(2) for "0.0.0.0" port 9000
lsof -ti:9000 | xargs kill -9
```

### Webpack再起動

```bash
# Ctrl+C でプロセス終了後、再度起動
npx webpack serve --config webpack.config.js
```

### ブラウザキャッシュクリア

```bash
# Chromeの場合: Ctrl+Shift+R (スーパーリロード)
# Firefoxの場合: Ctrl+Shift+R
```

## 検証結果

### ✅ 成功した項目
- [x] CSS Grid 4層ネスト表示
- [x] Pragmatic D&D によるドラッグ&ドロップ動作
- [x] 同じ親要素内でのスワップ
- [x] 異なる親要素への移動
- [x] 空グリッドへの移動（+ Addボタン方式）
- [x] ボタンの末尾固定

### 🎯 検証結論

**4層ネストGrid + Pragmatic D&D は完全に実装可能**

- CSS Gridは無制限にネスト可能
- Pragmatic D&Dは各階層で独立して動作
- `instanceId`でイベントを分離し、親子の干渉を防止
- `getIsSticky()`で正確なドロップターゲット制御

## 次のステップ

### 本番実装への適用
1. Reactコンポーネント化
2. 状態管理（useState / Zustand / Redux）
3. API連携（カード移動時にバックエンドへPOST）
4. アニメーション強化（`@atlaskit/motion`）
5. アクセシビリティ対応（ARIA属性）

## 参考資料

- [Pragmatic Drag and Drop Documentation](https://atlassian.design/components/pragmatic-drag-and-drop/)
- [Atlassian Design System](https://atlassian.design/)
- [CSS Grid Layout](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout)

## ライセンス

このプロジェクトはRedmine Release Kanbanプラグインの一部であり、技術検証目的で作成されています。

---

**最終更新**: 2025-10-01
**検証環境**: Node.js 18.x + Webpack 5 + Pragmatic Drag and Drop 1.26.0
