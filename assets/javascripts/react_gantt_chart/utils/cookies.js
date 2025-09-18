// Cookie操作ユーティリティ

/**
 * Cookieを設定
 * @param {string} name - Cookie名
 * @param {string} value - Cookie値
 * @param {number} days - 有効期限（日数）
 * @param {string} path - パス（オプション）
 * @param {string} domain - ドメイン（オプション）
 */
export const setCookie = (name, value, days = 365, path = '/', domain = null) => {
  const expires = new Date();
  expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
  
  let cookieString = `${name}=${encodeURIComponent(value)}; expires=${expires.toUTCString()}; path=${path}`;
  
  if (domain) {
    cookieString += `; domain=${domain}`;
  }
  
  // セキュアフラグの設定（HTTPSの場合）
  if (location.protocol === 'https:') {
    cookieString += '; secure';
  }
  
  document.cookie = cookieString;
};

/**
 * Cookieを取得
 * @param {string} name - Cookie名
 * @returns {string|null} Cookie値（存在しない場合はnull）
 */
export const getCookie = (name) => {
  const nameEQ = name + '=';
  const ca = document.cookie.split(';');
  
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === ' ') {
      c = c.substring(1, c.length);
    }
    if (c.indexOf(nameEQ) === 0) {
      return decodeURIComponent(c.substring(nameEQ.length, c.length));
    }
  }
  return null;
};

/**
 * Cookieを削除
 * @param {string} name - Cookie名
 * @param {string} path - パス（オプション）
 * @param {string} domain - ドメイン（オプション）
 */
export const deleteCookie = (name, path = '/', domain = null) => {
  let cookieString = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=${path}`;
  
  if (domain) {
    cookieString += `; domain=${domain}`;
  }
  
  document.cookie = cookieString;
};

/**
 * すべてのCookieを取得
 * @returns {Object} Cookie名-値のオブジェクト
 */
export const getAllCookies = () => {
  const cookies = {};
  const ca = document.cookie.split(';');
  
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === ' ') {
      c = c.substring(1, c.length);
    }
    const eqPos = c.indexOf('=');
    if (eqPos !== -1) {
      const name = c.substring(0, eqPos);
      const value = decodeURIComponent(c.substring(eqPos + 1));
      cookies[name] = value;
    }
  }
  
  return cookies;
};

/**
 * Cookieが存在するかチェック
 * @param {string} name - Cookie名
 * @returns {boolean} 存在する場合はtrue
 */
export const hasCookie = (name) => {
  return getCookie(name) !== null;
};

/**
 * プレフィックス付きCookieを設定
 * @param {string} prefix - プレフィックス
 * @param {string} name - Cookie名
 * @param {string} value - Cookie値
 * @param {number} days - 有効期限（日数）
 */
export const setPrefixedCookie = (prefix, name, value, days = 365) => {
  const cookieName = `${prefix}_${name}`;
  setCookie(cookieName, value, days);
};

/**
 * プレフィックス付きCookieを取得
 * @param {string} prefix - プレフィックス
 * @param {string} name - Cookie名
 * @returns {string|null} Cookie値
 */
export const getPrefixedCookie = (prefix, name) => {
  const cookieName = `${prefix}_${name}`;
  return getCookie(cookieName);
};

/**
 * プレフィックス付きCookieを削除
 * @param {string} prefix - プレフィックス
 * @param {string} name - Cookie名
 */
export const deletePrefixedCookie = (prefix, name) => {
  const cookieName = `${prefix}_${name}`;
  deleteCookie(cookieName);
};

/**
 * 特定のプレフィックスを持つすべてのCookieを取得
 * @param {string} prefix - プレフィックス
 * @returns {Object} Cookie名-値のオブジェクト（プレフィックスを除いた名前で）
 */
export const getAllPrefixedCookies = (prefix) => {
  const allCookies = getAllCookies();
  const prefixedCookies = {};
  const prefixPattern = `${prefix}_`;
  
  Object.keys(allCookies).forEach(name => {
    if (name.startsWith(prefixPattern)) {
      const shortName = name.substring(prefixPattern.length);
      prefixedCookies[shortName] = allCookies[name];
    }
  });
  
  return prefixedCookies;
};

/**
 * 特定のプレフィックスを持つすべてのCookieを削除
 * @param {string} prefix - プレフィックス
 */
export const deleteAllPrefixedCookies = (prefix) => {
  const prefixedCookies = getAllPrefixedCookies(prefix);
  Object.keys(prefixedCookies).forEach(name => {
    deletePrefixedCookie(prefix, name);
  });
};

/**
 * JSONオブジェクトをCookieに保存
 * @param {string} name - Cookie名
 * @param {Object} obj - 保存するオブジェクト
 * @param {number} days - 有効期限（日数）
 */
export const setJSONCookie = (name, obj, days = 365) => {
  try {
    const jsonString = JSON.stringify(obj);
    setCookie(name, jsonString, days);
  } catch (error) {
    console.error('JSONCookie設定エラー:', error);
  }
};

/**
 * JSONオブジェクトをCookieから取得
 * @param {string} name - Cookie名
 * @returns {Object|null} 取得したオブジェクト（エラーの場合はnull）
 */
export const getJSONCookie = (name) => {
  try {
    const jsonString = getCookie(name);
    return jsonString ? JSON.parse(jsonString) : null;
  } catch (error) {
    console.error('JSONCookie取得エラー:', error);
    return null;
  }
};

// Redmine用のCookieユーティリティ
export const RedmineCookies = {
  prefix: 'redmine_gantt',
  
  setGanttConfig: (config) => {
    setPrefixedCookie(RedmineCookies.prefix, 'config', JSON.stringify(config));
  },
  
  getGanttConfig: () => {
    const config = getPrefixedCookie(RedmineCookies.prefix, 'config');
    return config ? JSON.parse(config) : null;
  },
  
  setZoomLevel: (level) => {
    setPrefixedCookie(RedmineCookies.prefix, 'zoom_level', level);
  },
  
  getZoomLevel: () => {
    return getPrefixedCookie(RedmineCookies.prefix, 'zoom_level');
  },
  
  setColumnSettings: (settings) => {
    setPrefixedCookie(RedmineCookies.prefix, 'columns', JSON.stringify(settings));
  },
  
  getColumnSettings: () => {
    const settings = getPrefixedCookie(RedmineCookies.prefix, 'columns');
    return settings ? JSON.parse(settings) : null;
  },
  
  clearAll: () => {
    deleteAllPrefixedCookies(RedmineCookies.prefix);
  }
};