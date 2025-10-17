import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * チケットIDの表示/非表示を切り替えるトグルボタン
 */
export const IssueIdToggle: React.FC = () => {
  const isIssueIdVisible = useStore(state => state.isIssueIdVisible);
  const toggleIssueIdVisible = useStore(state => state.toggleIssueIdVisible);

  return (
    <button
      className={`detail-pane-toggle ${isIssueIdVisible ? 'active' : ''}`}
      onClick={toggleIssueIdVisible}
      title={isIssueIdVisible ? 'チケットIDを非表示' : 'チケットIDを表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isIssueIdVisible ? (
          // チケットID表示中アイコン（#マーク）
          <>
            <text
              x="10"
              y="15"
              fontSize="16"
              fontWeight="bold"
              textAnchor="middle"
              fill="currentColor"
            >
              #
            </text>
          </>
        ) : (
          // チケットID非表示アイコン（#マーク + 斜線）
          <>
            <text
              x="10"
              y="15"
              fontSize="16"
              fontWeight="bold"
              textAnchor="middle"
              fill="currentColor"
              opacity="0.5"
            >
              #
            </text>
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
        {isIssueIdVisible ? 'チケットID' : 'チケットID'}
      </span>
    </button>
  );
};
