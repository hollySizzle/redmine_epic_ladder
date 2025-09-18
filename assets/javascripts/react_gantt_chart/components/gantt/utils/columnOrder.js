// 列順序管理ユーティリティ

// ローカルストレージから列順序を復元
export const loadColumnOrder = (gantt) => {
  try {
    const savedOrder = localStorage.getItem('gantt_column_order');
    if (!savedOrder) {
      return false;
    }
    
    const columnOrder = JSON.parse(savedOrder);
    console.log("保存された列順序を復元:", columnOrder);
    
    // 現在の列設定と保存された順序をマッチング
    const currentColumns = gantt.config.columns;
    const reorderedColumns = [];
    
    // 保存された順序で列を並び替え
    columnOrder.forEach(savedCol => {
      const currentCol = currentColumns.find(col => col.name === savedCol.name);
      if (currentCol) {
        // 保存された幅や表示状態を復元
        if (savedCol.width) currentCol.width = savedCol.width;
        if (savedCol.hide !== undefined) currentCol.hide = savedCol.hide;
        reorderedColumns.push(currentCol);
      }
    });
    
    // 新しく追加された列があれば末尾に追加
    currentColumns.forEach(currentCol => {
      if (!reorderedColumns.find(col => col.name === currentCol.name)) {
        reorderedColumns.push(currentCol);
      }
    });
    
    gantt.config.columns = reorderedColumns;
    return true;
  } catch (error) {
    console.error("列順序の復元に失敗:", error);
    return false;
  }
};

// 列順序をローカルストレージに保存
export const saveColumnOrder = (gantt) => {
  try {
    const columns = gantt.config.columns;
    const columnOrder = columns.map(col => ({
      name: col.name,
      width: col.width,
      hide: col.hide
    }));
    
    localStorage.setItem('gantt_column_order', JSON.stringify(columnOrder));
    console.log("列順序を保存しました:", columnOrder);
  } catch (error) {
    console.error("列順序の保存に失敗:", error);
  }
};

// 列順序のリセット
export const resetColumnOrder = (gantt) => {
  try {
    localStorage.removeItem('gantt_column_order');
    console.log("列順序設定をリセットしました");
    
    // ページをリロードして初期状態に戻す
    if (window.location) {
      window.location.reload();
    }
  } catch (error) {
    console.error("列順序のリセットに失敗:", error);
  }
};