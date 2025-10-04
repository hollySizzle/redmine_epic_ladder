import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * Issue詳細ペインの表示/非表示を切り替えるトグルボタン
 */
export const DetailPaneToggle: React.FC = () => {
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);

  return (
    <button
      className={`detail-pane-toggle ${isDetailPaneVisible ? 'active' : ''}`}
      onClick={toggleDetailPane}
      title={isDetailPaneVisible ? 'Issue詳細を非表示' : 'Issue詳細を表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isDetailPaneVisible ? (
          // 目のアイコン（表示中）
          <>
            <path
              d="M10 4C5.5 4 2 10 2 10s3.5 6 8 6 8-6 8-6-3.5-6-8-6z"
              stroke="currentColor"
              strokeWidth="1.5"
              fill="none"
            />
            <circle cx="10" cy="10" r="2.5" stroke="currentColor" strokeWidth="1.5" fill="none" />
          </>
        ) : (
          // 目を閉じたアイコン（非表示中）
          <>
            <path
              d="M10 4C5.5 4 2 10 2 10s3.5 6 8 6 8-6 8-6-3.5-6-8-6z"
              stroke="currentColor"
              strokeWidth="1.5"
              fill="none"
              opacity="0.5"
            />
            <line x1="3" y1="3" x2="17" y2="17" stroke="currentColor" strokeWidth="1.5" />
          </>
        )}
      </svg>
      <span className="detail-pane-toggle__label">
        {isDetailPaneVisible ? 'Issue詳細を非表示' : 'Issue詳細を表示'}
      </span>
    </button>
  );
};
