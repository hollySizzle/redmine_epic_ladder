import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * UserStoryの期日の表示/非表示を切り替えるトグルボタン
 */
export const DueDateToggle: React.FC = () => {
  const isDueDateVisible = useStore(state => state.isDueDateVisible);
  const toggleDueDateVisible = useStore(state => state.toggleDueDateVisible);

  return (
    <button
      className={`detail-pane-toggle ${isDueDateVisible ? 'active' : ''}`}
      onClick={toggleDueDateVisible}
      title={isDueDateVisible ? '期日を非表示' : '期日を表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isDueDateVisible ? (
          // 期日表示中アイコン（カレンダーアイコン）
          <>
            <rect
              x="3"
              y="4"
              width="14"
              height="13"
              rx="2"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
            />
            <path
              d="M3 8 L17 8"
              stroke="currentColor"
              strokeWidth="2"
            />
            <path
              d="M6 3 L6 6"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <path
              d="M14 3 L14 6"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </>
        ) : (
          // 期日非表示アイコン（カレンダー + 斜線）
          <>
            <rect
              x="3"
              y="4"
              width="14"
              height="13"
              rx="2"
              stroke="currentColor"
              strokeWidth="2"
              fill="none"
              opacity="0.5"
            />
            <path
              d="M3 8 L17 8"
              stroke="currentColor"
              strokeWidth="2"
              opacity="0.5"
            />
            <path
              d="M6 3 L6 6"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              opacity="0.5"
            />
            <path
              d="M14 3 L14 6"
              stroke="currentColor"
              strokeWidth="2"
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
        {isDueDateVisible ? '期日' : '期日'}
      </span>
    </button>
  );
};
