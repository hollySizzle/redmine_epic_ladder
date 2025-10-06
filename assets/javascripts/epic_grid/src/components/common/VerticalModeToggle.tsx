import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * Epic/Featureセルの縦書き/横書きを切り替えるトグルボタン
 */
export const VerticalModeToggle: React.FC = () => {
  const isVerticalMode = useStore(state => state.isVerticalMode);
  const toggleVerticalMode = useStore(state => state.toggleVerticalMode);

  return (
    <button
      className={`detail-pane-toggle ${isVerticalMode ? 'active' : ''}`}
      onClick={toggleVerticalMode}
      title={isVerticalMode ? '横書きに切り替え' : '縦書きに切り替え'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        {isVerticalMode ? (
          // 縦書きアイコン（縦書き中）
          <>
            <path
              d="M10 3 L10 17"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <path
              d="M13 3 L13 17"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <path
              d="M7 3 L7 17"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </>
        ) : (
          // 横書きアイコン（横書き中）
          <>
            <path
              d="M3 7 L17 7"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <path
              d="M3 10 L17 10"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <path
              d="M3 13 L17 13"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </>
        )}
      </svg>
      <span className="detail-pane-toggle__label">
        {isVerticalMode ? '横書き' : '縦書き'}
      </span>
    </button>
  );
};
