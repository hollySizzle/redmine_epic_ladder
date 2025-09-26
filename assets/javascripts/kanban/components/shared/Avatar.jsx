import React, { useState, useCallback } from 'react';
import Badge from './Badge';
import './Avatar.scss';

/**
 * Avatar Component
 * ユーザーアバター表示コンポーネント
 *
 * @param {Object} props
 * @param {string} props.src - 画像URL
 * @param {string} props.alt - 画像のalt属性
 * @param {string} props.name - ユーザー名（イニシャル生成に使用）
 * @param {'small'|'medium'|'large'|'xlarge'} props.size - アバターサイズ
 * @param {'circle'|'square'|'rounded'} props.shape - アバターの形状
 * @param {string} props.fallbackIcon - フォールバックアイコンクラス
 * @param {string} props.backgroundColor - 背景色（イニシャル表示時）
 * @param {string} props.textColor - テキスト色（イニシャル表示時）
 * @param {boolean} props.showBadge - バッジ表示するかどうか
 * @param {Object} props.badge - バッジの設定
 * @param {boolean} props.clickable - クリック可能かどうか
 * @param {Function} props.onClick - クリックハンドラー
 * @param {string} props.className - 追加CSSクラス
 */
const Avatar = ({
  src,
  alt,
  name = '',
  size = 'medium',
  shape = 'circle',
  fallbackIcon = 'icon-user',
  backgroundColor,
  textColor,
  showBadge = false,
  badge = {},
  clickable = false,
  onClick,
  className = '',
  ...props
}) => {
  const [imageError, setImageError] = useState(false);

  // 画像読み込みエラー処理
  const handleImageError = useCallback(() => {
    setImageError(true);
  }, []);

  // イニシャル生成
  const getInitials = useCallback(() => {
    if (!name) return '';

    const words = name.trim().split(/\s+/);
    if (words.length === 1) {
      return words[0].charAt(0).toUpperCase();
    }

    return words
      .slice(0, 2)
      .map(word => word.charAt(0).toUpperCase())
      .join('');
  }, [name]);

  // 背景色生成（名前ベース）
  const getBackgroundColor = useCallback(() => {
    if (backgroundColor) return backgroundColor;

    if (!name) return '#6b7280';

    // 名前からハッシュ値を生成して色を決定
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }

    const colors = [
      '#3b82f6', '#ef4444', '#10b981', '#f59e0b',
      '#8b5cf6', '#06b6d4', '#84cc16', '#f97316',
      '#ec4899', '#6366f1', '#14b8a6', '#eab308'
    ];

    return colors[Math.abs(hash) % colors.length];
  }, [name, backgroundColor]);

  // クリックハンドラー
  const handleClick = useCallback((event) => {
    if (clickable && onClick) {
      onClick(event);
    }
  }, [clickable, onClick]);

  // キーボードハンドラー
  const handleKeyDown = useCallback((event) => {
    if (clickable && (event.key === 'Enter' || event.key === ' ')) {
      event.preventDefault();
      handleClick(event);
    }
  }, [clickable, handleClick]);

  const initials = getInitials();
  const bgColor = getBackgroundColor();
  const displayTextColor = textColor || (bgColor ? '#ffffff' : '#374151');

  const avatarClassName = [
    'avatar',
    `avatar_${size}`,
    `avatar_${shape}`,
    clickable ? 'avatar_clickable' : '',
    className
  ].filter(Boolean).join(' ');

  // アバター内容の決定
  const renderAvatarContent = () => {
    // 画像が正常に表示できる場合
    if (src && !imageError) {
      return (
        <img
          src={src}
          alt={alt || name || 'Avatar'}
          className="avatar_image"
          onError={handleImageError}
        />
      );
    }

    // イニシャルがある場合
    if (initials) {
      return (
        <span
          className="avatar_initials"
          style={{ color: displayTextColor }}
        >
          {initials}
        </span>
      );
    }

    // フォールバックアイコン
    return (
      <i
        className={`avatar_icon ${fallbackIcon}`}
        style={{ color: displayTextColor }}
      />
    );
  };

  const avatarStyle = {
    backgroundColor: (src && !imageError) ? 'transparent' : bgColor,
  };

  const AvatarComponent = clickable ? 'button' : 'div';

  const avatarElement = (
    <AvatarComponent
      className={avatarClassName}
      style={avatarStyle}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      tabIndex={clickable ? 0 : -1}
      role={clickable ? 'button' : undefined}
      aria-label={clickable ? `Avatar for ${name || 'user'}` : undefined}
      title={name || alt}
      {...props}
    >
      {renderAvatarContent()}
    </AvatarComponent>
  );

  // バッジ付きの場合
  if (showBadge && Object.keys(badge).length > 0) {
    return (
      <Badge {...badge}>
        {avatarElement}
      </Badge>
    );
  }

  return avatarElement;
};

export default Avatar;