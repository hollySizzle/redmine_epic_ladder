import React, { useState, useEffect, useRef, useCallback } from 'react';

interface TripleSplitLayoutProps {
  leftPane: React.ReactNode;
  centerPane: React.ReactNode;
  rightPane: React.ReactNode;
  isLeftPaneVisible: boolean;
  isRightPaneVisible: boolean;
  onLeftPaneWidthChange?: (width: number) => void;
  onRightPaneWidthChange?: (width: number) => void;
}

interface PaneWidths {
  left: number;
  right: number;
}

// CSS変数から値を取得（px値）、取得失敗時はフォールバック値を使用
const getCSSVariable = (name: string, fallback: number): number => {
  const value = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const parsed = parseFloat(value) * 16; // rem -> px変換
  return isNaN(parsed) ? fallback : parsed;
};

// SSoT: CSS変数が唯一の真実。styles.scssの:root定義を参照
// フォールバック値はテスト環境・SSR対応のため、CSSと同じ値をハードコーディング
const MIN_LEFT_WIDTH = getCSSVariable('--triple-split-min-left-width', 150);
const MAX_LEFT_WIDTH = getCSSVariable('--triple-split-max-left-width', 400);
const MIN_CENTER_WIDTH = getCSSVariable('--triple-split-min-center-width', 600);
const MIN_RIGHT_WIDTH = getCSSVariable('--triple-split-min-right-width', 200);
const MAX_RIGHT_WIDTH = getCSSVariable('--triple-split-max-right-width', 800);

const DEFAULT_LEFT_WIDTH = getCSSVariable('--triple-split-default-left-width', 230);
const DEFAULT_RIGHT_WIDTH = getCSSVariable('--triple-split-default-right-width', 450);

const STORAGE_KEY = 'epic_ladder_triple_split_widths';

/**
 * 3ペイン分割レイアウトコンポーネント
 *
 * 左サイドメニュー、中央グリッド、右詳細ペインの3つの領域を管理
 * 各ペインはドラッグ可能な分割バーでリサイズ可能
 * ペインの表示/非表示状態とサイズはLocalStorageに永続化
 */
export const TripleSplitLayout: React.FC<TripleSplitLayoutProps> = ({
  leftPane,
  centerPane,
  rightPane,
  isLeftPaneVisible,
  isRightPaneVisible,
  onLeftPaneWidthChange,
  onRightPaneWidthChange
}) => {
  const [paneWidths, setPaneWidths] = useState<PaneWidths>({
    left: DEFAULT_LEFT_WIDTH,
    right: DEFAULT_RIGHT_WIDTH
  });
  const [draggingPane, setDraggingPane] = useState<'left' | 'right' | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const saveTimerRef = useRef<NodeJS.Timeout | null>(null);

  // LocalStorageから幅を復元
  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        const parsed = JSON.parse(saved) as PaneWidths;
        setPaneWidths({
          left: clamp(parsed.left, MIN_LEFT_WIDTH, MAX_LEFT_WIDTH),
          right: clamp(parsed.right, MIN_RIGHT_WIDTH, MAX_RIGHT_WIDTH)
        });
      } catch (e) {
        console.warn('Failed to parse saved pane widths', e);
      }
    }
  }, []);

  // 幅をLocalStorageに保存（デバウンス）
  const savePaneWidths = useCallback((widths: PaneWidths) => {
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current);
    }
    saveTimerRef.current = setTimeout(() => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(widths));
    }, 300);
  }, []);

  // 左スプリッターのドラッグ開始
  const handleLeftMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setDraggingPane('left');
  }, []);

  // 右スプリッターのドラッグ開始
  const handleRightMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setDraggingPane('right');
  }, []);

  // ドラッグ中
  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (!draggingPane || !containerRef.current) return;

    const containerRect = containerRef.current.getBoundingClientRect();
    const containerWidth = containerRect.width;

    if (draggingPane === 'left') {
      const newLeftWidth = e.clientX - containerRect.left;
      const clampedWidth = clamp(newLeftWidth, MIN_LEFT_WIDTH, MAX_LEFT_WIDTH);

      // 中央ペインの最小幅を確保
      const maxAllowedLeftWidth = containerWidth - MIN_CENTER_WIDTH -
        (isRightPaneVisible ? paneWidths.right : 0);

      if (clampedWidth <= maxAllowedLeftWidth) {
        const newWidths = { ...paneWidths, left: clampedWidth };
        setPaneWidths(newWidths);
        savePaneWidths(newWidths);
        onLeftPaneWidthChange?.(clampedWidth);
      }
    } else if (draggingPane === 'right') {
      const newRightWidth = containerRect.right - e.clientX;
      const clampedWidth = clamp(newRightWidth, MIN_RIGHT_WIDTH, MAX_RIGHT_WIDTH);

      // 中央ペインの最小幅を確保
      const maxAllowedRightWidth = containerWidth - MIN_CENTER_WIDTH -
        (isLeftPaneVisible ? paneWidths.left : 0);

      if (clampedWidth <= maxAllowedRightWidth) {
        const newWidths = { ...paneWidths, right: clampedWidth };
        setPaneWidths(newWidths);
        savePaneWidths(newWidths);
        onRightPaneWidthChange?.(clampedWidth);
      }
    }
  }, [draggingPane, paneWidths, isLeftPaneVisible, isRightPaneVisible, savePaneWidths, onLeftPaneWidthChange, onRightPaneWidthChange]);

  // ドラッグ終了
  const handleMouseUp = useCallback(() => {
    setDraggingPane(null);
  }, []);

  // マウスイベントの登録
  useEffect(() => {
    if (draggingPane) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);

      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [draggingPane, handleMouseMove, handleMouseUp]);

  // スプリッターのダブルクリックでデフォルト幅に戻す
  const handleLeftDoubleClick = useCallback(() => {
    const newWidths = { ...paneWidths, left: DEFAULT_LEFT_WIDTH };
    setPaneWidths(newWidths);
    savePaneWidths(newWidths);
    onLeftPaneWidthChange?.(DEFAULT_LEFT_WIDTH);
  }, [paneWidths, savePaneWidths, onLeftPaneWidthChange]);

  const handleRightDoubleClick = useCallback(() => {
    const newWidths = { ...paneWidths, right: DEFAULT_RIGHT_WIDTH };
    setPaneWidths(newWidths);
    savePaneWidths(newWidths);
    onRightPaneWidthChange?.(DEFAULT_RIGHT_WIDTH);
  }, [paneWidths, savePaneWidths, onRightPaneWidthChange]);

  return (
    <div
      className={`triple-split-layout ${draggingPane ? 'triple-split-layout--dragging' : ''}`}
      ref={containerRef}
    >
      {/* 左ペイン */}
      {isLeftPaneVisible && (
        <>
          <div
            className="triple-split-layout__left"
            style={{ width: `${paneWidths.left}px` }}
          >
            {leftPane}
          </div>

          <div
            className="triple-split-layout__splitter triple-split-layout__splitter--left"
            onMouseDown={handleLeftMouseDown}
            onDoubleClick={handleLeftDoubleClick}
            role="separator"
            aria-orientation="vertical"
            aria-label="左ペインのリサイズ"
            title="ドラッグして幅を調整 (ダブルクリックで初期値に戻す)"
          >
            <div className="triple-split-layout__splitter-handle" />
          </div>
        </>
      )}

      {/* 中央ペイン */}
      <div className="triple-split-layout__center">
        {centerPane}
      </div>

      {/* 右ペイン */}
      {isRightPaneVisible && (
        <>
          <div
            className="triple-split-layout__splitter triple-split-layout__splitter--right"
            onMouseDown={handleRightMouseDown}
            onDoubleClick={handleRightDoubleClick}
            role="separator"
            aria-orientation="vertical"
            aria-label="右ペインのリサイズ"
            title="ドラッグして幅を調整 (ダブルクリックで初期値に戻す)"
          >
            <div className="triple-split-layout__splitter-handle" />
          </div>

          <div
            className="triple-split-layout__right"
            style={{ width: `${paneWidths.right}px` }}
          >
            {rightPane}
          </div>
        </>
      )}
    </div>
  );
};

/**
 * 値を最小値と最大値の間にクランプする
 */
function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
