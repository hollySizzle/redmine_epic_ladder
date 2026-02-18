import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * 担当者不在ハイライト表示切替ボタン
 */
export const UnassignedHighlightToggle: React.FC = () => {
  const isUnassignedHighlightVisible = useStore(state => state.isUnassignedHighlightVisible);
  const toggleUnassignedHighlightVisible = useStore(state => state.toggleUnassignedHighlightVisible);

  return (
    <button
      className={`eg-button eg-button--toggle ${isUnassignedHighlightVisible ? 'eg-button--active' : ''}`}
      onClick={toggleUnassignedHighlightVisible}
      title={isUnassignedHighlightVisible ? '担当者不在ハイライトを非表示' : '担当者不在ハイライトを表示'}
    >
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <circle cx="10" cy="10" r="7" stroke="currentColor" strokeWidth="2" fill="none" />
        {isUnassignedHighlightVisible && (
          <path d="M7 10 L13 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        )}
        {!isUnassignedHighlightVisible && (
          <>
            <path d="M7 10 L13 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            <path d="M10 7 L10 13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </>
        )}
      </svg>
      <span>{isUnassignedHighlightVisible ? '担当不在🟠' : '担当不在'}</span>
    </button>
  );
};
