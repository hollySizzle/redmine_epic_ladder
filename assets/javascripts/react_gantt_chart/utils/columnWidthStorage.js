/**
 * 列幅設定を管理するユーティリティ
 */

const COOKIE_KEY = "redmine_react_gantt_column_widths";
const listeners = new Set();

/**
 * 列幅の変更を監視するリスナーを登録
 * @param {Function} listener 列幅が変更された時に呼び出される関数
 * @returns {Function} リスナーの登録解除用関数
 */
export const subscribeToWidthChanges = (listener) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};

/**
 * 全てのリスナーに変更を通知
 * @param {Object} widths 更新された列幅の設定
 */
const notifyListeners = (widths) => {
  listeners.forEach((listener) => {
    try {
      listener(widths);
    } catch (e) {
      console.error("Error in column width change listener:", e);
    }
  });
};

/**
 * Cookieから列幅設定を読み込む
 * @returns {Object} columnId: width のマッピング
 */
export const loadColumnWidths = () => {
  try {
    const cookie = document.cookie
      .split(";")
      .find((row) => row.trim().startsWith(`${COOKIE_KEY}=`));
    if (cookie) {
      const value = cookie.split("=")[1];
      return JSON.parse(decodeURIComponent(value));
    }
  } catch (e) {
    console.error("Failed to load column widths:", e);
  }
  return {};
};

/**
 * 列幅設定をCookieに保存
 * @param {Object} widths columnId: width のマッピング
 */
export const saveColumnWidths = (widths) => {
  try {
    const value = encodeURIComponent(JSON.stringify(widths));
    // 3週間有効なCookieとして保存
    document.cookie = `${COOKIE_KEY}=${value};path=/;max-age=1814400`;
    notifyListeners(widths);
    console.log("Column widths saved:", widths);
  } catch (e) {
    console.error("Failed to save column widths:", e);
  }
};

/**
 * 特定の列の幅を更新
 * @param {string} columnId 列ID
 * @param {number} width 新しい幅
 */
export const updateColumnWidth = (columnId, width) => {
  const widths = loadColumnWidths();
  widths[columnId] = width;
  saveColumnWidths(widths);
};
