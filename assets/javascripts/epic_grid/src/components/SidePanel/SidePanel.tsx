import React from 'react';
import { useStore } from '../../store/useStore';
import { TabBar, Tab, TabId } from './TabBar';
import { SearchTab } from './SearchTab';
import { ListTab } from './ListTab';
import { AboutTab } from './AboutTab';

const TABS: Tab[] = [
  { id: 'search', label: '検索', icon: '🔍' },
  { id: 'list', label: '一覧', icon: '📊' },
  { id: 'about', label: 'About', icon: 'ℹ️' }
];

/**
 * SidePanel コンポーネント
 *
 * 左側に表示されるサイドメニュー
 * タブ切り替えで検索、Epic/Feature一覧、Aboutを表示
 */
export const SidePanel: React.FC = () => {
  const toggleSideMenu = useStore(state => state.toggleSideMenu);
  const activeSideTab = useStore(state => state.activeSideTab);
  const setActiveSideTab = useStore(state => state.setActiveSideTab);

  const handleTabChange = (tabId: TabId) => {
    setActiveSideTab(tabId);
  };

  const renderTabContent = () => {
    switch (activeSideTab) {
      case 'search':
        return <SearchTab />;
      case 'list':
        return <ListTab />;
      case 'about':
        return <AboutTab />;
      default:
        return <ListTab />;
    }
  };

  return (
    <div className="side-panel">
      <div className="side-panel__header">
        <h2 className="side-panel__title">メニュー</h2>
        <button
          className="eg-button eg-button--ghost side-panel__close-button"
          onClick={toggleSideMenu}
          title="サイドメニューを閉じる"
          aria-label="サイドメニューを閉じる"
        >
          ✕
        </button>
      </div>

      <TabBar
        tabs={TABS}
        activeTab={activeSideTab}
        onTabChange={handleTabChange}
      />

      <div className="side-panel__content">
        {renderTabContent()}
      </div>
    </div>
  );
};
