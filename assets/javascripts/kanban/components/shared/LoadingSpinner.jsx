import React from 'react';
import './LoadingSpinner.scss';

/**
 * Loading Spinner Component
 * ローディング状態を表示するスピナーコンポーネント
 *
 * @param {Object} props
 * @param {'small'|'medium'|'large'} props.size - スピナーサイズ
 * @param {string} props.color - スピナー色（CSS color値）
 * @param {boolean} props.overlay - オーバーレイ表示するかどうか
 * @param {string|React.ReactNode} props.message - ローディングメッセージ
 * @param {boolean} props.fullscreen - 全画面オーバーレイかどうか
 * @param {'spinner'|'dots'|'pulse'} props.variant - スピナーの種類
 * @param {string} props.className - 追加CSSクラス
 */
const LoadingSpinner = ({
  size = 'medium',
  color,
  overlay = false,
  message,
  fullscreen = false,
  variant = 'spinner',
  className = '',
  ...props
}) => {
  // スピナーのスタイル設定
  const spinnerStyle = {
    ...(color && { '--spinner-color': color }),
  };

  // スピナー要素の描画
  const renderSpinner = () => {
    switch (variant) {
      case 'dots':
        return (
          <div className={`loading_dots loading_dots_${size}`}>
            <div className="loading_dot" />
            <div className="loading_dot" />
            <div className="loading_dot" />
          </div>
        );

      case 'pulse':
        return (
          <div className={`loading_pulse loading_pulse_${size}`}>
            <div className="loading_pulse_circle" />
          </div>
        );

      case 'spinner':
      default:
        return (
          <div className={`loading_spinner loading_spinner_${size}`}>
            <div className="loading_spinner_circle">
              <div className="loading_spinner_path" />
            </div>
          </div>
        );
    }
  };

  // メッセージ付きローディング
  const renderLoadingContent = () => (
    <div className="loading_content">
      {renderSpinner()}
      {message && (
        <div className="loading_message">
          {message}
        </div>
      )}
    </div>
  );

  // オーバーレイ表示の場合
  if (overlay || fullscreen) {
    return (
      <div
        className={`
          loading_overlay
          ${fullscreen ? 'loading_overlay_fullscreen' : 'loading_overlay_relative'}
          ${className}
        `}
        style={spinnerStyle}
        role="status"
        aria-label={typeof message === 'string' ? message : 'Loading'}
        {...props}
      >
        {renderLoadingContent()}
      </div>
    );
  }

  // インライン表示の場合
  return (
    <div
      className={`loading_inline loading_inline_${size} ${className}`}
      style={spinnerStyle}
      role="status"
      aria-label={typeof message === 'string' ? message : 'Loading'}
      {...props}
    >
      {renderLoadingContent()}
    </div>
  );
};

export default LoadingSpinner;