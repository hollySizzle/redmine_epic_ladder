import React from 'react';
import { useStore } from '../../store/useStore';

/**
 * SearchBar コンポーネント
 *
 * サイドメニューの検索タブを開くシンプルなボタン
 * クリックするとサイドメニューが開き、SearchTabが表示され、検索入力にフォーカスする
 */
export const SearchBar: React.FC = () => {
  const isSideMenuVisible = useStore(state => state.isSideMenuVisible);
  const setActiveSideTab = useStore(state => state.setActiveSideTab);
  const toggleSideMenu = useStore(state => state.toggleSideMenu);

  const handleSearchButtonClick = () => {
    // サイドメニューが閉じている場合は開く
    if (!isSideMenuVisible) {
      toggleSideMenu();
    }

    // SearchTabをアクティブにする
    setActiveSideTab('search');
  };

  return (
    <button
      onClick={handleSearchButtonClick}
      className="eg-button eg-button--lg"
      title="検索タブを開く"
    >
      🔍 検索
    </button>
  );
};
