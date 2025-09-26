import React, { useMemo, useCallback, useRef, useEffect } from 'react';
import { FixedSizeGrid as Grid, FixedSizeList as List } from 'react-window';
import { useDroppable } from '@dnd-kit/core';
import AutoSizer from 'react-virtualized-auto-sizer';

/**
 * VirtualizedGrid - 仮想スクロール対応グリッドコンポーネント
 * 設計書仕様: 大量データ対応、60FPS維持、メモリ効率最適化
 *
 * パフォーマンス目標:
 * - 1000 Epic × 100 Version 対応
 * - 60FPS スクロール維持
 * - セル当たり1.5MB以内メモリ使用量
 */
export const VirtualizedGrid = ({
  epicRows,
  versionColumns,
  getCellFeatures,
  getCellStatistics,
  onFeatureMove,
  draggedCard,
  hoveredCell,
  compactMode = false,
  onCellClick,
  onCellDoubleClick
}) => {
  const gridRef = useRef();
  const headerRef = useRef();

  // セルサイズ計算（設計書準拠の最適化）
  const cellDimensions = useMemo(() => {
    if (compactMode) {
      return {
        width: 280,    // コンパクトモード
        height: 120
      };
    }
    return {
      width: 350,      // 通常モード
      height: 180
    };
  }, [compactMode]);

  // ヘッダー設定
  const headerHeight = 60;
  const epicHeaderWidth = 200;

  // グリッドデータ構造構築（メモ化）
  const gridData = useMemo(() => {
    const data = [];

    // Epic行データとNo Epic行を含む全行
    const allRows = [...epicRows];

    allRows.forEach((epicRow, rowIndex) => {
      const rowData = [];

      versionColumns.forEach((version, colIndex) => {
        const features = getCellFeatures(epicRow.id, version.id);
        const statistics = getCellStatistics(epicRow.id, version.id);

        rowData.push({
          epicId: epicRow.id,
          versionId: version.id,
          epicRow,
          version,
          features,
          statistics,
          coordinates: { row: rowIndex, col: colIndex },
          cellType: determineCellType(epicRow, version)
        });
      });

      data.push(rowData);
    });

    return data;
  }, [epicRows, versionColumns, getCellFeatures, getCellStatistics]);

  // セル描画コンポーネント（高度に最適化）
  const GridCell = React.memo(({ columnIndex, rowIndex, style, data }) => {
    const cellData = data[rowIndex]?.[columnIndex];

    if (!cellData) {
      return <div style={style} className="empty-cell" />;
    }

    const {
      epicId,
      versionId,
      features,
      statistics,
      coordinates,
      cellType,
      epicRow,
      version
    } = cellData;

    const isHovered = hoveredCell &&
      hoveredCell.epicId === epicId &&
      hoveredCell.versionId === versionId;

    const isDraggedOver = draggedCard && isHovered;

    return (
      <VirtualizedGridCell
        key={`${epicId}-${versionId}`}
        style={style}
        epicId={epicId}
        versionId={versionId}
        features={features}
        statistics={statistics}
        coordinates={coordinates}
        cellType={cellType}
        epicRow={epicRow}
        version={version}
        isHovered={isHovered}
        isDraggedOver={isDraggedOver}
        compactMode={compactMode}
        onCellClick={onCellClick}
        onCellDoubleClick={onCellDoubleClick}
      />
    );
  }, (prevProps, nextProps) => {
    // 精密な比較関数でリレンダリングを最小化
    return (
      prevProps.rowIndex === nextProps.rowIndex &&
      prevProps.columnIndex === nextProps.columnIndex &&
      prevProps.style.left === nextProps.style.left &&
      prevProps.style.top === nextProps.style.top &&
      shallowEqual(prevProps.data[prevProps.rowIndex]?.[prevProps.columnIndex],
                   nextProps.data[nextProps.rowIndex]?.[nextProps.columnIndex])
    );
  });

  // バージョンヘッダー描画
  const VersionHeader = React.memo(({ index, style, data }) => {
    const version = data[index];

    return (
      <div
        style={{
          ...style,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: version.type === 'no-version' ? '#f0f0f0' : '#ffffff',
          border: '1px solid #ddd',
          borderBottom: '2px solid #9673a6',
          fontWeight: 'bold',
          fontSize: compactMode ? '12px' : '14px',
          padding: '8px',
          boxSizing: 'border-box'
        }}
        className={`version-header ${version.type === 'no-version' ? 'no-version' : ''}`}
      >
        <div className="version-info">
          <div className="version-name">{version.name}</div>
          {!compactMode && version.issue_count > 0 && (
            <div className="version-count">({version.issue_count})</div>
          )}
        </div>
      </div>
    );
  });

  // Epic行ヘッダー描画
  const EpicHeader = React.memo(({ index, style, data }) => {
    const epicRow = data[index];

    return (
      <div
        style={{
          ...style,
          display: 'flex',
          alignItems: 'center',
          backgroundColor: epicRow.type === 'no-epic' ? '#f9f9f9' : '#ffffff',
          border: '1px solid #ddd',
          borderRight: '2px solid #9673a6',
          padding: '8px',
          fontSize: compactMode ? '12px' : '14px',
          fontWeight: 'bold',
          boxSizing: 'border-box'
        }}
        className={`epic-header ${epicRow.type === 'no-epic' ? 'no-epic' : ''}`}
      >
        <div className="epic-info">
          <div className="epic-name" title={epicRow.name}>
            {epicRow.name}
          </div>
          {!compactMode && epicRow.statistics && (
            <div className="epic-stats">
              完了: {epicRow.statistics.completed_features || 0}/
              {epicRow.statistics.total_features || 0}
            </div>
          )}
        </div>
      </div>
    );
  });

  // スクロール同期処理
  const handleGridScroll = useCallback(({ scrollLeft, scrollTop }) => {
    if (headerRef.current) {
      headerRef.current.scrollTo({ scrollLeft, scrollTop: 0 });
    }
  }, []);

  // アイテムサイズ取得（動的サイズ対応）
  const getColumnWidth = useCallback((index) => {
    // 最初の列はEpicヘッダー
    if (index === 0) return epicHeaderWidth;
    return cellDimensions.width;
  }, [cellDimensions.width, epicHeaderWidth]);

  const getRowHeight = useCallback((index) => {
    // ヘッダー行
    if (index === 0) return headerHeight;
    return cellDimensions.height;
  }, [cellDimensions.height, headerHeight]);

  // パフォーマンス最適化：アイテムデータメモ化
  const itemData = useMemo(() => ({
    gridData,
    versionColumns,
    epicRows,
    hoveredCell,
    draggedCard,
    compactMode,
    onCellClick,
    onCellDoubleClick
  }), [
    gridData,
    versionColumns,
    epicRows,
    hoveredCell,
    draggedCard,
    compactMode,
    onCellClick,
    onCellDoubleClick
  ]);

  return (
    <div className="virtualized-grid-container">
      {/* バージョンヘッダー */}
      <div className="grid-headers">
        <div
          className="epic-header-spacer"
          style={{
            width: epicHeaderWidth,
            height: headerHeight,
            backgroundColor: '#f5f5f5',
            border: '1px solid #ddd',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '14px'
          }}
        >
          EPIC
        </div>

        <div
          ref={headerRef}
          className="version-headers"
          style={{
            width: `calc(100% - ${epicHeaderWidth}px)`,
            height: headerHeight,
            overflow: 'hidden'
          }}
        >
          <List
            layout="horizontal"
            height={headerHeight}
            itemCount={versionColumns.length}
            itemSize={cellDimensions.width}
            itemData={versionColumns}
            overscanCount={5}
          >
            {VersionHeader}
          </List>
        </div>
      </div>

      {/* メイングリッド */}
      <div className="grid-body-container" style={{ height: 'calc(100% - 60px)' }}>
        <div className="epic-headers-column">
          <div style={{ width: epicHeaderWidth, height: '100%' }}>
            <List
              height="100%"
              itemCount={epicRows.length}
              itemSize={cellDimensions.height}
              itemData={epicRows}
              overscanCount={5}
            >
              {EpicHeader}
            </List>
          </div>
        </div>

        <div className="grid-cells-area" style={{ width: `calc(100% - ${epicHeaderWidth}px)` }}>
          <AutoSizer>
            {({ height, width }) => (
              <Grid
                ref={gridRef}
                height={height}
                width={width}
                columnCount={versionColumns.length}
                columnWidth={cellDimensions.width}
                rowCount={epicRows.length}
                rowHeight={cellDimensions.height}
                itemData={gridData}
                onScroll={handleGridScroll}
                overscanColumnCount={2}
                overscanRowCount={3}
              >
                {GridCell}
              </Grid>
            )}
          </AutoSizer>
        </div>
      </div>
    </div>
  );
};

/**
 * VirtualizedGridCell - 個別セルコンポーネント（高度最適化）
 */
const VirtualizedGridCell = React.memo(({
  style,
  epicId,
  versionId,
  features,
  statistics,
  coordinates,
  cellType,
  epicRow,
  version,
  isHovered,
  isDraggedOver,
  compactMode,
  onCellClick,
  onCellDoubleClick
}) => {
  const { setNodeRef } = useDroppable({
    id: `cell-${epicId}-${versionId}`,
    data: {
      type: 'grid-cell',
      epicId,
      versionId,
      coordinates
    }
  });

  const getCellBackground = () => {
    if (isDraggedOver) return '#e3f2fd';
    if (isHovered) return '#f5f5f5';
    if (cellType === 'no-version') return '#f9f9f9';
    return '#ffffff';
  };

  const getBorderColor = () => {
    if (isDraggedOver) return '#2196f3';
    return '#9673a6';
  };

  const handleClick = useCallback(() => {
    onCellClick?.(epicId, versionId, features);
  }, [epicId, versionId, features, onCellClick]);

  const handleDoubleClick = useCallback(() => {
    onCellDoubleClick?.(epicId, versionId, features);
  }, [epicId, versionId, features, onCellDoubleClick]);

  return (
    <div
      ref={setNodeRef}
      style={{
        ...style,
        backgroundColor: getCellBackground(),
        border: `1px solid ${getBorderColor()}`,
        boxSizing: 'border-box',
        padding: compactMode ? '4px' : '8px',
        overflow: 'hidden',
        cursor: 'pointer'
      }}
      className={`virtualized-grid-cell ${cellType} ${isDraggedOver ? 'drag-over' : ''}`}
      onClick={handleClick}
      onDoubleClick={handleDoubleClick}
    >
      {/* Feature Cards */}
      <div className="cell-features">
        {features.slice(0, compactMode ? 2 : 4).map((feature, index) => (
          <VirtualizedFeatureCard
            key={feature.issue.id}
            feature={feature}
            compact={compactMode}
            index={index}
          />
        ))}

        {features.length > (compactMode ? 2 : 4) && (
          <div className="more-features-indicator">
            +{features.length - (compactMode ? 2 : 4)} more
          </div>
        )}
      </div>

      {/* 統計情報 */}
      {!compactMode && statistics && (
        <div className="cell-statistics">
          <div className="completion-rate">
            完了率: {statistics.completion_rate || 0}%
          </div>
        </div>
      )}

      {/* ドロップインジケーター */}
      {isDraggedOver && (
        <div className="drop-indicator">
          <span>Drop here</span>
        </div>
      )}

      {/* 空セル表示 */}
      {features.length === 0 && !isDraggedOver && (
        <div className="empty-cell-message">
          {compactMode ? '空' : 'No Features'}
        </div>
      )}
    </div>
  );
}, (prevProps, nextProps) => {
  // パフォーマンス最適化：必要な場合のみリレンダリング
  return (
    prevProps.epicId === nextProps.epicId &&
    prevProps.versionId === nextProps.versionId &&
    prevProps.isHovered === nextProps.isHovered &&
    prevProps.isDraggedOver === nextProps.isDraggedOver &&
    prevProps.compactMode === nextProps.compactMode &&
    shallowEqual(prevProps.features, nextProps.features) &&
    shallowEqual(prevProps.statistics, nextProps.statistics)
  );
});

/**
 * VirtualizedFeatureCard - 軽量化Featureカード
 */
const VirtualizedFeatureCard = React.memo(({
  feature,
  compact,
  index
}) => {
  const cardStyle = {
    backgroundColor: '#fff',
    border: '1px solid #ddd',
    borderRadius: '4px',
    padding: compact ? '4px' : '6px',
    margin: compact ? '2px 0' : '4px 0',
    fontSize: compact ? '11px' : '12px',
    lineHeight: compact ? '1.2' : '1.4',
    maxHeight: compact ? '24px' : '32px',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap'
  };

  return (
    <div style={cardStyle} className="virtualized-feature-card">
      <span title={feature.issue.subject}>
        {feature.issue.subject}
      </span>
      {!compact && (
        <div style={{ fontSize: '10px', color: '#666' }}>
          {feature.issue.status}
        </div>
      )}
    </div>
  );
});

// ヘルパー関数
function determineCellType(epicRow, version) {
  if (epicRow.type === 'no-epic' && version.type === 'no-version') {
    return 'no-epic-no-version';
  } else if (epicRow.type === 'no-epic') {
    return 'no-epic-version';
  } else if (version.type === 'no-version') {
    return 'epic-no-version';
  }
  return 'epic-version';
}

function shallowEqual(obj1, obj2) {
  if (obj1 === obj2) return true;
  if (!obj1 || !obj2) return false;

  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);

  if (keys1.length !== keys2.length) return false;

  for (let key of keys1) {
    if (obj1[key] !== obj2[key]) return false;
  }

  return true;
}

export default VirtualizedGrid;