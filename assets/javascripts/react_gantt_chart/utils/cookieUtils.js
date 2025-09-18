/**
 * ガントチャート設定のCookie管理ユーティリティ
 */

/**
 * Cookieを取得
 * @param {string} name - Cookie名
 * @returns {string|null} Cookie値
 */
export function getCookie(name) {
  const nameEQ = name + "=";
  const ca = document.cookie.split(';');
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === ' ') c = c.substring(1, c.length);
    if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
  }
  return null;
}

/**
 * Cookieを設定
 * @param {string} name - Cookie名
 * @param {string} value - Cookie値
 * @param {number} days - 有効期限（日数）
 */
export function setCookie(name, value, days = 365) {
  let expires = "";
  if (days) {
    const date = new Date();
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
    expires = "; expires=" + date.toUTCString();
  }
  document.cookie = name + "=" + (value || "") + expires + "; path=/";
}

/**
 * Cookieを削除
 * @param {string} name - Cookie名
 */
export function deleteCookie(name) {
  document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
}

/**
 * ガントチャート設定管理クラス
 */
export class GanttSettings {
  static COOKIE_NAME = 'redmine_gantt_settings';
  static DEFAULT_SETTINGS = {
    viewMode: 'split', // デフォルトを分割表示に設定
    splitRatio: 0.6,
    lastSelectedTask: null,
    viewStartDate: null,
    viewEndDate: null,
    zoomLevel: 'month',
    showToolbarDetails: true // ツールバー詳細設定の表示状態
  };

  /**
   * 設定を取得
   * @returns {Object} 設定オブジェクト
   */
  static get() {
    const cookieValue = getCookie(this.COOKIE_NAME);
    console.log('GanttSettings.get: cookie生値', cookieValue);
    
    if (!cookieValue) {
      console.log('GanttSettings.get: デフォルト設定を使用');
      return { ...this.DEFAULT_SETTINGS };
    }

    try {
      const decodedValue = decodeURIComponent(cookieValue);
      console.log('GanttSettings.get: デコード後', decodedValue);
      const settings = JSON.parse(decodedValue);
      console.log('GanttSettings.get: パース後の設定', settings);
      const finalSettings = { ...this.DEFAULT_SETTINGS, ...settings };
      console.log('GanttSettings.get: 最終設定', finalSettings);
      return finalSettings;
    } catch (e) {
      console.error('Failed to parse gantt settings:', e, 'cookieValue:', cookieValue);
      return { ...this.DEFAULT_SETTINGS };
    }
  }

  /**
   * 設定を保存
   * @param {Object} settings - 設定オブジェクト
   */
  static set(settings) {
    const currentSettings = this.get();
    const updatedSettings = { ...currentSettings, ...settings };
    const cookieValue = encodeURIComponent(JSON.stringify(updatedSettings));
    setCookie(this.COOKIE_NAME, cookieValue, 365);
  }

  /**
   * 特定の設定値を取得
   * @param {string} key - 設定キー
   * @returns {any} 設定値
   */
  static getValue(key) {
    const settings = this.get();
    console.log(`GanttSettings.getValue(${key}):`, settings[key], 'from settings:', settings);
    return settings[key];
  }

  /**
   * 特定の設定値を更新
   * @param {string} key - 設定キー
   * @param {any} value - 設定値
   */
  static setValue(key, value) {
    const settings = this.get();
    settings[key] = value;
    this.set(settings);
  }

  /**
   * ビューモードを取得
   * @returns {string} 'modal' または 'split'
   */
  static getViewMode() {
    return this.getValue('viewMode');
  }

  /**
   * ビューモードを設定
   * @param {string} mode - 'modal' または 'split'
   */
  static setViewMode(mode) {
    if (mode !== 'modal' && mode !== 'split') {
      console.warn('Invalid view mode:', mode);
      return;
    }
    this.setValue('viewMode', mode);
  }

  /**
   * 分割比率を取得
   * @returns {number} 0.0 - 1.0
   */
  static getSplitRatio() {
    return this.getValue('splitRatio');
  }

  /**
   * 分割比率を設定
   * @param {number} ratio - 0.0 - 1.0
   */
  static setSplitRatio(ratio) {
    const clampedRatio = Math.max(0.3, Math.min(0.8, ratio));
    this.setValue('splitRatio', clampedRatio);
  }

  /**
   * 最後に選択したタスクIDを取得
   * @returns {number|null} タスクID
   */
  static getLastSelectedTask() {
    return this.getValue('lastSelectedTask');
  }

  /**
   * 最後に選択したタスクIDを設定
   * @param {number|null} taskId - タスクID
   */
  static setLastSelectedTask(taskId) {
    this.setValue('lastSelectedTask', taskId);
  }

  /**
   * 表示開始日を取得
   * @returns {string|null} 開始日 (YYYY-MM-DD)
   */
  static getViewStartDate() {
    const result = this.getValue('viewStartDate');
    console.log('GanttSettings.getViewStartDate: 結果', result);
    return result;
  }

  /**
   * 表示開始日を設定
   * @param {string|null} startDate - 開始日 (YYYY-MM-DD)
   */
  static setViewStartDate(startDate) {
    this.setValue('viewStartDate', startDate);
  }

  /**
   * 表示終了日を取得
   * @returns {string|null} 終了日 (YYYY-MM-DD)
   */
  static getViewEndDate() {
    const result = this.getValue('viewEndDate');
    console.log('GanttSettings.getViewEndDate: 結果', result);
    return result;
  }

  /**
   * 表示終了日を設定
   * @param {string|null} endDate - 終了日 (YYYY-MM-DD)
   */
  static setViewEndDate(endDate) {
    this.setValue('viewEndDate', endDate);
  }

  /**
   * 表示期間を設定
   * @param {string} startDate - 開始日 (YYYY-MM-DD)
   * @param {string} endDate - 終了日 (YYYY-MM-DD)
   */
  static setViewRange(startDate, endDate) {
    console.log('GanttSettings.setViewRange:', { startDate, endDate });
    this.set({
      viewStartDate: startDate,
      viewEndDate: endDate
    });
  }

  /**
   * 表示期間を取得
   * @returns {Object} {start: string|null, end: string|null}
   */
  static getViewRange() {
    const startDate = this.getViewStartDate();
    const endDate = this.getViewEndDate();
    console.log('GanttSettings.getViewRange:', { start: startDate, end: endDate });
    return {
      start: startDate,
      end: endDate
    };
  }

  /**
   * ズームレベルを取得
   * @returns {string} 'day' | 'week' | 'month' | 'quarter' | 'year'
   */
  static getZoomLevel() {
    const result = this.getValue('zoomLevel');
    console.log('GanttSettings.getZoomLevel: 結果', result);
    return result;
  }

  /**
   * ズームレベルを設定
   * @param {string} zoomLevel - 'day' | 'week' | 'month' | 'quarter' | 'year'
   */
  static setZoomLevel(zoomLevel) {
    const validZoomLevels = ['day', 'week', 'month', 'quarter', 'year'];
    if (!validZoomLevels.includes(zoomLevel)) {
      console.warn('Invalid zoom level:', zoomLevel);
      return;
    }
    console.log('GanttSettings.setZoomLevel:', zoomLevel);
    this.setValue('zoomLevel', zoomLevel);
  }

  /**
   * ツールバー詳細設定表示状態を取得
   * @returns {boolean} 表示状態
   */
  static getShowToolbarDetails() {
    return this.getValue('showToolbarDetails');
  }

  /**
   * ツールバー詳細設定表示状態を設定
   * @param {boolean} show - 表示状態
   */
  static setShowToolbarDetails(show) {
    this.setValue('showToolbarDetails', show);
  }

  /**
   * 設定をリセット
   */
  static reset() {
    this.set(this.DEFAULT_SETTINGS);
  }

  /**
   * プロジェクト固有のCookieを完全削除
   * @param {string} projectId - プロジェクトID
   */
  static clearProjectCookies(projectId) {
    console.log('GanttSettings.clearProjectCookies:', projectId);
    
    if (!projectId) {
      console.warn('projectIdが指定されていません');
      return;
    }
    
    // プロジェクト固有のCookieキーを生成
    const cookieKey = `${this.COOKIE_KEY}_${projectId}`;
    
    try {
      // Cookieを削除（過去の日付を設定して期限切れにする）
      document.cookie = `${cookieKey}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; SameSite=Lax`;
      console.log(`プロジェクト${projectId}のCookieを削除しました:`, cookieKey);
    } catch (error) {
      console.error('Cookie削除エラー:', error);
    }
  }
}