import React, { useState, useCallback } from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import UserStoryItem from './UserStoryItem';
import './FeatureCard.scss';

/**
 * Feature Card Component
 * ワイヤーフレーム: GROUP_FEATURE_CARD準拠
 *
 * @param {Object} props
 * @param {Object} props.feature - Feature データ
 * @param {Array} props.userStories - UserStory データ配列
 * @param {Object} props.statistics - Feature統計情報
 * @param {Object} props.permissions - ユーザー権限情報
 * @param {Function} props.onUserStoryToggle - UserStory展開/折りたたみコールバック
 * @param {Function} props.onBulkAction - 一括操作コールバック
 * @param {boolean} props.isDragDisabled - ドラッグ無効フラグ
 */
const FeatureCard = ({
  feature,
  userStories = [],
  statistics = {},
  permissions = {},
  onUserStoryToggle,
  onBulkAction,
  isDragDisabled = false,
  ...props
}) => {
  const [selectedUserStories, setSelectedUserStories] = useState(new Set());
  const [showBulkActions, setShowBulkActions] = useState(false);

  // @dnd-kit sortable setup
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: `feature-${feature.id}`,
    data: {
      type: 'feature',
      feature: feature
    },
    disabled: isDragDisabled
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  // UserStory選択ハンドラー
  const handleUserStorySelect = useCallback((userStoryId, selected) => {
    setSelectedUserStories(prev => {
      const newSet = new Set(prev);
      if (selected) {
        newSet.add(userStoryId);
      } else {
        newSet.delete(userStoryId);
      }
      return newSet;
    });
    setShowBulkActions(selectedUserStories.size > 0);
  }, [selectedUserStories.size]);

  // 全選択/全選択解除
  const handleSelectAll = useCallback(() => {
    if (selectedUserStories.size === userStories.length) {
      setSelectedUserStories(new Set());
      setShowBulkActions(false);
    } else {
      setSelectedUserStories(new Set(userStories.map(us => us.issue.id)));
      setShowBulkActions(true);
    }
  }, [selectedUserStories.size, userStories]);

  // 一括アクション実行
  const handleBulkAction = useCallback((actionType) => {
    if (selectedUserStories.size === 0) return;

    onBulkAction?.(actionType, Array.from(selectedUserStories));
    setSelectedUserStories(new Set());
    setShowBulkActions(false);
  }, [selectedUserStories, onBulkAction]);

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`group_feature_card ${isDragging ? 'dragging' : ''}`}
      {...attributes}
      {...listeners}
      {...props}
    >
      {/* GROUP_FEATURE_HEADER */}
      <div className="group_feature_header">
        <div className="feature_info">
          <span className="feature_id">#{feature.id}</span>
          <h3 className="feature_title">{feature.subject}</h3>
          <span className="feature_status" data-status={feature.status.name.toLowerCase()}>
            {feature.status.name}
          </span>
        </div>

        <div className="feature_metadata">
          <span className="assignee">{feature.assigned_to?.name || 'Unassigned'}</span>
          <span className="version">{feature.fixed_version?.name || 'No Version'}</span>
        </div>

        <div className="feature_statistics">
          <div className="completion_bar">
            <div
              className="completion_fill"
              style={{ width: `${statistics.completion_ratio || 0}%` }}
            />
          </div>
          <span className="completion_text">
            {statistics.completed_user_stories || 0}/{statistics.total_user_stories || 0}
          </span>
        </div>
      </div>

      {/* GROUP_USER_STORIES_SECTION */}
      <div className="group_user_stories_section">
        {/* USER_STORIES_HEADER */}
        <div className="user_stories_header">
          <div className="header_controls">
            <button
              className="expand_all_btn"
              onClick={handleSelectAll}
              disabled={userStories.length === 0}
            >
              {selectedUserStories.size === userStories.length ? 'Deselect All' : 'Select All'}
            </button>

            <span className="user_stories_count">
              {userStories.length} User Stories
            </span>
          </div>

          {/* BULK_ACTIONS_PANEL - 選択時のみ表示 */}
          {showBulkActions && (
            <div className="bulk_actions_panel">
              {permissions.can_assign_version && (
                <button
                  className="bulk_action_btn assign_version"
                  onClick={() => handleBulkAction('assign_version')}
                >
                  Assign Version
                </button>
              )}
              {permissions.can_edit && (
                <button
                  className="bulk_action_btn update_status"
                  onClick={() => handleBulkAction('update_status')}
                >
                  Update Status
                </button>
              )}
              {permissions.can_generate_tests && (
                <button
                  className="bulk_action_btn generate_tests"
                  onClick={() => handleBulkAction('generate_tests')}
                >
                  Generate Tests
                </button>
              )}
            </div>
          )}
        </div>

        {/* USER_STORIES_LIST */}
        <div className="user_stories_list">
          {userStories.map((userStory) => (
            <UserStoryItem
              key={userStory.issue.id}
              userStory={userStory}
              isSelected={selectedUserStories.has(userStory.issue.id)}
              onToggle={onUserStoryToggle}
              onSelect={handleUserStorySelect}
              permissions={permissions}
            />
          ))}

          {userStories.length === 0 && (
            <div className="empty_user_stories">
              <span className="empty_message">No User Stories</span>
            </div>
          )}
        </div>
      </div>

      {/* FEATURE_ACTIONS */}
      <div className="feature_actions">
        {permissions.can_edit && (
          <button className="action_btn edit_feature">
            <i className="icon-edit" />
            Edit
          </button>
        )}
        {permissions.can_assign_version && (
          <button className="action_btn assign_version">
            <i className="icon-tag" />
            Version
          </button>
        )}
        <button className="action_btn view_details">
          <i className="icon-zoom-in" />
          Details
        </button>
      </div>
    </div>
  );
};

export default FeatureCard;