import React, { useState, useEffect, useRef, useCallback } from 'react';

interface SplitLayoutProps {
  leftPane: React.ReactNode;
  rightPane: React.ReactNode;
  initialRatio?: number;
  onRatioChange?: (ratio: number) => void;
}

/**
 * 分割レイアウトコンポーネント
 * 左右のペインをドラッグ可能な分割バーで区切る
 */
export const SplitLayout: React.FC<SplitLayoutProps> = ({
  leftPane,
  rightPane,
  initialRatio = 0.6,
  onRatioChange
}) => {
  const [splitRatio, setSplitRatio] = useState(initialRatio);
  const [isDragging, setIsDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const splitterRef = useRef<HTMLDivElement>(null);
  const saveTimerRef = useRef<NodeJS.Timeout | null>(null);

  // 分割比率を保存（デバウンス処理）
  const saveSplitRatio = useCallback((ratio: number) => {
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current);
    }
    saveTimerRef.current = setTimeout(() => {
      // LocalStorageに保存
      localStorage.setItem('kanban_split_ratio', ratio.toString());
      if (onRatioChange) {
        onRatioChange(ratio);
      }
    }, 300);
  }, [onRatioChange]);

  // LocalStorageから初期値を復元
  useEffect(() => {
    const savedRatio = localStorage.getItem('kanban_split_ratio');
    if (savedRatio) {
      const ratio = parseFloat(savedRatio);
      if (!isNaN(ratio) && ratio >= 0.3 && ratio <= 0.8) {
        setSplitRatio(ratio);
      }
    }
  }, []);

  // ドラッグ開始
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  // ドラッグ中
  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (!isDragging || !containerRef.current) return;

    const containerRect = containerRef.current.getBoundingClientRect();
    const containerWidth = containerRect.width;
    const newLeftWidth = e.clientX - containerRect.left;

    // 最小幅の制約（左400px、右300px）
    const minLeftWidth = 400;
    const minRightWidth = 300;
    const maxLeftWidth = containerWidth - minRightWidth;

    if (newLeftWidth >= minLeftWidth && newLeftWidth <= maxLeftWidth) {
      const newRatio = newLeftWidth / containerWidth;
      setSplitRatio(newRatio);
      saveSplitRatio(newRatio);
    }
  }, [isDragging, saveSplitRatio]);

  // ドラッグ終了
  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);

  // マウスイベントの登録
  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);

      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, handleMouseMove, handleMouseUp]);

  // ダブルクリックで初期値に戻す
  const handleDoubleClick = useCallback(() => {
    const defaultRatio = 0.6;
    setSplitRatio(defaultRatio);
    saveSplitRatio(defaultRatio);
  }, [saveSplitRatio]);

  // キーボードでの微調整
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    const step = 0.02; // 2%ずつ調整
    let newRatio = splitRatio;

    switch (e.key) {
      case 'ArrowLeft':
        newRatio = Math.max(0.3, splitRatio - step);
        break;
      case 'ArrowRight':
        newRatio = Math.min(0.8, splitRatio + step);
        break;
      default:
        return;
    }

    e.preventDefault();
    setSplitRatio(newRatio);
    saveSplitRatio(newRatio);
  }, [splitRatio, saveSplitRatio]);

  return (
    <div className={`split-layout ${isDragging ? 'split-layout--dragging' : ''}`} ref={containerRef}>
      <div
        className="split-layout__left"
        style={{ width: `${splitRatio * 100}%` }}
      >
        {leftPane}
      </div>

      <div
        className="split-layout__splitter"
        ref={splitterRef}
        onMouseDown={handleMouseDown}
        onDoubleClick={handleDoubleClick}
        onKeyDown={handleKeyDown}
        tabIndex={0}
        role="separator"
        aria-orientation="vertical"
        aria-valuenow={Math.round(splitRatio * 100)}
        aria-valuemin={30}
        aria-valuemax={80}
        title="ドラッグして幅を調整 (ダブルクリックで初期値に戻す)"
      >
        <div className="split-layout__splitter-handle" />
      </div>

      <div
        className="split-layout__right"
        style={{ width: `${(1 - splitRatio) * 100}%` }}
      >
        {rightPane}
      </div>
    </div>
  );
};
