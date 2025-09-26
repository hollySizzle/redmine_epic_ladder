import React from 'react';
import './ProgressBar.scss';

/**
 * ProgressBar Component
 * 進捗バーコンポーネント
 *
 * @param {Object} props
 * @param {number} props.value - 現在の値
 * @param {number} props.max - 最大値
 * @param {number} props.min - 最小値
 * @param {string} props.label - ラベルテキスト
 * @param {boolean} props.showValue - 値の表示
 * @param {boolean} props.showPercentage - パーセンテージ表示
 * @param {'linear'|'circular'} props.variant - 表示バリアント
 * @param {'determinate'|'indeterminate'} props.mode - 進捗モード
 * @param {'primary'|'success'|'warning'|'danger'} props.color - カラーテーマ
 * @param {'small'|'medium'|'large'} props.size - サイズ
 * @param {boolean} props.striped - ストライプパターン
 * @param {boolean} props.animated - アニメーション有効
 * @param {string} props.className - 追加CSSクラス
 */
const ProgressBar = ({
  value = 0,
  max = 100,
  min = 0,
  label = '',
  showValue = false,
  showPercentage = false,
  variant = 'linear',
  mode = 'determinate',
  color = 'primary',
  size = 'medium',
  striped = false,
  animated = false,
  className = '',
  ...props
}) => {
  // 値の正規化
  const normalizedValue = Math.max(min, Math.min(max, value));
  const percentage = max > min ? ((normalizedValue - min) / (max - min)) * 100 : 0;

  // 円形プログレスバーの場合
  if (variant === 'circular') {
    const radius = size === 'small' ? 20 : size === 'large' ? 32 : 24;
    const strokeWidth = size === 'small' ? 2 : size === 'large' ? 4 : 3;
    const normalizedRadius = radius - strokeWidth * 2;
    const circumference = normalizedRadius * 2 * Math.PI;
    const strokeDashoffset = mode === 'determinate'
      ? circumference - (percentage / 100) * circumference
      : 0;

    const progressClassName = [
      'progress_bar',
      `progress_bar_${variant}`,
      `progress_bar_${color}`,
      `progress_bar_${size}`,
      `progress_bar_${mode}`,
      animated ? 'progress_bar_animated' : '',
      className
    ].filter(Boolean).join(' ');

    return (
      <div className={progressClassName} {...props}>
        {label && (
          <div className="progress_bar_label">
            {label}
            {(showValue || showPercentage) && (
              <span className="progress_bar_value">
                {showPercentage ? `${Math.round(percentage)}%` : `${normalizedValue}/${max}`}
              </span>
            )}
          </div>
        )}

        <div className="progress_bar_container">
          <svg
            width={radius * 2}
            height={radius * 2}
            className="progress_bar_svg"
            role="progressbar"
            aria-valuenow={normalizedValue}
            aria-valuemin={min}
            aria-valuemax={max}
            aria-label={label || `Progress: ${Math.round(percentage)}%`}
          >
            {/* 背景サークル */}
            <circle
              className="progress_bar_track"
              cx={radius}
              cy={radius}
              r={normalizedRadius}
              strokeWidth={strokeWidth}
              fill="transparent"
            />

            {/* 進捗サークル */}
            <circle
              className="progress_bar_fill"
              cx={radius}
              cy={radius}
              r={normalizedRadius}
              strokeWidth={strokeWidth}
              fill="transparent"
              strokeDasharray={`${circumference} ${circumference}`}
              style={{
                strokeDashoffset: mode === 'indeterminate' ? 0 : strokeDashoffset,
                transformOrigin: '50% 50%',
                transform: 'rotate(-90deg)'
              }}
            />
          </svg>

          {/* 中央の値表示 */}
          {(showValue || showPercentage) && !label && (
            <div className="progress_bar_center_value">
              {showPercentage ? `${Math.round(percentage)}%` : normalizedValue}
            </div>
          )}
        </div>
      </div>
    );
  }

  // 線形プログレスバーの場合
  const progressClassName = [
    'progress_bar',
    `progress_bar_${variant}`,
    `progress_bar_${color}`,
    `progress_bar_${size}`,
    `progress_bar_${mode}`,
    striped ? 'progress_bar_striped' : '',
    animated ? 'progress_bar_animated' : '',
    className
  ].filter(Boolean).join(' ');

  return (
    <div className={progressClassName} {...props}>
      {label && (
        <div className="progress_bar_label">
          {label}
          {(showValue || showPercentage) && (
            <span className="progress_bar_value">
              {showPercentage ? `${Math.round(percentage)}%` : `${normalizedValue}/${max}`}
            </span>
          )}
        </div>
      )}

      <div
        className="progress_bar_container"
        role="progressbar"
        aria-valuenow={normalizedValue}
        aria-valuemin={min}
        aria-valuemax={max}
        aria-label={label || `Progress: ${Math.round(percentage)}%`}
      >
        <div className="progress_bar_track">
          <div
            className="progress_bar_fill"
            style={{
              width: mode === 'determinate' ? `${percentage}%` : '100%'
            }}
          />
        </div>
      </div>

      {/* 下部の値表示（ラベルがない場合） */}
      {(showValue || showPercentage) && !label && (
        <div className="progress_bar_bottom_value">
          {showPercentage ? `${Math.round(percentage)}%` : `${normalizedValue} / ${max}`}
        </div>
      )}
    </div>
  );
};

export default ProgressBar;