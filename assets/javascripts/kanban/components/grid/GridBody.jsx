import React, { useMemo, useCallback } from 'react';
import { EpicRow } from './EpicRow';
import { NoEpicRow } from './NoEpicRow';
import { NewEpicRow } from './NewEpicRow';

/**
 * GridBody - 設計書準拠のグリッドボディコンポーネント
 * 設計書仕様: EpicRows + NoEpicRow + NewEpicRow（設計書73-85行目準拠）
 *
 * @param {Array} epicRows - Epic行配列
 * @param {Array} versionColumns - Version列配列
 * @param {Function} getCellFeatures - セル内Feature取得関数
 * @param {Function} getCellStatistics - セル統計計算関数
 * @param {Object} draggedCard - ドラッグ中カード情報
 * @param {Object} hoveredCell - ホバー中セル情報
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {Function} onNewEpic - 新Epic作成コールバック
 */
export const GridBody = ({
  epicRows = [],
  versionColumns = [],
  getCellFeatures,
  getCellStatistics,
  draggedCard,
  hoveredCell,
  compactMode = false,
  onNewEpic
}) => {
  // Epic行とNo Epic行の分離
  const { normalEpics, noEpicRow } = useMemo(() => {
    console.log('[GridBody] 🔍 デバッグ - Epic行分離処理開始');
    console.log('[GridBody] 📋 epicRows受信データ:', epicRows);
    console.log('[GridBody] 📊 epicRows件数:', epicRows?.length || 0);

    const normal = epicRows.filter(epic => epic.id !== 'no-epic');
    const noEpic = epicRows.find(epic => epic.type === 'no-epic');

    console.log('[GridBody] ✅ フィルタリング結果:');
    console.log('[GridBody] 👥 normalEpics:', normal);
    console.log('[GridBody] 👥 normalEpics件数:', normal.length);
    console.log('[GridBody] 🚫 noEpicRow:', noEpic);
    console.log('[GridBody] 🎯 表示判定: normalEpics.length === 0 && !noEpicRow =', normal.length === 0 && !noEpic);

    return {
      normalEpics: normal,
      noEpicRow: noEpic
    };
  }, [epicRows]);

  // セル相互作用ハンドラー（D&D対応）
  const handleCellInteraction = useCallback((cellData, interactionType) => {
    switch (interactionType) {
      case 'drag_enter':
        console.log('[GridBody] Cell drag enter:', cellData);
        break;
      case 'drag_leave':
        console.log('[GridBody] Cell drag leave:', cellData);
        break;
      case 'drop':
        console.log('[GridBody] Cell drop:', cellData);
        break;
      default:
        break;
    }
  }, []);

  // ドロップターゲット判定
  const isValidDropTarget = useCallback((cellData) => {
    if (!draggedCard) return false;

    // 基本制約チェック
    if (cellData.epic_id === draggedCard.currentCell?.epicId &&
        cellData.version_id === draggedCard.currentCell?.versionId) {
      return false; // 同じセルへの移動は無効
    }

    // カスタム制約チェック（将来の拡張ポイント）
    return true;
  }, [draggedCard]);

  // グリッド構造計算（CSS Grid Layout用）
  const gridStructure = useMemo(() => {
    const totalRows = normalEpics.length + (noEpicRow ? 1 : 0) + 1; // +1 for NewEpicRow
    const totalColumns = versionColumns.length;

    return {
      rows: totalRows,
      columns: totalColumns,
      epicCount: normalEpics.length,
      versionCount: totalColumns
    };
  }, [normalEpics, noEpicRow, versionColumns]);

  return (
    <div
      className={`kanban-grid-body ${compactMode ? 'compact' : ''}`}
      style={{
        '--grid-columns': gridStructure.columns,
        '--grid-rows': gridStructure.rows
      }}
    >
      {/* 通常Epic行群（設計書73-78行目準拠） */}
      {normalEpics.map((epicRow, index) => (
        <EpicRow
          key={epicRow.id}
          epic={epicRow}
          versionColumns={versionColumns}
          getCellFeatures={getCellFeatures}
          getCellStatistics={getCellStatistics}
          draggedCard={draggedCard}
          hoveredCell={hoveredCell}
          compactMode={compactMode}
          rowIndex={index}
          onCellInteraction={handleCellInteraction}
          isValidDropTarget={isValidDropTarget}
        />
      ))}

      {/* No Epic行（設計書74-75行目準拠） */}
      {noEpicRow && (
        <NoEpicRow
          noEpicData={noEpicRow}
          versionColumns={versionColumns}
          getCellFeatures={getCellFeatures}
          getCellStatistics={getCellStatistics}
          draggedCard={draggedCard}
          hoveredCell={hoveredCell}
          compactMode={compactMode}
          rowIndex={normalEpics.length}
          onCellInteraction={handleCellInteraction}
          isValidDropTarget={isValidDropTarget}
        />
      )}

      {/* 新Epic作成行（設計書76-77行目準拠） */}
      <NewEpicRow
        versionColumns={versionColumns}
        onNewEpic={onNewEpic}
        compactMode={compactMode}
        rowIndex={normalEpics.length + (noEpicRow ? 1 : 0)}
      />

      {/* グリッド状態インジケーター */}
      {draggedCard && (
        <div className="grid-drag-overlay">
          <div className="drag-info">
            ドラッグ中: {draggedCard.feature?.issue?.subject || 'Feature'}
          </div>
        </div>
      )}

      {/* 空グリッド状態 */}
      {normalEpics.length === 0 && !noEpicRow && (
        <div className="empty-grid-state">
          <div className="empty-message">
            <h3>Epicが登録されていません</h3>
            <p>「+ New Epic」ボタンから最初のEpicを作成してください。</p>
          </div>
        </div>
      )}

      {/* デバッグ情報（開発時のみ表示） */}
      {process.env.NODE_ENV === 'development' && (
        <div className="grid-debug-info">
          <div className="debug-item">
            <strong>Grid Structure:</strong> {gridStructure.rows}R × {gridStructure.columns}C
          </div>
          <div className="debug-item">
            <strong>Epics:</strong> {gridStructure.epicCount}
          </div>
          <div className="debug-item">
            <strong>Versions:</strong> {gridStructure.versionCount}
          </div>
          {draggedCard && (
            <div className="debug-item">
              <strong>Dragging:</strong> {draggedCard.feature?.issue?.id}
            </div>
          )}
          {hoveredCell && (
            <div className="debug-item">
              <strong>Hovered:</strong> E{hoveredCell.epicId} × V{hoveredCell.versionId}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default GridBody;