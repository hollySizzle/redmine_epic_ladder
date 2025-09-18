
// ガントチャートの基本設定
export const setupGanttConfig = (gantt, config = {}) => {
  const { projectId, locale = 'ja', viewStartDate, viewEndDate } = config;
  
  // 日付フォーマット設定
  gantt.config.date_format = "%Y-%m-%d";
  gantt.config.duration_unit = "day";
  gantt.config.scale_height = 50;
  gantt.config.row_height = 30;
  gantt.config.bar_height = 24;
  gantt.config.min_column_width = 50;
  
  // ツリー構造の設定
  gantt.config.open_tree_initially = true;
  gantt.config.preserve_scroll = true;
  gantt.config.round_dnd_dates = false;
  
  // スクロール設定
  gantt.config.scroll_on_load = true;
  gantt.config.horizontal_scroll_key = "shiftKey";
  gantt.config.keyboard_navigation = true;
  gantt.config.keyboard_navigation_cells = true;
  
  // グリッド設定
  gantt.config.grid_width = 500;
  gantt.config.grid_resize = true;
  gantt.config.show_progress = true;
  gantt.config.show_links = true;
  gantt.config.show_task_cells = true;
  gantt.config.static_background = false;
  gantt.config.branch_loading = false;
  gantt.config.smart_scales = true;
  gantt.config.smart_rendering = true;
  
  // 列の入替機能を有効化
  gantt.config.reorder_grid_columns = true;
  
  // 表示範囲の設定
  if (viewStartDate && viewEndDate) {
    // ユーザー指定の期間を使用
    gantt.config.start_date = new Date(viewStartDate);
    gantt.config.end_date = new Date(viewEndDate);
    console.log('setupGanttConfig: ユーザー指定期間を設定', {
      start: gantt.config.start_date,
      end: gantt.config.end_date
    });
  } else {
    // デフォルトの期間設定
    const today = new Date();
    gantt.config.start_date = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    gantt.config.end_date = new Date(today.getFullYear(), today.getMonth() + 6, 0);
    console.log('setupGanttConfig: デフォルト期間を設定', {
      start: gantt.config.start_date,
      end: gantt.config.end_date
    });
  }
  
  // ドラッグ設定
  gantt.config.drag_move = true;
  gantt.config.drag_resize = true;
  gantt.config.drag_progress = false;
  gantt.config.drag_links = true;
  
  // 行ドラッグ&ドロップ設定
  // 初期設定は通常モード
  gantt.config.order_branch = true;  // 行の並び替えを有効化
  gantt.config.order_branch_free = true;  // 階層間の自由な移動を許可
  
  // 複数選択したタスクの同時移動を有効化
  gantt.config.drag_multiple = true;
  
  // データロード後に大量タスク時はmarkerモードでパフォーマンス最適化
  gantt.attachEvent("onParse", function() {
    const taskCount = gantt.getTaskByTime ? gantt.getTaskByTime().length : 0;
    if (taskCount > 1000 && gantt.config.order_branch !== "marker") {
      gantt.config.order_branch = "marker";  // ドラッグ中は名前のみ表示でパフォーマンス向上
      console.log(`Performance mode enabled for ${taskCount} tasks`);
    }
  });
  
  // 編集設定
  gantt.config.details_on_dblclick = false;
  gantt.config.inline_editors_date_processing = "keepDates";
  
  // 自動スケジューリング無効化
  gantt.config.auto_scheduling = false;
  gantt.config.auto_scheduling_strict = false;
  gantt.config.auto_scheduling_compatibility = false;
  
  // スクロール設定（重要）
  gantt.config.scrollable = true;
  gantt.config.autosize = false;
  gantt.config.fit_tasks = false;
  gantt.config.autoscroll = true;
  gantt.config.autoscroll_speed = 30;
  
  // ローカライズ設定
  if (locale === 'ja') {
    setupJapaneseLocale(gantt);
  }
  
  // ツールチップ設定
  setupTooltipConfig(gantt);
  
  // ライトボックス設定
  setupLightboxConfig(gantt);
  
  // 行ドラッグ&ドロップの視覚的フィードバック
  setupRowDragDropTemplates(gantt);
  
  // 列入替機能の設定
  setupColumnReordering(gantt);
};

// 日本語ローカライズ
const setupJapaneseLocale = (gantt) => {
  gantt.locale = {
    date: {
      month_full: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
      month_short: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
      day_full: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"],
      day_short: ["日", "月", "火", "水", "木", "金", "土"]
    },
    labels: {
      new_task: "新規タスク",
      dhx_save_btn: "保存",
      dhx_cancel_btn: "キャンセル",
      dhx_delete_btn: "削除",
      confirm_deleting: "本当に削除しますか？",
      section_description: "説明",
      section_time: "期間"
    }
  };
};

// ツールチップ設定
const setupTooltipConfig = (gantt) => {
  gantt.plugins({
    tooltip: true,
    marker: true,
    fullscreen: true,
    keyboard_navigation: true,
    undo: true,  // undo/redo機能を有効化
    multiselect: true  // 複数選択機能を有効化
  });
  
  gantt.templates.tooltip_text = function(start, end, task) {
    const dateFormat = gantt.date.date_to_str("%Y-%m-%d");
    
    // 親タスクの場合の特別なメッセージ
    const parentTaskInfo = (task.$has_child || gantt.hasChild(task.id)) ? `
      <div style="background: #fff3cd; color: #856404; padding: 8px; margin: 8px 0; border-radius: 4px; border: 1px solid #ffeaa7;">
        <strong>⚠️ 親タスクの期間は自動計算されます</strong><br/>
        このタスクの期間は子タスクから自動的に計算されます。<br/>
        開始日: 最も早い子タスクの開始日<br/>
        終了日: 最も遅い子タスクの終了日
      </div>
    ` : '';
    
    return `
      <b>${task.text}</b><br/>
      開始日: ${dateFormat(start)}<br/>
      終了日: ${dateFormat(end)}<br/>
      ${task.redmine_data ? `
        担当者: ${task.redmine_data.assigned_to_name || '未割当'}<br/>
        ステータス: ${task.redmine_data.status_name || ''}<br/>
        進捗: ${task.redmine_data.done_ratio || 0}%
      ` : ''}
      ${parentTaskInfo}
    `;
  };
};

// ライトボックス設定
const setupLightboxConfig = (gantt) => {
  gantt.config.lightbox.sections = [
    { name: "description", height: 70, map_to: "text", type: "textarea", focus: true },
    { name: "time", height: 72, map_to: "auto", type: "duration" }
  ];
};

// 行ドラッグ&ドロップの視覚的フィードバック設定
const setupRowDragDropTemplates = (gantt) => {
  // ドロップ可能な場所を視覚的に表示
  gantt.templates.grid_row_class = function(start, end, task) {
    let classes = [];
    
    // ドロップターゲットの場合
    if (task.$drop_target) {
      classes.push("drop-target-row");
    }
    
    // ドラッグ中の行
    if (task.$dragging) {
      classes.push("gantt_row_dragging");
    }
    
    // ハイライトされた行
    if (task.$highlighted) {
      classes.push("gantt_row_highlighted");
    }
    
    return classes.join(" ");
  };
  
  // タスクバーのクラス設定
  gantt.templates.task_row_class = function(start, end, task) {
    let classes = [];
    
    // ドロップターゲットの場合
    if (task.$drop_target) {
      classes.push("drop-target-row");
    }
    
    // ドラッグ中の行
    if (task.$dragging) {
      classes.push("gantt_row_dragging");
    }
    
    return classes.join(" ");
  };
};

// ズーム設定の更新
export const updateZoomConfig = (gantt, zoomLevel) => {
  const zoomConfigs = {
    year: {
      scales: [
        { unit: "year", step: 1, format: "%Y年" },
        { unit: "month", step: 3, format: "%F" }
      ],
      min_column_width: 50,
      scale_height: 50
    },
    quarter: {
      scales: [
        { unit: "year", step: 1, format: "%Y年" },
        { unit: "quarter", step: 1, format: "第%q四半期" }
      ],
      min_column_width: 60,
      scale_height: 50
    },
    month: {
      scales: [
        { unit: "year", step: 1, format: "%Y年" },
        { unit: "month", step: 1, format: "%F" }
      ],
      min_column_width: 50,
      scale_height: 50
    },
    week: {
      scales: [
        { unit: "month", step: 1, format: "%Y年%F" },
        { unit: "week", step: 1, format: "第%W週" }
      ],
      min_column_width: 50,
      scale_height: 50
    },
    day: {
      scales: [
        { unit: "month", step: 1, format: "%Y年%F" },
        { 
          unit: "day", 
          step: 1, 
          format: "%j日(%D)", // 曜日も表示
          css: function(date) {
            // 祝日判定のためのインポート（動的インポートでエラー回避）
            const { isJapaneseHoliday, isWeekend } = require('../../../utils/japaneseHolidays');
            
            // 祝日の場合
            if (isJapaneseHoliday(date)) {
              return "holiday";
            }
            
            // 土日の場合
            if (isWeekend(date)) {
              return "weekend";
            }
            
            return "";
          }
        }
      ],
      min_column_width: 50,
      scale_height: 50
    }
  };
  
  const config = zoomConfigs[zoomLevel] || zoomConfigs.day;
  gantt.config.scales = config.scales;
  gantt.config.min_column_width = config.min_column_width;
  gantt.config.scale_height = config.scale_height;
  
  // タイムラインの表示範囲を明示的に設定
  const today = new Date();
  const start_date = new Date(today.getFullYear(), today.getMonth() - 1, 1);
  const end_date = new Date(today.getFullYear(), today.getMonth() + 6, 0);
  
  gantt.config.start_date = start_date;
  gantt.config.end_date = end_date;
  gantt.config.show_chart = true;
  
  gantt.render();
};

// スクロール可能グリッドレイアウト設定（操作カラム固定）
export const setupScrollableGridLayout = (gantt) => {
  // 操作カラム専用の設定
  const actionsColumnConfig = {
    columns: [
      {
        name: "actions",
        label: "操作",
        width: 75,
        template: function(task) {
          return `
            <div class="gantt-task-actions">
              <button 
                onclick="window.ganttComponent.handleCreateSubtask(${task.id})" 
                class="gantt-add-subtask-btn"
                title="サブタスク追加"
              >
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M8 1V15M1 8H15" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
            </div>
          `;
        }
      }
    ]
  };

  gantt.config.layout = {
    css: "gantt_container",
    cols: [
      {
        // メイングリッド部分（操作カラム以外）
        width: 500,
        minWidth: 200,
        maxWidth: 800,
        rows: [
          {
            view: "grid", 
            scrollX: "gridScroll", 
            scrollable: true, 
            scrollY: "scrollVer",
            bind: "task"
          },
          {
            view: "scrollbar", 
            id: "gridScroll", 
            group: "horizontal"
          }
        ]
      },
      {
        // 操作カラム専用グリッド（固定表示）
        width: 85,
        rows: [
          {
            view: "grid",
            id: "actionsGrid",
            config: actionsColumnConfig,
            bind: "task",
            scrollY: "scrollVer"
          }
        ]
      },
      { resizer: true, width: 1 },
      {
        // タイムライン部分
        rows: [
          {
            view: "timeline", 
            scrollX: "scrollHor", 
            scrollY: "scrollVer"
          },
          {
            view: "scrollbar", 
            id: "scrollHor", 
            group: "horizontal"
          }
        ]
      },
      {
        view: "scrollbar", 
        id: "scrollVer"
      }
    ]
  };
};

// 固定カラム（操作カラム）のスクロール監視設定
export const setupFixedColumnScrolling = (gantt) => {
  gantt.attachEvent("onGanttReady", function () {
    const el = document.querySelector(".gantt_hor_scroll");
    if (el) {
      el.addEventListener('scroll', function () {
        document.documentElement.style.setProperty(
          '--gantt-frozen-column-scroll-left', el.scrollLeft + "px"
        );
      });
    }
    
    // グリッドのスクロールバーも監視
    const gridScrollEl = document.querySelector("#gridScroll");
    if (gridScrollEl) {
      gridScrollEl.addEventListener('scroll', function () {
        document.documentElement.style.setProperty(
          '--gantt-frozen-column-scroll-left', gridScrollEl.scrollLeft + "px"
        );
      });
    }
  });
};

// タスク表示設定
export const setupTaskDisplay = (gantt) => {
  // タスクバーのテキスト表示
  gantt.templates.task_text = function(start, end, task) {
    return task.text;
  };
  
  // タスクのクラス設定
  gantt.templates.task_class = function(start, end, task) {
    const classes = [];
    
    if (task.type === 'milestone') {
      classes.push('gantt-milestone');
    }
    
    if (task.$virtual) {
      classes.push('gantt-virtual');
    }
    
    if (task.critical_task) {
      classes.push('gantt-critical');
    }
    
    return classes.join(' ');
  };
  
  // 進捗バーの表示
  gantt.templates.progress_text = function(start, end, task) {
    return Math.round(task.progress * 100) + "%";
  };
};


// 表示期間を動的に更新する関数
export const updateGanttDateRange = (gantt, viewStartDate, viewEndDate) => {
  if (viewStartDate && viewEndDate) {
    gantt.config.start_date = new Date(viewStartDate);
    gantt.config.end_date = new Date(viewEndDate);
    
    console.log('updateGanttDateRange: 期間を更新', {
      start: gantt.config.start_date,
      end: gantt.config.end_date
    });
    
    // ガントチャートの表示を更新
    gantt.render();
  }
};

// グリッド幅制御のインポート
import { setupGridWidthController } from '../utils/gridWidthController';

// グリッド幅制御の設定関数をエクスポート
export { setupGridWidthController };

// 列入替機能の設定
const setupColumnReordering = (gantt) => {
  // ガントチャートの初期化完了後にイベントを設定
  gantt.attachEvent("onGanttReady", function() {
    const grid = gantt.$ui.getView("grid");
    if (!grid) {
      console.warn("Grid view not found for column reordering setup");
      return;
    }

    // 列ドラッグ開始前のイベント（特定の列のドラッグを制御可能）
    grid.attachEvent("onBeforeColumnDragStart", function(column, index) {
      console.log("列ドラッグ開始前:", column, index);
      
      // textカラム（タスク名）のドラッグを禁止（基本構造を保持）
      if (column.draggedColumn && column.draggedColumn.name === "text") {
        console.log("テキストカラムのドラッグは禁止されています");
        return false;
      }
      
      // IDカラムのドラッグも禁止（基本構造を保持）
      if (column.draggedColumn && column.draggedColumn.name === "id") {
        console.log("IDカラムのドラッグは禁止されています");
        return false;
      }
      
      // 操作カラムのドラッグを禁止（固定表示のため）
      if (column.draggedColumn && column.draggedColumn.name === "actions") {
        console.log("操作カラムのドラッグは禁止されています");
        return false;
      }
      
      return true; // その他の列は移動可能
    });

    // 列ドラッグ中のイベント
    grid.attachEvent("onColumnDragMove", function(column, index) {
      // ドラッグ中の視覚的フィードバックをここで制御可能
      console.log("列ドラッグ中:", column, index);
    });

    // 列入替完了後のイベント
    grid.attachEvent("onAfterColumnReorder", function(object) {
      console.log("列入替完了:", object);
      
      // 列順序の変更をローカルストレージに保存
      saveColumnOrder(gantt);
      
      // カスタムイベントを発火してReactコンポーネントに通知
      if (window.ganttComponent && window.ganttComponent.handleColumnReorder) {
        window.ganttComponent.handleColumnReorder(object);
      }
      
      // 必要に応じてサーバーに列順序を保存
      // saveToDB(object);
    });

    console.log("列入替機能が正常に設定されました");
  });
};

// 列順序管理のインポート
import { saveColumnOrder } from '../utils/columnOrder';

