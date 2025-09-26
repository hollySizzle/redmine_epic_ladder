import React, { useEffect, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';
import './Toast.scss';

/**
 * Toast Component
 * 通知メッセージを表示するコンポーネント
 *
 * @param {Object} props
 * @param {'success'|'error'|'warning'|'info'} props.type - 通知の種別
 * @param {string|React.ReactNode} props.message - 表示メッセージ
 * @param {number} props.duration - 表示時間（ミリ秒）
 * @param {boolean} props.autoClose - 自動消失設定
 * @param {Function} props.onClose - クローズコールバック
 * @param {Object} props.action - アクションボタン設定
 * @param {string} props.action.label - アクションボタンラベル
 * @param {Function} props.action.onClick - アクションボタンクリックハンドラー
 * @param {string} props.className - 追加CSSクラス
 */
const Toast = ({
  type = 'info',
  message,
  duration = 3000,
  autoClose = true,
  onClose,
  action,
  className = '',
  ...props
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [remainingTime, setRemainingTime] = useState(duration);

  // アニメーション開始
  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), 100);
    return () => clearTimeout(timer);
  }, []);

  // 自動閉じるタイマー
  useEffect(() => {
    if (!autoClose || isPaused) return;

    const interval = setInterval(() => {
      setRemainingTime((prev) => {
        const newTime = prev - 100;
        if (newTime <= 0) {
          handleClose();
          return 0;
        }
        return newTime;
      });
    }, 100);

    return () => clearInterval(interval);
  }, [autoClose, isPaused]);

  // クローズ処理
  const handleClose = useCallback(() => {
    setIsVisible(false);
    // アニメーション完了後にコールバック実行
    setTimeout(() => {
      onClose?.();
    }, 300);
  }, [onClose]);

  // マウスホバー時の一時停止
  const handleMouseEnter = useCallback(() => {
    if (autoClose) {
      setIsPaused(true);
    }
  }, [autoClose]);

  const handleMouseLeave = useCallback(() => {
    if (autoClose) {
      setIsPaused(false);
    }
  }, [autoClose]);

  // アクションボタンクリック
  const handleActionClick = useCallback(() => {
    action?.onClick?.();
    handleClose();
  }, [action, handleClose]);

  // 通知タイプ別のアイコン
  const getTypeIcon = () => {
    switch (type) {
      case 'success':
        return 'icon-check-circle';
      case 'error':
        return 'icon-x-circle';
      case 'warning':
        return 'icon-alert-triangle';
      case 'info':
      default:
        return 'icon-info-circle';
    }
  };

  // プログレスバーの進行率計算
  const progressPercent = autoClose ? (remainingTime / duration) * 100 : 100;

  const toastContent = (
    <div
      className={`toast toast_${type} ${isVisible ? 'toast_visible' : ''} ${className}`}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      role="alert"
      aria-live="polite"
      {...props}
    >
      {/* プログレスバー */}
      {autoClose && (
        <div className="toast_progress">
          <div
            className="toast_progress_bar"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      )}

      {/* メインコンテンツ */}
      <div className="toast_content">
        {/* アイコン */}
        <div className="toast_icon">
          <i className={getTypeIcon()} />
        </div>

        {/* メッセージ */}
        <div className="toast_message">
          {message}
        </div>

        {/* アクションボタン */}
        {action && (
          <button
            className="toast_action"
            onClick={handleActionClick}
            type="button"
          >
            {action.label}
          </button>
        )}

        {/* クローズボタン */}
        <button
          className="toast_close"
          onClick={handleClose}
          type="button"
          aria-label="Close notification"
        >
          <i className="icon-x" />
        </button>
      </div>
    </div>
  );

  // body直下にポータルで描画
  return createPortal(toastContent, document.body);
};

export default Toast;