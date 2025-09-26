import React, { useMemo } from 'react';

/**
 * DragIndicator - 設計書準拠のドラッグインジケーターコンポーネント
 * 設計書仕様: ドロップ予告・視覚的フィードバック（設計書83行目・530-535行目準拠）
 *
 * @param {boolean} isValidDrop - 有効なドロップターゲットか
 * @param {string} cellType - セルタイプ（epic-version, no-epic-version等）
 * @param {Object} draggedFeature - ドラッグ中Feature情報
 */
export const DragIndicator = ({
  isValidDrop = false,
  cellType = 'epic-version',
  draggedFeature = null
}) => {
  // インジケーター表示内容計算（メモ化）
  const indicatorContent = useMemo(() => {
    if (!draggedFeature) {
      return {
        message: 'Drop here',
        icon: '📝',
        detail: ''
      };
    }

    const featureName = draggedFeature.issue?.subject || 'Feature';
    const featureId = draggedFeature.issue?.id || '?';

    if (isValidDrop) {
      return {
        message: 'Drop to move here',
        icon: '✓',
        detail: `${featureName} (#${featureId})`
      };
    } else {
      return {
        message: 'Cannot drop here',
        icon: '⚠️',
        detail: getDropRestrictionReason(cellType, draggedFeature)
      };
    }
  }, [isValidDrop, cellType, draggedFeature]);

  // インジケータースタイル計算（メモ化）
  const indicatorStyle = useMemo(() => {
    const baseStyle = {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 100,
      borderRadius: '4px',
      transition: 'all 0.2s ease',
      backdropFilter: 'blur(2px)'
    };

    if (isValidDrop) {
      return {
        ...baseStyle,
        backgroundColor: 'rgba(76, 175, 80, 0.15)',
        border: '2px dashed #4caf50',
        color: '#2e7d32'
      };
    } else {
      return {
        ...baseStyle,
        backgroundColor: 'rgba(244, 67, 54, 0.15)',
        border: '2px dashed #f44336',
        color: '#c62828'
      };
    }
  }, [isValidDrop]);

  // アニメーション効果CSS クラス
  const indicatorClassName = useMemo(() => {
    const classes = ['drag-indicator'];

    if (isValidDrop) {
      classes.push('valid-drop');
    } else {
      classes.push('invalid-drop');
    }

    // セルタイプ別スタイル
    classes.push(`cell-type-${cellType}`);

    // アニメーション効果
    classes.push('pulse-animation');

    return classes.join(' ');
  }, [isValidDrop, cellType]);

  return (
    <div
      className={indicatorClassName}
      style={indicatorStyle}
    >
      {/* メインインジケーター */}
      <div className="indicator-content">
        <div className="indicator-icon">
          {indicatorContent.icon}
        </div>

        <div className="indicator-message">
          {indicatorContent.message}
        </div>

        {indicatorContent.detail && (
          <div className="indicator-detail">
            {indicatorContent.detail}
          </div>
        )}
      </div>

      {/* 矢印インジケーター（有効ドロップ時のみ） */}
      {isValidDrop && (
        <div className="drop-arrow-indicator">
          <div className="arrow-down">↓</div>
        </div>
      )}

      {/* セルタイプ固有の表示 */}
      {renderCellTypeSpecificIndicator(cellType, isValidDrop, draggedFeature)}

      {/* 無効ドロップ時の詳細情報 */}
      {!isValidDrop && draggedFeature && (
        <div className="restriction-info">
          <small>
            {getDetailedDropRestriction(cellType, draggedFeature)}
          </small>
        </div>
      )}
    </div>
  );
};

// セルタイプ固有インジケーター表示
const renderCellTypeSpecificIndicator = (cellType, isValidDrop, draggedFeature) => {
  switch (cellType) {
    case 'no-epic-version':
      return (
        <div className="cell-type-indicator no-epic">
          <div className="cell-type-label">
            <span className="label-icon">📋</span>
            <span className="label-text">No Epic</span>
          </div>
        </div>
      );

    case 'epic-no-version':
      return (
        <div className="cell-type-indicator no-version">
          <div className="cell-type-label">
            <span className="label-icon">📅</span>
            <span className="label-text">No Version</span>
          </div>
        </div>
      );

    case 'no-epic-no-version':
      return (
        <div className="cell-type-indicator no-epic-no-version">
          <div className="cell-type-label">
            <span className="label-icon">📝</span>
            <span className="label-text">Unassigned</span>
          </div>
        </div>
      );

    case 'epic-version':
    default:
      return null;
  }
};

// ドロップ制限理由取得
const getDropRestrictionReason = (cellType, draggedFeature) => {
  if (!draggedFeature) return 'No feature being dragged';

  // 基本的な制限理由
  const restrictions = [
    'Permission denied',
    'Feature locked',
    'Version closed',
    'Epic archived'
  ];

  // セルタイプ別制限
  switch (cellType) {
    case 'no-epic-version':
      return 'Epic assignment required for this version';
    case 'epic-no-version':
      return 'Version assignment recommended';
    case 'no-epic-no-version':
      return 'Consider assigning to Epic and Version';
    default:
      return restrictions[0];
  }
};

// 詳細なドロップ制限情報取得
const getDetailedDropRestriction = (cellType, draggedFeature) => {
  const featureName = draggedFeature.issue?.subject || 'Feature';
  const currentEpic = draggedFeature.currentCell?.epicId || 'None';
  const currentVersion = draggedFeature.currentCell?.versionId || 'None';

  return [
    `Current: Epic ${currentEpic}, Version ${currentVersion}`,
    `Feature: ${featureName}`,
    'Check permissions and cell constraints'
  ].join(' • ');
};

export default DragIndicator;