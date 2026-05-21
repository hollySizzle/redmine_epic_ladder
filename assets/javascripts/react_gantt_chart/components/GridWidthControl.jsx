import React, { useState, useEffect, useCallback, useRef } from 'react';
import './GridWidthControl.scss';

/**
 * ガントグリッド・列幅統合調整コンポーネント（Reactフレンドリー版）
 * CSS Custom Propertiesとganttインスタンスを使用してグリッド幅を制御
 */
const GridWidthControl = ({ gantt, initialWidth = 500 }) => {
  const [gridWidth, setGridWidth] = useState(() => {
    // LocalStorageから保存された値を復元
    try {
      const saved = localStorage.getItem('gantt_grid_width');
      return saved ? parseInt(saved) : initialWidth;
    } catch {
      return initialWidth;
    }
  });
  const [isVisible, setIsVisible] = useState(false);
  const [activeTab, setActiveTab] = useState('grid');
  const [columnWidths, setColumnWidths] = useState({});
  const ganttContainerRef = useRef(null);

  // 列幅情報を取得
  useEffect(() => {
    if (gantt && gantt.config && gantt.config.columns) {
      const currentWidths = {};
      gantt.config.columns.forEach(col => {
        if (col.name && col.width) {
          currentWidths[col.name] = col.width;
        }
      });
      setColumnWidths(currentWidths);
    }
  }, [gantt]);

  // DOM要素を安全に取得する関数
  const getGanttGridElements = useCallback(() => {
    // タイミングを考慮して要素を取得
    const outerCell = document.querySelector('.gantt_layout_cell.gantt_layout.gantt_layout_y.gantt_layout_cell_border_right[data-cell-id^="c"]');
    const innerCell = document.querySelector('.gantt_layout_cell.grid_cell.gantt_layout_cell_border_transparent.gantt_layout_outer_scroll');
    
    return { outerCell, innerCell };
  }, []);

  // 安全なDOM操作でグリッド幅を適用
  const applyGridWidthToDOM = useCallback((width) => {
    // React のライフサイクル内でDOM操作を実行
    const { outerCell, innerCell } = getGanttGridElements();
    
    if (outerCell) {
      outerCell.style.width = `${width}px`;
      outerCell.style.minWidth = `${width}px`;
      outerCell.style.maxWidth = `${width}px`;
    }
    
    if (innerCell) {
      const innerWidth = width - 1;
      innerCell.style.width = `${innerWidth}px`;
      innerCell.style.minWidth = `${innerWidth}px`;
      innerCell.style.maxWidth = `${innerWidth}px`;
    }
    
    return { outerCell: !!outerCell, innerCell: !!innerCell };
  }, [getGanttGridElements]);

  // Reactフレンドリーなグリッド幅変更ハンドラー
  const handleGridWidthChange = useCallback((newWidth) => {
    // 状態を先に更新
    setGridWidth(newWidth);
    
    // ガント設定を更新
    if (gantt && gantt.config) {
      gantt.config.grid_width = newWidth;
    }
    
    // DOM操作は次のtickで実行（Reactの更新後）
    setTimeout(() => {
      const result = applyGridWidthToDOM(newWidth);
      console.log('Grid width applied:', { width: newWidth, success: result });
      
      // ガントチャートの再描画
      if (gantt && gantt.render) {
        gantt.render();
      }
    }, 0);
    
    // ストレージに保存
    try {
      localStorage.setItem('gantt_grid_width', newWidth.toString());
    } catch (error) {
      console.warn('Failed to save grid width:', error);
    }
  }, [gantt, applyGridWidthToDOM]);

  // ガントインスタンスが変更された時に幅を再適用
  useEffect(() => {
    if (gantt && gridWidth) {
      // ガントが完全に初期化されるのを待ってから適用
      const timeoutId = setTimeout(() => {
        applyGridWidthToDOM(gridWidth);
      }, 100);
      
      return () => clearTimeout(timeoutId);
    }
  }, [gantt, gridWidth, applyGridWidthToDOM]);

  // 列幅変更ハンドラー（Reactフレンドリー版）
  const handleColumnWidthChange = useCallback((columnName, newWidth) => {
    if (gantt && gantt.config && gantt.config.columns) {
      const column = gantt.config.columns.find(col => col.name === columnName);
      if (column) {
        const width = parseInt(newWidth);
        column.width = width;
        
        // 状態を更新
        setColumnWidths(prev => ({
          ...prev,
          [columnName]: width
        }));
        
        // より軽量な更新を試行
        if (gantt.refreshData) {
          gantt.refreshData();
        } else if (gantt.render) {
          gantt.render();
        }
        
        // ローカルストレージに保存
        try {
          const savedWidths = JSON.parse(localStorage.getItem('gantt_column_widths') || '{}');
          savedWidths[columnName] = width;
          localStorage.setItem('gantt_column_widths', JSON.stringify(savedWidths));
        } catch (error) {
          console.warn('列幅の保存に失敗:', error);
        }
      }
    }
  }, [gantt]);

  // カラム表示名を取得（HTMLタグを除去）
  const getColumnDisplayName = (column) => {
    const columnNameMap = {
      'id': 'ID',
      'text': 'タスク名',
      'tracker_name': 'トラッカー',
      'status_name': 'ステータス',
      'assigned_to_name': '担当者',
      'category_name': 'カテゴリ',
      'start_date': '開始日',
      'end_date': '終了日',
      'description': '説明',
      'actions': '操作'
    };

    // 名前マッピングがある場合はそれを使用
    if (columnNameMap[column.name]) {
      return columnNameMap[column.name];
    }

    // HTMLタグを除去
    if (column.label && typeof column.label === 'string') {
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = column.label;
      return tempDiv.textContent || tempDiv.innerText || column.name;
    }
    
    return column.name;
  };

  // プリセット幅の設定
  const presetWidths = [
    { label: '狭い', value: 300 },
    { label: '標準', value: 500 },
    { label: '広い', value: 700 },
    { label: '最大', value: 900 }
  ];

  // ガントインスタンスが存在しない場合
  if (!gantt) {
    return <div style={{padding: '8px 16px', background: '#fff3cd', color: '#856404'}}>
      ガントチャートの初期化中...
    </div>;
  }

  return (
    <div className="grid-width-control">
      {/* トグルボタン */}
      <button
        className="grid-width-toggle"
        onClick={() => setIsVisible(!isVisible)}
        title="列幅設定"
      >
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M2 4h12M2 8h12M2 12h12M6 2v12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        列幅設定
      </button>

      {/* 設定パネル */}
      {isVisible && (
        <div className="grid-width-panel">
          <div className="panel-header">
            <h3>レイアウト設定</h3>
            <button 
              className="close-button"
              onClick={() => setIsVisible(false)}
            >
              ×
            </button>
          </div>

          {/* タブメニュー */}
          <div className="tab-menu">
            <button 
              className={`tab-button ${activeTab === 'grid' ? 'active' : ''}`}
              onClick={() => setActiveTab('grid')}
            >
              グリッド幅
            </button>
            <button 
              className={`tab-button ${activeTab === 'columns' ? 'active' : ''}`}
              onClick={() => setActiveTab('columns')}
            >
              列幅個別設定
            </button>
          </div>

          <div className="panel-content">
            {activeTab === 'grid' && (
              <>
                {/* 現在のグリッド幅表示 */}
                <div className="current-width">
                  <span>現在のグリッド幅: <strong>{gridWidth}px</strong></span>
                </div>

                {/* スライダー */}
                <div className="width-slider">
                  <label htmlFor="grid-width-range">グリッド幅調整</label>
                  <input
                    id="grid-width-range"
                    type="range"
                    min="250"
                    max="1000"
                    step="50"
                    value={gridWidth}
                    onChange={(e) => handleGridWidthChange(parseInt(e.target.value))}
                    className="slider"
                  />
                  <div className="slider-labels">
                    <span>250px</span>
                    <span>1000px</span>
                  </div>
                </div>

                {/* プリセットボタン */}
                <div className="preset-buttons">
                  <label>プリセット:</label>
                  <div className="button-group">
                    {presetWidths.map((preset) => (
                      <button
                        key={preset.value}
                        className={`preset-button ${gridWidth === preset.value ? 'active' : ''}`}
                        onClick={() => handleGridWidthChange(preset.value)}
                      >
                        {preset.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 数値入力 */}
                <div className="width-input">
                  <label htmlFor="grid-width-input">直接入力 (px):</label>
                  <input
                    id="grid-width-input"
                    type="number"
                    min="250"
                    max="1000"
                    value={gridWidth}
                    onChange={(e) => {
                      const value = parseInt(e.target.value) || 250;
                      if (value >= 250 && value <= 1000) {
                        handleGridWidthChange(value);
                      }
                    }}
                    className="width-number-input"
                  />
                </div>

                {/* リセットボタン */}
                <div className="reset-section">
                  <button
                    className="reset-button"
                    onClick={() => handleGridWidthChange(500)}
                  >
                    デフォルトに戻す (500px)
                  </button>
                </div>
              </>
            )}

            {activeTab === 'columns' && (
              <>
                {/* 列幅個別設定 */}
                <div className="column-width-controls">
                  <div className="section-header">
                    <h4>列幅個別設定</h4>
                    <p className="description">各列の幅を個別に調整できます</p>
                  </div>
                  
                  <div className="column-list">
                    {gantt && gantt.config && gantt.config.columns ? gantt.config.columns.map((column) => (
                      <div key={column.name} className="column-control">
                        <div className="column-info">
                          <label className="column-label">
                            {getColumnDisplayName(column)}
                          </label>
                          <span className="current-value">{columnWidths[column.name] || column.width || 100}px</span>
                        </div>
                        <div className="column-controls">
                          <input
                            type="range"
                            min="50"
                            max="500"
                            step="10"
                            value={columnWidths[column.name] || column.width || 100}
                            onChange={(e) => handleColumnWidthChange(column.name, e.target.value)}
                            className="column-slider"
                          />
                          <input
                            type="number"
                            min="50"
                            max="500"
                            value={columnWidths[column.name] || column.width || 100}
                            onChange={(e) => handleColumnWidthChange(column.name, e.target.value)}
                            className="column-number-input"
                          />
                        </div>
                      </div>
                    )) : <div className="no-columns">列データが読み込まれていません</div>}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default GridWidthControl;