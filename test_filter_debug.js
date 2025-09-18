// フィルタ問題のデバッグ用スクリプト
// 実行: node test_filter_debug.js

console.log("=== フィルタ問題デバッグ開始 ===");

// 1. 初期化時のフィルタオプション確認
console.log("\n1. 初期化時（タスクなし）:");
const emptyTasks = [];
const emptyOptions = buildFilterOptions(emptyTasks);
console.log("フィルタオプション:", JSON.stringify(emptyOptions, null, 2));

// 2. データ取得後のフィルタオプション確認
console.log("\n2. データ取得後（タスクあり）:");
const sampleTasks = [
  {
    id: 1,
    redmine_data: {
      tracker_id: 1,
      tracker_name: "バグ",
      status_id: 1,
      status_name: "新規",
      assigned_to_id: 1,
      assigned_to_name: "田中太郎"
    }
  },
  {
    id: 2,
    redmine_data: {
      tracker_id: 2,
      tracker_name: "機能",
      status_id: 2,
      status_name: "進行中",
      assigned_to_id: 2,
      assigned_to_name: "山田花子"
    }
  }
];
const filledOptions = buildFilterOptions(sampleTasks);
console.log("フィルタオプション:", JSON.stringify(filledOptions, null, 2));

// buildFilterOptions関数の簡易実装（実際のコードを模倣）
function buildFilterOptions(tasks) {
  const options = {
    trackers: [],
    statuses: [],
    assignees: []
  };

  if (!tasks || tasks.length === 0) return options;

  const trackersSet = new Set();
  const statusesSet = new Set();
  const assigneesSet = new Set();

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
  });

  options.trackers = Array.from(trackersSet).map(s => JSON.parse(s));
  options.statuses = Array.from(statusesSet).map(s => JSON.parse(s));
  options.assignees = Array.from(assigneesSet).map(s => JSON.parse(s));

  return options;
}

console.log("\n=== 結論 ===");
console.log("初期化時はフィルタオプションが空になることを確認");
console.log("データ取得後にカラムを再設定する必要がある");