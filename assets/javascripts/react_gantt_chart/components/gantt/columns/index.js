// ガントチャートのカラム定義

// 列幅調整機能のインポート
import { applySavedColumnWidths } from "../utils/columnResize";
// 列順序機能のインポート
import { loadColumnOrder } from "../utils/columnOrder";

// ヘッダーフィルタHTMLを生成するヘルパー関数
const createFilterHeader = (title, filterType, options = [], filterKey = null) => {
  const key = filterKey || title.toLowerCase();
  
  // フィルタUIを組み込んだヘッダーHTML（初期状態はフィルタ非表示）
  const filterHTML = [
    `<div class='gantt-header-with-filter' data-filter-key='${key}' data-filter-type='${filterType}'>`,
    `  <div class='header-title' onclick='toggleHeaderFilter(this)'>${title}</div>`,
    `  <div class='header-filter-container'>`,
    filterType === 'select' ?
      `    <select class='header-filter' data-filter='${key}' data-filter-type='select'>
           <option value=''>全て</option>
           ${options.map(opt => `<option value='${opt.value || opt}'>${opt.label || opt}</option>`).join('')}
         </select>` :
      filterType === 'date' ?
      `    <input class='header-filter' type='date' data-filter='${key}' data-filter-type='date' placeholder='日付選択'>` :
      `    <input class='header-filter' type='text' placeholder='検索...' data-filter='${key}' data-filter-type='text'>`,
    `  </div>`,
    `</div>`
  ].join('');
  
  return filterHTML;
};

// フィルタ対応基本カラムの定義
export const getBaseColumns = (filterOptions = {}) => [
  {
    name: "id",
    label: createFilterHeader("ID", "text", [], "id"),
    width: 50,
    template: function (task) {
      return "#" + task.id;
    },
  },
  {
    name: "text",
    label: createFilterHeader("タスク名", "text", [], "text"),
    tree: true,
    width: 250,
    resize: true,
    min_width: 180,
    template: function (task) {
      // 長いテキストの場合はツールチップ用のtitle属性を追加
      const text = task.text || '';
      if (text.length > 25) {
        return `<span title="${text}">${text}</span>`;
      }
      return text;
    },
  },
  {
    name: "tracker_name",
    label: createFilterHeader("トラッカー", "select", filterOptions.trackers || [], "tracker_id"),
    width: 100,
    resize: true,
    min_width: 80,
    template: function (task) {
      return task.redmine_data?.tracker_name || "";
    },
  },
  {
    name: "status_name",
    label: createFilterHeader("ステータス", "select", filterOptions.statuses || [], "status_id"),
    width: 100,
    resize: true,
    min_width: 80,
    template: function (task) {
      return task.redmine_data?.status_name || "";
    },
  },
  {
    name: "assigned_to_name",
    label: createFilterHeader("担当者", "select", filterOptions.assignees || [], "assigned_to_id"),
    width: 120,
    resize: true,
    min_width: 100,
    template: function (task) {
      return task.redmine_data?.assigned_to_name || "";
    },
  },
  {
    name: "category_name",
    label: createFilterHeader("カテゴリ", "select", filterOptions.categories || [], "category_id"),
    width: 120,
    resize: true,
    min_width: 100,
    template: function (task) {
      return task.redmine_data?.category_name || "";
    },
  },
  {
    name: "start_date",
    label: createFilterHeader("開始日", "date", [], "start_date"),
    width: 100,
    resize: true,
    min_width: 80,
    align: "center",
    template: function (task) {
      return gantt.templates.date_grid(task.start_date);
    },
  },
  {
    name: "end_date",
    label: createFilterHeader("終了日", "date", [], "due_date"),
    width: 100,
    resize: true,
    min_width: 80,
    align: "center",
    template: function (task) {
      const endDate = gantt.calculateEndDate(task.start_date, task.duration);
      return gantt.templates.date_grid(endDate);
    },
  },
  {
    name: "description",
    label: createFilterHeader("説明", "text", [], "description"),
    width: 200,
    resize: true,
    min_width: 120,
    template: function (task) {
      return task.redmine_data?.description || "";
    },
  },
  {
    name: "actions",
    label: "操作",
    width: 75,
    template: function (task) {
      // サブタスク追加ボタン
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
    },
  },
];

// カスタムフィールドカラムの動的生成
export const getCustomColumns = (tasks) => {
  const customColumns = [];

  if (!tasks || tasks.length === 0) return customColumns;

  // カスタムフィールドを持つタスクを探す
  const sampleTask = tasks.find((task) => task.custom_fields);
  if (!sampleTask || !sampleTask.custom_fields) return customColumns;

  // カスタムフィールドからカラムを生成
  Object.entries(sampleTask.custom_fields).forEach(([key, field]) => {
    customColumns.push({
      name: `redmine_data.custom_fields.${key}.value`,
      label: field.name,
      resize: true,
      min_width: 100,
      template: function (task) {
        return task.redmine_data?.custom_fields?.[key]?.value || "";
      },
    });
  });

  return customColumns;
};

// フィルタオプションを構築（タスクデータから動的生成）
const buildFilterOptions = (tasks) => {
  // APIから提供されたフィルタオプションを優先的に使用
  if (window.ganttFilterOptions) {
    console.log("[buildFilterOptions] APIのフィルタオプション詳細:", window.ganttFilterOptions);
    return {
      trackers: window.ganttFilterOptions.trackers || [],
      statuses: window.ganttFilterOptions.statuses || [],
      assignees: window.ganttFilterOptions.assignees || [],
      categories: window.ganttFilterOptions.categories || []
    };
  }

  // 既存のフォールバック処理（APIが利用できない場合）
  const options = {
    trackers: [],
    statuses: [],
    assignees: [],
    categories: []
  };

  if (!tasks || tasks.length === 0) return options;

  // 重複を避けるためにSetを使用
  const trackersSet = new Set();
  const statusesSet = new Set();
  const assigneesSet = new Set();
  const categoriesSet = new Set();

  console.log("[buildFilterOptions] 最初のタスクのデータ構造:", tasks[0]);
  
  tasks.forEach(task => {
    const redmineData = task.redmine_data || {};
    
    if (redmineData.tracker_name) {
      trackersSet.add(JSON.stringify({
        value: redmineData.tracker_id || redmineData.tracker_name,
        label: redmineData.tracker_name
      }));
    }
    
    if (redmineData.status_name) {
      statusesSet.add(JSON.stringify({
        value: redmineData.status_id || redmineData.status_name,
        label: redmineData.status_name
      }));
    }
    
    if (redmineData.assigned_to_name) {
      assigneesSet.add(JSON.stringify({
        value: redmineData.assigned_to_id || redmineData.assigned_to_name,
        label: redmineData.assigned_to_name
      }));
    }
    
    if (redmineData.category_name) {
      categoriesSet.add(JSON.stringify({
        value: redmineData.category_id || redmineData.category_name,
        label: redmineData.category_name
      }));
    }
  });

  // Setから配列に変換してJSONをパース
  options.trackers = Array.from(trackersSet).map(json => JSON.parse(json));
  options.statuses = Array.from(statusesSet).map(json => JSON.parse(json));
  options.assignees = Array.from(assigneesSet).map(json => JSON.parse(json));
  options.categories = Array.from(categoriesSet).map(json => JSON.parse(json));

  return options;
};

// フィルタオプションをAPIデータから構築
const buildFilterOptionsFromAPI = (filterDefinitions) => {
  const options = {
    trackers: [],
    statuses: [],
    assignees: [],
    categories: []
  };

  if (!filterDefinitions || !filterDefinitions.availableFilters) {
    console.warn('フィルタ定義が利用できません。フォールバック使用。');
    return options;
  }

  const filters = filterDefinitions.availableFilters;

  // トラッカー
  if (filters.tracker_id && filters.tracker_id.values) {
    options.trackers = filters.tracker_id.values.map(([label, value]) => ({
      value: value,
      label: label
    }));
  }

  // ステータス
  if (filters.status_id && filters.status_id.values) {
    options.statuses = filters.status_id.values.map(([label, value]) => ({
      value: value,
      label: label
    }));
  }

  // 担当者
  if (filters.assigned_to_id && filters.assigned_to_id.values) {
    options.assignees = filters.assigned_to_id.values.map(([label, value]) => ({
      value: value,
      label: label
    }));
  }

  // カテゴリ
  if (filters.category_id && filters.category_id.values) {
    options.categories = filters.category_id.values.map(([label, value]) => ({
      value: value,
      label: label
    }));
  }

  console.log('APIから構築したフィルタオプション:', options);
  return options;
};

// カラム設定の適用
export const setupColumns = (gantt, tasks, visibleColumns) => {
  console.log("[setupColumns] 呼び出し - タスク数:", tasks.length);
  
  // フィルタオプションをタスクデータから構築
  const filterOptions = buildFilterOptions(tasks);
  console.log("[setupColumns] フィルタオプション:", filterOptions);
  
  const baseColumns = getBaseColumns(filterOptions);
  const customColumns = getCustomColumns(tasks);
  const allColumns = [...baseColumns, ...customColumns];

  // 操作カラムを除外（専用グリッドで表示するため）
  const columnsWithoutActions = allColumns.filter(
    (col) => col.name !== "actions"
  );

  // visibleColumnsが指定されている場合
  if (visibleColumns && visibleColumns.length > 0) {
    const mappedVisibleColumns = mapVisibleColumns(visibleColumns);

    // カテゴリカラムを強制的に追加（表示されない問題の修正）
    if (!mappedVisibleColumns.includes("category_name")) {
      mappedVisibleColumns.push("category_name");
    }

    // 表示するカラムをフィルタリング（textは常に表示、actionsは除外）
    gantt.config.columns = columnsWithoutActions.filter(
      (col) => mappedVisibleColumns.includes(col.name) || col.name === "text"
    );
  } else {
    // 操作カラム以外の全カラムを表示
    gantt.config.columns = columnsWithoutActions;
  }

  // カラム設定後に保存された列幅を適用
  applySavedColumnWidths(gantt);
  
  // 保存された列順序を復元
  loadColumnOrder(gantt);
};

// visibleColumnsのマッピング
const mapVisibleColumns = (visibleColumns) => {
  const columnMapping = {
    id: "id",
    text: "text",
    tracker_name: "tracker_name",
    status_name: "status_name",
    assigned_to_name: "assigned_to_name",
    category: "category_name",
    start: "start_date",
    end: "end_date",
    details: "description",
  };

  return visibleColumns.map((col) => {
    // カスタムフィールドの場合
    if (col.id && col.id.startsWith("custom_fields_")) {
      const cfKey = col.id.replace("custom_fields_", "");
      return `redmine_data.custom_fields.${cfKey}.value`;
    }
    // 標準フィールドの場合
    return columnMapping[col.id] || col.id;
  });
};

// 日付表示フォーマット
export const setupDateFormats = (gantt) => {
  gantt.templates.date_grid = gantt.date.date_to_str("%Y-%m-%d");
};

// インラインエディタの設定
export const setupInlineEditors = (gantt) => {
  gantt.config.editor_types.custom_editor = {
    show: function (id, column, config, placeholder) {
      // カスタムエディタの表示ロジック
      const html = `<input type='text' id='gantt_editor_${id}'>`;
      placeholder.innerHTML = html;
    },
    hide: function () {
      // エディタを隠す
    },
    set_value: function (value, id, column, node) {
      node.querySelector("input").value = value;
    },
    get_value: function (id, column, node) {
      return node.querySelector("input").value;
    },
    is_changed: function (value, id, column, node) {
      return value !== node.querySelector("input").value;
    },
    focus: function (node) {
      const input = node.querySelector("input");
      input.focus();
      input.select();
    },
  };
};
