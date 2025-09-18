import React, { useState, useEffect } from "react";
import DHMLXGanttChart from "./components/DHMLXGanttChart";
// import DHMLXGanttChart from "./components/DHMLXGanttChartNew";
import { loadColumnSettings } from "./utils/columnStorage";
import { GanttSettings } from "./utils/cookieUtils";
import { viewRangeManager } from "./utils/ViewRangeManager";
import DataWarning from "./components/DataWarning";
import ErrorBoundary from "./components/ErrorBoundary";

// 基本列の定義
const baseColumns = [
  { id: "id", header: "ID", width: 50, defaultVisible: true },
  { id: "text", header: "タスク名", defaultVisible: true },
  { id: "tracker_name", header: "トラッカー", defaultVisible: true },
  { id: "status_name", header: "ステータス", defaultVisible: true },
  { id: "assigned_to_name", header: "担当者", defaultVisible: true },
  { id: "category", header: "カテゴリ", defaultVisible: true },
  { id: "start", header: "開始日", defaultVisible: true },
  { id: "end", header: "終了日", defaultVisible: true },
  { id: "details", header: "説明", defaultVisible: false },
];

/**
 * メインAppコンポーネント
 * Flowbite + Tailwind CSSでスタイリングされたGanttチャートアプリケーション
 */
const App = ({ buildTime }) => {
  const [tasks, setTasks] = useState([]);
  const [links, setLinks] = useState([]);
  const [error, setError] = useState(null);
  const [projectId] = useState(() => {
    const pathSegments = window.location.pathname.split("/");
    console.log("URLパスセグメント:", pathSegments);
    const id = pathSegments[2];
    console.log("抽出されたprojectId:", id);
    return id;
  });
  const [availableColumns, setAvailableColumns] = useState(baseColumns);
  const [visibleColumns, setVisibleColumns] = useState(() => {
    // 保存された列設定を読み込む
    const settings = loadColumnSettings();
    if (settings.visibleColumns && settings.visibleColumns.length > 0) {
      return settings.visibleColumns;
    }
    // 保存された設定がない場合はデフォルトを使用
    return baseColumns.filter((col) => col.defaultVisible);
  });
  const [currentFilters, setCurrentFilters] = useState({
    fields: [],
    operators: {},
    values: {}
  });
  const [dataWarning, setDataWarning] = useState(null);
  
  // 権限情報（サーバーから取得するか、デフォルト値を設定）
  const [permissions] = useState(() => {
    // windowオブジェクトから権限情報を取得
    return window.ganttPermissions || {
      canEdit: true,
      canDelete: true,
      canAdd: true,
      canView: true
    };
  });
  
  // ロケール情報
  const [locale] = useState(() => {
    // windowオブジェクトからロケール情報を取得
    return window.ganttLocale || 'ja';
  });
  
  
  // ズーム状態
  const [currentZoom, setCurrentZoom] = useState(() => {
    // Cookieから保存されたズームレベルを復元
    const savedZoom = viewRangeManager.getCurrentZoom();
    console.log("App.jsx: Cookieから復元されたズームレベル:", savedZoom);
    return savedZoom || 'month';
  });
  
  // 期間設定状態（ViewRangeManagerで統一管理）
  const [viewStartDate, setViewStartDate] = useState(() => {
    const currentRange = viewRangeManager.getCurrentRange();
    console.log('App.jsx: ViewRangeManager からの期間読み込み', currentRange);
    return currentRange?.start || null;
  });
  const [viewEndDate, setViewEndDate] = useState(() => {
    const currentRange = viewRangeManager.getCurrentRange();
    return currentRange?.end || null;
  });

  // -----------------------
  // 初回マウント時に、フィルタ無し（set_filter=1）で1回だけfetch
  // -----------------------
  // additional_issuesからCSSを生成して適用
  const applyAdditionalIssuesStyles = (additionalIssues) => {
    if (!additionalIssues) {
      console.warn("additional_issuesが存在しません");
      return;
    }

    // 既存のstyle要素があれば削除
    const existingStyle = document.getElementById("additional-issues-styles");
    if (existingStyle) {
      existingStyle.remove();
    }

    // カテゴリごとのスタイルを生成
    const cssRules = [];
    for (const [category, issues] of Object.entries(additionalIssues)) {
      if (category === "default") continue;

      if (category === "overdue-task") {
        // 各issueに対してセレクタを生成
        for (const issueId of Object.keys(issues)) {
          cssRules.push(`
          div.wx-row[data-context-id="${issueId}"] {
            color: ${category === "overdue-task" ? "red" : "inherit"};
          }
        `);
        }
      }

      if (category === "closed-task") {
        // 各issueに対してセレクタを生成
        for (const issueId of Object.keys(issues)) {
          cssRules.push(`
          div.wx-row[data-context-id="${issueId}"] {
            color: ${category === "closed-task" ? "#999" : "inherit"};
            text-decoration: ${
              category === "closed-task" ? "line-through" : "none"
            };
          }
        `);
        }
      }
    }

    // style要素を作成してDOMに追加
    const styleElement = document.createElement("style");
    styleElement.id = "additional-issues-styles";
    styleElement.textContent = cssRules.join("\n");
    document.head.appendChild(styleElement);
  };

  // ViewRangeManagerからの変更通知を受信
  useEffect(() => {
    const unsubscribe = viewRangeManager.addListener((range) => {
      console.log('App.jsx: ViewRangeManager変更通知', range);
      if (range) {
        setViewStartDate(range.start);
        setViewEndDate(range.end);
      }
    });
    
    return unsubscribe;
  }, []);

  useEffect(() => {
    console.log('App.jsx: 初期化開始', { viewStartDate, viewEndDate });
    
    // 初期データの取得
    handleFilterApply({
      set_filter: "1",
      fields: [],
      operators: {},
      values: {},
    });
  }, []); // projectIdは初期化時に設定され変更されないため空配列

  // ズーム変更ハンドラー（無限ループを防ぐため手動制御）
  const handleZoomChange = (newZoom) => {
    console.log(`App.jsx: ズーム変更 ${currentZoom} → ${newZoom}`);
    setCurrentZoom(newZoom);
    
    // ViewRangeManagerにズームレベルを保存（Cookie保存含む）
    viewRangeManager.setZoom(newZoom);
    
    // ズーム変更時のデータ再取得
    const updatedFilters = {
      ...currentFilters,
      // ズーム情報は calculateViewRange() で自動計算されるため不要
    };
    handleFilterApply(updatedFilters);
  };

  // 期間変更ハンドラー（ViewRangeManagerで統一処理）
  const handleViewRangeChange = (startDate, endDate) => {
    console.log(`App.jsx: 期間変更 ${startDate} 〜 ${endDate}`);
    console.log('App.jsx: handleViewRangeChange called with:', { startDate, endDate, type_start: typeof startDate, type_end: typeof endDate });
    
    // ViewRangeManagerに期間設定を委譲
    // これにより React/Cookie/Gantt の状態が自動同期される
    viewRangeManager.setRange(startDate, endDate);
  };

  // 状態変更の追跡
  console.log('App.jsx: 現在の期間状態', { viewStartDate, viewEndDate });

  /**
   * 表示範囲の取得（サーバーサイドフィルタリング用）
   */
  const getViewRange = () => {
    // ViewRangeManagerから現在の期間を取得
    const currentRange = viewRangeManager.getCurrentRange();
    return currentRange ? {
      start: currentRange.start,
      end: currentRange.end
    } : {
      start: viewRangeManager.calculateDefaultStartDate(),
      end: viewRangeManager.calculateDefaultEndDate()
    };
  };

  /**
   * データ取得関数（フィルタパラメータを含む）
   * @param {Object} additionalParams - 追加のパラメータ（フィルタなど）
   */
  const loadGanttData = (additionalParams = {}) => {
    console.log("loadGanttData called", additionalParams);
    
    // 現在のフィルタ状態とマージ
    const mergedFilters = {
      fields: currentFilters.fields || [],
      operators: currentFilters.operators || {},
      values: currentFilters.values || {},
      ...additionalParams
    };
    
    // サーバーサイドフィルタ用パラメータを追加
    const viewRange = getViewRange();
    console.log("loadGanttData: 使用する期間", { 
      viewRange, 
      stateStartDate: viewStartDate, 
      stateEndDate: viewEndDate 
    });
    
    const enhancedParams = {
      ...mergedFilters,
      gantt_view: true,
      view_start: viewRange.start,
      view_end: viewRange.end,
      zoom_level: currentZoom
    };
    
    const qs = buildQueryString(enhancedParams);
    const projectId = window.location.pathname.split("/")[2];
    const url = `/projects/${projectId}/react_gantt_chart/data?${qs}`;

    console.log("リクエストURL:", url);
    console.log("プロジェクトID:", projectId);
    console.log("表示範囲:", viewRange);
    console.log("ズームレベル:", currentZoom);
    console.log("フィルタパラメータ:", mergedFilters);

    return fetch(url)
      .then((res) => {
        console.log("APIレスポンス:", res.status);
        if (!res.ok) {
          console.error(`HTTP Error ${res.status}: ${res.statusText}`);
          console.error(`Request URL: ${url}`);
          // 500エラーの詳細をログ出力
          return res.text().then(errorText => {
            console.error('Error response body:', errorText);
            throw new Error(`HTTP ${res.status}: ${res.statusText}`);
          });
        }
        return res.json();
      })
      .then((json) => {
        console.log("取得したデータ:", json);

        // フィルタオプションをグローバルに保存（新規追加）
        if (json.filter_options) {
          window.ganttFilterOptions = json.filter_options;
          // デバッグログ（開発環境のみ）
          if (process.env.NODE_ENV === 'development' || window.location.hostname === 'localhost') {
            console.log("フィルタオプションを保存:", json.filter_options);
          }
        }

        // メタデータの活用
        if (json.meta) {
          console.log(`データ取得完了: ${json.meta.returned_count}/${json.meta.total_count}件`);
          if (json.meta.has_more) {
            console.log("追加データが利用可能です");
          }
          console.log("表示範囲:", json.meta.view_range);
        }
        
        // パフォーマンス情報の表示
        if (json.performance) {
          console.log(`クエリ実行時間: ${json.performance.query_time}ms`);
        }

        // 警告情報の処理
        if (json.warnings) {
          setDataWarning(json.warnings);
          console.warn("データ制限警告:", json.warnings);
        } else {
          setDataWarning(null);
        }

        // additional_issuesからcssクラスを設定
        const tasksWithCss = (json.tasks || []).map((task) => {
          // additional_issuesの各カテゴリをチェック
          for (const [category, issues] of Object.entries(
            json.additional_issues
          )) {
            // デフォルトカテゴリはスキップ
            if (category === "default") continue;

            // タスクIDがこのカテゴリに含まれているか確認
            if (issues[task.id]) {
              return {
                ...task,
                css: category, // 例: overdue-task, closed-task など
              };
            }
          }
          return task;
        });

        console.log('サーバーから取得したデータ:', {
          totalTasks: json.tasks.length,
          negativeDurationTasks: json.tasks.filter(t => t.duration < 0).map(t => ({
            id: t.id,
            text: t.text,
            start: t.start,
            end: t.end,
            duration: t.duration,
            parent: t.parent
          }))
        });
        
        setTasks(tasksWithCss);
        setLinks(json.links || []);

        // additional_issuesのスタイルを適用
        applyAdditionalIssuesStyles(json.additional_issues);

        // カスタムフィールドの列を更新
        if (json.tasks && json.tasks.length > 0) {
          const sampleTask = json.tasks.find((task) => task.custom_fields);
          if (sampleTask) {
            const customColumns = Object.entries(sampleTask.custom_fields).map(
              ([key, field]) => ({
                id: `custom_fields_${key}`,
                header: field.name,
                defaultVisible: false,
              })
            );

            // 既存のカスタムフィールド列を除外して新しい列リストを作成
            const baseOnly = availableColumns.filter(
              (col) => !col.id.startsWith("custom_fields_")
            );
            const newColumns = [...baseOnly, ...customColumns];

            setAvailableColumns(newColumns);

            // 表示中の列も更新（カスタムフィールドの変更を反映）
            const newVisibleColumns = visibleColumns.filter((col) =>
              newColumns.some((nc) => nc.id === col.id)
            );
            setVisibleColumns(newVisibleColumns);
          }
        }

        // カスタムフィールドの列を追加
        if (json.tasks && json.tasks.length > 0) {
          const sampleTask = json.tasks.find((task) => task.custom_fields);
          if (sampleTask) {
            const customColumns = Object.entries(sampleTask.custom_fields).map(
              ([key, field]) => ({
                id: `custom_fields_${key}`,
                header: field.name,
                defaultVisible: false,
              })
            );
            setAvailableColumns([...baseColumns, ...customColumns]);
          }
        }
        
        return json;
      })
      .catch((err) => {
        console.error("データ取得エラー:", err);
        setError(`データ取得に失敗しました: ${err.message}`);
        throw err;
      });
  };

  /**
   * フィルタ適用時に呼ばれる関数
   * => Redmineの /data にリクエストを行い、JSONを取得
   */
  const handleFilterApply = (filterParams) => {
    console.log("handleFilterApply called", filterParams);
    
    // フィルタ状態を更新
    setCurrentFilters({
      fields: filterParams.fields || [],
      operators: filterParams.operators || {},
      values: filterParams.values || {}
    });
    
    // loadGanttDataを使用してデータを取得
    loadGanttData(filterParams);
  };

  // 列設定の変更を処理
  const handleColumnSettingsChange = (newVisibleColumns) => {
    // 列を表示設定の変更時
    if (JSON.stringify(newVisibleColumns) !== JSON.stringify(visibleColumns)) {
      setVisibleColumns(newVisibleColumns);
    }
  };
  
  /**
   * 一括更新ハンドラー
   * @param {Object} updateData - 更新データ
   */
  const handleBulkUpdate = async (updateData) => {
    console.log('一括更新データ:', updateData);
    
    try {
      const url = `/projects/${projectId}/react_gantt_chart/bulk_update`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify(updateData)
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const result = await response.json();
      console.log('一括更新結果:', result);
      
      // データを再読み込み
      await loadGanttData();
    } catch (error) {
      console.error('一括更新エラー:', error);
      setError(`一括更新に失敗しました: ${error.message}`);
    }
  };

  // DHTMLX版のみを使用（SVAR版は削除済み）

  return (
    <div className="app-container">
      {/* エラー表示 */}
      {error && (
        <div className="error-message">
          <strong>エラーが発生しました：</strong>
          <span>{error}</span>
        </div>
      )}

      {/* データ制限警告 */}
      {dataWarning && (
        <DataWarning 
          warning={dataWarning}
          onClose={() => setDataWarning(null)}
        />
      )}


      {/* ガントチャート本体 (DHTMLX版) - Cardを削除して余白を最小化 */}
      <div className="gantt-chart-container">
        <DHMLXGanttChart
          tasks={tasks}
          links={links}
          onDataUpdate={handleBulkUpdate}
          locale={locale}
          currentZoom={currentZoom}
          permissions={permissions}
          projectId={projectId}
          onFilterChange={(filters) => {
            console.log('App: ヘッダーフィルタ変更受信', filters);
            
            // ヘッダーフィルタの形式をRedmineフィルタ形式に変換
            if (filters && filters.length > 0) {
              const filterParams = {
                set_filter: '1',
                fields: [],
                operators: {},
                values: {}
              };
              
              filters.forEach(filter => {
                if (filter && filter.field) {
                  filterParams.fields.push(filter.field);
                  filterParams.operators[filter.field] = filter.operator || '=';
                  filterParams.values[filter.field] = Array.isArray(filter.value) ? filter.value : [filter.value];
                }
              });
              
              console.log('App: 変換後のフィルタパラメータ', filterParams);
              
              // currentFiltersを更新
              setCurrentFilters({
                fields: filterParams.fields,
                operators: filterParams.operators,
                values: filterParams.values
              });
              
              // データ再取得
              loadGanttData(filterParams);
            } else {
              // フィルタクリアの場合
              console.log('App: ヘッダーフィルタクリア');
              setCurrentFilters({
                fields: [],
                operators: {},
                values: {}
              });
              
              // フィルタなしでデータ再取得
              loadGanttData({ set_filter: '1' });
            }
          }}
          loadGanttData={loadGanttData}
          viewStartDate={viewStartDate}
          viewEndDate={viewEndDate}
          onViewRangeChange={handleViewRangeChange}
          visibleColumns={visibleColumns}
          onVisibleColumnsChange={handleColumnSettingsChange}
          filterOptions={window.ganttFilterOptions || { trackers: [], statuses: [], assignees: [] }}
        />
      </div>

      {/* ビルド日情報 */}
      <div className="build-time-info">
        <span>最終ビルド日: {buildTime}</span>
        <span className="badge">DHTMLX Gantt</span>
      </div>
    </div>
  );
};

/**
 * Redmineフィルタ風のパラメータをクエリ文字列に組み立てる関数
 */
function buildQueryString(p) {
  const parts = [];
  parts.push("set_filter=1");

  // ガントビュー最適化フィルタのパラメータ
  if (p.gantt_view) {
    parts.push("gantt_view=true");
  }
  if (p.view_start) {
    parts.push(`view_start=${encodeURIComponent(p.view_start)}`);
  }
  if (p.view_end) {
    parts.push(`view_end=${encodeURIComponent(p.view_end)}`);
  }
  if (p.zoom_level) {
    parts.push(`zoom_level=${encodeURIComponent(p.zoom_level)}`);
  }

  // フィールド
  if (p.fields && p.fields.length) {
    p.fields.forEach((fld) => {
      parts.push(`f[]=${encodeURIComponent(fld)}`);
    });
  }

  // オペレータ
  Object.keys(p.operators || {}).forEach((fld) => {
    const op = p.operators[fld];
    parts.push(`op[${fld}]=${encodeURIComponent(op)}`);
  });

  // 値
  Object.keys(p.values || {}).forEach((fld) => {
    const arr = p.values[fld];
    arr.forEach((val) => {
      parts.push(`v[${fld}][]=${encodeURIComponent(val)}`);
    });
  });

  return parts.join("&");
}

export default App;
