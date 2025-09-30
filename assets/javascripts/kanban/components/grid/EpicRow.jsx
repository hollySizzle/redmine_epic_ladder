import React, { useState, useMemo, useCallback } from 'react';
import { GridCell } from './GridCell';

/**
 * EpicRow - 設計書準拠のEpic行コンポーネント
 * 設計書仕様: EpicHeaderCell + VersionCells（設計書77-83行目準拠）
 *
 * @param {Object} epic - Epic情報（issue, features, statistics, ui_state含む）
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
export const EpicRow = ({
  epic,
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
  console.log('[EpicRow] 🎯 受信Epic詳細:', epic);
  console.log('[EpicRow] 📝 Epic ID:', epic.id);
  console.log('[EpicRow] 📝 Epic name:', epic.name);
  console.log('[EpicRow] 📝 Epic.data:', epic.data);
  console.log('[EpicRow] 📝 Epic.data.issue:', epic.data?.issue);
  console.log('[EpicRow] 📝 Epic.data.issue.subject:', epic.data?.issue?.subject);
  // Epic行の展開状態管理
  const [isExpanded, setIsExpanded] = useState(
    epic.ui_state?.expanded !== undefined ? epic.ui_state.expanded : true
  );

  // Epic編集状態
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({
    subject: epic.data?.issue?.subject || '',
    description: epic.data?.issue?.description || ''
  });

  // Epic統計情報（メモ化）
  const epicStatistics = useMemo(() => {
    if (!epic.statistics) {
      // 統計が提供されていない場合の代替計算
      const totalFeatures = epic.data?.features?.length || 0;
      const completedFeatures = epic.data?.features?.filter(feature =>
        ['Resolved', 'Closed'].includes(feature.issue?.status)
      ).length || 0;

      return {
        total_features: totalFeatures,
        completed_features: completedFeatures,
        completion_rate: totalFeatures > 0 ?
          Math.round((completedFeatures / totalFeatures) * 100) : 0
      };
    }

    return epic.statistics;
  }, [epic.statistics, epic.data]);

  // セルデータ生成（メモ化）
  const epicCells = useMemo(() => {
    return versionColumns.map(version => {
      const cellData = {
        epic_id: epic.id,
        version_id: version.id,
        coordinates: {
          epic_id: epic.id,
          version_id: version.id,
          row_index: rowIndex,
          column_index: versionColumns.indexOf(version)
        }
      };

      const features = getCellFeatures ? getCellFeatures(epic.id, version.id) : [];
      const statistics = getCellStatistics ? getCellStatistics(epic.id, version.id) : {
        total_features: features.length,
        completed_features: 0,
        completion_rate: 0
      };

      return {
        ...cellData,
        features,
        statistics,
        drop_allowed: isValidDropTarget ? isValidDropTarget(cellData) : true,
        cell_type: version.type === 'no-version' ? 'epic-no-version' : 'epic-version'
      };
    });
  }, [epic.id, versionColumns, getCellFeatures, getCellStatistics, isValidDropTarget, rowIndex]);

  // Epic展開/折りたたみトグル
  const toggleExpanded = useCallback(() => {
    setIsExpanded(prev => !prev);
  }, []);

  // Epic編集開始
  const startEditing = useCallback(() => {
    setEditData({
      subject: epic.data?.issue?.subject || '',
      description: epic.data?.issue?.description || ''
    });
    setIsEditing(true);
  }, [epic.data?.issue]);

  // Epic編集キャンセル
  const cancelEditing = useCallback(() => {
    setIsEditing(false);
    setEditData({
      subject: epic.data?.issue?.subject || '',
      description: epic.data?.issue?.description || ''
    });
  }, [epic.data?.issue]);

  // Epic更新処理
  const handleUpdateEpic = useCallback(async () => {
    if (!editData.subject.trim()) {
      alert('Epic名を入力してください');
      return;
    }

    try {
      // TODO: Epic更新API呼び出し
      console.log('[EpicRow] Epic更新:', {
        id: epic.id,
        subject: editData.subject,
        description: editData.description
      });

      // 成功時の処理
      setIsEditing(false);
      // 実際の実装では、親コンポーネントの更新コールバックを呼び出し
    } catch (error) {
      console.error('Epic更新エラー:', error);
      alert(`Epic更新に失敗しました: ${error.message}`);
    }
  }, [epic.id, editData]);

  return (
    <div
      className={`epic-row ${compactMode ? 'compact' : ''} ${isExpanded ? 'expanded' : 'collapsed'}`}
      data-epic-id={epic.id}
      data-row-index={rowIndex}
    >
      {/* Epic ヘッダーセル（設計書77行目準拠） */}
      <div className="epic-header-cell">
        <div className="epic-header-content">
          {/* 展開/折りたたみボタン */}
          <button
            className="epic-expand-toggle"
            onClick={toggleExpanded}
            title={isExpanded ? 'Epic行を折りたたむ' : 'Epic行を展開'}
          >
            <span className={`expand-icon ${isExpanded ? 'expanded' : ''}`}>
              ▼
            </span>
          </button>

          {/* Epic情報表示 */}
          <div className="epic-info">
            {!isEditing ? (
              <div className="epic-display">
                <h4
                  className="epic-title"
                  title={epic.data?.issue?.description}
                  onDoubleClick={startEditing}
                >
                  {(() => {
                    console.log('[EpicRow] 🎨 レンダリング時のepic.data?.issue?.subject:', epic.data?.issue?.subject);
                    console.log('[EpicRow] 🎨 レンダリング時のepic全体:', epic);
                    const subject = epic.data?.issue?.subject || 'Untitled Epic';
                    console.log('[EpicRow] 🎨 最終表示subject:', subject);
                    return subject;
                  })()}
                </h4>

                <div className="epic-metadata">
                  <span className="epic-id">#{epic.data?.issue?.id}</span>
                  {epic.data?.issue?.status && (
                    <span className={`epic-status ${epic.data.issue.status.toLowerCase()}`}>
                      {epic.data.issue.status}
                    </span>
                  )}
                </div>
              </div>
            ) : (
              <div className="epic-edit-form">
                <input
                  type="text"
                  value={editData.subject}
                  onChange={(e) => setEditData({ ...editData, subject: e.target.value })}
                  className="epic-subject-input"
                  placeholder="Epic名"
                  autoFocus
                />

                <div className="edit-actions">
                  <button onClick={handleUpdateEpic} className="save-button">
                    保存
                  </button>
                  <button onClick={cancelEditing} className="cancel-button">
                    キャンセル
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Epic統計情報 */}
          <div className="epic-statistics">
            <div className="stat-item">
              <span className="stat-value">{epicStatistics.total_features}</span>
              <span className="stat-label">Features</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{epicStatistics.completion_rate}%</span>
              <span className="stat-label">Complete</span>
            </div>
          </div>
        </div>
      </div>

      {/* Version列セル群（設計書78-83行目準拠） */}
      {isExpanded && epicCells.map((cellData, cellIndex) => (
        <GridCell
          key={`${epic.id}-${cellData.version_id}`}
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
        <div className="epic-collapsed-summary">
          <div className="summary-stats">
            {epicStatistics.total_features}件のFeature（完了率: {epicStatistics.completion_rate}%）
          </div>
          <button
            className="expand-hint"
            onClick={toggleExpanded}
            title="Epic行を展開してセルを表示"
          >
            詳細を表示
          </button>
        </div>
      )}
    </div>
  );
};

export default EpicRow;