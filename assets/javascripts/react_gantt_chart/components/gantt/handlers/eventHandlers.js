// ガントチャートのイベントハンドラー設定

// 列幅調整機能のインポート
import { adjustColumnWidth } from '../utils/columnResize';
// ハイライト関数のインポート
import { highlightTask } from '../utils/helpers';

// 開発環境用ログ関数
const isDev = process.env.NODE_ENV === 'development';
const devLog = isDev ? console.log.bind(console) : () => {};

// デバウンス用タイムアウトを格納
let highlightTimeout = null;

export const setupEventHandlers = (gantt, config) => {
  const {
    taskHandlers,
    linkHandlers,
    markModified,
    updateParentState,
    pendingOrder,
    setLoading,
    setCriticalPath,
    onTaskSelected,
    onTaskUnselected,
  } = config;

  // タスク関連イベント
  setupTaskEvents(
    gantt,
    taskHandlers,
    markModified,
    updateParentState,
    pendingOrder,
    onTaskSelected,
    onTaskUnselected
  );

  // リンク関連イベント
  setupLinkEvents(gantt, linkHandlers);

  // UI関連イベント
  setupUIEvents(gantt, setLoading, setCriticalPath);

  // その他のイベント
  setupMiscEvents(gantt);
  
  // クリーンアップ関数を返す
  return () => {
    // タイムアウトのクリーンアップ
    if (highlightTimeout) {
      clearTimeout(highlightTimeout);
      highlightTimeout = null;
    }
  };
};

// タスク関連イベントの設定
const setupTaskEvents = (
  gantt,
  handlers,
  markModified,
  updateParentState,
  pendingOrder,
  onTaskSelected,
  onTaskUnselected
) => {
  // タスク移動前チェック
  gantt.attachEvent("onBeforeTaskMove", function (id, parent, tindex) {
    return handlers.handleMoveTask(id, parent, tindex);
  });

  // タスク更新前チェック（インライン編集用）
  gantt.attachEvent("onBeforeTaskUpdate", function (id, item) {
    return handlers.validateTaskData(id, item);
  });

  // タスク更新後処理
  gantt.attachEvent("onAfterTaskUpdate", function (id, item) {
    markModified(id);
    updateParentState();
    
    // 子タスクが更新された場合、親タスクの日付を再計算
    if (gantt.isTaskExists(id)) {
      const task = gantt.getTask(id);
      if (task && task.parent) {
        updateParentDates(gantt, task.parent);
      }
    }
  });

  // タスク移動後処理
  gantt.attachEvent("onAfterTaskMove", function (id, parent, tindex) {
    if (!gantt.isTaskExists(id)) {
      console.warn(`Task ${id} does not exist after move`);
      return;
    }
    const task = gantt.getTask(id);
    const moveInfo = pendingOrder.get(id);

    if (moveInfo && moveInfo.operation === "parent_change") {
      console.log(`親子関係変更完了: "${task.text}"`, {
        newParent: parent === 0 ? "ルート" : gantt.getTask(parent)?.text,
        position: tindex,
      });

      // 親子関係変更時は即座にAPIへ送信準備
      markModified(id);

      // 視覚的フィードバック
      highlightTask(id);
    }

    updateParentState();
  });

  // タスクダブルクリック（編集モード）
  gantt.attachEvent("onTaskDblClick", function (id, e) {
    // デフォルトのライトボックスを無効化
    return false;
  });

  // タスク選択
  gantt.attachEvent("onTaskSelected", function (id) {
    console.log("Task selected:", id);
    if (onTaskSelected && typeof onTaskSelected === "function") {
      onTaskSelected(id);
    }
  });

  // タスク選択解除
  gantt.attachEvent("onTaskUnselected", function (id) {
    console.log("Task unselected:", id);
    if (onTaskUnselected && typeof onTaskUnselected === "function") {
      onTaskUnselected(id);
    }
  });

  // 行ドラッグ&ドロップ - ドラッグ終了
  gantt.attachEvent("onRowDragEnd", function (id, target) {
    try {
      if (!gantt.isTaskExists(id)) {
        console.warn(`Task ${id} does not exist after drag`);
        return;
      }
      const task = gantt.getTask(id);
      console.log("Row drag completed:", {
        task: task.text,
        newParent: task.parent,
        newIndex: gantt.getTaskIndex(id)
      });
      
      // 楽観的ロックのためのタイムスタンプを記録
      task.$move_timestamp = new Date().getTime();
      
      // タスクを変更済みとしてマーク
      markModified(id);
      updateParentState();
      
      // 視覚的フィードバック
      highlightTask(id);
    } catch (error) {
      console.error("Row drag error:", error);
      // undo機能が利用可能な場合は使用
      if (gantt.undo && typeof gantt.undo === 'function') {
        try {
          gantt.undo();
          console.log("Changes rolled back");
        } catch (undoError) {
          console.error("Undo failed:", undoError);
        }
      }
      alert("タスクの移動に失敗しました。画面を更新してください。");
    }
  });

  // ドラッグ開始
  gantt.attachEvent("onBeforeTaskDrag", function (id, mode, e) {
    if (!gantt.isTaskExists(id)) {
      console.warn(`Task ${id} does not exist before drag`);
      return false;
    }
    const task = gantt.getTask(id);
    console.log("Drag started:", task.text, "Mode:", mode);
    
    // 親タスク（子タスクを持つタスク）の場合
    if (gantt.hasChild(id)) {
      if (mode === "move") {
        // 移動（期間のシフト）は許可
        console.log("Parent task move allowed:", task.text);
        // 元の位置を保存（キャンセル時の復元用）
        task.$originalStart = new Date(task.start_date);
        task.$originalEnd = task.end_date ? new Date(task.end_date) : null;
        return true;
      } else if (mode === "resize") {
        // リサイズ（期間の変更）は禁止
        console.log("Parent task resize disabled:", task.text);
        return false;
      }
    }
    
    return true;
  });

  // ドラッグ終了
  gantt.attachEvent("onAfterTaskDrag", function (id, mode, e) {
    if (!gantt.isTaskExists(id)) {
      console.warn(`Task ${id} does not exist after drag`);
      return;
    }
    const task = gantt.getTask(id);
    console.log("Drag ended:", task.text, "Mode:", mode);
    
    // 親タスクの移動の場合
    if (mode === "move" && gantt.hasChild(id)) {
      // 移動量を計算
      const originalStart = task.$originalStart;
      if (originalStart) {
        const diff = task.start_date.getTime() - originalStart.getTime();
        
        if (diff !== 0) {
          console.log(`Parent task "${task.text}" moved by ${diff / (1000 * 60 * 60 * 24)} days`);
          
          // バッチ更新で全ての子タスクを移動
          gantt.batchUpdate(() => {
            shiftChildTasks(gantt, id, diff, markModified);
          });
          
          // 移動した親タスクも変更済みとしてマーク
          markModified(id);
        }
        
        // 一時的なプロパティをクリーンアップ
        delete task.$originalStart;
        delete task.$originalEnd;
      }
      
      // ハイライトをクリア
      clearAffectedHighlight();
    } else {
      // 通常のタスクドラッグ
      markModified(id);
      
      // 子タスクがドラッグされた場合、親タスクの日付を再計算
      if (task && task.parent) {
        updateParentDates(gantt, task.parent);
      }
    }
    
    updateParentState();
  });
  
  // ドラッグキャンセル時の処理
  gantt.attachEvent("onBeforeTaskChanged", function(id, mode, e) {
    if (!gantt.isTaskExists(id)) {
      console.warn(`Task ${id} does not exist before change`);
      return false;
    }
    const task = gantt.getTask(id);
    
    // ESCキーでのキャンセルなど
    if (e && e.type === "keydown" && e.keyCode === 27) {
      // 一時的なプロパティをクリーンアップ
      delete task.$originalStart;
      delete task.$originalEnd;
      
      // ハイライトをクリア
      clearAffectedHighlight();
      
      return false; // 変更をキャンセル
    }
    
    return true;
  });
};

// リンク関連イベントの設定
const setupLinkEvents = (gantt, handlers) => {
  // リンク作成前チェック
  gantt.attachEvent("onBeforeLinkAdd", function (id, link) {
    return handlers.validateLinkCreation(link);
  });

  // リンク作成後処理
  gantt.attachEvent("onAfterLinkAdd", function (id, link) {
    handlers.handleLinkCreated(id, link);
  });

  // リンク削除前チェック
  gantt.attachEvent("onBeforeLinkDelete", function (id, link) {
    return handlers.validateLinkDeletion(link);
  });

  // リンク削除後処理
  gantt.attachEvent("onAfterLinkDelete", function (id, link) {
    handlers.handleLinkDeleted(id, link);
  });

  // リンク更新前チェック
  gantt.attachEvent("onBeforeLinkUpdate", function (id, link) {
    return handlers.validateLinkUpdate(link);
  });

  // リンク更新後処理
  gantt.attachEvent("onAfterLinkUpdate", function (id, link) {
    handlers.handleLinkUpdated(id, link);
  });
};

// UI関連イベントの設定
const setupUIEvents = (gantt, setLoading, setCriticalPath) => {
  // ドラッグ中のイベント
  gantt.attachEvent("onTaskDrag", function(id, mode, task, original) {
    if (gantt.hasChild(id) && mode === "move") {
      // デバウンス処理でパフォーマンスを最適化
      if (highlightTimeout) {
        clearTimeout(highlightTimeout);
      }
      highlightTimeout = setTimeout(() => {
        highlightAffectedTasks(gantt, id);
      }, 50);
    }
  });
  // データ処理開始
  gantt.attachEvent("onBeforeDataRender", function () {
    setLoading(true);
    return true;
  });

  // データ処理完了
  gantt.attachEvent("onDataRender", function () {
    setLoading(false);
  });

  // グリッドのリサイズ
  gantt.attachEvent("onGridResizeEnd", function (old_width, new_width) {
    console.log("Grid resized from", old_width, "to", new_width);
  });

  // 列幅変更イベント
  gantt.attachEvent("onAfterColumnResize", function (columnName, newWidth, oldWidth) {
    console.log("[EventHandler] 列幅変更:", { columnName, newWidth, oldWidth });
    
    // 列幅を調整して保存
    adjustColumnWidth(gantt, columnName, newWidth);
  });

  // スケール変更
  gantt.attachEvent("onScaleAdjusted", function () {
    console.log("Scale adjusted");
  });

  // コンテキストメニュー
  gantt.attachEvent("onContextMenu", function (taskId, linkId, e) {
    if (taskId) {
      // タスクのコンテキストメニュー
      e.preventDefault();
      // カスタムコンテキストメニューを表示
      return false;
    }
    return true;
  });
};

// その他のイベント設定
const setupMiscEvents = (gantt) => {
  // エラーハンドリング
  gantt.attachEvent("onError", function (errorMessage) {
    // Task not found エラーの場合はワーニングレベルで出力し、詳細な情報を追加
    if (errorMessage.includes('Task not found')) {
      console.warn("Gantt warning:", errorMessage, "- This may occur during filtering when tasks are removed from the display");
      
      // フィルタ関連のTask not foundエラーの場合は、より詳しい情報を出力
      const match = errorMessage.match(/Task not found id=(.+)$/);
      if (match) {
        const taskId = match[1];
        console.warn(`Task ${taskId} was likely removed by current filter conditions`);
      }
    } else {
      // その他のエラーはエラーレベルで出力
      console.error("Gantt error:", errorMessage);
    }
    return true;
  });

  // DHMLXGanttのデフォルトスクロール機能を使用（カスタムスクロール処理は削除）

  // パース完了 - 汎用的な日付復元処理
  gantt.attachEvent("onParse", function () {
    console.log("Data parsed successfully");
    
    // オリジナルデータを保存（parse時に利用可能）
    const originalTaskData = gantt._originalTaskData || new Map();
    console.log('Original task data available:', originalTaskData.size, 'tasks');
    
    // parse完了後に強制的にオリジナル日付を復元
    setTimeout(() => {
      console.log("=== 汎用的日付復元開始 ===");
      
      gantt.batchUpdate(() => {
        gantt.eachTask(task => {
          // オリジナルデータが存在する場合のみ復元
          const original = originalTaskData.get(task.id);
          if (original && original.start_date) {
            const originalStartDate = gantt.date.parseDate(original.start_date, "%Y-%m-%d");
            const originalEndDate = original.end_date 
              ? gantt.date.parseDate(original.end_date, "%Y-%m-%d")
              : null;
            
            // 現在の日付と比較して変更されている場合のみ復元
            const currentStart = gantt.date.date_to_str("%Y-%m-%d")(task.start_date);
            if (currentStart !== original.start_date) {
              console.log(`Task ${task.id} 日付復元:`, {
                現在: currentStart,
                正しい値: original.start_date
              });
              
              // 強制的に正しい日付を設定
              task.start_date = originalStartDate;
              if (originalEndDate) {
                task.end_date = originalEndDate;
                task.duration = gantt.calculateDuration(task.start_date, task.end_date);
              }
              
              // 内部データを更新
              gantt.refreshTask(task.id);
            }
          }
        });
      });
      
      console.log("=== 汎用的日付復元完了 ===");
    }, 100); // parse完了の直後に実行
  });

  // クリア完了
  gantt.attachEvent("onClear", function () {
    console.log("Gantt cleared");
  });

  // 自動スケジューリング関連（無効化）
  gantt.attachEvent("onBeforeAutoSchedule", function () {
    return false; // 自動スケジューリングを無効化
  });

  // タスクのロード
  gantt.attachEvent("onTaskLoading", function (task) {
    // タスクデータの前処理
    
    // デバッグ: 元のデータを確認
    if (task.id === 104 || task.id === 721 || task.id === 723 || task.id === 727) {
      console.log(`Task ${task.id} before mapping:`, {
        id: task.id,
        text: task.text,
        start: task.start,
        end: task.end,
        start_date: task.start_date,
        end_date: task.end_date,
        duration: task.duration,
        parent: task.parent
      });
    }
    
    // タスクのタイプを明示的に設定（プロジェクトタイプを防ぐ）
    if (!task.type) {
      task.type = 'task';
    }

    // バックエンドのフィールド名をDHTMLX Ganttの期待する名前にマッピング
    if (task.start && !task.start_date) {
      task.start_date = task.start;
      delete task.start; // 元のフィールドを削除
    }
    if (task.end && !task.end_date) {
      task.end_date = task.end;
      delete task.end; // 元のフィールドを削除
    }

    // 日付文字列をDateオブジェクトに変換
    if (task.start_date && typeof task.start_date === "string") {
      // 日付パース前の値を保存（デバッグ用）
      const originalStartStr = task.start_date;
      task.start_date = gantt.date.parseDate(task.start_date, "xml_date");
      
      // パース後の確認
      if (task.id === 104 || task.id === 721 || task.id === 723 || task.id === 727 || task.id === 735) {
        console.log(`Task ${task.id}: start_date parse:`, {
          original: originalStartStr,
          parsed: task.start_date,
          formatted: gantt.date.date_to_str("%Y-%m-%d")(task.start_date)
        });
      }
    }
    if (task.end_date && typeof task.end_date === "string") {
      // 日付パース前の値を保存（デバッグ用）
      const originalEndStr = task.end_date;
      task.end_date = gantt.date.parseDate(task.end_date, "xml_date");
      
      // パース後の確認
      if (task.id === 104 || task.id === 721 || task.id === 723 || task.id === 727 || task.id === 735) {
        console.log(`Task ${task.id}: end_date parse:`, {
          original: originalEndStr,
          parsed: task.end_date,
          formatted: gantt.date.date_to_str("%Y-%m-%d")(task.end_date)
        });
      }
    }
    
    // 親タスクの場合はスタイルを適用（ただし、hasChildはまだ利用できない可能性がある）
    // onTaskLoadingイベントの時点では親子関係がまだ確立されていない可能性があるため、
    // スタイル適用は後で行う
    
    // durationの計算（end_dateがある場合）
    if (task.start_date && task.end_date) {
      const calculatedDuration = gantt.calculateDuration(task.start_date, task.end_date);
      if (task.duration !== calculatedDuration) {
        console.log(`Task ${task.id}: duration mismatch - given: ${task.duration}, calculated: ${calculatedDuration}`);
        // durationを正しい値に修正
        task.duration = calculatedDuration;
      }
    }
    
    // デバッグ: 変換後のデータを確認
    if (task.id === 104 || task.id === 721 || task.id === 723 || task.id === 727 || task.id === 735) {
      console.log(`Task ${task.id} after mapping:`, {
        id: task.id,
        text: task.text,
        start_date: task.start_date,
        end_date: task.end_date,
        duration: task.duration,
        parent: task.parent,
        $has_child: task.$has_child
      });
    }
    
    return true;
  });

  // リンクのロード
  gantt.attachEvent("onLinkLoading", function (link) {
    // リンクデータの前処理

    // リンクタイプの変換（文字列から数値へ）
    if (typeof link.type === "string") {
      const typeMapping = {
        finish_to_start: "0",
        start_to_start: "1",
        finish_to_finish: "2",
        start_to_finish: "3",
        precedes: "0",
        follows: "0",
      };
      link.type = typeMapping[link.type] || "0";
    }

    // リンクタイプが数値でない場合はデフォルト値を設定
    if (!["0", "1", "2", "3"].includes(String(link.type))) {
      console.warn("Invalid link type:", link.type, "Setting to default (0)");
      link.type = "0";
    }

    // IDの数値変換
    if (typeof link.source === "string") {
      link.source = parseInt(link.source, 10);
    }
    if (typeof link.target === "string") {
      link.target = parseInt(link.target, 10);
    }

    return true;
  });
};

// DHMLXGanットのデフォルトスクロール機能を使用
// カスタムスクロール処理は削除し、DHMLXGanttの内蔵機能に任せる

// ヘルパー関数

// 最大ネスト深さの制限
const MAX_NESTING_DEPTH = 10;

// 子タスクを再帰的にシフト（深さ制限付き）
const shiftChildTasks = (gantt, parentId, diffMs, markModified, depth = 0) => {
  // 深さ制限チェック
  if (depth > MAX_NESTING_DEPTH) {
    console.warn('Maximum nesting depth reached');
    return;
  }
  
  const children = gantt.getChildren(parentId);
  
  children.forEach(childId => {
    try {
      const child = gantt.getTask(childId);
      
      // start_dateのnullチェック
      if (!child.start_date) {
        console.warn(`Child task ${childId} has no start date`);
        return;
      }
      
      // 日付をシフト
      const newStartDate = new Date(child.start_date.getTime() + diffMs);
      const newEndDate = child.end_date ? new Date(child.end_date.getTime() + diffMs) : null;
      
      child.start_date = newStartDate;
      if (newEndDate) {
        child.end_date = newEndDate;
      }
      
      // UIを更新
      gantt.updateTask(childId);
      
      // 変更済みとしてマーク
      markModified(childId);
      
      // 孫タスクも再帰的に処理（深さを増やして）
      if (gantt.hasChild(childId)) {
        shiftChildTasks(gantt, childId, diffMs, markModified, depth + 1);
      }
    } catch (error) {
      console.error(`Error shifting child task ${childId}:`, error);
    }
  });
};


// 影響を受けるタスクをハイライト
const highlightAffectedTasks = (gantt, parentId) => {
  const children = gantt.getChildren(parentId);
  children.forEach(childId => {
    const el = document.querySelector(`[task_id="${childId}"]`);
    if (el) {
      el.classList.add('affected-by-parent-drag');
    }
    // 再帰的に孫タスクも
    if (gantt.hasChild(childId)) {
      highlightAffectedTasks(gantt, childId);
    }
  });
};

// ハイライトをクリア
const clearAffectedHighlight = () => {
  document.querySelectorAll('.affected-by-parent-drag').forEach(el => {
    el.classList.remove('affected-by-parent-drag');
  });
};

// highlightTask関数はutils/helpersからインポート済み

// タスクの終了日を取得するヘルパー関数
const getTaskEndDate = (gantt, task) => {
  if (task.end_date) {
    return task.end_date;
  }
  const defaultDuration = gantt.config.duration_unit === 'day' ? 1 : 0;
  return gantt.calculateEndDate(task.start_date, task.duration || defaultDuration);
};

// 親タスクのスタイルを適用
const applyParentTaskStyle = (gantt, task) => {
  if (gantt.hasChild(task.id)) {
    // ドラッグは許可、リサイズのみ無効
    task.$no_resize = true;
    task.$css = 'parent-task-computed';
    // $no_dragは設定しない（移動は可能にする）
  }
};

// 親タスクの日付更新用のデバウンス処理
const parentUpdateQueue = new Set();
let parentUpdateTimeout = null;

const debouncedParentUpdate = (gantt) => {
  if (parentUpdateTimeout) {
    clearTimeout(parentUpdateTimeout);
  }
  
  parentUpdateTimeout = setTimeout(() => {
    const parentsToUpdate = Array.from(parentUpdateQueue);
    parentUpdateQueue.clear();
    
    // 上位の親から順番に処理（重複を避けるため）
    const sortedParents = parentsToUpdate.sort((a, b) => {
      // 階層の浅い順（親から子へ）
      const depthA = getTaskDepth(gantt, a);
      const depthB = getTaskDepth(gantt, b);
      return depthA - depthB;
    });
    
    sortedParents.forEach(parentId => {
      updateParentDatesImmediate(gantt, parentId);
    });
  }, 50); // 50ms のデバウンス
};

const getTaskDepth = (gantt, taskId) => {
  let depth = 0;
  let currentId = taskId;
  
  while (currentId) {
    try {
      // タスクの存在確認を先に行う
      if (!gantt.isTaskExists(currentId)) {
        console.warn(`Task ${currentId} does not exist during depth calculation`);
        break;
      }
      const task = gantt.getTask(currentId);
      if (!task || !task.parent) break;
      currentId = task.parent;
      depth++;
    } catch (e) {
      console.warn(`Error accessing task ${currentId} during depth calculation:`, e.message);
      break;
    }
  }
  return depth;
};

// 親タスクの日付を再計算（デバウンス版）
const updateParentDates = (gantt, parentId) => {
  if (!parentId || parentId === 0) return;
  
  // キューに追加してデバウンス処理
  parentUpdateQueue.add(parentId);
  debouncedParentUpdate(gantt);
};

// 即座に親タスクの日付を再計算（内部用）
const updateParentDatesImmediate = (gantt, parentId) => {
  
  try {
    if (!parentId || parentId === 0) return;
    
    // タスクの存在確認を先に行う
    if (!gantt.isTaskExists(parentId)) {
      console.warn(`Parent task ${parentId} does not exist`);
      return;
    }
    
    const parent = gantt.getTask(parentId);
    if (!parent) {
      console.warn(`Parent task ${parentId} not found`);
      return;
    }
    
    const children = gantt.getChildren(parentId);
    if (!children || children.length === 0) return;
    
    let minStart = null;
    let maxEnd = null;
    
    // 全ての子タスクから最早開始日と最遅終了日を取得
    children.forEach(childId => {
      try {
        // 子タスクの存在確認を先に行う
        if (!gantt.isTaskExists(childId)) {
          console.warn(`Child task ${childId} does not exist in parent ${parentId}`);
          return;
        }
        const child = gantt.getTask(childId);
        if (child && child.start_date) {
          const childStart = child.start_date;
          const childEnd = getTaskEndDate(gantt, child);
          
          console.log(`親タスク${parentId}の子タスク ${childId} (${child.text}) の期間:`, {
            start: childStart,
            end: childEnd,
            duration: child.duration,
            hasChild: gantt.hasChild(childId)
          });
          
          if (!minStart || childStart < minStart) {
            minStart = childStart;
          }
          if (!maxEnd || childEnd > maxEnd) {
            maxEnd = childEnd;
          }
        }
      } catch (error) {
        console.error(`Error processing child task ${childId}:`, error);
      }
    });
    
    // 親タスクの日付を更新
    if (minStart && maxEnd) {
      devLog(`親タスク ${parentId} の日付を更新:`, {
        oldStart: parent.start_date,
        oldEnd: parent.end_date,
        newStart: minStart,
        newEnd: maxEnd
      });
      
      parent.start_date = new Date(minStart);
      parent.end_date = new Date(maxEnd);
      parent.duration = gantt.calculateDuration(parent.start_date, parent.end_date);
      
      // 親タスクのスタイルを適用
      applyParentTaskStyle(gantt, parent);
      
      // UIを更新（gantt.refreshTaskで視覚的な更新のみ）
      gantt.refreshTask(parentId);
      
      // 上位の親タスクもキューに追加（デバウンス処理で一括処理される）
      if (parent.parent) {
        parentUpdateQueue.add(parent.parent);
      }
    }
  } catch (error) {
    console.error('Error updating parent dates:', error);
  }
};
