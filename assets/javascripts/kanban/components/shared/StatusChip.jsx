import React, { useMemo } from 'react';
import './StatusChip.scss';

/**
 * Status Chip Component
 * Issue/タスクのステータス表示を統一するコンポーネント
 *
 * @param {Object} props
 * @param {Object|string} props.status - ステータス情報（オブジェクトまたは文字列）
 * @param {string} props.status.name - ステータス名
 * @param {string} props.status.color - ステータス色
 * @param {boolean} props.status.is_closed - 終了状態かどうか
 * @param {'small'|'medium'} props.size - サイズ指定
 * @param {boolean} props.clickable - クリック可能かどうか
 * @param {Function} props.onClick - クリックハンドラー
 * @param {boolean} props.showIcon - アイコン表示するかどうか
 * @param {string} props.customIcon - カスタムアイコンクラス
 * @param {string} props.className - 追加CSSクラス
 */
const StatusChip = ({
  status,
  size = 'medium',
  clickable = false,
  onClick,
  showIcon = true,
  customIcon,
  className = '',
  ...props
}) => {
  // ステータス情報の正規化
  const normalizedStatus = useMemo(() => {
    if (typeof status === 'string') {
      return {
        name: status,
        color: null,
        is_closed: false
      };
    }

    return {
      name: status?.name || 'Unknown',
      color: status?.color || null,
      is_closed: status?.is_closed || false,
      ...status
    };
  }, [status]);

  // Redmineデフォルトステータスカラーマッピング
  const getStatusColor = useMemo(() => {
    if (normalizedStatus.color) {
      return normalizedStatus.color.startsWith('#')
        ? normalizedStatus.color
        : `#${normalizedStatus.color}`;
    }

    // Redmineの典型的なステータスに対するデフォルト色
    const statusName = normalizedStatus.name.toLowerCase();

    if (statusName.includes('new') || statusName.includes('新規')) {
      return '#3b82f6'; // blue
    }
    if (statusName.includes('progress') || statusName.includes('進行') || statusName.includes('対応中')) {
      return '#f59e0b'; // amber
    }
    if (statusName.includes('review') || statusName.includes('レビュー') || statusName.includes('確認')) {
      return '#8b5cf6'; // violet
    }
    if (statusName.includes('resolved') || statusName.includes('解決') || statusName.includes('完了')) {
      return '#10b981'; // emerald
    }
    if (statusName.includes('closed') || statusName.includes('終了') || statusName.includes('クローズ')) {
      return '#6b7280'; // gray
    }
    if (statusName.includes('rejected') || statusName.includes('却下') || statusName.includes('無効')) {
      return '#ef4444'; // red
    }

    return '#6b7280'; // デフォルトグレー
  }, [normalizedStatus]);

  // アイコンの決定
  const getStatusIcon = useMemo(() => {
    if (customIcon) return customIcon;
    if (!showIcon) return null;

    if (normalizedStatus.is_closed) {
      return 'icon-check-circle';
    }

    const statusName = normalizedStatus.name.toLowerCase();

    if (statusName.includes('new') || statusName.includes('新規')) {
      return 'icon-plus-circle';
    }
    if (statusName.includes('progress') || statusName.includes('進行') || statusName.includes('対応中')) {
      return 'icon-play-circle';
    }
    if (statusName.includes('review') || statusName.includes('レビュー') || statusName.includes('確認')) {
      return 'icon-eye';
    }
    if (statusName.includes('resolved') || statusName.includes('解決') || statusName.includes('完了')) {
      return 'icon-check-circle';
    }
    if (statusName.includes('rejected') || statusName.includes('却下') || statusName.includes('無効')) {
      return 'icon-x-circle';
    }

    return 'icon-circle';
  }, [normalizedStatus, customIcon, showIcon]);

  // クリックハンドラー
  const handleClick = (event) => {
    if (!clickable) return;

    onClick?.(normalizedStatus, event);
  };

  // キーボードハンドラー
  const handleKeyDown = (event) => {
    if (!clickable) return;

    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      handleClick(event);
    }
  };

  // CSS変数でカスタム色を設定
  const customStyle = {
    '--status-color': getStatusColor,
    '--status-color-light': `${getStatusColor}20`,
    '--status-color-dark': `${getStatusColor}cc`,
  };

  const chipClassName = [
    'status_chip',
    `status_chip_${size}`,
    normalizedStatus.is_closed ? 'status_chip_closed' : 'status_chip_open',
    clickable ? 'status_chip_clickable' : '',
    className
  ].filter(Boolean).join(' ');

  const ChipComponent = clickable ? 'button' : 'span';

  return (
    <ChipComponent
      className={chipClassName}
      style={customStyle}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      tabIndex={clickable ? 0 : -1}
      role={clickable ? 'button' : 'status'}
      aria-label={`Status: ${normalizedStatus.name}${normalizedStatus.is_closed ? ' (Closed)' : ''}`}
      title={`${normalizedStatus.name}${normalizedStatus.is_closed ? ' (Closed)' : ''}`}
      {...props}
    >
      {getStatusIcon && (
        <i className={`status_chip_icon ${getStatusIcon}`} />
      )}

      <span className="status_chip_text">
        {normalizedStatus.name}
      </span>

      {normalizedStatus.is_closed && (
        <span className="status_chip_badge" aria-hidden="true">
          ✓
        </span>
      )}
    </ChipComponent>
  );
};

export default StatusChip;