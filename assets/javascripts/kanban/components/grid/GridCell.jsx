import { useMemo, useCallback } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { FeatureCard } from './FeatureCard';
import { DragIndicator } from './DragIndicator';

/**
 * GridCell - 設計書準拠のグリッドセルコンポーネント（D&D対応）
 * 設計書仕様: FeatureCard + DropIndicator + EmptyCellMessage（設計書82-86行目準拠）
 *
 * @param {Object} cellData - セル座標・制約情報
 * @param {Array} features - セル内Feature配列
 * @param {Object} statistics - セル統計情報
 * @param {Object} draggedCard - ドラッグ中カード情報
 * @param {Object} hoveredCell - ホバー中セル情報
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {Function} onCellInteraction - セル相互作用ハンドラー
 * @param {number} cellIndex - セル列インデックス
 */
export const GridCell = ({
  cellData,
  features = [],
  statistics,
  draggedCard,
  hoveredCell,
  compactMode = false,
  onCellInteraction,
  cellIndex
}) => {
  // @dnd-kit ドロップ可能エリア設定
  const {
    isOver,
    setNodeRef,
    active
  } = useDroppable({
    id: `cell-${cellData.epic_id}-${cellData.version_id}`,
    data: {
      type: 'grid-cell',
      epicId: cellData.epic_id,
      versionId: cellData.version_id,
      coordinates: cellData.coordinates,
      cell_type: cellData.cell_type,
      drop_allowed: cellData.drop_allowed
    }
  });

  // セル状態判定（メモ化）
  const cellStatus = useMemo(() => {
    const isDraggedOver = isOver && active;
    const isHovered = hoveredCell?.epicId === cellData.epic_id &&
                     hoveredCell?.versionId === cellData.version_id;
    const hasFeatures = features.length > 0;
    const isDropTarget = isDraggedOver && cellData.drop_allowed;
    const isInvalidDrop = isDraggedOver && !cellData.drop_allowed;

    return {
      isDraggedOver,
      isHovered,
      hasFeatures,
      isDropTarget,
      isInvalidDrop,
      isEmpty: !hasFeatures
    };
  }, [isOver, active, hoveredCell, cellData, features.length]);

  // セル統計表示（メモ化）
  const cellStatistics = useMemo(() => {
    if (!statistics) {
      return {
        total_features: features.length,
        completed_features: features.filter(f =>
          ['Resolved', 'Closed'].includes(f.issue?.status)
        ).length,
        completion_rate: 0
      };
    }
    return statistics;
  }, [statistics, features]);

  // セル相互作用処理
  const handleCellClick = useCallback((e) => {
    e.stopPropagation();
    onCellInteraction?.(cellData, 'click');
  }, [cellData, onCellInteraction]);

  const handleCellDoubleClick = useCallback((e) => {
    e.stopPropagation();
    onCellInteraction?.(cellData, 'double_click');
  }, [cellData, onCellInteraction]);

  // セルCSS クラス生成
  const cellClassName = useMemo(() => {
    const classes = ['grid-cell'];

    // 基本状態クラス
    classes.push(cellData.cell_type);
    if (compactMode) classes.push('compact');
    if (cellStatus.hasFeatures) classes.push('has-features');
    if (cellStatus.isEmpty) classes.push('empty');

    // D&D状態クラス
    if (cellStatus.isDropTarget) classes.push('drop-target');
    if (cellStatus.isInvalidDrop) classes.push('invalid-drop');
    if (cellStatus.isDraggedOver) classes.push('dragged-over');
    if (cellStatus.isHovered) classes.push('hovered');

    // 特殊セルクラス
    if (cellData.epic_id === 'no-epic') classes.push('no-epic-cell');
    if (cellData.version_id === 'no-version') classes.push('no-version-cell');

    return classes.join(' ');
  }, [cellData, compactMode, cellStatus]);

  return (
    <div
      ref={setNodeRef}
      className={cellClassName}
      data-cell-epic={cellData.epic_id}
      data-cell-version={cellData.version_id}
      data-cell-index={cellIndex}
      onClick={handleCellClick}
      onDoubleClick={handleCellDoubleClick}
      style={{
        '--cell-feature-count': features.length,
        '--completion-rate': `${cellStatistics.completion_rate}%`
      }}
    >
      {/* ドロップインジケーター（D&D時表示） */}
      {cellStatus.isDraggedOver && (
        <DragIndicator
          isValidDrop={cellData.drop_allowed}
          cellType={cellData.cell_type}
          draggedFeature={draggedCard?.feature}
        />
      )}

      {/* Feature Card一覧 */}
      <div className="cell-features">
        {features.map((feature, featureIndex) => (
          <FeatureCard
            key={feature.issue.id}
            feature={feature}
            cellCoordinates={cellData.coordinates}
            compactMode={compactMode}
            expanded={!compactMode && features.length <= 3} // 3個以下は展開表示
            isDragging={draggedCard?.feature?.issue?.id === feature.issue.id}
            featureIndex={featureIndex}
          />
        ))}
      </div>

      {/* 空セルメッセージ（設計書85行目準拠） */}
      {cellStatus.isEmpty && !cellStatus.isDraggedOver && (
        <div className="empty-cell-message">
          <div className="empty-content">
            <span className="empty-icon">📝</span>
            <span className="empty-text">
              {compactMode ? 'Empty' : 'No Features'}
            </span>
          </div>
        </div>
      )}

      {/* セル統計インジケーター（多数Feature時） */}
      {features.length > (compactMode ? 2 : 5) && (
        <div className="cell-overflow-indicator">
          <div className="overflow-count">
            +{features.length - (compactMode ? 2 : 5)} more
          </div>
        </div>
      )}

      {/* セル統計表示（設定により） */}
      {!compactMode && cellStatistics.total_features > 0 && (
        <div className="cell-statistics">
          <div className="stat-row">
            <span className="stat-item">
              {cellStatistics.total_features} features
            </span>
            {cellStatistics.completion_rate > 0 && (
              <span className="stat-item completion-rate">
                {cellStatistics.completion_rate}% done
              </span>
            )}
          </div>
        </div>
      )}

      {/* セル操作ヒント（ホバー時表示） */}
      {cellStatus.isHovered && !cellStatus.isDraggedOver && (
        <div className="cell-interaction-hint">
          <small>
            {features.length > 0
              ? 'ダブルクリックで詳細表示'
              : 'FeatureをここにDropして配置'
            }
          </small>
        </div>
      )}

      {/* デバッグ情報（開発時のみ） */}
      {process.env.NODE_ENV === 'development' && (
        <div className="cell-debug-info">
          <small>
            E{cellData.epic_id}×V{cellData.version_id} ({features.length})
          </small>
        </div>
      )}
    </div>
  );
};

export default GridCell;