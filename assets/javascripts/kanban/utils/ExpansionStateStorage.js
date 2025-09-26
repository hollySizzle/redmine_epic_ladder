/**
 * Feature Card展開状態管理クラス
 * 設計仕様書準拠: @vibes/docs/logics/feature_card/feature_card_server_specification.md
 * LocalStorage方式でユーザー別展開状態を管理
 */

class ExpansionStateStorage {
  constructor(projectId, userId) {
    this.projectId = projectId;
    this.userId = userId;
    this.storageKey = `kanban_expansion_${projectId}_${userId}`;
    this.maxAgeMillis = 30 * 24 * 60 * 60 * 1000; // 30日
  }

  /**
   * 展開状態データを取得
   * @returns {Map<number, boolean>} UserStoryID -> 展開状態のMap
   */
  getExpansionStates() {
    try {
      const storedData = localStorage.getItem(this.storageKey);
      if (!storedData) {
        return new Map();
      }

      const parsed = JSON.parse(storedData);

      // データ形式チェック・古いデータのクリーンアップ
      if (!this.isValidStorageData(parsed)) {
        console.warn('Invalid expansion state data found, resetting...');
        this.clearExpansionStates();
        return new Map();
      }

      // 古いデータの削除
      if (this.isExpired(parsed.timestamp)) {
        console.info('Expired expansion state data found, resetting...');
        this.clearExpansionStates();
        return new Map();
      }

      // MapオブジェクトをMapに変換
      return new Map(Object.entries(parsed.states).map(([k, v]) => [parseInt(k), v]));
    } catch (error) {
      console.error('Failed to load expansion states:', error);
      return new Map();
    }
  }

  /**
   * 単一UserStoryの展開状態を取得
   * @param {number} userStoryId - UserStoryのID
   * @returns {boolean} 展開状態（デフォルト: false）
   */
  getExpansionState(userStoryId) {
    const states = this.getExpansionStates();
    return states.get(userStoryId) || false;
  }

  /**
   * 単一UserStoryの展開状態を設定
   * @param {number} userStoryId - UserStoryのID
   * @param {boolean} expanded - 展開状態
   */
  setExpansionState(userStoryId, expanded) {
    try {
      const states = this.getExpansionStates();
      states.set(userStoryId, expanded);
      this.saveExpansionStates(states);
    } catch (error) {
      console.error('Failed to save expansion state:', error);
    }
  }

  /**
   * UserStoryの展開状態を切替
   * @param {number} userStoryId - UserStoryのID
   * @returns {boolean} 切替後の展開状態
   */
  toggleExpansionState(userStoryId) {
    const currentState = this.getExpansionState(userStoryId);
    const newState = !currentState;
    this.setExpansionState(userStoryId, newState);
    return newState;
  }

  /**
   * 複数UserStoryの展開状態を一括設定
   * @param {Map<number, boolean>} statesMap - UserStoryID -> 展開状態のMap
   */
  setBulkExpansionStates(statesMap) {
    try {
      this.saveExpansionStates(statesMap);
    } catch (error) {
      console.error('Failed to save bulk expansion states:', error);
    }
  }

  /**
   * 全展開状態をクリア
   */
  clearExpansionStates() {
    try {
      localStorage.removeItem(this.storageKey);
    } catch (error) {
      console.error('Failed to clear expansion states:', error);
    }
  }

  /**
   * 展開状態をLocalStorageに保存
   * @private
   * @param {Map<number, boolean>} statesMap - 展開状態Map
   */
  saveExpansionStates(statesMap) {
    const storageData = {
      version: '1.0',
      projectId: this.projectId,
      userId: this.userId,
      timestamp: Date.now(),
      states: Object.fromEntries(statesMap)
    };

    try {
      const serialized = JSON.stringify(storageData);
      localStorage.setItem(this.storageKey, serialized);
    } catch (error) {
      if (error.name === 'QuotaExceededError') {
        console.warn('LocalStorage quota exceeded, clearing old data...');
        this.performCleanup();
        // リトライ
        try {
          localStorage.setItem(this.storageKey, serialized);
        } catch (retryError) {
          console.error('Failed to save after cleanup:', retryError);
        }
      } else {
        throw error;
      }
    }
  }

  /**
   * 保存データの形式チェック
   * @private
   * @param {*} data - チェック対象データ
   * @returns {boolean} 有効かどうか
   */
  isValidStorageData(data) {
    return data &&
           typeof data === 'object' &&
           data.version === '1.0' &&
           data.projectId === this.projectId &&
           data.userId === this.userId &&
           typeof data.timestamp === 'number' &&
           typeof data.states === 'object';
  }

  /**
   * データの期限切れチェック
   * @private
   * @param {number} timestamp - 保存時のタイムスタンプ
   * @returns {boolean} 期限切れかどうか
   */
  isExpired(timestamp) {
    return (Date.now() - timestamp) > this.maxAgeMillis;
  }

  /**
   * 古いデータのクリーンアップ実行
   * @private
   */
  performCleanup() {
    try {
      // 他のプロジェクト・ユーザーの古いデータを削除
      const keysToRemove = [];

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith('kanban_expansion_')) {
          try {
            const data = JSON.parse(localStorage.getItem(key));
            if (this.isExpired(data.timestamp)) {
              keysToRemove.push(key);
            }
          } catch (error) {
            // パースエラーの場合も削除対象
            keysToRemove.push(key);
          }
        }
      }

      keysToRemove.forEach(key => localStorage.removeItem(key));
      console.info(`Cleaned up ${keysToRemove.length} expired expansion state entries`);
    } catch (error) {
      console.error('Failed to perform cleanup:', error);
    }
  }

  /**
   * デバッグ情報出力
   * @returns {Object} デバッグ情報
   */
  getDebugInfo() {
    const states = this.getExpansionStates();
    return {
      storageKey: this.storageKey,
      projectId: this.projectId,
      userId: this.userId,
      statesCount: states.size,
      expandedCount: Array.from(states.values()).filter(Boolean).length,
      storageUsage: this.getStorageUsage()
    };
  }

  /**
   * LocalStorage使用量取得
   * @private
   * @returns {Object} 使用量情報
   */
  getStorageUsage() {
    try {
      const data = localStorage.getItem(this.storageKey);
      return {
        bytes: data ? new Blob([data]).size : 0,
        entries: localStorage.length
      };
    } catch (error) {
      return { bytes: 0, entries: 0, error: error.message };
    }
  }
}

// グローバル管理用のファクトリー関数
const ExpansionStateStorageFactory = {
  instances: new Map(),

  /**
   * ExpansionStateStorageインスタンスを取得（シングルトン）
   * @param {number} projectId - プロジェクトID
   * @param {number} userId - ユーザーID
   * @returns {ExpansionStateStorage} インスタンス
   */
  getInstance(projectId, userId) {
    const key = `${projectId}_${userId}`;

    if (!this.instances.has(key)) {
      this.instances.set(key, new ExpansionStateStorage(projectId, userId));
    }

    return this.instances.get(key);
  },

  /**
   * 全インスタンスをクリア（テスト用）
   */
  clearInstances() {
    this.instances.clear();
  }
};

export { ExpansionStateStorage, ExpansionStateStorageFactory };