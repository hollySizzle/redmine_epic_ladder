/**
 * 列の設定を管理するユーティリティ
 */

const STORAGE_KEY = "redmine_react_gantt_column_settings";
const listeners = new Set();

/**
 * 列設定の変更を監視するリスナーを登録
 * @param {Function} listener 設定が変更された時に呼び出される関数
 * @returns {Function} リスナーの登録解除用関数
 */
export const subscribeToColumnChanges = (listener) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};

/**
 * 全てのリスナーに変更を通知
 * @param {Object} settings 更新された設定
 */
const notifyListeners = (settings) => {
  listeners.forEach((listener) => {
    try {
      listener(settings);
    } catch (e) {
      console.error("Error in column settings change listener:", e);
    }
  });
};

/**
 * Cookieから列設定を読み込む
 * @returns {Object} 列設定
 */
export const loadColumnSettings = () => {
  try {
    const cookie = document.cookie
      .split(";")
      .find((row) => row.trim().startsWith(`${STORAGE_KEY}=`));
    if (cookie) {
      const value = cookie.split("=")[1];
      return JSON.parse(decodeURIComponent(value));
    }
  } catch (e) {
    console.error("Failed to load column settings:", e);
  }
  return {
    visibleColumns: [],
    columnWidths: {},
  };
};

/**
 * 列設定をCookieに保存
 * @param {Object} settings 列設定
 * @param {Array} settings.visibleColumns 表示する列の設定配列
 * @param {Object} settings.columnWidths 列幅の設定
 */
export const saveColumnSettings = (settings) => {
  try {
    const value = encodeURIComponent(JSON.stringify(settings));
    // 3週間有効なCookieとして保存
    document.cookie = `${STORAGE_KEY}=${value};path=/;max-age=1814400`;
    notifyListeners(settings);
    console.log("Column settings saved:", settings);
  } catch (e) {
    console.error("Failed to save column settings:", e);
  }
};

/**
 * 特定の列の幅を更新
 * @param {string} columnId 列ID
 * @param {number} width 新しい幅
 */
export const updateColumnWidth = (columnId, width) => {
  const settings = loadColumnSettings();
  settings.columnWidths = settings.columnWidths || {};
  settings.columnWidths[columnId] = width;
  saveColumnSettings(settings);
};

/**
 * 表示する列の設定を更新
 * @param {Array} columns 表示する列の設定配列
 */
export const updateVisibleColumns = (columns) => {
  const settings = loadColumnSettings();
  settings.visibleColumns = columns;
  saveColumnSettings(settings);
};

/**
 * 保存されている列設定をすべてリセット
 */
export const resetAllColumnSettings = () => {
  try {
    // Cookieを削除
    document.cookie = `${STORAGE_KEY}=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    notifyListeners({ visibleColumns: [], columnWidths: {} });
    console.log("Column settings reset");
  } catch (e) {
    console.error("Failed to reset column settings:", e);
  }
};
