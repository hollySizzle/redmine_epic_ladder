import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * UserStoryの担当者名の表示/非表示を切り替えるトグルボタン
 */
export const AssignedToToggle: React.FC = () => {
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);
  const toggleAssignedToVisible = useStore(state => state.toggleAssignedToVisible);

  return (
    <button
      className={`detail-pane-toggle ${isAssignedToVisible ? 'active' : ''}`}
      onClick={toggleAssignedToVisible}
      title={isAssignedToVisible ? '担当者名を非表示' : '担当者名を表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isAssignedToVisible ? (
          // 担当者名表示中アイコン（人物アイコン）
          <>
            <circle
              cx="10"
              cy="7"
              r="3"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
            />
            <path
              d="M4 17 C4 13, 7 11, 10 11 C13 11, 16 13, 16 17"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
              strokeLinecap="round"
            />
          </>
        ) : (
          // 担当者名非表示アイコン（人物アイコン + 斜線）
          <>
            <circle
              cx="10"
              cy="7"
              r="3"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
              opacity="0.5"
            />
            <path
              d="M4 17 C4 13, 7 11, 10 11 C13 11, 16 13, 16 17"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
              strokeLinecap="round"
              opacity="0.5"
            />
            <path
              d="M3 3 L17 17"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </>
        )}
      </svg>
      <span className="detail-pane-toggle__label">
        {isAssignedToVisible ? '担当者名' : '担当者名'}
      </span>
    </button>
  );
};
