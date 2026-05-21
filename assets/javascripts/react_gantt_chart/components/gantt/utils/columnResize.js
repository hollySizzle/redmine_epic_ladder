// 列幅調整のユーティリティ関数

// デフォルトの列幅設定
const DEFAULT_COLUMN_WIDTHS = {
  id: { default: 50, min: 40, max: 100 },
  text: { default: 200, min: 150, max: 500 },
  tracker_name: { default: 100, min: 80, max: 200 },
  status_name: { default: 100, min: 80, max: 200 },
  assigned_to_name: { default: 120, min: 100, max: 250 },
  start_date: { default: 100, min: 90, max: 150 },
  end_date: { default: 100, min: 90, max: 150 },
  description: { default: 200, min: 120, max: 400 },
  actions: { default: 75, min: 75, max: 75 },
  // カスタムフィールドのデフォルト
  custom_field: { default: 120, min: 100, max: 300 }
};

// 列幅の調整
export const adjustColumnWidth = (gantt, columnName, newWidth) => {
  console.log('[ColumnResize] 列幅調整:', { columnName, newWidth });
  const column = gantt.getGridColumn(columnName);
  if (!column) {
    console.error('[ColumnResize] カラムが見つかりません:', columnName);
    return false;
  }
  
  const widthConfig = DEFAULT_COLUMN_WIDTHS[columnName] || DEFAULT_COLUMN_WIDTHS.custom_field;
  
  // 最小・最大幅の制限を適用
  const constrainedWidth = Math.max(
    widthConfig.min,
    Math.min(widthConfig.max, newWidth)
  );
  
  console.log('[ColumnResize] 制約適用後の幅:', constrainedWidth);
  column.width = constrainedWidth;
  gantt.render();
  
  // 幅を保存
  saveColumnWidth(columnName, constrainedWidth);
  
  return constrainedWidth;
};

// すべての列幅をリセット
export const resetAllColumnWidths = (gantt) => {
  const columns = gantt.config.columns;
  
  columns.forEach(column => {
    const widthConfig = DEFAULT_COLUMN_WIDTHS[column.name] || DEFAULT_COLUMN_WIDTHS.custom_field;
    column.width = widthConfig.default;
  });
  
  gantt.render();
  clearSavedColumnWidths();
};

// 保存された列幅を適用
export const applySavedColumnWidths = (gantt) => {
  console.log('[ColumnResize] 保存された列幅を適用開始');
  const savedWidths = getSavedColumnWidths();
  const columns = gantt.config.columns;
  
  console.log('[ColumnResize] 現在のカラム設定:', columns);
  console.log('[ColumnResize] 保存された幅:', savedWidths);
  
  columns.forEach(column => {
    if (savedWidths[column.name]) {
      console.log(`[ColumnResize] ${column.name}の幅を${column.width}から${savedWidths[column.name]}に変更`);
      column.width = savedWidths[column.name];
    }
  });
  
  gantt.render();
  console.log('[ColumnResize] 列幅の適用完了');
};

// 列幅の保存（LocalStorage使用）
const STORAGE_KEY = 'redmine_gantt_column_widths';

const saveColumnWidth = (columnName, width) => {
  console.log('[ColumnResize] 列幅を保存:', { columnName, width });
  const savedWidths = getSavedColumnWidths();
  savedWidths[columnName] = width;
  const result = localStorage.setItem(STORAGE_KEY, JSON.stringify(savedWidths));
  console.log('[ColumnResize] LocalStorageに保存完了:', savedWidths);
};

const getSavedColumnWidths = () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    console.log('[ColumnResize] LocalStorageから読み込み:', saved);
    return saved ? JSON.parse(saved) : {};
  } catch (e) {
    console.error('[ColumnResize] 列幅の読み込みに失敗:', e);
    return {};
  }
};

const clearSavedColumnWidths = () => {
  localStorage.removeItem(STORAGE_KEY);
};

// 列幅の自動調整（コンテンツに合わせる）
export const autoFitColumn = (gantt, columnName) => {
  const column = gantt.getGridColumn(columnName);
  if (!column) return;
  
  let maxWidth = 0;
  
  // すべてのタスクを確認してコンテンツの最大幅を計算
  gantt.eachTask(task => {
    let content = '';
    
    if (column.template) {
      content = column.template(task);
    } else if (columnName === 'text') {
      content = task.text || '';
    } else {
      content = task[columnName] || '';
    }
    
    // HTMLタグを除去
    const textContent = content.replace(/<[^>]*>/g, '');
    
    // 文字数から推定幅を計算（1文字約8px）
    const estimatedWidth = textContent.length * 8 + 20; // パディング分を追加
    maxWidth = Math.max(maxWidth, estimatedWidth);
  });
  
  // ヘッダーラベルの幅も考慮
  const headerWidth = (column.label || '').length * 10 + 20;
  maxWidth = Math.max(maxWidth, headerWidth);
  
  // 最小・最大幅の制限を適用
  const widthConfig = DEFAULT_COLUMN_WIDTHS[columnName] || DEFAULT_COLUMN_WIDTHS.custom_field;
  const newWidth = Math.max(
    widthConfig.min,
    Math.min(widthConfig.max, maxWidth)
  );
  
  adjustColumnWidth(gantt, columnName, newWidth);
};

// すべての列を自動調整
export const autoFitAllColumns = (gantt) => {
  const columns = gantt.config.columns;
  
  columns.forEach(column => {
    if (column.name !== 'actions') { // アクション列は固定
      autoFitColumn(gantt, column.name);
    }
  });
};

// 列幅設定のエクスポート
export const exportColumnWidths = (gantt) => {
  const columns = gantt.config.columns;
  const widths = {};
  
  columns.forEach(column => {
    widths[column.name] = column.width || DEFAULT_COLUMN_WIDTHS[column.name]?.default || 100;
  });
  
  return widths;
};

// 列幅設定のインポート
export const importColumnWidths = (gantt, widths) => {
  Object.entries(widths).forEach(([columnName, width]) => {
    adjustColumnWidth(gantt, columnName, width);
  });
};