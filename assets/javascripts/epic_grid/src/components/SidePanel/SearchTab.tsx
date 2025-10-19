import React from 'react';
import './SearchTab.scss';

/**
 * SearchTab コンポーネント
 *
 * 検索機能とその結果を表示するタブコンテンツ
 */
export const SearchTab: React.FC = () => {
  return (
    <div className="search-tab">
      <div className="search-tab__input-area">
        <input
          type="text"
          className="search-tab__input"
          placeholder="Epic/Feature/ストーリーを検索..."
        />
        <button className="search-tab__button">
          🔍 検索
        </button>
      </div>

      <div className="search-tab__results">
        <div className="search-tab__placeholder">
          <p>🚧 検索機能は実装予定です</p>
          <ul className="search-tab__features">
            <li>全文検索</li>
            <li>タグ検索</li>
            <li>担当者検索</li>
            <li>ステータス絞り込み</li>
          </ul>
        </div>
      </div>
    </div>
  );
};
