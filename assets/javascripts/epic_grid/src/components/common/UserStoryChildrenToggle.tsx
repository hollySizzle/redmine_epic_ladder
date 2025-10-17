import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * UserStory配下（Task/Test/Bug）の一括展開・折り畳みボタン
 */
export const UserStoryChildrenToggle: React.FC = () => {
  const setAllUserStoriesCollapsed = useStore(state => state.setAllUserStoriesCollapsed);

  return (
    <div className="userstory-toggle-group">
      <button
        className="userstory-toggle-button expand"
        onClick={() => setAllUserStoriesCollapsed(false)}
        title="全UserStoryのTask/Test/Bugを展開"
      >
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
          <path d="M5 7 L10 15 L15 7 Z" fill="currentColor" />
        </svg>
        <span>全展開</span>
      </button>

      <button
        className="userstory-toggle-button collapse"
        onClick={() => setAllUserStoriesCollapsed(true)}
        title="全UserStoryのTask/Test/Bugを折り畳み"
      >
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
          <path d="M7 5 L15 10 L7 15 Z" fill="currentColor" />
        </svg>
        <span>全折畳</span>
      </button>
    </div>
  );
};
