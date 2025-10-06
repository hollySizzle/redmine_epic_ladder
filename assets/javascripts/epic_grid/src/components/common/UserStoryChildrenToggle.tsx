import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * UserStory配下（Task/Test/Bug）の一括折り畳みを切り替えるトグルボタン
 */
export const UserStoryChildrenToggle: React.FC = () => {
  const isCollapsed = useStore(state => state.isUserStoryChildrenCollapsed);
  const toggle = useStore(state => state.toggleUserStoryChildrenCollapsed);

  return (
    <button
      className={`detail-pane-toggle ${isCollapsed ? 'active' : ''}`}
      onClick={toggle}
      title={isCollapsed ? 'Task/Test/Bugを展開' : 'Task/Test/Bugを折り畳み'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isCollapsed ? (
          // 折り畳み中アイコン（▶）
          <path
            d="M7 5 L15 10 L7 15 Z"
            fill="currentColor"
          />
        ) : (
          // 展開中アイコン（▼）
          <path
            d="M5 7 L10 15 L15 7 Z"
            fill="currentColor"
          />
        )}
      </svg>
      <span className="detail-pane-toggle__label">
        {isCollapsed ? 'Task展開' : 'Task折畳'}
      </span>
    </button>
  );
};
