import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * バージョン統計情報の表示/非表示を切り替えるトグルボタン
 */
export const VersionStatsToggle: React.FC = () => {
  const isVersionStatsVisible = useStore(state => state.isVersionStatsVisible);
  const toggleVersionStatsVisible = useStore(state => state.toggleVersionStatsVisible);

  return (
    <button
      className={`eg-button eg-button--toggle ${isVersionStatsVisible ? 'eg-button--active' : ''}`}
      onClick={toggleVersionStatsVisible}
      title={isVersionStatsVisible ? 'バージョン統計を非表示' : 'バージョン統計を表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isVersionStatsVisible ? (
          // 統計情報表示中アイコン（カレンダー + チェック）
          <>
            <rect
              x="3"
              y="4"
              width="14"
              height="12"
              rx="1"
              stroke="currentColor"
              strokeWidth="1.5"
              fill="none"
            />
            <path
              d="M3 7 L17 7"
              stroke="currentColor"
              strokeWidth="1.5"
            />
            <path
              d="M7 9 L9 11 L13 7"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              fill="none"
            />
          </>
        ) : (
          // 統計情報非表示アイコン（カレンダー + 斜線）
          <>
            <rect
              x="3"
              y="4"
              width="14"
              height="12"
              rx="1"
              stroke="currentColor"
              strokeWidth="1.5"
              fill="none"
              opacity="0.5"
            />
            <path
              d="M3 7 L17 7"
              stroke="currentColor"
              strokeWidth="1.5"
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
      <span>
        {isVersionStatsVisible ? 'Ver統計' : 'Ver統計'}
      </span>
    </button>
  );
};
