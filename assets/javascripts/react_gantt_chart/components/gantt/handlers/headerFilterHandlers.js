// サーバーサイドフィルタ統合ハンドラー（クライアントサイドフィルタリング削除版）

// グローバル関数：ヘッダークリック時にフィルター表示を切り替え
window.toggleHeaderFilter = function(headerElement) {
  const container = headerElement.parentElement;
  const filterContainer = container.querySelector('.header-filter-container');
  
  if (filterContainer) {
    const isVisible = filterContainer.style.display !== 'none';
    
    // 他の全てのフィルターを閉じる
    document.querySelectorAll('.header-filter-container').forEach(elem => {
      elem.style.display = 'none';
    });
    
    // クリックされたフィルターの表示を切り替え
    if (!isVisible) {
      filterContainer.style.display = 'block';
      const input = filterContainer.querySelector('.header-filter');
      if (input) {
        // 少し遅らせてフォーカス（DOMの更新を待つ）
        setTimeout(() => input.focus(), 10);
      }
    }
  }
};

/**
 * ヘッダーフィルタハンドラーを作成（サーバーサイドフィルタのみ）
 * @param {Object} options - オプション
 * @param {Function} options.onFilterChange - フィルタ変更時のコールバック（サーバーサイド処理）
 * @returns {Object} ヘッダーフィルタハンドラー
 */
export const createHeaderFilterHandlers = ({ onFilterChange }) => {
  /**
   * サーバーサイドフィルタパラメータを構築
   * @param {string} filterField - フィールド名
   * @param {string} filterValue - フィルタ値
   * @returns {Object} フィルタパラメータ
   */
  const buildServerFilterParams = (filterField, filterValue) => {
    if (!filterValue || filterValue === '') return null;
    
    // フィールドタイプに応じたオペレータを設定
    let operator = '~'; // デフォルト: 含む
    if (filterField === 'start_date' || filterField === 'due_date') {
      operator = '='; // 日付は完全一致
    } else if (filterField === 'tracker_id' || filterField === 'status_id' || filterField === 'assigned_to_id') {
      operator = '='; // ID系は完全一致
    }
    
    // ID系フィールドの場合は数値変換
    let processedValue = filterValue;
    if (filterField === 'tracker_id' || filterField === 'status_id' || filterField === 'assigned_to_id') {
      const numericValue = parseInt(filterValue, 10);
      if (!isNaN(numericValue)) {
        processedValue = numericValue.toString();
      }
    }
    
    return {
      field: filterField,
      operator: operator,
      value: processedValue
    };
  };

  /**
   * フィルタ変更ハンドラー（サーバーサイドに直接送信）
   * @param {Event} event - イベントオブジェクト
   */
  const handleFilterChange = (event) => {
    const target = event.target;
    
    if (!target.classList.contains('header-filter')) {
      return;
    }
    
    const filterField = target.getAttribute('data-filter');
    const filterValue = target.value;
    
    console.log(`ヘッダーフィルタ変更（サーバーサイド送信）: ${filterField} = "${filterValue}"`);
    
    // サーバーサイドフィルタパラメータを構築
    const filterParams = buildServerFilterParams(filterField, filterValue);
    
    // 親コンポーネントに即座に通知（サーバーサイドフィルタ実行）
    if (onFilterChange && filterParams) {
      onFilterChange([filterParams]); // 配列形式で送信
    } else if (onFilterChange && (!filterValue || filterValue === '')) {
      // フィルタクリアの場合は空配列を送信
      onFilterChange([]);
    }
  };
  
  /**
   * フィルタをクリア（サーバーサイドに通知）
   */
  const clearFilters = () => {
    console.log('ヘッダーフィルタクリア（サーバーサイド通知）');
    
    // フィルタUIをクリア
    document.querySelectorAll('.header-filter').forEach(input => {
      input.value = '';
    });
    
    // 親コンポーネントに空フィルタを通知
    if (onFilterChange) {
      onFilterChange([]);
    }
  };
  
  /**
   * イベントリスナーを設定
   */
  const setupEventListeners = () => {
    console.log('ヘッダーフィルタのイベントリスナーを設定（サーバーサイド統合版）');
    
    // change イベント（select要素用）
    document.addEventListener('change', handleFilterChange);
    
    // input イベント（text/date要素用、debounce適用を推奨）
    document.addEventListener('input', handleFilterChange);
    
    // 外部クリックでフィルターを閉じる
    document.addEventListener('click', (event) => {
      const clickedElement = event.target;
      
      // ヘッダータイトルまたはフィルター要素をクリックした場合は何もしない
      if (clickedElement.classList.contains('header-title') || 
          clickedElement.classList.contains('header-filter') ||
          clickedElement.closest('.header-filter-container') ||
          clickedElement.closest('.gantt-header-with-filter')) {
        return;
      }
      
      // 全てのフィルターを閉じる
      document.querySelectorAll('.header-filter-container').forEach(elem => {
        elem.style.display = 'none';
      });
    });
  };
  
  /**
   * イベントリスナーを削除
   */
  const removeEventListeners = () => {
    console.log('ヘッダーフィルタのイベントリスナーを削除');
    document.removeEventListener('change', handleFilterChange);
    document.removeEventListener('input', handleFilterChange);
  };

  // 簡素化されたメソッド群
  return {
    setupEventListeners,
    removeEventListeners,
    clearFilters
  };
};