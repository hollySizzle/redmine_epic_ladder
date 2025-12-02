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
      <TabBar
        tabs={TABS}
        activeTab={activeSideTab}
        onTabChange={handleTabChange}
        onClose={toggleSideMenu}
      />

      <div className="side-panel__content">
        {renderTabContent()}
      </div>
    </div>
  );
};
