# Grid レイアウト定量測定ガイド

## 関連ドキュメント
- @vibes/rules/testing/kanban_test_strategy.md
- @vibes/rules/technical_architecture_standards.md

## 1. 測定対象の問題

### 1.1 CSS Grid 構造の問題

**HTML構造**
```html
<div class="kanban-grid-body" style="--grid-columns: 1; --grid-rows: 3;">
  <div class="epic-row" data-row-index="0">      <!-- display: contents -->
    <div class="epic-header-cell">...</div>       <!-- Grid セル 1 -->
    <div class="grid-cell">...</div>              <!-- Grid セル 2 -->
  </div>
  <div class="no-epic-row" data-row-index="1">   <!-- display: contents -->
    <div class="no-epic-header-cell">...</div>    <!-- Grid セル 3 -->
    <div class="grid-cell">...</div>              <!-- Grid セル 4 -->
    <div class="no-epic-empty-state">...</div>    <!-- Grid セル 5 -->
  </div>
  <div class="new-epic-row" data-row-index="2">  <!-- display: contents -->
    <div class="new-epic-button-container">...</div> <!-- Grid セル 6 -->
  </div>
</div>
```

**問題点**
- Grid定義: `1列 × 3行 = 3セル`
- 実際の子要素: `6セル` （display: contents により展開）
- 結果: Grid が `2列×3行` として解釈される可能性
- 影響: ヘッダーとセルの配置ズレ、オーバーフロー、視認性低下

### 1.2 測定すべき指標

| 指標 | 測定方法 | 正常値 | 異常判定 |
|------|---------|--------|---------|
| Grid構造整合性 | 宣言列数 vs 実セル数 | 一致または誤差50%以内 | 2倍以上の差 |
| 横オーバーフロー | scrollWidth > clientWidth | 0px | 1px以上 |
| 縦オーバーフロー | scrollHeight > clientHeight | 0px | 1px以上 |
| ビューポート外配置 | getBoundingClientRect() | 画面内 | right > innerWidth |
| セル配置精度 | ヘッダーとセルの相対位置 | 右側または下側 | 重なり・逆配置 |
| レイアウト計算時間 | performance.now() | <16ms | ≥16ms（60fps未満）|

## 2. Playwright 測定戦略

### 2.1 テストファイル

**配置**: `playwright/tests/grid-layout-measurement.spec.js`

**6つの測定テスト**

1. **Grid構造整合性検証** - CSS変数とcomputedStyleの比較
2. **オーバーフロー検出** - 全要素のscrollWidth/clientWidth差分
3. **Grid セル配置精度** - ヘッダーとセルの相対位置計算
4. **レスポンシブ検証** - 3解像度でのビューポート収まり確認
5. **視覚的スナップショット** - ピクセル単位での差分検出
6. **パフォーマンス測定** - レイアウト計算時間（60fps基準）

### 2.2 実行コマンド

```bash
cd /usr/src/redmine/plugins/redmine_release_kanban

# 全測定テスト
npx playwright test grid-layout-measurement

# 個別測定
npx playwright test grid-layout-measurement -g "Grid 構造の整合性"
npx playwright test grid-layout-measurement -g "オーバーフロー検出"

# デバッグモード（ブラウザ表示）
npx playwright test grid-layout-measurement --headed --debug

# レポート生成
npx playwright test grid-layout-measurement --reporter=html
npx playwright show-report
```

## 3. 測定結果の解釈

### 3.1 Grid構造整合性

**出力例**
```json
{
  "declaredColumns": 1,
  "declaredRows": 3,
  "computedColumns": 2,
  "computedRows": 3,
  "actualGridCells": 6,
  "contentsElementsCount": 3
}
```

**診断**
- `computedColumns (2) ≠ declaredColumns (1)` → **Grid定義ミス**
- `actualGridCells (6) > declaredColumns × declaredRows (3)` → **セル過剰**
- 原因: `display: contents` による子要素展開で2列として解釈

**解決策**
- CSS Grid定義を `--grid-columns: 2` に修正
- または `grid-template-columns: auto 1fr` で明示的定義

### 3.2 オーバーフロー検出

**出力例**
```json
[
  {
    "selector": "epic-header-cell",
    "dimensions": { "clientWidth": 200, "scrollWidth": 250 },
    "overflowAmount": { "horizontal": 50, "vertical": 0 },
    "isOverflowing": true
  }
]
```

**診断**
- 横50pxオーバーフロー → **テキストまたは子要素が収まっていない**
- 原因: 固定幅不足、min-width未設定、overflow: hidden欠如

**解決策**
```css
.epic-header-cell {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

### 3.3 セル配置精度

**出力例**
```json
{
  "rows": [
    {
      "type": "epic",
      "header": { "left": 0, "top": 0, "width": 300 },
      "cells": [
        { "left": 310, "top": 0 }  // ヘッダーの右側
      ]
    }
  ]
}
```

**診断**
- `cell.left (310) > header.left + header.width (300)` → **正常配置**
- もし `cell.left < header.left` なら → **配置逆転（異常）**

**解決策**
- Grid定義で `grid-template-areas` を使用して明示的配置
- または `grid-column` で個別指定

### 3.4 レスポンシブ検証

**出力例**
```json
{
  "Desktop": { "isOverflowing": false, "overflowAmount": 0 },
  "Laptop": { "isOverflowing": true, "overflowAmount": 50 },
  "Tablet": { "isOverflowing": true, "overflowAmount": 200 }
}
```

**診断**
- Laptop/Tablet で横スクロール発生 → **レスポンシブ未対応**

**解決策**
```css
@media (max-width: 1366px) {
  .kanban-grid-body {
    grid-template-columns: 1fr;
  }
  .epic-header-cell {
    max-width: 100%;
  }
}
```

## 4. CI/CD 統合

### 4.1 GitHub Actions

```yaml
- name: Grid Layout Measurement
  run: |
    cd plugins/redmine_release_kanban
    npx playwright test grid-layout-measurement --reporter=json > grid-report.json

- name: Upload Grid Report
  uses: actions/upload-artifact@v4
  with:
    name: grid-layout-report
    path: plugins/redmine_release_kanban/grid-report.json
```

### 4.2 しきい値設定

```javascript
// playwright.config.js
export default {
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100  // 許容ピクセル差分
    }
  }
};
```

## 5. トラブルシューティング

### 5.1 Grid が見つからない

**症状**
```
Error: locator.waitForSelector: Timeout 10000ms exceeded
```

**解決**
- カンバンページURLを確認
- プロジェクト作成とカンバン有効化
- `await page.goto()` のURL修正

### 5.2 display: contents が効いていない

**症状**
- `contentsElementsCount: 0`
- Grid構造が想定と異なる

**解決**
- CSSファイルが読み込まれているか確認
- `await page.waitForLoadState('networkidle')`

### 5.3 スナップショットが常に失敗

**症状**
- 毎回ピクセル差分が発生

**解決**
```bash
# ベースライン更新
npx playwright test grid-layout-measurement --update-snapshots
```

## 6. ベストプラクティス

### 6.1 測定頻度

- **開発中**: Grid CSS変更時に毎回実行
- **コミット前**: 全測定テスト実行
- **CI/CD**: PR作成時に自動実行
- **定期**: 週次で視覚的回帰テスト

### 6.2 メトリクス記録

```javascript
// 測定結果をファイルに保存
const metrics = await page.evaluate(/* ... */);
await fs.writeFile('grid-metrics.json', JSON.stringify(metrics, null, 2));
```

### 6.3 しきい値の調整

| 環境 | オーバーフロー許容 | スナップショット差分 | レイアウト時間 |
|------|------------------|-------------------|--------------|
| 開発 | 0px | 200px | 30ms |
| ステージング | 0px | 100px | 20ms |
| 本番 | 0px | 50px | 16ms |

---

**Vibes準拠 - Grid レイアウト定量測定ガイド**