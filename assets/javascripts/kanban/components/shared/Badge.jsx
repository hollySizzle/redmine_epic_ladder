import React from 'react';
import './Badge.scss';

/**
 * Badge Component
 * 数値や短いテキストを表示するバッジコンポーネント
 *
 * @param {Object} props
 * @param {string|number} props.content - バッジに表示する内容
 * @param {'primary'|'secondary'|'success'|'warning'|'error'|'info'} props.variant - バッジの種類
 * @param {'small'|'medium'|'large'} props.size - バッジサイズ
 * @param {'default'|'dot'|'pill'} props.shape - バッジの形状
 * @param {boolean} props.showZero - 0の場合も表示するかどうか
 * @param {number} props.max - 最大表示数値（超過時は+表示）
 * @param {boolean} props.pulse - パルスアニメーションするかどうか
 * @param {string} props.color - カスタム色
 * @param {string} props.className - 追加CSSクラス
 * @param {React.ReactNode} props.children - バッジを付ける対象要素
 */
const Badge = ({
  content,
  variant = 'primary',
  size = 'medium',
  shape = 'default',
  showZero = false,
  max = 99,
  pulse = false,
  color,
  className = '',
  children,
  ...props
}) => {
  // 数値の処理
  const getDisplayContent = () => {
    if (content === null || content === undefined) {
      return '';
    }

    // 0の場合の表示制御
    if (content === 0 && !showZero) {
      return null;
    }

    // 数値の場合の最大値制御
    if (typeof content === 'number') {
      if (content > max) {
        return `${max}+`;
      }
      return content.toString();
    }

    return content;
  };

  const displayContent = getDisplayContent();

  // バッジを表示しない場合
  if (displayContent === null) {
    return children || null;
  }

  // カスタム色のスタイル
  const customStyle = color ? {
    '--badge-color': color,
    '--badge-color-light': `${color}20`,
  } : {};

  const badgeClassName = [
    'badge',
    `badge_${variant}`,
    `badge_${size}`,
    `badge_${shape}`,
    pulse ? 'badge_pulse' : '',
    className
  ].filter(Boolean).join(' ');

  const badgeElement = (
    <span
      className={badgeClassName}
      style={customStyle}
      title={typeof content === 'number' && content > max ? `${content}` : undefined}
      {...props}
    >
      {shape === 'dot' ? null : displayContent}
    </span>
  );

  // 子要素がある場合は相対配置
  if (children) {
    return (
      <div className="badge_container">
        {children}
        {badgeElement}
      </div>
    );
  }

  // 単独で使用する場合
  return badgeElement;
};

export default Badge;