import React from 'react';
import { useDroppable } from '@dnd-kit/core';
import { FeatureCard } from './FeatureCard';

/**
 * GridCell (ドロップゾーン)
 * ワイヤーフレーム準拠: Epic行 × Version列 の個別セル
 *
 * @param {string} epicId - Epic ID
 * @param {string} versionId - Version ID
 * @param {Array} features - セル内のFeature配列
 * @param {boolean} isDropTarget - ドロップターゲット状態
 * @param {string} cellType - セルタイプ ('version' | 'no-version')
 */
export const GridCell = ({
  epicId,
  versionId,
  features = [],
  isDropTarget,
  cellType
}) => {
  const { setNodeRef, isOver } = useDroppable({
    id: `cell-${epicId}-${versionId}`,
    data: {
      type: 'grid-cell',
      epicId: epicId,
      versionId: versionId
    }
  });

  const getCellStyle = () => {
    if (cellType === 'no-version') {
      return 'grid-cell no-version-cell';
    }
    return 'grid-cell version-cell';
  };

  const getCellBackgroundColor = () => {
    if (isOver || isDropTarget) {
      return cellType === 'no-version' ? '#f0f0f0' : '#f0ebf7';
    }
    return cellType === 'no-version' ? '#f9f9f9' : '#ffffff';
  };

  return (
    <div
      ref={setNodeRef}
      className={getCellStyle()}
      style={{
        backgroundColor: getCellBackgroundColor(),
        border: isOver ? '2px dashed #9673a6' : '1px solid #9673a6',
        minHeight: '120px'
      }}
    >
      <div className="cell-features">
        {features.map(feature => (
          <FeatureCard
            key={feature.issue.id}
            feature={feature}
            expanded={false} // グリッド内では常に折り畳み
            onToggle={() => handleFeatureExpand(feature)}
            compact={true} // コンパクト表示モード
          />
        ))}
      </div>

      {isOver && (
        <div className="drop-indicator">
          ここにFeatureをドロップ
        </div>
      )}

      {features.length === 0 && !isOver && (
        <div className="empty-cell-message">
          Feature未割当
        </div>
      )}
    </div>
  );

  function handleFeatureExpand(feature) {
    // Featureの詳細表示または編集画面を開く
    window.open(`/issues/${feature.issue.id}`, '_blank');
  }
};