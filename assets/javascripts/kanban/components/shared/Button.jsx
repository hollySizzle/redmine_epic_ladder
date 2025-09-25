import React, { forwardRef } from 'react';
import './Button.scss';

/**
 * Button Component
 * 汎用ボタンコンポーネント
 *
 * @param {Object} props
 * @param {'primary'|'secondary'|'success'|'warning'|'danger'|'ghost'} props.variant - ボタンの種類
 * @param {'small'|'medium'|'large'} props.size - ボタンサイズ
 * @param {boolean} props.disabled - 無効化状態
 * @param {boolean} props.loading - ローディング状態
 * @param {string} props.icon - アイコンクラス名
 * @param {'button'|'submit'|'reset'} props.type - ボタンタイプ
 * @param {Function} props.onClick - クリックハンドラー
 * @param {React.ReactNode} props.children - ボタン内容
 * @param {string} props.className - 追加CSSクラス
 */
const Button = forwardRef(({
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  icon,
  type = 'button',
  onClick,
  children,
  className = '',
  ...props
}, ref) => {
  const handleClick = (event) => {
    if (disabled || loading) {
      event.preventDefault();
      return;
    }
    onClick?.(event);
  };

  const buttonClassName = [
    'btn',
    `btn_${variant}`,
    `btn_${size}`,
    icon && !children ? 'btn_icon_only' : '',
    loading ? 'btn_loading' : '',
    disabled ? 'btn_disabled' : '',
    className
  ].filter(Boolean).join(' ');

  return (
    <button
      ref={ref}
      type={type}
      className={buttonClassName}
      disabled={disabled || loading}
      onClick={handleClick}
      {...props}
    >
      {loading ? (
        <>
          <i className="icon-spinner btn_loading_icon" />
          {children && <span className="btn_loading_text">Loading...</span>}
        </>
      ) : (
        <>
          {icon && (
            <i className={`${icon} btn_icon`} />
          )}
          {children && (
            <span className="btn_text">{children}</span>
          )}
        </>
      )}
    </button>
  );
});

Button.displayName = 'Button';

export default Button;