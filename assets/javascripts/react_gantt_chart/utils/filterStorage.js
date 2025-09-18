/**
 * プロジェクト単位のCookie管理ユーティリティ
 * 注意: フィルタ機能はサーバーサイドに統合済み。このファイルは汎用Cookie管理のみ
 */

// プロジェクトIDを取得する関数
const getProjectId = () => {
  return window.location.pathname.split("/")[2] || 'default';
};

// Cookieの有効期限（30日）
const COOKIE_EXPIRY_DAYS = 30;

/**
 * Cookieを設定する
 * @param {string} name - Cookie名
 * @param {string} value - Cookie値
 * @param {number} days - 有効期限（日数）
 */
const setCookie = (name, value, days) => {
  try {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    const encodedValue = encodeURIComponent(value);
    document.cookie = `${name}=${encodedValue}; expires=${expires.toUTCString()}; path=/; SameSite=Strict`;
  } catch (error) {
    console.warn('Cookie設定エラー:', error);
  }
};

/**
 * Cookieを取得する
 * @param {string} name - Cookie名
 * @returns {string|null} Cookie値
 */
const getCookie = (name) => {
  try {
    const nameEQ = name + "=";
    const ca = document.cookie.split(';');
    
    for (let i = 0; i < ca.length; i++) {
      let c = ca[i];
      while (c.charAt(0) === ' ') c = c.substring(1, c.length);
      if (c.indexOf(nameEQ) === 0) {
        const value = c.substring(nameEQ.length, c.length);
        return decodeURIComponent(value);
      }
    }
    return null;
  } catch (error) {
    console.warn('Cookie取得エラー:', error);
    return null;
  }
};

/**
 * Cookieを削除する
 * @param {string} name - Cookie名
 */
const deleteCookie = (name) => {
  document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
};

/**
 * 汎用的なプロジェクト設定をCookieに保存（将来の機能拡張用）
 * @param {string} settingKey - 設定キー
 * @param {Object} settingValue - 設定値オブジェクト
 */
export const saveProjectSetting = (settingKey, settingValue) => {
  try {
    const projectId = getProjectId();
    const cookieName = `gantt_${settingKey}_${projectId}`;
    const settingJson = JSON.stringify(settingValue);
    
    // JSON文字列が長すぎる場合は警告（Cookieサイズ制限: 4KB）
    if (settingJson.length > 3000) {
      console.warn(`設定データ（${settingKey}）のサイズが大きすぎます。保存されない可能性があります。`);
    }
    
    setCookie(cookieName, settingJson, COOKIE_EXPIRY_DAYS);
    console.log(`プロジェクト設定を保存しました (${settingKey}, プロジェクト: ${projectId}):`, settingValue);
  } catch (error) {
    console.error(`設定保存エラー (${settingKey}):`, error);
  }
};

/**
 * プロジェクト設定をCookieから復元
 * @param {string} settingKey - 設定キー
 * @returns {Object|null} 設定値オブジェクトまたはnull
 */
export const loadProjectSetting = (settingKey) => {
  try {
    const projectId = getProjectId();
    const cookieName = `gantt_${settingKey}_${projectId}`;
    const settingJson = getCookie(cookieName);
    
    if (!settingJson) {
      console.log(`設定が見つかりません (${settingKey}, プロジェクト: ${projectId})`);
      return null;
    }
    
    const settingValue = JSON.parse(settingJson);
    console.log(`設定を復元しました (${settingKey}, プロジェクト: ${projectId}):`, settingValue);
    return settingValue;
  } catch (error) {
    console.error(`設定復元エラー (${settingKey}):`, error);
    return null;
  }
};

/**
 * プロジェクト設定をクリア
 * @param {string} settingKey - 設定キー
 */
export const clearProjectSetting = (settingKey) => {
  try {
    const projectId = getProjectId();
    const cookieName = `gantt_${settingKey}_${projectId}`;
    deleteCookie(cookieName);
    console.log(`設定をクリアしました (${settingKey}, プロジェクト: ${projectId})`);
  } catch (error) {
    console.error(`設定クリアエラー (${settingKey}):`, error);
  }
};

// 後方互換性のため、古いフィルタ関数は非推奨として残す
/** @deprecated フィルタ機能はサーバーサイドに統合済み */
export const saveFilterState = (filterState) => {
  console.warn('saveFilterState は非推奨です。フィルタ機能はサーバーサイドに統合されました。');
  return saveProjectSetting('filters', filterState);
};

/** @deprecated フィルタ機能はサーバーサイドに統合済み */
export const loadFilterState = () => {
  console.warn('loadFilterState は非推奨です。フィルタ機能はサーバーサイドに統合されました。');
  return loadProjectSetting('filters');
};

/** @deprecated フィルタ機能はサーバーサイドに統合済み */
export const clearFilterState = () => {
  console.warn('clearFilterState は非推奨です。フィルタ機能はサーバーサイドに統合されました。');
  return clearProjectSetting('filters');
};

/** @deprecated フィルタ機能はサーバーサイドに統合済み */
export const updateSingleFilter = (filterName, filterValue) => {
  console.warn('updateSingleFilter は非推奨です。フィルタ機能はサーバーサイドに統合されました。');
};