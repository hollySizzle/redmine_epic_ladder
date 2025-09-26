import { useState, useMemo, useCallback } from 'react';
import { GridCell } from './GridCell';

/**
 * NoEpicRow - 設計書準拠のNo Epic行コンポーネント
 * 設計書仕様: NoEpicHeaderCell + VersionCells（設計書79-83行目準拠）
 *
 * @param {Object} noEpicData - No Epic情報（statistics含む）
 * @param {Array} versionColumns - Version列配列
 * @param {Function} getCellFeatures - セル内Feature取得関数
 * @param {Function} getCellStatistics - セル統計計算関数
 * @param {Object} draggedCard - ドラッグ中カード情報
 * @param {Object} hoveredCell - ホバー中セル情報
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {number} rowIndex - 行インデックス
 * @param {Function} onCellInteraction - セル相互作用ハンドラー
 * @param {Function} isValidDropTarget - ドロップターゲット判定関数
 */
export const NoEpicRow = ({
  noEpicData,
  versionColumns = [],
  getCellFeatures,
  getCellStatistics,
  draggedCard,
  hoveredCell,
  compactMode = false,
  rowIndex,
  onCellInteraction,
  isValidDropTarget
}) => {
  // No Epic行の展開状態管理
  const [isExpanded, setIsExpanded] = useState(true);

  // No Epic統計情報（メモ化）
  const noEpicStatistics = useMemo(() => {
    if (!noEpicData?.statistics) {
      // 統計が提供されていない場合の代替計算
      const totalFeatures = 0; // 実際の実装では孤立Featureをカウント
      return {
        total_features: totalFeatures,
        completed_features: 0,
        completion_rate: 0
      };
    }

    return noEpicData.statistics;
  }, [noEpicData?.statistics]);

  // セルデータ生成（メモ化）
  const noEpicCells = useMemo(() => {
    return versionColumns.map(version => {
      const cellData = {
        epic_id: 'no-epic',
        version_id: version.id,
        coordinates: {
          epic_id: null, // No Epic = null
          version_id: version.id,
          row_index: rowIndex,
          column_index: versionColumns.indexOf(version)
        }
      };

      const features = getCellFeatures ? getCellFeatures('no-epic', version.id) : [];
      const statistics = getCellStatistics ? getCellStatistics('no-epic', version.id) : {
        total_features: features.length,
        completed_features: 0,
        completion_rate: 0
      };

      return {
        ...cellData,
        features,
        statistics,
        drop_allowed: isValidDropTarget ? isValidDropTarget(cellData) : true,
        cell_type: version.type === 'no-version' ? 'no-epic-no-version' : 'no-epic-version'
      };
    });
  }, [versionColumns, getCellFeatures, getCellStatistics, isValidDropTarget, rowIndex]);

  // 展開/折りたたみトグル
  const toggleExpanded = useCallback(() => {
    setIsExpanded(prev => !prev);
  }, []);

  // Epic割り当て一括処理（将来の機能）
  const handleBulkAssignToEpic = useCallback(() => {
    console.log('[NoEpicRow] Bulk assign to Epic triggered');
    // TODO: 一括Epic割り当て機能の実装
    alert('一括Epic割り当て機能は今後実装予定です');
  }, []);

  // セルからFeature総数を計算
  const totalOrphanFeatures = useMemo(() => {
    return noEpicCells.reduce((total, cell) => {
      return total + (cell.features?.length || 0);
    }, 0);
  }, [noEpicCells]);

  return (
    <div
      className={`no-epic-row ${compactMode ? 'compact' : ''} ${isExpanded ? 'expanded' : 'collapsed'}`}
      data-epic-id="no-epic"
      data-row-index={rowIndex}
    >
      {/* No Epic ヘッダーセル（設計書79行目準拠） */}
      <div className="no-epic-header-cell">
        <div className="no-epic-header-content">
          {/* 展開/折りたたみボタン */}
          <button
            className="epic-expand-toggle"
            onClick={toggleExpanded}
            title={isExpanded ? 'No Epic行を折りたたむ' : 'No Epic行を展開'}
          >
            <span className={`expand-icon ${isExpanded ? 'expanded' : ''}`}>
              ▼
            </span>
          </button>

          {/* No Epic情報表示 */}
          <div className="no-epic-info">
            <div className="no-epic-display">
              <h4 className="no-epic-title">
                <span className="no-epic-icon">📝</span>
                No EPIC
              </h4>

              <div className="no-epic-description">
                親Epicが未設定のFeatureが表示されます
              </div>
            </div>
          </div>

          {/* No Epic統計情報 */}
          <div className="no-epic-statistics">
            <div className="stat-item">
              <span className="stat-value">{totalOrphanFeatures}</span>
              <span className="stat-label">Orphan Features</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{noEpicStatistics.completion_rate}%</span>
              <span className="stat-label">Complete</span>
            </div>
          </div>

          {/* No Epic行専用アクション */}
          <div className="no-epic-actions">
            {totalOrphanFeatures > 0 && (
              <button
                className="bulk-assign-button"
                onClick={handleBulkAssignToEpic}
                title="孤立Featureを既存Epicに一括割り当て"
              >
                <span className="action-icon">🎯</span>
                <span className="action-text">一括割当</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Version列セル群（設計書80-83行目準拠） */}
      {isExpanded && noEpicCells.map((cellData, cellIndex) => (
        <GridCell
          key={`no-epic-${cellData.version_id}`}
          cellData={cellData}
          features={cellData.features}
          statistics={cellData.statistics}
          draggedCard={draggedCard}
          hoveredCell={hoveredCell}
          compactMode={compactMode}
          onCellInteraction={onCellInteraction}
          cellIndex={cellIndex}
        />
      ))}

      {/* 折りたたみ時のサマリー表示 */}
      {!isExpanded && (
        <div className="no-epic-collapsed-summary">
          <div className="summary-stats">
            {totalOrphanFeatures}件の孤立Feature（完了率: {noEpicStatistics.completion_rate}%）
          </div>
          <button
            className="expand-hint"
            onClick={toggleExpanded}
            title="No Epic行を展開してセルを表示"
          >
            詳細を表示
          </button>
        </div>
      )}

      {/* 空状態メッセージ */}
      {isExpanded && totalOrphanFeatures === 0 && (
        <div className="no-epic-empty-state">
          <div className="empty-message">
            <span className="empty-icon">✨</span>
            <p>現在、親Epic未設定のFeatureはありません</p>
            <small>全てのFeatureが適切なEpicに割り当てられています</small>
          </div>
        </div>
      )}

      {/* 警告表示（孤立Featureが多い場合） */}
      {totalOrphanFeatures > 10 && (
        <div className="no-epic-warning">
          <span className="warning-icon">⚠️</span>
          <span className="warning-text">
            孤立Featureが多数あります。整理をお勧めします。
          </span>
        </div>
      )}
    </div>
  );
};

export default NoEpicRow;