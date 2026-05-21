import React, { useState } from 'react';
import { GanttSettings } from '../utils/cookieUtils';
import './ViewModeToggle.scss';

/**
 * ビューモード切り替えコンポーネント
 * モーダル表示と分割表示を切り替える（ページリロードを伴う）
 */
const ViewModeToggle = ({ currentMode, onModeChange }) => {
  const [isLoading, setIsLoading] = useState(false);
  
  const handleToggle = () => {
    const newMode = currentMode === 'modal' ? 'split' : 'modal';
    setIsLoading(true);
    GanttSettings.setViewMode(newMode);
    onModeChange(newMode);
  };

  return (
    <div className="view-mode-toggle">
      <button
        className={`view-mode-toggle__button ${currentMode === 'modal' ? 'view-mode-toggle__button--modal' : 'view-mode-toggle__button--split'} ${isLoading ? 'view-mode-toggle__button--loading' : ''}`}
        onClick={handleToggle}
        disabled={isLoading}
        title={currentMode === 'modal' ? '分割表示に切り替え（ページが再読み込みされます）' : 'モーダル表示に切り替え（ページが再読み込みされます）'}
      >
        <span className="view-mode-toggle__icon">
          {currentMode === 'modal' ? (
            // 分割アイコン
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="1" y="1" width="8" height="18" stroke="currentColor" strokeWidth="2" fill="none"/>
              <rect x="11" y="1" width="8" height="18" stroke="currentColor" strokeWidth="2" fill="none"/>
            </svg>
          ) : (
            // モーダルアイコン
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="1" y="1" width="18" height="18" stroke="currentColor" strokeWidth="2" fill="none"/>
              <rect x="4" y="4" width="12" height="12" stroke="currentColor" strokeWidth="1" fill="none"/>
            </svg>
          )}
        </span>
        <span className="view-mode-toggle__label">
          {isLoading ? '切り替え中...' : (currentMode === 'modal' ? '分割表示' : 'モーダル表示')}
        </span>
      </button>
    </div>
  );
};

export default ViewModeToggle;