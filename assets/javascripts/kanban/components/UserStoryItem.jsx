import React, { useState, useCallback } from 'react';
import BaseItemCard from './BaseItemCard';
import './UserStoryItem.scss';

/**
 * User Story Item Component
 * ワイヤーフレーム: GROUP_USER_STORY_ITEM準拠
 *
 * @param {Object} props
 * @param {Object} props.userStory - UserStory データ
 * @param {boolean} props.isSelected - 選択状態
 * @param {boolean} props.expanded - 展開状態（初期値）
 * @param {Function} props.onToggle - 展開/折りたたみコールバック
 * @param {Function} props.onSelect - 選択コールバック
 * @param {Object} props.permissions - ユーザー権限情報
 */
const UserStoryItem = ({
  userStory,
  isSelected = false,
  expanded: initialExpanded,
  onToggle,
  onSelect,
  permissions = {},
  ...props
}) => {
  const [expanded, setExpanded] = useState(initialExpanded || userStory.expansion_state || false);
  const { issue, child_items, statistics } = userStory;

  // 展開/折りたたみハンドラー
  const handleToggle = useCallback(() => {
    const newExpanded = !expanded;
    setExpanded(newExpanded);
    onToggle?.(issue.id, newExpanded);
  }, [expanded, issue.id, onToggle]);

  // 選択ハンドラー
  const handleSelect = useCallback((event) => {
    event.stopPropagation();
    onSelect?.(issue.id, !isSelected);
  }, [issue.id, isSelected, onSelect]);

  // 子アイテム数計算
  const totalChildItems = (child_items?.tasks?.length || 0) +
                         (child_items?.tests?.length || 0) +
                         (child_items?.bugs?.length || 0);

  const completedChildItems = [
    ...(child_items?.tasks || []),
    ...(child_items?.tests || []),
    ...(child_items?.bugs || [])
  ].filter(item => item.status?.is_closed).length;

  return (
    <div
      className={`group_user_story_item ${isSelected ? 'selected' : ''} ${expanded ? 'expanded' : 'collapsed'}`}
      {...props}
    >
      {/* USER_STORY_HEADER */}
      <div className="user_story_header" onClick={handleToggle}>
        <div className="header_left">
          <input
            type="checkbox"
            className="select_checkbox"
            checked={isSelected}
            onChange={handleSelect}
            onClick={(e) => e.stopPropagation()}
          />

          <button
            className={`expand_toggle ${totalChildItems === 0 ? 'disabled' : ''}`}
            disabled={totalChildItems === 0}
            onClick={(e) => {
              e.stopPropagation();
              handleToggle();
            }}
          >
            <i className={`icon-chevron-${expanded ? 'down' : 'right'}`} />
          </button>

          <div className="user_story_info">
            <span className="user_story_id">#{issue.id}</span>
            <span className="user_story_title">{issue.subject}</span>
            <span className="user_story_status" data-status={issue.status.name.toLowerCase()}>
              {issue.status.name}
            </span>
          </div>
        </div>

        <div className="header_right">
          <div className="user_story_metadata">
            <span className="assignee">{issue.assigned_to?.name || 'Unassigned'}</span>
            <span className="priority">{issue.priority?.name || 'Normal'}</span>
          </div>

          <div className="child_items_summary">
            <span className="items_count">
              {completedChildItems}/{totalChildItems} items
            </span>
            <div className="completion_indicator">
              <div
                className="completion_fill"
                style={{ width: `${totalChildItems > 0 ? (completedChildItems / totalChildItems * 100) : 0}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* CHILD_ITEMS_SECTION - 展開時のみ表示 */}
      {expanded && totalChildItems > 0 && (
        <div className="child_items_section">
          {/* TASKS_GROUP */}
          {child_items?.tasks && child_items.tasks.length > 0 && (
            <div className="child_items_group tasks_group">
              <h4 className="group_title">
                <i className="icon-task" />
                Tasks ({child_items.tasks.length})
              </h4>
              <div className="items_grid">
                {child_items.tasks.map((task) => (
                  <BaseItemCard
                    key={task.id}
                    item={task}
                    itemType="task"
                    permissions={permissions}
                  />
                ))}
              </div>
            </div>
          )}

          {/* TESTS_GROUP */}
          {child_items?.tests && child_items.tests.length > 0 && (
            <div className="child_items_group tests_group">
              <h4 className="group_title">
                <i className="icon-test" />
                Tests ({child_items.tests.length})
              </h4>
              <div className="items_grid">
                {child_items.tests.map((test) => (
                  <BaseItemCard
                    key={test.id}
                    item={test}
                    itemType="test"
                    permissions={permissions}
                  />
                ))}
              </div>
            </div>
          )}

          {/* BUGS_GROUP */}
          {child_items?.bugs && child_items.bugs.length > 0 && (
            <div className="child_items_group bugs_group">
              <h4 className="group_title">
                <i className="icon-bug" />
                Bugs ({child_items.bugs.length})
              </h4>
              <div className="items_grid">
                {child_items.bugs.map((bug) => (
                  <BaseItemCard
                    key={bug.id}
                    item={bug}
                    itemType="bug"
                    permissions={permissions}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* USER_STORY_ACTIONS */}
      <div className="user_story_actions">
        {permissions.can_edit && (
          <button className="action_btn edit_user_story">
            <i className="icon-edit" />
          </button>
        )}
        {permissions.can_generate_tests && totalChildItems === 0 && (
          <button className="action_btn generate_tests">
            <i className="icon-plus" />
          </button>
        )}
        <button className="action_btn view_details">
          <i className="icon-zoom-in" />
        </button>
      </div>
    </div>
  );
};

export default UserStoryItem;