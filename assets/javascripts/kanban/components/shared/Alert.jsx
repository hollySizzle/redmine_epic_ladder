import React, { useState, useCallback } from 'react';
import Button from './Button';
import './Alert.scss';

/**
 * Alert Component
 * インライン形式でアラートメッセージを表示するコンポーネント
 *
 * @param {Object} props
 * @param {'info'|'success'|'warning'|'error'} props.variant - アラートの種類
 * @param {string} props.title - アラートタイトル
 * @param {string|React.ReactNode} props.message - アラートメッセージ
 * @param {boolean} props.dismissible - 閉じるボタンを表示するかどうか
 * @param {Function} props.onClose - 閉じる時のコールバック
 * @param {boolean} props.showIcon - アイコンを表示するかどうか
 * @param {string} props.customIcon - カスタムアイコンクラス
 * @param {Array} props.actions - アクションボタン配列
 * @param {string} props.className - 追加CSSクラス
 */
const Alert = ({
  variant = 'info',
  title,
  message,
  dismissible = false,
  onClose,
  showIcon = true,
  customIcon,
  actions = [],
  className = '',
  ...props
}) => {
  const [isVisible, setIsVisible] = useState(true);

  // 閉じる処理
  const handleClose = useCallback(() => {
    setIsVisible(false);
    setTimeout(() => {
      onClose?.();
    }, 300); // フェードアウト時間に合わせる
  }, [onClose]);

  // バリアント別のアイコン取得
  const getVariantIcon = () => {
    if (customIcon) return customIcon;
    if (!showIcon) return null;

    switch (variant) {
      case 'success':
        return 'icon-check-circle';
      case 'warning':
        return 'icon-alert-triangle';
      case 'error':
        return 'icon-x-circle';
      case 'info':
      default:
        return 'icon-info';
    }
  };

  if (!isVisible) return null;

  const alertIcon = getVariantIcon();

  return (
    <div
      className={`alert alert_${variant} ${className}`}
      role="alert"
      aria-live="polite"
      {...props}
    >
      {/* アイコン */}
      {alertIcon && (
        <div className="alert_icon">
          <i className={alertIcon} />
        </div>
      )}

      {/* メインコンテンツ */}
      <div className="alert_content">
        {/* タイトル */}
        {title && (
          <div className="alert_title">
            {title}
          </div>
        )}

        {/* メッセージ */}
        <div className="alert_message">
          {message}
        </div>

        {/* アクションボタン */}
        {actions.length > 0 && (
          <div className="alert_actions">
            {actions.map((action, index) => (
              <Button
                key={index}
                variant={action.variant || 'ghost'}
                size="small"
                onClick={action.onClick}
                className="alert_action_button"
              >
                {action.label}
              </Button>
            ))}
          </div>
        )}
      </div>

      {/* 閉じるボタン */}
      {dismissible && (
        <button
          className="alert_close"
          onClick={handleClose}
          type="button"
          aria-label="Close alert"
        >
          <i className="icon-x" />
        </button>
      )}
    </div>
  );
};

export default Alert;