import React from 'react';
import { useStore } from '../../store/useStore';
import './SidePanel.scss';

/**
 * SidePanel コンポーネント
 *
 * 左側に表示されるサイドメニュー
 * 検索結果一覧、Epic一覧、Feature一覧などを表示する拡張可能な基盤コンポーネント
 */
export const SidePanel: React.FC = () => {
  const toggleSideMenu = useStore(state => state.toggleSideMenu);

  return (
    <div className="side-panel">
      <div className="side-panel__header">
        <h2 className="side-panel__title">メニュー</h2>
        <button
          className="side-panel__close-button"
          onClick={toggleSideMenu}
          title="サイドメニューを閉じる"
          aria-label="サイドメニューを閉じる"
        >
          ✕
        </button>
      </div>

      <div className="side-panel__content">
        <div className="side-panel__placeholder">
          <p>🚧 実装予定</p>
          <ul>
            <li>🔍 検索結果一覧</li>
            <li>📊 Epic一覧</li>
            <li>🎯 Feature一覧</li>
          </ul>
        </div>
      </div>

      <div className="side-panel__footer">
        <button
          className="side-panel__toggle-button"
          onClick={toggleSideMenu}
        >
          ← 閉じる
        </button>
      </div>
    </div>
  );
};
