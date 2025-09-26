/**
 * GridV2API - 設計書準拠のGrid V2 API通信サービス
 * 設計書仕様: RESTful API、エラーハンドリング、楽観的更新対応
 */
export class GridV2API {
  static baseUrl = '/kanban/projects';

  /**
   * APIリクエスト共通処理
   */
  static async request(url, options = {}) {
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.getCSRFToken()
      },
      credentials: 'same-origin'
    };

    const mergedOptions = {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...options.headers
      }
    };

    try {
      const response = await fetch(url, mergedOptions);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new APIError(
          errorData.error || `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          errorData
        );
      }

      return await response.json();
    } catch (error) {
      if (error instanceof APIError) {
        throw error;
      }

      // ネットワークエラーなど
      throw new APIError(
        `Network error: ${error.message}`,
        0,
        { originalError: error }
      );
    }
  }

  /**
   * GET /kanban/projects/:project_id/api/v1/grid
   * グリッドデータの取得（設計書準拠）
   */
  static async getGridData(projectId, filters = {}) {
    const params = new URLSearchParams();

    // フィルタパラメータの設定
    if (filters.assignee_id) {
      params.append('assignee_id', filters.assignee_id);
    }

    if (filters.status_ids && filters.status_ids.length > 0) {
      params.append('status_ids', filters.status_ids.join(','));
    }

    if (filters.version_ids && filters.version_ids.length > 0) {
      params.append('version_ids', filters.version_ids.join(','));
    }

    if (filters.search) {
      params.append('search', filters.search);
    }

    const queryString = params.toString();
    const url = `${this.baseUrl}/${projectId}/api/v1/grid${queryString ? `?${queryString}` : ''}`;

    return await this.request(url, {
      method: 'GET'
    });
  }

  /**
   * POST /kanban/projects/:project_id/api/v1/grid/move_feature
   * Feature D&D移動処理（設計書準拠）
   */
  static async moveFeature(projectId, moveData) {
    const url = `${this.baseUrl}/${projectId}/api/v1/grid/move_feature`;

    return await this.request(url, {
      method: 'POST',
      body: JSON.stringify({
        feature_id: moveData.feature_id,
        source_cell: moveData.source_cell,
        target_cell: moveData.target_cell,
        lock_version: moveData.lock_version
      })
    });
  }

  /**
   * POST /kanban/projects/:project_id/api/v1/grid/propagate_version
   * バージョン割当処理（設計書準拠）
   */
  static async assignVersion(projectId, assignData) {
    const url = `${this.baseUrl}/${projectId}/api/v1/grid/propagate_version`;

    return await this.request(url, {
      method: 'POST',
      body: JSON.stringify({
        issue_id: assignData.issue_id,
        version_id: assignData.version_id
      })
    });
  }

  /**
   * POST /kanban/projects/:project_id/api/v1/grid/create_epic
   * Epic作成処理（設計書準拠）
   */
  static async createEpic(projectId, epicData) {
    const url = `${this.baseUrl}/${projectId}/api/v1/grid/create_epic`;

    return await this.request(url, {
      method: 'POST',
      body: JSON.stringify({
        epic: {
          subject: epicData.subject,
          description: epicData.description,
          assigned_to_id: epicData.assigned_to_id,
          fixed_version_id: epicData.fixed_version_id
        }
      })
    });
  }

  /**
   * POST /kanban/projects/:project_id/api/v1/grid/create_version
   * Version作成処理（設計書準拠GridController統合）
   */
  static async createVersion(projectId, versionData) {
    const url = `${this.baseUrl}/${projectId}/api/v1/grid/create_version`;

    return await this.request(url, {
      method: 'POST',
      body: JSON.stringify({
        version: {
          name: versionData.name,
          description: versionData.description,
          effective_date: versionData.effective_date,
          status: versionData.status || 'open'
        }
      })
    });
  }

  /**
   * GET /kanban/projects/:project_id/api/v1/realtime/poll_updates
   * リアルタイム更新データ取得（設計書準拠）
   */
  static async getUpdates(projectId, sinceTimestamp = null) {
    const params = new URLSearchParams();

    if (sinceTimestamp) {
      params.append('since', sinceTimestamp);
    }

    const queryString = params.toString();
    const url = `${this.baseUrl}/${projectId}/api/v1/realtime/poll_updates${queryString ? `?${queryString}` : ''}`;

    return await this.request(url, {
      method: 'GET'
    });
  }

  /**
   * DELETE /kanban/projects/:project_id/api/v1/cards/:id
   * Epic削除処理（設計書準拠）
   */
  static async deleteEpic(projectId, epicId) {
    const url = `${this.baseUrl}/${projectId}/api/v1/cards/${epicId}`;

    return await this.request(url, {
      method: 'DELETE'
    });
  }

  /**
   * 楽観的更新対応のリトライ機能付きAPI呼び出し
   */
  static async requestWithRetry(requestFn, maxRetries = 3) {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await requestFn();
      } catch (error) {
        lastError = error;

        // 楽観的更新の衝突（HTTP 409）の場合はリトライ
        if (error.status === 409 && attempt < maxRetries) {
          console.warn(`Optimistic update conflict, retrying (${attempt}/${maxRetries})`);

          // 指数バックオフでリトライ
          await this.delay(Math.pow(2, attempt - 1) * 1000);
          continue;
        }

        // その他のエラーまたは最大リトライ数到達の場合は再スロー
        throw error;
      }
    }

    throw lastError;
  }

  /**
   * バッチ操作API（複数Feature の一括移動）（設計書準拠）
   */
  static async batchMoveFeatures(projectId, moves) {
    const url = `${this.baseUrl}/${projectId}/api/v1/batch/update`;

    return await this.request(url, {
      method: 'POST',
      body: JSON.stringify({
        moves: moves
      })
    });
  }

  /**
   * グリッド統計情報取得（設計書準拠）
   */
  static async getStatistics(projectId, filters = {}) {
    const params = new URLSearchParams();

    Object.entries(filters).forEach(([key, value]) => {
      if (value !== null && value !== undefined) {
        params.append(key, value);
      }
    });

    const queryString = params.toString();
    const url = `${this.baseUrl}/${projectId}/api/v1/grid${queryString ? `?${queryString}` : ''}`;

    return await this.request(url, {
      method: 'GET'
    });
  }

  /**
   * ユーティリティメソッド群
   */

  static getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : '';
  }

  static delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * WebSocket接続（リアルタイム更新）
   */
  static connectWebSocket(projectId, onMessage, onError) {
    // 設計書では WebSocket/SSE 対応とあるが、
    // 実装簡略化のためポーリングベースとする
    const pollingInterval = 5000; // 5秒間隔
    let lastUpdateTimestamp = null;

    const poll = async () => {
      try {
        const updates = await this.getUpdates(projectId, lastUpdateTimestamp);

        if (updates.success && updates.updates.length > 0) {
          onMessage(updates);
          lastUpdateTimestamp = updates.last_update_timestamp;
        }
      } catch (error) {
        onError?.(error);
      }
    };

    const intervalId = setInterval(poll, pollingInterval);

    return {
      disconnect: () => clearInterval(intervalId)
    };
  }

  /**
   * キャッシュ管理
   */
  static cache = new Map();
  static cacheTimeout = 5 * 60 * 1000; // 5分

  static async getCachedGridData(projectId, filters = {}) {
    const cacheKey = `grid_${projectId}_${JSON.stringify(filters)}`;
    const cached = this.cache.get(cacheKey);

    if (cached && (Date.now() - cached.timestamp) < this.cacheTimeout) {
      return cached.data;
    }

    const data = await this.getGridData(projectId, filters);

    this.cache.set(cacheKey, {
      data,
      timestamp: Date.now()
    });

    return data;
  }

  static invalidateCache(projectId) {
    const keysToDelete = [];

    for (const key of this.cache.keys()) {
      if (key.startsWith(`grid_${projectId}_`)) {
        keysToDelete.push(key);
      }
    }

    keysToDelete.forEach(key => this.cache.delete(key));
  }
}

/**
 * カスタムエラークラス
 */
export class APIError extends Error {
  constructor(message, status, details = {}) {
    super(message);
    this.name = 'APIError';
    this.status = status;
    this.details = details;
  }

  isNetworkError() {
    return this.status === 0;
  }

  isClientError() {
    return this.status >= 400 && this.status < 500;
  }

  isServerError() {
    return this.status >= 500;
  }

  isOptimisticUpdateConflict() {
    return this.status === 409;
  }
}

/**
 * レスポンス型定義（TypeScriptドキュメント用）
 */

/*
interface GridDataResponse {
  success: boolean;
  data: {
    grid: {
      rows: EpicRow[];
      columns: VersionColumn[];
      versions: Version[];
    };
    metadata: GridMetadata;
    statistics: GridStatistics;
  };
  timestamp: string;
}

interface MoveFeatureResponse {
  success: boolean;
  updated_card: Issue;
  affected_cells: CellUpdate[];
  updated_data: GridData;
  move_result: MoveResult;
  timestamp: string;
}

interface UpdatesResponse {
  success: boolean;
  updates: IssueUpdate[];
  deleted_issues: number[];
  grid_structure_changes: GridChange[];
  last_update_timestamp: string;
  has_more: boolean;
}
*/

export default GridV2API;