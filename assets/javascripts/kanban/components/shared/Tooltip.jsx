import React, { useState, useRef, useCallback } from 'react';
import './Tooltip.scss';

/**
 * Tooltip Component
 * ホバー時にツールチップを表示するコンポーネント
 *
 * @param {Object} props
 * @param {React.ReactNode} props.children - ツールチップのトリガー要素
 * @param {string|React.ReactNode} props.content - ツールチップに表示するコンテンツ
 * @param {'top'|'bottom'|'left'|'right'} props.position - ツールチップの表示位置
 * @param {number} props.delay - 表示遅延時間（ミリ秒）
 * @param {boolean} props.disabled - ツールチップ無効化
 * @param {string} props.className - 追加CSSクラス
 */
const Tooltip = ({
  children,
  content,
  position = 'top',
  delay = 500,
  disabled = false,
  className = '',
  ...props
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const [tooltipStyle, setTooltipStyle] = useState({});
  const triggerRef = useRef(null);
  const tooltipRef = useRef(null);
  const timeoutRef = useRef(null);

  // ツールチップの位置計算
  const calculatePosition = useCallback(() => {
    if (!triggerRef.current || !tooltipRef.current) return;

    const triggerRect = triggerRef.current.getBoundingClientRect();
    const tooltipRect = tooltipRef.current.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    let top, left;

    switch (position) {
      case 'top':
        top = triggerRect.top - tooltipRect.height - 8;
        left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
        break;

      case 'bottom':
        top = triggerRect.bottom + 8;
        left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
        break;

      case 'left':
        top = triggerRect.top + (triggerRect.height - tooltipRect.height) / 2;
        left = triggerRect.left - tooltipRect.width - 8;
        break;

      case 'right':
        top = triggerRect.top + (triggerRect.height - tooltipRect.height) / 2;
        left = triggerRect.right + 8;
        break;

      default:
        top = triggerRect.top - tooltipRect.height - 8;
        left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
    }

    // ビューポートからはみ出ないように調整
    if (left < 8) {
      left = 8;
    } else if (left + tooltipRect.width > viewportWidth - 8) {
      left = viewportWidth - tooltipRect.width - 8;
    }

    if (top < 8) {
      top = 8;
    } else if (top + tooltipRect.height > viewportHeight - 8) {
      top = viewportHeight - tooltipRect.height - 8;
    }

    setTooltipStyle({
      position: 'fixed',
      top: `${top}px`,
      left: `${left}px`,
      zIndex: 1000
    });
  }, [position]);

  // マウス入力時の処理
  const handleMouseEnter = useCallback(() => {
    if (disabled || !content) return;

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(() => {
      setIsVisible(true);
      setTimeout(calculatePosition, 0);
    }, delay);
  }, [disabled, content, delay, calculatePosition]);

  // マウス離脱時の処理
  const handleMouseLeave = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    setIsVisible(false);
  }, []);

  // クリーンアップ
  React.useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  // リサイズ時の位置再計算
  React.useEffect(() => {
    if (isVisible) {
      const handleResize = () => calculatePosition();
      window.addEventListener('resize', handleResize);
      return () => window.removeEventListener('resize', handleResize);
    }
  }, [isVisible, calculatePosition]);

  if (!content) {
    return children;
  }

  return (
    <>
      <span
        ref={triggerRef}
        className={`tooltip_trigger ${className}`}
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleMouseLeave}
        {...props}
      >
        {children}
      </span>

      {isVisible && (
        <div
          ref={tooltipRef}
          className={`tooltip_content ${position}`}
          style={tooltipStyle}
        >
          <div className="tooltip_inner">
            {content}
          </div>
          <div className={`tooltip_arrow arrow_${position}`} />
        </div>
      )}
    </>
  );
};

export default Tooltip;