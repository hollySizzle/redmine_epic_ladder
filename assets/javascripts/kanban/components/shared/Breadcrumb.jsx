import React from 'react';
import './Breadcrumb.scss';

/**
 * Breadcrumb Component
 * パンくずリストナビゲーションコンポーネント
 *
 * @param {Object} props
 * @param {Array} props.items - パンくず項目配列
 * @param {string} props.separator - 区切り文字/アイコン
 * @param {'small'|'medium'|'large'} props.size - サイズ
 * @param {number} props.maxItems - 最大表示項目数
 * @param {boolean} props.showHome - ホームアイコン表示
 * @param {Function} props.onItemClick - 項目クリックハンドラー
 * @param {string} props.className - 追加CSSクラス
 */
const Breadcrumb = ({
  items = [],
  separator = 'icon-chevron-right',
  size = 'medium',
  maxItems = 0,
  showHome = false,
  onItemClick,
  className = '',
  ...props
}) => {
  // アイテムの正規化
  const normalizedItems = items.map((item, index) => {
    if (typeof item === 'string') {
      return {
        label: item,
        key: index,
        href: null,
        current: index === items.length - 1
      };
    }
    return {
      ...item,
      key: item.key || index,
      current: item.current !== undefined ? item.current : index === items.length - 1
    };
  });

  // 最大項目数の制限処理
  const displayItems = maxItems > 0 && normalizedItems.length > maxItems
    ? [
        ...normalizedItems.slice(0, 1), // 最初の項目
        { label: '...', key: 'ellipsis', isEllipsis: true },
        ...normalizedItems.slice(-(maxItems - 2)) // 最後の項目たち
      ]
    : normalizedItems;

  // ホーム項目の追加
  const finalItems = showHome
    ? [
        {
          label: 'Home',
          key: 'home',
          icon: 'icon-home',
          href: '/',
          current: false
        },
        ...displayItems
      ]
    : displayItems;

  // 項目クリック処理
  const handleItemClick = (event, item) => {
    if (item.current || item.isEllipsis || item.disabled) {
      event.preventDefault();
      return;
    }

    if (onItemClick) {
      event.preventDefault();
      onItemClick(item, event);
    }
  };

  // セパレーターの判定
  const isIconSeparator = separator.startsWith('icon-');

  const breadcrumbClassName = [
    'breadcrumb',
    `breadcrumb_${size}`,
    className
  ].filter(Boolean).join(' ');

  if (finalItems.length === 0) {
    return null;
  }

  return (
    <nav
      className={breadcrumbClassName}
      aria-label="Breadcrumb navigation"
      {...props}
    >
      <ol className="breadcrumb_list" role="list">
        {finalItems.map((item, index) => {
          const isLast = index === finalItems.length - 1;
          const isClickable = !item.current && !item.isEllipsis && !item.disabled && (item.href || onItemClick);

          const itemClassName = [
            'breadcrumb_item',
            item.current ? 'breadcrumb_item_current' : '',
            item.disabled ? 'breadcrumb_item_disabled' : '',
            isClickable ? 'breadcrumb_item_clickable' : ''
          ].filter(Boolean).join(' ');

          return (
            <li key={item.key} className={itemClassName}>
              {/* パンくず項目のリンクまたはテキスト */}
              {isClickable ? (
                <a
                  href={item.href || '#'}
                  className="breadcrumb_link"
                  onClick={(e) => handleItemClick(e, item)}
                  title={item.tooltip || item.label}
                  aria-current={item.current ? 'page' : undefined}
                >
                  {/* アイコン */}
                  {item.icon && (
                    <i className={`breadcrumb_icon ${item.icon}`} />
                  )}

                  {/* ラベル */}
                  <span className="breadcrumb_text">
                    {item.label}
                  </span>
                </a>
              ) : (
                <span
                  className="breadcrumb_text"
                  title={item.tooltip || item.label}
                  aria-current={item.current ? 'page' : undefined}
                >
                  {/* アイコン */}
                  {item.icon && (
                    <i className={`breadcrumb_icon ${item.icon}`} />
                  )}

                  {/* ラベル */}
                  {item.label}
                </span>
              )}

              {/* セパレーター */}
              {!isLast && (
                <span className="breadcrumb_separator" aria-hidden="true">
                  {isIconSeparator ? (
                    <i className={separator} />
                  ) : (
                    separator
                  )}
                </span>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
};

export default Breadcrumb;