/**
 * Kanban API Client
 * サーバーサイドAPIとの通信を担当するクライアント
 */
class KanbanAPI {
  constructor(projectId, options = {}) {
    this.projectId = projectId;
    this.baseUrl = `/kanban`;
    this.options = {
      timeout: 10000,
      retries: 3,
      ...options
    };
    this.csrfToken = this.getCSRFToken();

    // キャッシング機能初期化
    this.cache = new Map();
  }

  /**
   * CSRFトークンを取得
   */
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }

  /**
   * HTTPリクエストを実行
   */
  async request(endpoint, options = {}) {
    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`;

    const config = {
      timeout: this.options.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken,
        ...options.headers
      },
      ...options
    };

    try {
      const response = await fetch(url, config);

      if (!response.ok) {
        await this.handleErrorResponse(response);
      }

      return await response.json();
    } catch (error) {
      throw this.handleNetworkError(error);
    }
  }

  /**
   * GET リクエスト
   */
  async get(endpoint, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const url = queryString ? `${endpoint}?${queryString}` : endpoint;

    return this.request(url, { method: 'GET' });
  }

  /**
   * POST リクエスト
   */
  async post(endpoint, data = {}) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  /**
   * PATCH リクエスト
   */
  async patch(endpoint, data = {}) {
    return this.request(endpoint, {
      method: 'PATCH',
      body: JSON.stringify(data)
    });
  }

  /**
   * DELETE リクエスト
   */
  async delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' });
  }

  // === カンバンデータ API ===

  /**
   * カンバンデータを取得
   */
  async getKanbanData(filters = {}) {
    return this.get('/cards', filters);
  }

  /**
   * Issue詳細を取得
   */
  async getIssueDetail(issueId) {
    return this.get(`/cards/${issueId}`);
  }

  /**
   * カードを移動
   */
  async moveCard(cardId, sourceCell, targetCell) {
    return this.post(`/move_card`, {
      card_id: cardId,
      source_cell: sourceCell,
      target_cell: targetCell
    });
  }

  /**
   * 一括更新
   */
  async bulkUpdate(actionType, issueIds, actionParams = {}) {
    return this.post('/batch_update', {
      action: actionType,
      issue_ids: issueIds,
      action_params: actionParams
    });
  }

  /**
   * 統計データを取得
   */
  async getStatistics(params = {}) {
    return this.get('/statistics', params);
  }

  // === バージョン管理 API ===

  /**
   * バージョン一覧を取得 (キャッシング対応)
   */
  async getVersions(useCache = true) {
    const cacheKey = 'versions_list';

    // キャッシュチェック
    if (useCache && this.isValidCache(cacheKey)) {
      return this.getFromCache(cacheKey);
    }

    const result = await this.get('/versions');

    // キャッシュ保存 (10分)
    this.setCache(cacheKey, result, 10 * 60 * 1000);

    return result;
  }

  /**
   * バージョン詳細を取得
   */
  async getVersion(versionId) {
    return this.get(`/versions/${versionId}`);
  }

  /**
   * バージョンを作成
   */
  async createVersion(versionData) {
    return this.post('/versions', { version: versionData });
  }

  /**
   * バージョンを更新
   */
  async updateVersion(versionId, versionData) {
    return this.patch(`/versions/${versionId}`, { version: versionData });
  }

  /**
   * Issueにバージョンを一括割り当て
   */
  async bulkAssignVersion(versionId, issueIds) {
    return this.post(`/versions/${versionId}/bulk_assign`, {
      bulk_assign: { issue_ids: issueIds }
    });
  }

  /**
   * バージョンタイムラインを取得
   */
  async getVersionTimeline(versionId, params = {}) {
    return this.get(`/versions/${versionId}/timeline`, params);
  }

  // === リアルタイム通信 API ===

  /**
   * リアルタイム更新を購読
   */
  async subscribeToUpdates() {
    return this.post('/realtime/subscribe');
  }

  /**
   * リアルタイム更新の購読を停止
   */
  async unsubscribeFromUpdates() {
    return this.delete('/realtime/unsubscribe');
  }

  /**
   * 更新をポーリング（WebSocket非対応時のフォールバック）
   */
  async pollUpdates(since = null) {
    const params = since ? { since: since } : {};
    return this.get('/realtime/poll_updates', params);
  }

  /**
   * ハートビート送信
   */
  async sendHeartbeat() {
    return this.post('/realtime/heartbeat');
  }

  // === キャッシング機能 ===

  /**
   * キャッシュにデータを保存
   */
  setCache(key, data, ttl = 5 * 60 * 1000) {
    this.cache.set(key, {
      data: data,
      timestamp: Date.now(),
      ttl: ttl
    });
  }

  /**
   * キャッシュからデータを取得
   */
  getFromCache(key) {
    const cached = this.cache.get(key);
    return cached ? cached.data : null;
  }

  /**
   * キャッシュが有効かチェック
   */
  isValidCache(key) {
    const cached = this.cache.get(key);
    if (!cached) return false;

    const now = Date.now();
    return (now - cached.timestamp) < cached.ttl;
  }

  /**
   * キャッシュをクリア
   */
  clearCache(key = null) {
    if (key) {
      this.cache.delete(key);
    } else {
      this.cache.clear();
    }
  }

  // === エラーハンドリング ===

  /**
   * HTTPエラーレスポンスを処理
   */
  async handleErrorResponse(response) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    let errorData = null;

    try {
      errorData = await response.json();
      if (errorData.error) {
        errorMessage = errorData.error.message || errorData.error;
      }
    } catch (parseError) {
      // JSON解析に失敗した場合はデフォルトメッセージを使用
    }

    const error = new KanbanAPIError(errorMessage, response.status, errorData);

    // エラータイプ別の処理
    if (response.status === 401) {
      this.handleAuthenticationError(error);
    } else if (response.status === 403) {
      this.handleAuthorizationError(error);
    } else if (response.status === 422) {
      this.handleValidationError(error);
    }

    throw error;
  }

  /**
   * ネットワークエラーを処理
   */
  handleNetworkError(error) {
    if (error.name === 'AbortError') {
      return new KanbanAPIError('Request timeout', 408);
    } else if (error.name === 'TypeError') {
      return new KanbanAPIError('Network error', 0);
    }
    return error;
  }

  /**
   * 認証エラー処理
   */
  handleAuthenticationError(error) {
    // セッション切れ時の処理
    if (typeof window !== 'undefined') {
      console.warn('Authentication error, redirecting to login');
      // window.location.reload(); // 必要に応じて有効化
    }
  }

  /**
   * 認可エラー処理
   */
  handleAuthorizationError(error) {
    console.warn('Authorization error:', error.message);
  }

  /**
   * バリデーションエラー処理
   */
  handleValidationError(error) {
    console.warn('Validation error:', error.data);
  }
}

/**
 * Kanban API専用エラークラス
 */
class KanbanAPIError extends Error {
  constructor(message, status = 500, data = null) {
    super(message);
    this.name = 'KanbanAPIError';
    this.status = status;
    this.data = data;
  }

  /**
   * バリデーションエラーかどうか
   */
  isValidationError() {
    return this.status === 422;
  }

  /**
   * 認証エラーかどうか
   */
  isAuthenticationError() {
    return this.status === 401;
  }

  /**
   * 認可エラーかどうか
   */
  isAuthorizationError() {
    return this.status === 403;
  }

  /**
   * ネットワークエラーかどうか
   */
  isNetworkError() {
    return this.status === 0;
  }
}

export { KanbanAPI, KanbanAPIError };