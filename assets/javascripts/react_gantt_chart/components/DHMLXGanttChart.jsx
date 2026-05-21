import React, { useEffect, useRef, useState, useCallback } from 'react';
import { gantt } from 'dhtmlx-gantt';
import 'dhtmlx-gantt/codebase/dhtmlxgantt.css';

// 設定とヘルパーのインポート
import { setupGanttConfig, updateZoomConfig, setupTaskDisplay, setupScrollableGridLayout, setupFixedColumnScrolling, updateGanttDateRange } from './gantt/config';
import { setupColumns, setupDateFormats } from './gantt/columns';
import { setupEventHandlers } from './gantt/handlers/eventHandlers';
import { createTaskHandlers } from './gantt/handlers/taskHandlers';
import { createLinkHandlers } from './gantt/handlers/linkHandlers';
import { createHeaderFilterHandlers } from './gantt/handlers/headerFilterHandlers';
import { 
  getModifiedTasks, 
  getModifiedLinks, 
  expandAllTasks, 
  collapseAllTasks,
  getTaskStatistics 
} from './gantt/utils/helpers';

// 固定カラム用CSSをインポート
import './gantt/config/frozenColumns.css';
// 行ドラッグ&ドロップ用CSS
import './gantt/config/rowDragDrop.css';
// ヘッダーフィルタ用CSS
import './gantt/config/headerFilters.css';
// 土日スタイル用CSS
import './gantt/config/weekendStyle.css';
// 列入替機能用CSS
import './gantt/config/columnReorder.css';
// リンクハンドル用CSS（未実装）

// 2ペインモード関連のインポート
import { GanttSettings } from '../utils/cookieUtils';
import { viewRangeManager } from '../utils/ViewRangeManager';
import ViewModeToggle from './ViewModeToggle';
import SplitLayout from './SplitLayout';
import TaskDetailPane from './TaskDetailPane';
import RedmineIframeModal from './RedmineIframeModal';

// ツールバーコンポーネントのインポート
import GanttToolbar from './GanttToolbar';

// 列幅調整機能のインポート
import ColumnResizeControl from './ColumnResizeControl';
import { applySavedColumnWidths } from './gantt/utils/columnResize';
import { initializeDragHandles, refreshDragHandles } from './gantt/utils/dragHandleManager';
import './ColumnResizeControl.scss';



/**
 * Ganttデータの整合性を検証し、大規模プロジェクトでの問題を防ぐ
 * @param {Array} tasks - タスクデータ
 * @param {Array} links - リンクデータ
 * @returns {Object} 検証済みデータ
 */
const validateGanttData = (tasks, links) => {
  const validTasks = [];
  const taskIds = new Set();
  
  // タスクの検証
  tasks.forEach(task => {
    if (task && task.id !== undefined && task.id !== null) {
      // 重複ID除外
      if (!taskIds.has(task.id)) {
        taskIds.add(task.id);
        
        // 必要なプロパティの検証
        const validTask = {
          ...task,
          text: task.text || 'Unnamed Task',
          start_date: task.start_date || new Date().toISOString().split('T')[0],
          duration: Math.max(0, parseInt(task.duration) || 1), // 負のdurationを防ぐ
          progress: Math.max(0, Math.min(1, parseFloat(task.progress) || 0)) // 0-1範囲に制限
        };
        
        validTasks.push(validTask);
      } else {
        console.warn(`重複タスクID: ${task.id} をスキップ`);
      }
    } else {
      console.warn('無効なタスクデータ:', task);
    }
  });
  
  // リンクの検証（存在しないタスクへの参照を除外）
  const validLinks = [];
  links.forEach(link => {
    if (link && link.id && link.source && link.target) {
      // source と target がタスクに存在するかチェック
      if (taskIds.has(link.source) && taskIds.has(link.target)) {
        validLinks.push(link);
      } else {
        console.warn(`無効なリンク: ${link.source} -> ${link.target} (存在しないタスク参照)`);
      }
    } else {
      console.warn('無効なリンクデータ:', link);
    }
  });
  
  return {
    tasks: validTasks,
    links: validLinks
  };
};

const DHMLXGanttChart = ({
  tasks = [],
  links = [],
  onDataUpdate,
  onDataRequest,
  onDataLoaded,
  onError,
  showErrorMessage,
  appliedFilters,
  visibleColumns,
  projectId,
  filters,
  onFilterChange,
  onConfigUpdate,
  onPermissionDenied,
  currentZoom = 'day',
  onZoomChange,
  viewStartDate,
  viewEndDate,
  onViewRangeChange,
  loadGanttData: loadGanttDataFromProps
}) => {
  const ganttRef = useRef(null);
  const [modifiedTasks, setModifiedTasks] = useState(new Set());
  const [pendingOrder] = useState(new Map());
  const [criticalPath, setCriticalPath] = useState(false);
  const [loading, setLoading] = useState(false);
  const [ganttInstance, setGanttInstance] = useState(null);
  const [currentZoomLevel, setCurrentZoomLevel] = useState(() => {
    // Cookieから保存されたズームレベルを復元
    const savedZoom = viewRangeManager.getCurrentZoom();
    return savedZoom || currentZoom;
  });
  const isInitializingRef = useRef(false);

  // エラーメッセージ定数（国際化対応準備）
  const ERROR_MESSAGES = {
    PERMISSION_ERROR: 'ガントチャート表示権限を確認してください',
    SERVER_ERROR: 'バックエンドログを確認してください',
    NETWORK_ERROR: '接続を確認してください',
    DATA_LOAD_ERROR: 'データの読み込みに失敗しました。ページを更新してください。',
    PERFORMANCE_WARNING_TIME: '読み込み時間が3秒を超えています',
    PERFORMANCE_WARNING_COUNT: 'データ件数が800件を超えています（要最適化）',
    FALLBACK_MODE: 'フォールバック: 従来方式で再試行',
    LEGACY_MODE_COMPLETE: 'レガシーモードでの読み込み完了（最適化未適用）',
    LEGACY_MODE_FAILED: 'レガシーモードも失敗',
    INVALID_DATE_RANGE: '無効な日付範囲が計算されました',
    VIEW_RANGE_ERROR: '表示範囲計算エラー',
    FILTER_PARAMS_ERROR: 'フィルタパラメータ構築エラー',
    DATA_RESTRICTED: '表示可能なデータが制限されています'
  };

  // パフォーマンス閾値定数
  const PERFORMANCE_THRESHOLDS = {
    MAX_LOAD_TIME: 3000,     // 3秒
    MAX_DATA_COUNT: 800      // 800件
  };
  
  // 2ペインモード関連の状態
  const [viewMode, setViewMode] = useState(GanttSettings.getViewMode());
  const [selectedTaskId, setSelectedTaskId] = useState(GanttSettings.getLastSelectedTask());
  const [showModal, setShowModal] = useState(false);
  

  // 変更されたタスクをマーク（初期化中は無視）
  const markModified = (id) => {
    if (!isInitializingRef.current) {
      // IDを常に文字列として保存
      setModifiedTasks(prev => new Set(prev).add(String(id)));
    }
  };

  // 日付フォーマット関数
  const formatDate = (date) => {
    if (!(date instanceof Date) || isNaN(date.getTime())) {
      console.error('Invalid date provided to formatDate:', date);
      return new Date().toISOString().split('T')[0]; // フォールバック: 今日の日付
    }
    return date.toISOString().split('T')[0]; // YYYY-MM-DD形式
  };

  // より安全な日付計算関数
  const addMonths = (date, months) => {
    if (!(date instanceof Date)) {
      throw new Error('Invalid date provided to addMonths');
    }
    const result = new Date(date.getTime()); // 元の日付をコピー
    result.setMonth(result.getMonth() + months);
    return result;
  };

  // 月の最初の日を取得
  const getFirstDayOfMonth = (date) => {
    if (!(date instanceof Date)) {
      throw new Error('Invalid date provided to getFirstDayOfMonth');
    }
    return new Date(date.getFullYear(), date.getMonth(), 1);
  };

  // 月の最後の日を取得
  const getLastDayOfMonth = (date) => {
    if (!(date instanceof Date)) {
      throw new Error('Invalid date provided to getLastDayOfMonth');
    }
    return new Date(date.getFullYear(), date.getMonth() + 1, 0);
  };

  // 年の最初の日を取得
  const getFirstDayOfYear = (date) => {
    if (!(date instanceof Date)) {
      throw new Error('Invalid date provided to getFirstDayOfYear');
    }
    return new Date(date.getFullYear(), 0, 1);
  };

  // 年の最後の日を取得
  const getLastDayOfYear = (date) => {
    if (!(date instanceof Date)) {
      throw new Error('Invalid date provided to getLastDayOfYear');
    }
    return new Date(date.getFullYear(), 11, 31);
  };

  // 表示範囲の自動計算（改善版）
  const calculateViewRange = (zoomLevel = 'month') => {
    try {
      const today = new Date();
      
      // ズームレベル別の表示範囲設定（安全な日付計算）
      const zoomConfig = {
        day: {
          start: getFirstDayOfMonth(today),                    // 今月初日
          end: getLastDayOfMonth(addMonths(today, 2))          // 2ヶ月後の末日
        },
        week: {
          start: getFirstDayOfMonth(addMonths(today, -1)),     // 先月初日  
          end: getLastDayOfMonth(addMonths(today, 3))          // 3ヶ月後の末日
        },
        month: {
          start: getFirstDayOfMonth(addMonths(today, -2)),     // 2ヶ月前の初日
          end: getLastDayOfMonth(addMonths(today, 6))          // 6ヶ月後の末日
        },
        quarter: {
          start: getFirstDayOfMonth(addMonths(today, -6)),     // 6ヶ月前の初日
          end: getLastDayOfMonth(addMonths(today, 12))         // 12ヶ月後の末日
        },
        year: {
          start: getFirstDayOfYear(addMonths(today, -12)),     // 昨年初日
          end: getLastDayOfYear(addMonths(today, 12))          // 来年の年末
        }
      };
      
      const config = zoomConfig[zoomLevel] || zoomConfig.month;
      
      const result = {
        start: formatDate(config.start),
        end: formatDate(config.end)
      };
      
      // 結果の妥当性チェック
      if (result.start >= result.end) {
        console.warn(`${ERROR_MESSAGES.INVALID_DATE_RANGE}: ${result.start} >= ${result.end}, using fallback`);
        const fallback = zoomConfig.month;
        return {
          start: formatDate(fallback.start),
          end: formatDate(fallback.end)
        };
      }
      
      return result;
    } catch (error) {
      console.error(`${ERROR_MESSAGES.VIEW_RANGE_ERROR}:`, error);
      // フォールバック: デフォルトの月表示範囲
      const today = new Date();
      return {
        start: formatDate(new Date(today.getFullYear(), today.getMonth() - 2, 1)),
        end: formatDate(new Date(today.getFullYear(), today.getMonth() + 6, 0))
      };
    }
  };

  // フィルタパラメータをRedmine形式に変換
  const buildFilterParams = () => {
    const filterParams = {};
    
    // ヘッダーフィルタからのパラメータを優先
    if (headerFilters && headerFilters.length > 0) {
      console.log('ヘッダーフィルタを使用:', headerFilters);
      
      // set_filterパラメータを追加
      filterParams.set_filter = '1';
      
      headerFilters.forEach((filter, index) => {
        if (filter && filter.field) {
          // フィールド名の配列
          if (!filterParams[`f[${index}]`]) {
            filterParams[`f[]`] = [];
          }
          if (!Array.isArray(filterParams[`f[]`])) {
            filterParams[`f[]`] = [filterParams[`f[]`]];
          }
          filterParams[`f[]`].push(filter.field);
          
          // オペレータ
          filterParams[`op[${filter.field}]`] = filter.operator || '=';
          
          // 値
          const values = Array.isArray(filter.value) ? filter.value : [filter.value];
          values.forEach((value, valueIndex) => {
            filterParams[`v[${filter.field}][${valueIndex}]`] = value;
          });
        }
      });
      
      console.log('構築されたフィルタパラメータ:', filterParams);
      return filterParams;
    }
    
    // フォールバック: 既存のappliedFiltersを使用
    try {
      if (!appliedFilters || typeof appliedFilters !== 'object') {
        console.debug('appliedFilters is not a valid object:', appliedFilters);
        return filterParams;
      }
      
      if (appliedFilters === null || Object.keys(appliedFilters).length === 0) {
        console.debug('appliedFilters is empty or null');
        return filterParams;
      }
      
      // 既存のフィルタ状態を取得
      Object.entries(appliedFilters).forEach(([key, filter]) => {
        try {
          if (!key || typeof key !== 'string') {
            console.warn('Invalid filter key:', key);
            return;
          }
          
          if (!filter || typeof filter !== 'object') {
            console.warn('Invalid filter object for key:', key, filter);
            return;
          }
          
          if (!filter.operator || !filter.values) {
            console.debug(`Filter missing operator or values for key: ${key}`, filter);
            return;
          }
          
          // operatorの型チェック
          if (typeof filter.operator !== 'string') {
            console.warn(`Invalid operator type for key: ${key}`, filter.operator);
            return;
          }
          
          // valuesの配列チェック
          if (!Array.isArray(filter.values)) {
            console.warn(`Filter values is not an array for key: ${key}`, filter.values);
            return;
          }
          
          // フィルタパラメータの構築
          filterParams[`f[${key}]`] = key;
          filterParams[`op[${key}]`] = filter.operator;
          
          // 各値の妥当性チェック
          filter.values.forEach((value, index) => {
            if (value !== null && value !== undefined && value !== '') {
              // 値を文字列に変換（安全性確保）
              const safeValue = String(value);
              filterParams[`v[${key}][${index}]`] = safeValue;
            } else {
              console.debug(`Skipping invalid value at index ${index} for key: ${key}`, value);
            }
          });
          
        } catch (entryError) {
          console.error(`Error processing filter entry for key: ${key}`, entryError);
        }
      });
      
      console.debug('Built filter params:', filterParams);
      return filterParams;
      
    } catch (error) {
      console.error(`${ERROR_MESSAGES.FILTER_PARAMS_ERROR}:`, error);
      // フォールバック: 空のフィルタパラメータを返す
      return {};
    }
  };

  // パフォーマンス監視（改善版）
  const logPerformanceMetrics = (startTime, dataCount) => {
    const loadTime = Date.now() - startTime;
    
    console.log(`=== Gantt パフォーマンス ===`);
    console.log(`データ件数: ${dataCount}件`);
    console.log(`読み込み時間: ${loadTime}ms`);
    console.log(`平均処理時間: ${(loadTime / dataCount).toFixed(2)}ms/件`);
    
    // パフォーマンス劣化の警告（定数使用）
    if (loadTime > PERFORMANCE_THRESHOLDS.MAX_LOAD_TIME) {
      console.warn(`⚠️ ${ERROR_MESSAGES.PERFORMANCE_WARNING_TIME}`);
    }
    
    if (dataCount > PERFORMANCE_THRESHOLDS.MAX_DATA_COUNT) {
      console.warn(`⚠️ ${ERROR_MESSAGES.PERFORMANCE_WARNING_COUNT}`);
    }
  };

  // エラー分類とハンドリング（改善版）
  const handleDataLoadError = (error, context = '') => {
    console.group(`🔥 ガントデータエラー${context ? ` (${context})` : ''}`);
    console.error('エラー詳細:', error);
    
    // エラー種別の判定と適切なメッセージ表示
    let errorMessage = ERROR_MESSAGES.DATA_LOAD_ERROR; // デフォルトメッセージ
    
    if (error.message.includes('HTTP 403')) {
      console.error(`権限エラー: ${ERROR_MESSAGES.PERMISSION_ERROR}`);
      errorMessage = ERROR_MESSAGES.PERMISSION_ERROR;
    } else if (error.message.includes('HTTP 500')) {
      console.error(`サーバーエラー: ${ERROR_MESSAGES.SERVER_ERROR}`);
      errorMessage = `サーバーエラー: ${ERROR_MESSAGES.SERVER_ERROR}`;
    } else if (error.name === 'TypeError') {
      console.error(`ネットワークエラー: ${ERROR_MESSAGES.NETWORK_ERROR}`);
      errorMessage = `ネットワークエラー: ${ERROR_MESSAGES.NETWORK_ERROR}`;
    }
    
    console.groupEnd();
    
    // ユーザー向けエラー表示
    if (showErrorMessage) {
      showErrorMessage(errorMessage);
    }
  };

  // 従来方式のフォールバック（互換性確保・改善版）
  const loadGanttDataLegacy = async () => {
    console.log('レガシーモードでデータ取得');
    
    try {
      const response = await fetch(
        `/projects/${projectId}/react_gantt_chart/data`
      );
      
      if (!response.ok) {
        throw new Error(`Legacy mode failed: ${response.status}`);
      }
      
      const data = await response.json();
      
      if (ganttInstance) {
        ganttInstance.clearAll();
        
        // データ整合性チェック
        const validatedData = validateGanttData(data.tasks || [], data.links || []);
        
        ganttInstance.parse({
          data: validatedData.tasks,
          links: validatedData.links
        });
      }
      
      console.warn(ERROR_MESSAGES.LEGACY_MODE_COMPLETE);
      
    } catch (error) {
      console.error(`${ERROR_MESSAGES.LEGACY_MODE_FAILED}:`, error);
      throw error;
    }
  };

  // サーバーサイドフィルタを使用したデータ取得
  const loadGanttData = async (forceReload = false) => {
    // App.jsxから渡された関数が存在する場合はそれを使用
    if (loadGanttDataFromProps) {
      console.log('[DHMLXGanttChart] App.jsxのloadGanttData関数を使用');
      
      // ヘッダーフィルタをApp.jsx形式に変換
      const appFilterParams = {};
      if (headerFilters && headerFilters.length > 0) {
        appFilterParams.set_filter = '1';
        appFilterParams.fields = [];
        appFilterParams.operators = {};
        appFilterParams.values = {};
        
        headerFilters.forEach(filter => {
          if (filter && filter.field) {
            appFilterParams.fields.push(filter.field);
            appFilterParams.operators[filter.field] = filter.operator || '=';
            appFilterParams.values[filter.field] = Array.isArray(filter.value) ? filter.value : [filter.value];
          }
        });
        
        console.log('[DHMLXGanttChart] App.jsx形式に変換:', appFilterParams);
      }
      
      return await loadGanttDataFromProps(appFilterParams);
    }
    
    // フォールバック: 独自実装
    try {
      setLoading(true);
      const startTime = Date.now();
      
      // 表示範囲を自動計算
      const viewRange = calculateViewRange(currentZoomLevel);
      
      // サーバーサイドフィルタ用パラメータ
      const baseParams = {
        gantt_view: true,                    // サーバーサイド最適化有効
        view_start: viewRange.start,         // 表示開始日
        view_end: viewRange.end,            // 表示終了日
        zoom_level: currentZoomLevel         // ズームレベル
      };
      
      const filterParams = buildFilterParams();
      console.log('[loadGanttData] フィルタパラメータ:', filterParams);
      
      // クエリ文字列を手動構築（配列パラメータ対応）
      const queryParts = [];
      
      // 基本パラメータを追加
      Object.entries(baseParams).forEach(([key, value]) => {
        queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
      });
      
      // フィルタパラメータを追加
      Object.entries(filterParams).forEach(([key, value]) => {
        if (Array.isArray(value)) {
          value.forEach(v => {
            queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(v)}`);
          });
        } else {
          queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
        }
      });
      
      const queryString = queryParts.join('&');
      
      console.log(`データ取得開始: ${viewRange.start} ~ ${viewRange.end} (${currentZoomLevel})`);
      
      const url = `/projects/${projectId}/react_gantt_chart/data?${queryString}`;
      console.log('[loadGanttData] リクエストURL:', url);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      // メタデータの活用
      if (data.meta) {
        console.log(`データ取得完了: ${data.meta.returned_count}/${data.meta.total_count}件`);
        
        // パフォーマンス情報の表示
        if (data.performance) {
          console.log(`クエリ時間: ${data.performance.query_time.toFixed(2)}ms`);
        }
        
        // 追加データの必要性チェック
        if (data.meta.has_more) {
          console.warn(ERROR_MESSAGES.DATA_RESTRICTED);
        }
        
        // パフォーマンス監視
        logPerformanceMetrics(startTime, data.meta.returned_count);
      }
      
      // Ganttにデータをセット
      if (ganttInstance) {
        ganttInstance.clearAll();
        
        // データ整合性チェック（大規模プロジェクト対応）
        const validatedData = validateGanttData(data.tasks || [], data.links || []);
        console.log('[loadGanttData] データ検証完了', {
          originalTasks: data.tasks?.length || 0,
          validTasks: validatedData.tasks.length,
          originalLinks: data.links?.length || 0,
          validLinks: validatedData.links.length
        });
        
        ganttInstance.parse({
          data: validatedData.tasks,
          links: validatedData.links
        });
      }
      
      // 成功コールバック
      if (onDataLoaded) {
        onDataLoaded(data);
      }
      
    } catch (error) {
      console.error('ガントデータ取得エラー:', error);
      
      // エラーハンドリング
      handleDataLoadError(error, 'loadGanttData');
      if (onError) {
        onError(error);
      }
      
      // フォールバック: 従来の方式で再試行
      if (!forceReload) {
        console.log(ERROR_MESSAGES.FALLBACK_MODE);
        await loadGanttDataLegacy();
      }
      
    } finally {
      setLoading(false);
    }
  };

  // ズームレベル変更のハンドリング
  const handleZoomChangeWithReload = async (newZoomLevel) => {
    console.log(`ズームレベル変更: ${currentZoomLevel} → ${newZoomLevel}`);
    
    // 状態更新
    setCurrentZoomLevel(newZoomLevel);
    
    // Ganttのズーム設定を更新
    if (ganttInstance) {
      updateZoomConfig(ganttInstance, newZoomLevel);
    }
    
    // 新しい表示範囲でデータを再取得
    await loadGanttData();
  };



  // 親コンポーネントへの状態更新通知
  const updateParentState = () => {
    if (onDataUpdate && ganttInstance) {
      const tasks = getModifiedTasks(ganttInstance, modifiedTasks);
      const links = getModifiedLinks(ganttInstance, modifiedTasks);
      const statistics = getTaskStatistics(ganttInstance);
      
      onDataUpdate({
        modifiedTasks: tasks,
        modifiedLinks: links,
        statistics: statistics
      });
    }
  };

  // タスク選択ハンドラー
  const handleTaskSelected = useCallback((taskId) => {
    setSelectedTaskId(taskId);
    if (viewMode === 'modal') {
      setShowModal(true);
    }
  }, [viewMode]);

  // タスク選択解除ハンドラー
  const handleTaskUnselected = useCallback(() => {
    if (viewMode === 'modal') {
      setShowModal(false);
    }
    // 分割モードでは選択を維持
  }, [viewMode]);

  // ビューモード変更ハンドラー - ページリロードで確実に切り替え
  const handleViewModeChange = useCallback((newMode) => {
    // Cookieに新しいモードを保存
    GanttSettings.setViewMode(newMode);
    
    // 現在選択されているタスクIDも保存（リロード後に復元するため）
    if (selectedTaskId) {
      GanttSettings.setLastSelectedTask(selectedTaskId);
    }
    
    // ページをリロード
    window.location.reload();
  }, [selectedTaskId]);

  // タスク更新ハンドラー（ポーリングから）
  const handleTaskUpdate = useCallback((taskId, data) => {
    // 無限ループを防ぐため、自動データ再取得を無効化
    console.log('タスク更新通知:', taskId, data);
    // if (onDataRequest) {
    //   onDataRequest();
    // }
  }, []);

  // 列入替ハンドラー
  const handleColumnReorder = useCallback((reorderData) => {
    console.log("列が入れ替わりました:", reorderData);
    
    // 列順序がローカルストレージに保存されるため、特にサーバー同期は不要
    // 必要に応じてここで追加のロジックを実装可能
  }, []);

  // TaskDetailPane のリフレッシュハンドラー
  const [taskDetailRefreshKey, setTaskDetailRefreshKey] = useState(0);
  const handleTaskDetailRefresh = useCallback((taskId) => {
    console.log('TaskDetailPane リフレッシュ要求:', taskId);
    // リフレッシュキーを更新してTaskDetailPaneの再描画をトリガー
    setTaskDetailRefreshKey(prev => prev + 1);
  }, []);

  // ローカルフィルタ状態
  const [headerFilters, setHeaderFilters] = useState([]);

  // サーバーサイドフィルタ変更処理（App.jsx一元化版）
  const handleServerFilterChange = async (filterParams) => {
    console.log('サーバーサイドフィルタ変更:', filterParams);
    
    // ローカルフィルタ状態を更新
    setHeaderFilters(filterParams || []);
    
    // 親コンポーネントのフィルタ状態更新（データ再取得はApp.jsxに委譲）
    if (onFilterChange) {
      onFilterChange(filterParams);
    }
    
    // DHMLXGanttChart内でのデータ再取得は行わない（App.jsxに委譲）
  };

  // 初期化
  useEffect(() => {
    if (!ganttRef.current) return;
    
    // コンテナに固定高さを設定（ビューモードに応じて）
    ganttRef.current.style.height = viewMode === 'modal' ? '600px' : '100%';
    ganttRef.current.style.width = '100%';
    ganttRef.current.style.position = 'relative';
    
    // 既存のイベントをクリア
    gantt.clearAll();
    
    // 権限情報を取得
    const permissions = window.ganttPermissions || {};
    
    // 基本設定（権限情報と期間設定を渡す）
    setupGanttConfig(gantt, { 
      projectId, 
      locale: 'ja', 
      permissions, 
      viewStartDate, 
      viewEndDate 
    });
    
    console.log('DHMLXGanttChart: setupGanttConfigに期間を渡す', {
      viewStartDate,
      viewEndDate
    });
    
    // スクロール可能グリッドレイアウトの設定
    setupScrollableGridLayout(gantt);
    
    // 固定カラムのスクロール監視設定
    setupFixedColumnScrolling(gantt);
    
    setupTaskDisplay(gantt);
    setupDateFormats(gantt);
    
    // カラム設定（フィルタ定義を渡す）
    setupColumns(gantt, tasks, visibleColumns);
    
    // 保存された列幅を適用
    applySavedColumnWidths(gantt);
    
    // ハンドラーの作成
    const taskHandlers = createTaskHandlers({
      projectId,
      gantt,
      markModified,
      updateParentState,
      pendingOrder,
      modifiedTasks,
      filters,
      onTaskSelected: handleTaskSelected,
      onTaskDetailRefresh: handleTaskDetailRefresh
    });
    
    const linkHandlers = createLinkHandlers({
      gantt,
      markModified,
      updateParentState
    });
    
    // イベントハンドラーの設定
    setupEventHandlers(gantt, {
      taskHandlers,
      linkHandlers,
      markModified,
      updateParentState,
      pendingOrder,
      setLoading,
      setCriticalPath,
      onTaskSelected: handleTaskSelected,
      onTaskUnselected: handleTaskUnselected
    });
    
    // ヘッダーフィルタハンドラーの作成（サーバーサイド統合版）
    const headerFilterHandlers = createHeaderFilterHandlers({
      onFilterChange: handleServerFilterChange
    });

    // グローバルアクセス用（カラムのボタンから呼び出すため）
    window.ganttComponent = {
      handleCreateSubtask: taskHandlers.handleCreateSubtask,
      handleCreateRootTask: taskHandlers.handleCreateRootTask,
      headerFilterHandlers: headerFilterHandlers,
      handleColumnReorder: handleColumnReorder
    };
    
    // 初期化
    gantt.init(ganttRef.current);
    setGanttInstance(gantt);
    
    // 強制的にスクロールを有効化とドラッグハンドルの生成
    setTimeout(() => {
      gantt.render();
      
      
      // ヘッダーフィルタのイベントリスナーを設定
      if (headerFilterHandlers) {
        headerFilterHandlers.setupEventListeners();
      }
      
      // 権限がある場合、ドラッグ機能を完全に有効化
      if (permissions.canEdit) {
        // simple_drag_fix.jsのアプローチを適用
        const currentData = gantt.serialize();
        gantt.clearAll();
        
        // イベントハンドラーを再設定
        gantt.attachEvent("onBeforeTaskDrag", function(id, mode, e) {
          console.log("ドラッグ開始:", id, mode);
          return true;
        });
        
        gantt.attachEvent("onAfterTaskDrag", function(id, mode, e) {
          console.log("ドラッグ終了:", id, mode);
          gantt.updateTask(id);
          return true;
        });
        
        // データを再パース（初期化フラグ設定）
        isInitializingRef.current = true;
        console.log('gantt.parse前のデータ:', currentData);
        
        // バージョンのデータを確認
        if (currentData && currentData.tasks) {
          const versionTasks = currentData.tasks.filter(t => t.id && t.id.toString().startsWith('version-'));
          console.log('バージョンタスク:', versionTasks);
          
          // 子タスクのデータも確認
          versionTasks.forEach(version => {
            const childTasks = currentData.tasks.filter(t => t.parent === version.id);
            if (childTasks.length > 0) {
              console.log(`Version ${version.id} の子タスク:`, childTasks.slice(0, 3));
            }
          });
        }
        
        gantt.parse(currentData);
        
        
        // パース後のデータを確認
        console.log('gantt.parse後のタスクデータ確認:');
        gantt.eachTask(function(task) {
          if (task.duration < 0) {
            console.log(`負のdurationタスク: ID=${task.id}, text=${task.text}`, {
              start_date: task.start_date,
              end_date: task.end_date,
              duration: task.duration,
              parent: task.parent,
              原データ: currentData.tasks.find(t => t.id === task.id)
            });
          }
        });
        
        isInitializingRef.current = false;
        
        // すべてのタスクを編集可能に（初期化フラグ設定）
        isInitializingRef.current = true;
        gantt.eachTask(function(task) {
          task.$readonly = false;
          task.$no_drag = false;
          task.$no_resize = false;
          task.editable = true;
          gantt.updateTask(task.id);
        });
        isInitializingRef.current = false;
        
        // 統合されたドラッグハンドル作成
        initializeDragHandles(permissions, {
          enableLogging: true
        }).catch(console.error);
      }
      
      // スクロールバーの存在を確認
      console.log('Gantt scroll settings:', {
        scrollable: gantt.config.scrollable,
        scroll_size: gantt.config.scroll_size,
        autosize: gantt.config.autosize,
        container_width: ganttRef.current.offsetWidth
      });
    }, 100);
    
    // クリーンアップ
    return () => {
      // ヘッダーフィルタのイベントリスナーを削除
      if (headerFilterHandlers) {
        headerFilterHandlers.removeEventListeners();
      }
      delete window.ganttComponent;
      gantt.clearAll();
    };
  }, []);

  // データの更新
  useEffect(() => {
    if (!ganttInstance) return;
    
    ganttInstance.clearAll();
    
    if (tasks.length > 0 || links.length > 0) {
      // Issue #737修正確認: 受信データ確認
      const issue737 = tasks.find(task => task.id === 737);
      if (issue737) {
        console.log('Issue #737 found in received data:', issue737);
        console.log('Issue #737 auto_scheduling property:', issue737.auto_scheduling);
      }
      
      // オリジナルデータを保存（日付復元用）
      ganttInstance._originalTaskData = new Map();
      tasks.forEach(task => {
        ganttInstance._originalTaskData.set(task.id, {
          start_date: task.start,
          end_date: task.end
        });
        console.log(`Saving original data for task ${task.id}:`, {
          start: task.start,
          end: task.end
        });
      });
      
      isInitializingRef.current = true;
      console.log("[DHMLXGanttChart] parse前 - タスク数:", tasks.length);
      
      // データ整合性チェック
      const validatedData = validateGanttData(tasks, links);
      console.log("[DHMLXGanttChart] データ検証完了:", {
        originalTasks: tasks.length,
        validTasks: validatedData.tasks.length,
        originalLinks: links.length,
        validLinks: validatedData.links.length
      });
      
      ganttInstance.parse({
        data: validatedData.tasks,
        links: validatedData.links
      });
      console.log("[DHMLXGanttChart] parse後 - カラム再設定は行われていない");
      isInitializingRef.current = false;
      
      
      // データ読み込み後にドラッグハンドルを作成（根本的解決）
      const permissions = window.ganttPermissions || {};
      if (permissions.canEdit) {
        setTimeout(() => {
          // データ再初期化でドラッグハンドルを有効化
          const currentData = ganttInstance.serialize();
          ganttInstance.clearAll();
          
          // ドラッグイベントハンドラー
          ganttInstance.attachEvent("onBeforeTaskDrag", function(id, mode, e) {
            console.log("ドラッグ開始:", id, mode);
            return true;
          });
          
          ganttInstance.attachEvent("onAfterTaskDrag", function(id, mode, e) {
            console.log("ドラッグ終了:", id, mode);
            ganttInstance.updateTask(id);
            return true;
          });
          
          // データを再パース（初期化フラグ設定）
          isInitializingRef.current = true;
          ganttInstance.parse(currentData);
          isInitializingRef.current = false;
          
          
          // タスクを編集可能に（初期化フラグ設定）
          isInitializingRef.current = true;
          ganttInstance.eachTask(function(task) {
            task.$readonly = false;
            task.$no_drag = false;
            task.$no_resize = false;
            task.editable = true;
            ganttInstance.updateTask(task.id);
          });
          isInitializingRef.current = false;
          
          // 統合されたドラッグハンドル更新
          refreshDragHandles(permissions, {
            enableLogging: false
          }).catch(console.error);
        }, 200);
      }
    }
    
    // 変更状態をクリア
    setModifiedTasks(new Set());
    pendingOrder.clear();
  }, [tasks, links, ganttInstance]);

  // ズームレベルの更新
  useEffect(() => {
    if (!ganttInstance) return;
    updateZoomConfig(ganttInstance, currentZoom);
  }, [currentZoom, ganttInstance]);

  // 期間設定の更新
  useEffect(() => {
    if (!ganttInstance) return;
    if (viewStartDate && viewEndDate) {
      console.log('DHMLXGanttChart: 期間設定を更新', { viewStartDate, viewEndDate });
      updateGanttDateRange(ganttInstance, viewStartDate, viewEndDate);
    }
  }, [viewStartDate, viewEndDate, ganttInstance]);

  // カラムの更新
  useEffect(() => {
    if (!ganttInstance) return;
    setupColumns(ganttInstance, tasks, visibleColumns);
    ganttInstance.render();
  }, [visibleColumns, ganttInstance]);

  // クリティカルパスの表示切り替え
  useEffect(() => {
    if (!ganttInstance) return;
    ganttInstance.config.highlight_critical_path = criticalPath;
    ganttInstance.render();
  }, [criticalPath, ganttInstance]);

  // ビューモードに応じた初期高さ設定
  useEffect(() => {
    if (!ganttRef.current) return;
    
    // ビューモードに応じて高さを設定
    if (viewMode === 'modal') {
      ganttRef.current.style.height = '600px';
    } else {
      ganttRef.current.style.height = '100%';
    }
  }, [viewMode]);

  // ResizeObserverでコンテナのサイズ変更を監視
  useEffect(() => {
    if (!ganttInstance || !ganttRef.current) return;
    
    const resizeObserver = new ResizeObserver(() => {
      ganttInstance.setSizes();
      ganttInstance.render();
    });
    
    resizeObserver.observe(ganttRef.current);
    
    return () => {
      resizeObserver.disconnect();
    };
  }, [ganttInstance]);

  // 保存処理
  const handleSave = async () => {
    if (modifiedTasks.size === 0) {
      alert('変更はありません');
      return;
    }
    
    setLoading(true);
    
    try {
      const updates = Array.from(modifiedTasks).map(id => {
        // IDを文字列に変換
        const idStr = String(id);
        if (idStr.startsWith('link_')) {
          // リンクの処理
          const linkId = idStr.replace('link_', '');
          const link = ganttInstance.getLink(linkId);
          return {
            type: 'link',
            data: link
          };
        } else {
          // タスクの処理
          const task = ganttInstance.getTask(id);
          const orderInfo = pendingOrder.get(id) || {};
          
          return {
            type: 'task',
            data: {
              id: parseInt(idStr),
              subject: task.text,
              start_date: task.start_date,
              due_date: ganttInstance.calculateEndDate(task.start_date, task.duration),
              parent_issue_id: task.parent || null,
              ...orderInfo
            }
          };
        }
      });
      
      // 一括更新APIを呼び出し
      const response = await fetch(`/projects/${projectId}/react_gantt_chart/bulk_update`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        credentials: 'same-origin',
        body: JSON.stringify({ issues: updates.filter(u => u.type === 'task').map(u => u.data) })
      });
      
      if (response.ok) {
        const result = await response.json();
        
        // 保存されたチケット情報をログ出力
        if (result.updated_issues && result.updated_issues.length > 0) {
          console.log('=== チケット保存完了 ===');
          result.updated_issues.forEach(issue => {
            console.log(`チケットID: ${issue.id}`);
            console.log(`  件名: ${issue.text || issue.subject}`);
            console.log(`  開始日: ${issue.start || issue.start_date}`);
            console.log(`  終了日: ${issue.end || issue.due_date}`);
            console.log(`  進捗: ${issue.progress || issue.done_ratio}%`);
            console.log(`  担当者: ${issue.assigned_to_name || '未設定'}`);
            console.log(`  ステータス: ${issue.status_name || ''}`);
            console.log(`  トラッカー: ${issue.tracker_name || ''}`);
            console.log('  ---');
          });
          console.log(`合計 ${result.updated_issues.length} 件のチケットが更新されました`);
          console.log('========================');
        }
        
        alert('保存が完了しました');
        
        // 変更状態をクリア
        setModifiedTasks(new Set());
        pendingOrder.clear();
        
        // 無限ループを防ぐため、自動データ再取得を無効化
        console.log('並び順保存完了 - 自動再取得はスキップ');
        // if (onDataRequest) {
        //   onDataRequest();
        // }
      } else {
        throw new Error('保存に失敗しました');
      }
    } catch (error) {
      console.error('Save error:', error);
      alert('保存中にエラーが発生しました: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  // ズーム変更ハンドラー（Cookie保存機能追加）
  const handleZoomChange = (newZoom) => {
    console.log(`ズーム変更: ${currentZoomLevel} → ${newZoom}`);
    
    // 状態更新
    setCurrentZoomLevel(newZoom);
    
    // ViewRangeManagerにズームレベルを保存（Cookie保存含む）
    viewRangeManager.setZoom(newZoom);
    
    // Ganttのズーム設定を更新
    if (ganttInstance) {
      updateZoomConfig(ganttInstance, newZoom);
    }
    
    // 親コンポーネントに通知（App.jsx側でデータ再取得を処理）
    if (onZoomChange) {
      onZoomChange(newZoom);
    }
  };

  // 展開/折りたたみ統合ハンドラー
  const handleToggleAllTasks = () => {
    if (!ganttInstance) return;
    
    console.log('展開/折りたたみトグル実行開始');
    
    // 親タスク（子を持つタスク）を収集
    const parentTasks = [];
    ganttInstance.eachTask((task) => {
      if (ganttInstance.hasChild(task.id)) {
        parentTasks.push(task);
      }
    });
    
    console.log(`親タスク数: ${parentTasks.length}`);
    
    if (parentTasks.length === 0) {
      console.log('親タスクが見つかりません');
      return;
    }
    
    // 現在の展開状態を判定（複数の方法でチェック）
    const expandedCount = parentTasks.filter(task => {
      // 方法1: DHMLXのisTaskOpen API
      if (ganttInstance.isTaskOpen) {
        return ganttInstance.isTaskOpen(task.id);
      }
      // 方法2: $openプロパティ（フォールバック）
      return task.$open !== false;
    }).length;
    
    const allExpanded = expandedCount === parentTasks.length;
    
    console.log(`展開済みタスク: ${expandedCount}/${parentTasks.length}`);
    console.log(`すべて展開済み: ${allExpanded}`);
    
    if (allExpanded) {
      console.log('すべて折りたたみを実行');
      collapseAllTasks(ganttInstance);
    } else {
      console.log('すべて展開を実行');
      expandAllTasks(ganttInstance);
    }
  };

  // フィルタクリアハンドラー
  const handleClearFilters = () => {
    if (window.ganttComponent?.headerFilterHandlers) {
      window.ganttComponent.headerFilterHandlers.clearFilters();
    }
    
    // プロジェクト固有のCookieを削除
    if (projectId) {
      GanttSettings.clearProjectCookies(projectId);
      console.log('フィルタクリア: プロジェクトCookieを削除しました', projectId);
    }
  };

  // 新規タスク作成ハンドラー
  const handleCreateRootTask = () => {
    if (window.ganttComponent?.handleCreateRootTask) {
      window.ganttComponent.handleCreateRootTask();
    }
  };

  // ガントチャートのコンテンツ（常に同じDOM要素）
  const ganttChartElement = (
    <>
      <div ref={ganttRef} className="gantt-chart-container" />
      {loading && (
        <div className="gantt-loading-overlay">
          <div className="gantt-loading-spinner">処理中...</div>
        </div>
      )}
    </>
  );

  // メインレンダリング
  return (
    <div className={`dhtmlx-gantt-container ${viewMode === 'split' ? 'dhtmlx-gantt-container--split' : ''}`}>
      {/* ガントツールバー */}
      <GanttToolbar
        modifiedTasksCount={modifiedTasks.size}
        loading={loading}
        onSave={handleSave}
        onCreateRootTask={handleCreateRootTask}
        onToggleAllTasks={handleToggleAllTasks}
        onClearFilters={handleClearFilters}
        currentZoom={currentZoom}
        onZoomChange={handleZoomChange}
        viewMode={viewMode}
        onViewModeChange={handleViewModeChange}
        viewStartDate={viewStartDate}
        viewEndDate={viewEndDate}
        onViewRangeChange={onViewRangeChange}
        criticalPath={criticalPath}
        onCriticalPathChange={setCriticalPath}
        gantt={ganttInstance}
        disabled={loading}
      />
      
      {viewMode === 'split' ? (
        <SplitLayout
          leftPane={ganttChartElement}
          rightPane={
            <TaskDetailPane
              taskId={selectedTaskId}
              projectId={projectId}
              onTaskUpdate={handleTaskUpdate}
              refreshKey={taskDetailRefreshKey}
            />
          }
        />
      ) : (
        <>
          {ganttChartElement}
          {showModal && selectedTaskId && (
            <RedmineIframeModal
              taskId={selectedTaskId}
              onClose={() => setShowModal(false)}
            />
          )}
        </>
      )}
      
      {/* 列幅調整コントロール（モーダル） */}
    </div>
  );
};

export default DHMLXGanttChart;