import React from 'react';
import './ListTab.scss';

/**
 * ListTab コンポーネント
 *
 * Epic/Feature一覧を階層的に表示するタブコンテンツ
 */
export const ListTab: React.FC = () => {
  return (
    <div className="list-tab">
      <div className="list-tab__header">
        <h3 className="list-tab__title">Epic / Feature 一覧</h3>
      </div>

      <div className="list-tab__content">
        <div className="list-tab__placeholder">
          <p>🚧 一覧機能は実装予定です</p>
          <ul className="list-tab__features">
            <li>Epic階層ツリー表示</li>
            <li>Feature一覧表示</li>
            <li>クリックでグリッドにフォーカス</li>
            <li>折りたたみ/展開機能</li>
            <li>進捗バー表示</li>
          </ul>
        </div>
      </div>
    </div>
  );
};
