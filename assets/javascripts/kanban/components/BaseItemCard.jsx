import React from 'react';
import './BaseItemCard.scss';

/**
 * BaseItemCard - Task/Test/Bug基底クラス
 * 設計仕様書完全準拠: @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const BaseItemCard = ({
  item,
  type, // 'Task' | 'Test' | 'Bug'
  onUpdate,
  onDelete,
  className = ''
}) => {
  const getAssigneeDisplay = (assignee) => {
    if (!assignee) return '（未割当）';
    return assignee.name || assignee;
  };

  const handleDeleteClick = (e) => {
    e.stopPropagation();
    if (window.confirm(`${type} "${item.subject}" を削除しますか？`)) {
      onDelete(item.id);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#f0f0f0',
      '完了': '#e0e0e0',
      '対応中': '#f0f0f0',
      '未着手': '#f0f0f0'
    };
    return colors[status] || '#f0f0f0';
  };

  return (
    <div className={`base-item-card ${type.toLowerCase()}-card ${className}`}>
      <div className="item-card-content">
        <div className="item-name">{item.subject}</div>
        <div className="item-assignee">
          {getAssigneeDisplay(item.assigned_to)}
        </div>
        <button
          className="item-delete-btn"
          onClick={handleDeleteClick}
          title={`${type}を削除`}
        >
          Delete
        </button>
      </div>

      <div className="item-status-container">
        <span
          className="item-status"
          style={{ backgroundColor: getStatusColor(item.status) }}
        >
          {item.status}
        </span>
      </div>
    </div>
  );
};