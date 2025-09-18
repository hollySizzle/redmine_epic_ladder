import React, { useState, useEffect } from 'react';
import { 
  adjustColumnWidth, 
  resetAllColumnWidths, 
  autoFitColumn,
  autoFitAllColumns,
  exportColumnWidths 
} from './gantt/utils/columnResize';

const ColumnResizeControl = ({ ganttInstance, onClose }) => {
  const [columns, setColumns] = useState([]);
  const [currentWidths, setCurrentWidths] = useState({});

  useEffect(() => {
    if (!ganttInstance) return;
    
    // 現在の列情報を取得
    const ganttColumns = ganttInstance.config.columns || [];
    setColumns(ganttColumns);
    
    // 現在の幅を取得
    const widths = exportColumnWidths(ganttInstance);
    setCurrentWidths(widths);
  }, [ganttInstance]);

  const handleWidthChange = (columnName, value) => {
    const newWidth = parseInt(value, 10);
    if (isNaN(newWidth)) return;
    
    const actualWidth = adjustColumnWidth(ganttInstance, columnName, newWidth);
    setCurrentWidths(prev => ({ ...prev, [columnName]: actualWidth }));
  };

  const handleAutoFit = (columnName) => {
    autoFitColumn(ganttInstance, columnName);
    // 更新後の幅を取得
    const widths = exportColumnWidths(ganttInstance);
    setCurrentWidths(widths);
  };

  const handleAutoFitAll = () => {
    autoFitAllColumns(ganttInstance);
    // 更新後の幅を取得
    const widths = exportColumnWidths(ganttInstance);
    setCurrentWidths(widths);
  };

  const handleResetAll = () => {
    resetAllColumnWidths(ganttInstance);
    // 更新後の幅を取得
    const widths = exportColumnWidths(ganttInstance);
    setCurrentWidths(widths);
  };

  const getColumnLabel = (column) => {
    return column.label || column.name;
  };

  const isResizable = (columnName) => {
    // ID列とアクション列は固定
    return columnName !== 'id' && columnName !== 'actions';
  };

  return (
    <div className="column-resize-control">
      <div className="column-resize-header">
        <h3>列幅の調整</h3>
        <button onClick={onClose} className="close-button">×</button>
      </div>
      
      <div className="column-resize-actions">
        <button onClick={handleAutoFitAll} className="auto-fit-all-btn">
          すべて自動調整
        </button>
        <button onClick={handleResetAll} className="reset-all-btn">
          すべてリセット
        </button>
      </div>
      
      <div className="column-resize-list">
        {columns.map(column => (
          <div key={column.name} className="column-resize-item">
            <div className="column-info">
              <span className="column-label">{getColumnLabel(column)}</span>
              {!isResizable(column.name) && (
                <span className="column-fixed">(固定)</span>
              )}
            </div>
            
            {isResizable(column.name) ? (
              <div className="column-controls">
                <input
                  type="range"
                  min="50"
                  max="500"
                  value={currentWidths[column.name] || 100}
                  onChange={(e) => handleWidthChange(column.name, e.target.value)}
                  className="width-slider"
                />
                <input
                  type="number"
                  min="50"
                  max="500"
                  value={currentWidths[column.name] || 100}
                  onChange={(e) => handleWidthChange(column.name, e.target.value)}
                  className="width-input"
                />
                <span className="width-unit">px</span>
                <button
                  onClick={() => handleAutoFit(column.name)}
                  className="auto-fit-btn"
                  title="内容に合わせて自動調整"
                >
                  自動
                </button>
              </div>
            ) : (
              <div className="column-controls">
                <span className="fixed-width">{currentWidths[column.name]} px</span>
              </div>
            )}
          </div>
        ))}
      </div>
      
      <div className="column-resize-footer">
        <p className="help-text">
          スライダーまたは数値入力で列幅を調整できます。
          「自動」ボタンで内容に合わせた幅に調整されます。
        </p>
      </div>
    </div>
  );
};

export default ColumnResizeControl;