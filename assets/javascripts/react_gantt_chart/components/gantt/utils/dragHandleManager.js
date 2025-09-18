/**
 * ドラッグハンドル管理ユーティリティ
 * 手動DOM操作によるドラッグハンドル作成を集約管理
 */

/**
 * ドラッグハンドルの作成設定
 */
const DEFAULT_CONFIG = {
  // タイミング設定
  initialDelay: 200,    // 初回作成遅延（ms）
  refreshDelay: 100,    // 更新時遅延（ms）
  
  // セレクター設定
  taskSelector: '.gantt_task_line',
  handleSelector: '.gantt_task_drag',
  parentTaskSelector: '.gantt_task_line.parent-task-computed',
  
  // ハンドルクラス
  leftHandleClass: 'gantt_task_drag task_left',
  rightHandleClass: 'gantt_task_drag task_right',
  
  // デバッグ設定
  enableLogging: false,
  logPrefix: '[DragHandle]'
};

/**
 * ドラッグハンドル作成の実行
 * @param {Object} config - 設定オブジェクト
 */
function createDragHandles(config = {}) {
  const { enableLogging, logPrefix, taskSelector, handleSelector, 
          leftHandleClass, rightHandleClass, parentTaskSelector } = config;
  
  if (enableLogging) {
    console.log(`${logPrefix} ドラッグハンドル作成開始`, new Date().toISOString());
  }
  
  let handlesCreated = 0;
  let tasksSkipped = 0;
  
  document.querySelectorAll(taskSelector).forEach((taskEl) => {
    // 親タスクはスキップ
    if (taskEl.matches(parentTaskSelector)) {
      tasksSkipped++;
      return;
    }
    
    // 既存のハンドルを削除
    taskEl.querySelectorAll(handleSelector).forEach(handle => handle.remove());
    
    // 左ハンドル作成
    const leftHandle = document.createElement('div');
    leftHandle.className = leftHandleClass;
    taskEl.appendChild(leftHandle);
    
    // 右ハンドル作成
    const rightHandle = document.createElement('div');
    rightHandle.className = rightHandleClass;
    taskEl.appendChild(rightHandle);
    
    handlesCreated++;
  });
  
  if (enableLogging) {
    console.log(`${logPrefix} 作成完了: ${handlesCreated}個, スキップ: ${tasksSkipped}個`);
  }
  
  return { handlesCreated, tasksSkipped };
}

/**
 * DOMの準備ができているかチェック
 * @param {string} selector - チェック対象のセレクター
 * @returns {boolean}
 */
function isDOMReady(selector) {
  return document.querySelectorAll(selector).length > 0;
}

/**
 * 遅延実行でドラッグハンドルを作成
 * @param {number} delay - 遅延時間（ms）
 * @param {Object} config - 設定
 * @returns {Promise}
 */
function createDragHandlesDelayed(delay, config = {}) {
  const mergedConfig = { ...DEFAULT_CONFIG, ...config };
  
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      try {
        // DOMの準備チェック
        if (!isDOMReady(mergedConfig.taskSelector)) {
          if (mergedConfig.enableLogging) {
            console.warn(`${mergedConfig.logPrefix} DOM未準備のためスキップ`);
          }
          resolve({ handlesCreated: 0, tasksSkipped: 0, skipped: true });
          return;
        }
        
        const result = createDragHandles(mergedConfig);
        resolve(result);
      } catch (error) {
        if (mergedConfig.enableLogging) {
          console.error(`${mergedConfig.logPrefix} エラー:`, error);
        }
        reject(error);
      }
    }, delay);
  });
}

/**
 * Gantt初期化時のドラッグハンドル作成
 * @param {Object} permissions - 権限設定
 * @param {Object} config - カスタム設定
 * @returns {Promise}
 */
export async function initializeDragHandles(permissions = {}, config = {}) {
  if (!permissions.canEdit) {
    return { handlesCreated: 0, tasksSkipped: 0, skipped: true };
  }
  
  const mergedConfig = {
    ...DEFAULT_CONFIG,
    enableLogging: true,
    ...config
  };
  
  return await createDragHandlesDelayed(mergedConfig.initialDelay, mergedConfig);
}

/**
 * データ更新時のドラッグハンドル更新
 * @param {Object} permissions - 権限設定
 * @param {Object} config - カスタム設定
 * @returns {Promise}
 */
export async function refreshDragHandles(permissions = {}, config = {}) {
  if (!permissions.canEdit) {
    return { handlesCreated: 0, tasksSkipped: 0, skipped: true };
  }
  
  const mergedConfig = {
    ...DEFAULT_CONFIG,
    enableLogging: false,  // 更新時はログを抑制
    ...config
  };
  
  return await createDragHandlesDelayed(mergedConfig.refreshDelay, mergedConfig);
}

/**
 * 即座にドラッグハンドルを作成（テスト用）
 * @param {Object} config - 設定
 * @returns {Object}
 */
export function createDragHandlesImmediate(config = {}) {
  const mergedConfig = { ...DEFAULT_CONFIG, ...config };
  return createDragHandles(mergedConfig);
}

/**
 * 設定可能なオプション一覧を取得
 * @returns {Object}
 */
export function getDefaultConfig() {
  return { ...DEFAULT_CONFIG };
}