import React, { useState, useCallback, useRef, useEffect } from 'react';
import Badge from './Badge';
import './Tabs.scss';

/**
 * Tabs Component
 * タブナビゲーションコンポーネント
 *
 * @param {Object} props
 * @param {Array} props.tabs - タブ配列
 * @param {string|number} props.activeTab - アクティブなタブのキー
 * @param {Function} props.onTabChange - タブ変更ハンドラー
 * @param {'default'|'pills'|'underline'|'cards'} props.variant - タブのスタイル
 * @param {'small'|'medium'|'large'} props.size - タブサイズ
 * @param {'horizontal'|'vertical'} props.orientation - タブの方向
 * @param {boolean} props.scrollable - スクロール可能かどうか
 * @param {boolean} props.lazy - 遅延読み込みかどうか
 * @param {string} props.className - 追加CSSクラス
 */
const Tabs = ({
  tabs = [],
  activeTab,
  onTabChange,
  variant = 'default',
  size = 'medium',
  orientation = 'horizontal',
  scrollable = false,
  lazy = false,
  className = '',
  ...props
}) => {
  const [activeTabState, setActiveTabState] = useState(activeTab || tabs[0]?.key);
  const [visitedTabs, setVisitedTabs] = useState(new Set([activeTab || tabs[0]?.key]));
  const tabListRef = useRef(null);
  const tabRefs = useRef({});

  // アクティブタブの同期
  useEffect(() => {
    if (activeTab !== undefined) {
      setActiveTabState(activeTab);
    }
  }, [activeTab]);

  // タブ変更処理
  const handleTabChange = useCallback((tabKey, tabData) => {
    setActiveTabState(tabKey);
    setVisitedTabs(prev => new Set([...prev, tabKey]));
    onTabChange?.(tabKey, tabData);
  }, [onTabChange]);

  // キーボードナビゲーション
  const handleKeyDown = useCallback((event, tabKey) => {
    const tabKeys = tabs.map(tab => tab.key);
    const currentIndex = tabKeys.indexOf(tabKey);

    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault();
        if (orientation === 'horizontal' && event.key === 'ArrowUp') break;
        if (orientation === 'vertical' && event.key === 'ArrowLeft') break;
        const prevIndex = currentIndex > 0 ? currentIndex - 1 : tabKeys.length - 1;
        const prevTab = tabs[prevIndex];
        if (!prevTab.disabled) {
          handleTabChange(prevTab.key, prevTab);
          tabRefs.current[prevTab.key]?.focus();
        }
        break;

      case 'ArrowRight':
      case 'ArrowDown':
        event.preventDefault();
        if (orientation === 'horizontal' && event.key === 'ArrowDown') break;
        if (orientation === 'vertical' && event.key === 'ArrowRight') break;
        const nextIndex = currentIndex < tabKeys.length - 1 ? currentIndex + 1 : 0;
        const nextTab = tabs[nextIndex];
        if (!nextTab.disabled) {
          handleTabChange(nextTab.key, nextTab);
          tabRefs.current[nextTab.key]?.focus();
        }
        break;

      case 'Home':
        event.preventDefault();
        const firstTab = tabs.find(tab => !tab.disabled);
        if (firstTab) {
          handleTabChange(firstTab.key, firstTab);
          tabRefs.current[firstTab.key]?.focus();
        }
        break;

      case 'End':
        event.preventDefault();
        const lastTab = tabs.slice().reverse().find(tab => !tab.disabled);
        if (lastTab) {
          handleTabChange(lastTab.key, lastTab);
          tabRefs.current[lastTab.key]?.focus();
        }
        break;

      default:
        break;
    }
  }, [tabs, orientation, handleTabChange]);

  // アクティブなタブデータ取得
  const activeTabData = tabs.find(tab => tab.key === activeTabState);

  const containerClassName = [
    'tabs_container',
    `tabs_container_${variant}`,
    `tabs_container_${size}`,
    `tabs_container_${orientation}`,
    scrollable ? 'tabs_container_scrollable' : '',
    className
  ].filter(Boolean).join(' ');

  return (
    <div className={containerClassName} {...props}>
      {/* タブリスト */}
      <div
        ref={tabListRef}
        className="tabs_list"
        role="tablist"
        aria-orientation={orientation}
      >
        {tabs.map((tab) => {
          const isActive = tab.key === activeTabState;
          const isDisabled = tab.disabled;

          const tabClassName = [
            'tabs_tab',
            isActive ? 'tabs_tab_active' : '',
            isDisabled ? 'tabs_tab_disabled' : ''
          ].filter(Boolean).join(' ');

          return (
            <button
              key={tab.key}
              ref={(el) => { tabRefs.current[tab.key] = el; }}
              className={tabClassName}
              role="tab"
              aria-selected={isActive}
              aria-controls={`tabpanel-${tab.key}`}
              aria-disabled={isDisabled}
              tabIndex={isActive && !isDisabled ? 0 : -1}
              disabled={isDisabled}
              onClick={() => !isDisabled && handleTabChange(tab.key, tab)}
              onKeyDown={(e) => handleKeyDown(e, tab.key)}
              title={tab.tooltip}
            >
              {/* アイコン */}
              {tab.icon && (
                <i className={`tabs_icon ${tab.icon}`} />
              )}

              {/* ラベル */}
              <span className="tabs_label">{tab.label}</span>

              {/* バッジ */}
              {tab.badge && (
                <Badge
                  content={tab.badge.content}
                  variant={tab.badge.variant || 'primary'}
                  size="small"
                  className="tabs_badge"
                />
              )}

              {/* クローズボタン（閉じられるタブの場合） */}
              {tab.closable && (
                <button
                  className="tabs_close"
                  onClick={(e) => {
                    e.stopPropagation();
                    tab.onClose?.(tab.key);
                  }}
                  tabIndex={-1}
                  aria-label={`Close ${tab.label}`}
                >
                  <i className="icon-x" />
                </button>
              )}
            </button>
          );
        })}
      </div>

      {/* タブパネル */}
      <div className="tabs_panels">
        {tabs.map((tab) => {
          const isActive = tab.key === activeTabState;
          const shouldRender = !lazy || visitedTabs.has(tab.key);

          return (
            <div
              key={tab.key}
              id={`tabpanel-${tab.key}`}
              className={[
                'tabs_panel',
                isActive ? 'tabs_panel_active' : 'tabs_panel_hidden'
              ].filter(Boolean).join(' ')}
              role="tabpanel"
              aria-labelledby={`tab-${tab.key}`}
              hidden={!isActive}
              tabIndex={isActive ? 0 : -1}
            >
              {shouldRender && (
                <>
                  {/* パネルの内容 */}
                  {typeof tab.content === 'function'
                    ? tab.content({ isActive, tab })
                    : tab.content
                  }
                </>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Tabs;