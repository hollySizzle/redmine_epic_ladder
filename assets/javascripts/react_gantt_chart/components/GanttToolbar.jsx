import React, { useState, useEffect } from 'react';
import ViewModeToggle from './ViewModeToggle';
import GridWidthControl from './GridWidthControl';
import { GanttSettings } from '../utils/cookieUtils';

/**
 * ガントチャート用二段組ツールバーコンポーネント
 * レスポンシブデザインに対応した主要操作と補助機能の分離型UI
 */
const GanttToolbar = ({
  // 保存関連
  modifiedTasksCount = 0,
  loading = false,
  onSave,
  
  // タスク操作関連
  onCreateRootTask,
  onToggleAllTasks,
  onClearFilters,
  
  // ズーム関連
  currentZoom = 'month',
  onZoomChange,
  
  // ビューモード関連
  viewMode = 'normal',
  onViewModeChange,
  
  // 期間設定関連
  viewStartDate,
  viewEndDate,
  onViewRangeChange,
  
  // 設定関連
  
  // クリティカルパス
  criticalPath = false,
  onCriticalPathChange,
  
  // カスタマイズ可能な設定
  showSecondTierInitially = null, // Cookie設定を優先するためnullに設定
  enableExport = false,
  onExport,
  
  // 無効化制御
  disabled = false
}) => {
  // 二段目表示状態（詳細設定の開閉）- Cookie連携
  const [showSecondTier, setShowSecondTier] = useState(() => {
    // Cookieから設定を取得、パラメータで上書きされている場合はそれを優先
    return showSecondTierInitially !== null 
      ? showSecondTierInitially 
      : GanttSettings.getShowToolbarDetails();
  });

  // ズームオプション定義
  const zoomOptions = [
    { value: 'day', label: '日' },
    { value: 'week', label: '週' },
    { value: 'month', label: '月' },
    { value: 'quarter', label: '四半期' },
    { value: 'year', label: '年' }
  ];

  // エクスポート処理（カスタムまたはデフォルト）
  const handleExport = () => {
    if (onExport) {
      onExport();
    } else {
      alert('エクスポート機能は準備中です');
    }
  };

  // 保存ボタンのテキスト生成
  const getSaveButtonText = () => {
    if (loading) return '保存中...';
    if (modifiedTasksCount === 0) return '💾 保存';
    return `💾 保存(${modifiedTasksCount}件)`;
  };

  // デバッグ: 期間props変更時のみログ出力
  useEffect(() => {
    console.log('GanttToolbar: 期間props変更', { 
      viewStartDate, 
      viewEndDate, 
      onViewRangeChange: !!onViewRangeChange 
    });
  }, [viewStartDate, viewEndDate]);

  return (
    <div className="gantt-toolbar-container">
      {/* 1段目: 主要操作 */}
      <div className="gantt-toolbar-tier1">
        {/* 保存ボタン（最優先配置） */}
        <button 
          onClick={onSave}
          disabled={modifiedTasksCount === 0 || loading || disabled}
          className="gantt-btn gantt-btn-save"
          title={modifiedTasksCount > 0 ? `${modifiedTasksCount}件の変更を保存` : '変更はありません'}
        >
          {getSaveButtonText()}
        </button>
        
        {/* 新規タスク作成 */}
        <button 
          onClick={onCreateRootTask}
          className="gantt-btn gantt-btn-primary"
          disabled={disabled}
          title="新しいルートタスクを作成"
        >
          新規タスク
        </button>
        
        {/* 表示期間選択 */}
        <div className="gantt-zoom-controls">
          <label className="gantt-zoom-label">表示期間:</label>
          <select 
            value={currentZoom}
            onChange={(e) => onZoomChange && onZoomChange(e.target.value)}
            className="gantt-zoom-select"
            disabled={disabled}
            title="ガントチャートの表示期間を選択"
          >
            {zoomOptions.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
        
        {/* 期間設定 */}
        <div className="gantt-date-range-controls">
          <label className="gantt-date-label">期間:</label>
          <input
            type="date"
            value={viewStartDate || ''}
            onChange={(e) => {
              console.log('GanttToolbar: 開始日変更', e.target.value, '→', viewEndDate);
              onViewRangeChange && onViewRangeChange(e.target.value, viewEndDate || null);
            }}
            className="gantt-date-input"
            disabled={disabled}
            title="表示開始日を設定"
            ref={(el) => {
              if (el) {
                console.log('GanttToolbar: 開始日input要素', {
                  value: el.value,
                  propValue: viewStartDate,
                  disabled: el.disabled,
                  className: el.className
                });
              }
            }}
          />
          <span className="gantt-date-separator">〜</span>
          <input
            type="date"
            value={viewEndDate || ''}
            onChange={(e) => {
              console.log('GanttToolbar: 終了日変更', viewStartDate, '→', e.target.value);
              onViewRangeChange && onViewRangeChange(viewStartDate || null, e.target.value);
            }}
            className="gantt-date-input"
            disabled={disabled}
            title="表示終了日を設定"
            ref={(el) => {
              if (el) {
                console.log('GanttToolbar: 終了日input要素', {
                  value: el.value,
                  propValue: viewEndDate,
                  disabled: el.disabled,
                  className: el.className
                });
              }
            }}
          />
        </div>
        
        {/* 展開/折りたたみ統合ボタン */}
        <button 
          onClick={onToggleAllTasks}
          className="gantt-btn"
          disabled={disabled}
          title="すべてのタスクを展開または折りたたみ"
        >
          展開/折りたたみ
        </button>
        
        {/* フィルタクリア */}
        <button
          onClick={onClearFilters}
          className="gantt-btn"
          disabled={disabled}
          title="すべてのフィルタをクリア"
        >
          🗑️ フィルタクリア
        </button>
        
        {/* 詳細設定トグル */}
        <button
          onClick={() => {
            const newShowState = !showSecondTier;
            setShowSecondTier(newShowState);
            // Cookie に保存
            GanttSettings.setShowToolbarDetails(newShowState);
          }}
          className={`gantt-btn ${showSecondTier ? 'active' : ''}`}
          disabled={disabled}
          title={showSecondTier ? "詳細設定を閉じる" : "詳細設定を開く"}
        >
          {showSecondTier ? '▼ 閉じる' : '▲ 開く'}
        </button>
      </div>
      
      {/* 2段目: 補助機能（折りたたみ可能） */}
      {showSecondTier && (
        <div className="gantt-toolbar-tier2">
          
          {/* 列幅設定 */}
          {gantt && <GridWidthControl gantt={gantt} />}
          
          {/* クリティカルパス表示 */}
          <label className="gantt-checkbox">
            <input
              type="checkbox"
              checked={criticalPath}
              onChange={(e) => onCriticalPathChange && onCriticalPathChange(e.target.checked)}
              disabled={disabled}
            />
            ☑️ クリティカルパス
          </label>
          
          {/* ビューモード切替 */}
          <ViewModeToggle 
            currentMode={viewMode}
            onModeChange={onViewModeChange}
            disabled={disabled}
          />
          
          {/* エクスポート機能 */}
          <button
            onClick={handleExport}
            className="gantt-btn"
            disabled={disabled || !enableExport}
            title="ガントチャートをエクスポート"
          >
            📤 エクスポート
          </button>
        </div>
      )}
    </div>
  );
};

// PropTypes の代替として JSDoc でタイプ定義
/**
 * @typedef {Object} GanttToolbarProps
 * @property {number} [modifiedTasksCount=0] - 変更されたタスクの数
 * @property {boolean} [loading=false] - 保存中の状態
 * @property {Function} [onSave] - 保存ボタンクリック時のコールバック
 * @property {Function} [onCreateRootTask] - 新規タスク作成のコールバック
 * @property {Function} [onToggleAllTasks] - 全展開/折りたたみのコールバック
 * @property {Function} [onClearFilters] - フィルタクリアのコールバック
 * @property {string} [currentZoom='month'] - 現在のズームレベル
 * @property {Function} [onZoomChange] - ズーム変更のコールバック
 * @property {string} [viewMode='normal'] - 現在のビューモード
 * @property {Function} [onViewModeChange] - ビューモード変更のコールバック
 * @property {string} [viewStartDate] - 表示開始日 (YYYY-MM-DD形式)
 * @property {string} [viewEndDate] - 表示終了日 (YYYY-MM-DD形式) 
 * @property {Function} [onViewRangeChange] - 期間変更のコールバック
 * @property {boolean} [criticalPath=false] - クリティカルパス表示状態
 * @property {Function} [onCriticalPathChange] - クリティカルパス変更のコールバック
 * @property {boolean} [showSecondTierInitially=null] - 二段目の初期表示状態（nullの場合はCookieから取得）
 * @property {boolean} [enableExport=false] - エクスポート機能の有効性
 * @property {Function} [onExport] - カスタムエクスポート処理のコールバック
 * @property {boolean} [disabled=false] - ツールバー全体の無効化状態
 */

export default GanttToolbar;