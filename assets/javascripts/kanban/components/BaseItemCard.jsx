import React, { useCallback } from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import './BaseItemCard.scss';

/**
 * Base Item Card Component (Task/Test/Bug用)
 * ワイヤーフレーム: GROUP_BASE_ITEM_CARD準拠 (160×25px)
 *
 * @param {Object} props
 * @param {Object} props.item - Item データ (Task/Test/Bug)
 * @param {'task'|'test'|'bug'} props.itemType - アイテムタイプ
 * @param {Object} props.permissions - ユーザー権限情報
 * @param {boolean} props.isDragDisabled - ドラッグ無効フラグ
 * @param {Function} props.onClick - クリックコールバック
 */
const BaseItemCard = ({
  item,
  itemType,
  permissions = {},
  isDragDisabled = false,
  onClick,
  ...props
}) => {
  // @dnd-kit sortable setup
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: `${itemType}-${item.id}`,
    data: {
      type: itemType,
      item: item
    },
    disabled: isDragDisabled
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  // アイテムタイプ別のアイコンとスタイル
  const getItemConfig = useCallback(() => {
    switch (itemType) {
      case 'task':
        return {
          icon: 'icon-task',
          className: 'task_item',
          colorClass: 'task_color'
        };
      case 'test':
        return {
          icon: 'icon-test',
          className: 'test_item',
          colorClass: 'test_color'
        };
      case 'bug':
        return {
          icon: 'icon-bug',
          className: 'bug_item',
          colorClass: 'bug_color'
        };
      default:
        return {
          icon: 'icon-issue',
          className: 'default_item',
          colorClass: 'default_color'
        };
    }
  }, [itemType]);

  const handleClick = useCallback((event) => {
    event.stopPropagation();
    onClick?.(item, itemType);
  }, [item, itemType, onClick]);

  const config = getItemConfig();

  // ブロック状態の判定
  const isBlocked = item.blocked_by && item.blocked_by.length > 0;

  // 優先度に基づく視覚的優先度
  const getPriorityClass = () => {
    if (!item.priority) return '';
    const priority = item.priority.toLowerCase();
    if (priority.includes('high') || priority.includes('urgent')) return 'high_priority';
    if (priority.includes('low')) return 'low_priority';
    return '';
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`
        group_base_item_card
        ${config.className}
        ${item.status?.is_closed ? 'completed' : 'active'}
        ${isBlocked ? 'blocked' : ''}
        ${getPriorityClass()}
        ${isDragging ? 'dragging' : ''}
      `.trim()}
      onClick={handleClick}
      {...attributes}
      {...listeners}
      {...props}
    >
      {/* ITEM_INDICATOR */}
      <div className={`item_indicator ${config.colorClass}`}>
        <i className={config.icon} />
      </div>

      {/* ITEM_CONTENT */}
      <div className="item_content">
        <div className="item_header">
          <span className="item_id">#{item.id}</span>
          <span className="item_title" title={item.subject}>
            {item.subject}
          </span>
        </div>

        <div className="item_metadata">
          <span className="item_status" data-status={item.status?.name?.toLowerCase()}>
            {item.status?.name}
          </span>

          {item.assigned_to && (
            <span className="item_assignee" title={item.assigned_to.name}>
              {item.assigned_to.name.charAt(0).toUpperCase()}
            </span>
          )}

          {item.due_date && (
            <span className="item_due_date" title={`Due: ${item.due_date}`}>
              <i className="icon-calendar" />
            </span>
          )}
        </div>
      </div>

      {/* ITEM_INDICATORS */}
      <div className="item_indicators">
        {/* 完了進捗 (Task/Testの場合) */}
        {item.completion_ratio !== undefined && item.completion_ratio > 0 && (
          <div className="completion_indicator" title={`${item.completion_ratio}% complete`}>
            <div
              className="completion_bar"
              style={{ width: `${item.completion_ratio}%` }}
            />
          </div>
        )}

        {/* ブロック状態インジケータ */}
        {isBlocked && (
          <div className="blocked_indicator" title="Blocked by other issues">
            <i className="icon-lock" />
          </div>
        )}

        {/* 優先度インジケータ */}
        {item.priority && getPriorityClass() && (
          <div className={`priority_indicator ${getPriorityClass()}`} title={item.priority}>
            <i className="icon-priority" />
          </div>
        )}
      </div>

      {/* ITEM_ACTIONS - ホバー時表示 */}
      <div className="item_actions">
        {permissions.can_edit && (
          <button
            className="action_btn edit_item"
            onClick={(e) => {
              e.stopPropagation();
              // Edit action
            }}
            title="Edit"
          >
            <i className="icon-edit" />
          </button>
        )}

        <button
          className="action_btn view_item"
          onClick={(e) => {
            e.stopPropagation();
            // View details action
          }}
          title="View Details"
        >
          <i className="icon-zoom-in" />
        </button>
      </div>
    </div>
  );
};

export default BaseItemCard;