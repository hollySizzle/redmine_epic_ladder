import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * 統計情報の表示/非表示を切り替えるトグルボタン
 */
export const StatsToggle: React.FC = () => {
  const isStatsVisible = useStore(state => state.isStatsVisible);
  const toggleStatsVisible = useStore(state => state.toggleStatsVisible);

  return (
    <button
      className={`eg-button eg-button--toggle ${isStatsVisible ? 'eg-button--active' : ''}`}
      onClick={toggleStatsVisible}
      title={isStatsVisible ? '統計情報を非表示' : '統計情報を表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isStatsVisible ? (
          // 統計情報表示中アイコン（棒グラフ）
          <>
            <rect
              x="3"
              y="12"
              width="3"
              height="5"
              fill="currentColor"
            />
            <rect
              x="8"
              y="8"
              width="3"
              height="9"
              fill="currentColor"
            />
            <rect
              x="13"
              y="4"
              width="3"
              height="13"
              fill="currentColor"
            />
          </>
        ) : (
          // 統計情報非表示アイコン（棒グラフ + 斜線）
          <>
            <rect
              x="3"
              y="12"
              width="3"
              height="5"
              fill="currentColor"
              opacity="0.5"
            />
            <rect
              x="8"
              y="8"
              width="3"
              height="9"
              fill="currentColor"
              opacity="0.5"
            />
            <rect
              x="13"
              y="4"
              width="3"
              height="13"
              fill="currentColor"
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
        {isStatsVisible ? '統計情報' : '統計情報'}
      </span>
    </button>
  );
};
