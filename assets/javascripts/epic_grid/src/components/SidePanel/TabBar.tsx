import React from 'react';

export type TabId = 'search' | 'list' | 'about';

export interface Tab {
  id: TabId;
  label: string;
  icon: string;
}

interface TabBarProps {
  tabs: Tab[];
  activeTab: TabId;
  onTabChange: (tabId: TabId) => void;
  onClose?: () => void;
}

/**
 * TabBar コンポーネント
 *
 * シンプルなボタンタブUI
 * オプションでクローズボタンを右端に配置可能
 */
export const TabBar: React.FC<TabBarProps> = ({ tabs, activeTab, onTabChange, onClose }) => {
  return (
    <div className="tab-bar">
      <div className="tab-bar__tabs">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            className={`tab-bar__tab ${activeTab === tab.id ? 'tab-bar__tab--active' : ''}`}
            onClick={() => onTabChange(tab.id)}
            aria-selected={activeTab === tab.id}
            role="tab"
          >
            <span className="tab-bar__icon">{tab.icon}</span>
            <span className="tab-bar__label">{tab.label}</span>
          </button>
        ))}
      </div>
      {onClose && (
        <button
          className="tab-bar__close-button"
          onClick={onClose}
          title="サイドメニューを閉じる"
          aria-label="サイドメニューを閉じる"
        >
          ✕
        </button>
      )}
    </div>
  );
};
