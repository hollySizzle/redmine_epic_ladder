// Grid レイアウトの定量的測定テスト
import { test, expect } from '@playwright/test';

// 環境変数から設定を取得
const baseURL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';
const projectId = process.env.PLAYWRIGHT_PROJECT_ID || 'test';
const username = process.env.PLAYWRIGHT_USERNAME || 'admin';
const password = process.env.PLAYWRIGHT_PASSWORD || 'admin';

test.describe('Kanban Grid Layout Measurement', () => {
  test.beforeEach(async ({ page }) => {
    // ログイン
    await page.goto(`${baseURL}/login`);
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('input[type="submit"]');

    // ログイン成功確認
    await page.waitForURL(/\/$/); // ホームページにリダイレクト

    // カンバンページに移動
    await page.goto(`${baseURL}/projects/${projectId}/kanban`);

    // Grid が読み込まれるまで待機
    await page.waitForSelector('.kanban-grid-body', { timeout: 10000 });
  });

  test('1. Grid 構造の整合性検証', async ({ page }) => {
    const gridMetrics = await page.evaluate(() => {
      const grid = document.querySelector('.kanban-grid-body');
      if (!grid) return null;

      const computedStyle = window.getComputedStyle(grid);
      const gridColumns = computedStyle.gridTemplateColumns;
      const gridRows = computedStyle.gridTemplateRows;

      // CSS変数取得
      const declaredColumns = grid.style.getPropertyValue('--grid-columns');
      const declaredRows = grid.style.getPropertyValue('--grid-rows');

      // 実際の子要素数（display: contents を考慮）
      const allChildren = Array.from(grid.querySelectorAll('*'));
      const directChildren = Array.from(grid.children);

      // display: contents 要素の検出
      const contentsElements = directChildren.filter(child => {
        const style = window.getComputedStyle(child);
        return style.display === 'contents';
      });

      // 実際のグリッドセル数
      let actualGridCells = directChildren.length;
      contentsElements.forEach(elem => {
        actualGridCells--; // contents 要素自体は削除
        actualGridCells += elem.children.length; // 子要素を追加
      });

      return {
        declaredColumns: parseInt(declaredColumns) || 0,
        declaredRows: parseInt(declaredRows) || 0,
        computedColumns: gridColumns.split(' ').length,
        computedRows: gridRows.split(' ').length,
        directChildrenCount: directChildren.length,
        actualGridCells: actualGridCells,
        contentsElementsCount: contentsElements.length
      };
    });

    console.log('Grid Metrics:', gridMetrics);

    // 期待値検証
    expect(gridMetrics).not.toBeNull();
    expect(gridMetrics.declaredColumns).toBeGreaterThan(0);
    expect(gridMetrics.declaredRows).toBeGreaterThan(0);

    // Grid定義と実際のセル数の整合性
    const expectedCells = gridMetrics.declaredColumns * gridMetrics.declaredRows;
    expect(gridMetrics.actualGridCells).toBeLessThanOrEqual(expectedCells * 1.5); // 50%以内の誤差許容
  });

  test('2. オーバーフロー検出（全要素）', async ({ page }) => {
    const overflowMetrics = await page.evaluate(() => {
      const grid = document.querySelector('.kanban-grid-body');
      if (!grid) return [];

      const allElements = [
        ...grid.querySelectorAll('.epic-row, .no-epic-row, .new-epic-row'),
        ...grid.querySelectorAll('.epic-header-cell, .no-epic-header-cell'),
        ...grid.querySelectorAll('.grid-cell'),
        ...grid.querySelectorAll('.empty-cell-message, .no-epic-empty-state')
      ];

      return allElements.map(el => {
        const rect = el.getBoundingClientRect();
        const isOverflowing =
          el.scrollWidth > el.clientWidth ||
          el.scrollHeight > el.clientHeight;

        const isOutOfViewport =
          rect.right > window.innerWidth ||
          rect.bottom > window.innerHeight ||
          rect.left < 0 ||
          rect.top < 0;

        return {
          selector: el.className,
          dataEpicId: el.dataset.epicId || 'none',
          dimensions: {
            clientWidth: el.clientWidth,
            clientHeight: el.clientHeight,
            scrollWidth: el.scrollWidth,
            scrollHeight: el.scrollHeight
          },
          position: {
            top: rect.top,
            left: rect.left,
            right: rect.right,
            bottom: rect.bottom
          },
          isOverflowing,
          isOutOfViewport,
          overflowAmount: {
            horizontal: Math.max(0, el.scrollWidth - el.clientWidth),
            vertical: Math.max(0, el.scrollHeight - el.clientHeight)
          }
        };
      });
    });

    console.log('Overflow Metrics:', JSON.stringify(overflowMetrics, null, 2));

    // オーバーフロー要素の検出
    const overflowingElements = overflowMetrics.filter(m => m.isOverflowing);
    const outOfViewportElements = overflowMetrics.filter(m => m.isOutOfViewport);

    // レポート生成
    if (overflowingElements.length > 0) {
      console.error('❌ オーバーフロー要素:', overflowingElements.length);
      overflowingElements.forEach(el => {
        console.error(`  - ${el.selector}: ${el.overflowAmount.horizontal}px 横, ${el.overflowAmount.vertical}px 縦`);
      });
    }

    if (outOfViewportElements.length > 0) {
      console.warn('⚠️  ビューポート外要素:', outOfViewportElements.length);
    }

    // 閾値チェック
    expect(overflowingElements.length).toBe(0);
  });
});