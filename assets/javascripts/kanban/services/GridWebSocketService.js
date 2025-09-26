/**
 * GridWebSocketService - 設計書準拠のWebSocket/SSE リアルタイム同期サービス
 * 設計書仕様: WebSocket接続、データ伝播、衝突検出、自動再接続
 */
export class GridWebSocketService {
  static instances = new Map();

  constructor(projectId, userId, options = {}) {
    this.projectId = projectId;
    this.userId = userId;
    this.options = {
      autoReconnect: true,
      reconnectDelay: 1000,
      maxReconnectAttempts: 5,
      heartbeatInterval: 30000,
      ...options
    };

    this.socket = null;
    this.reconnectAttempts = 0;
    this.isConnected = false;
    this.heartbeatTimer = null;
    this.lastUpdateTimestamp = null;

    // コールバック管理
    this.eventHandlers = {
      'grid_update': new Set(),
      'feature_moved': new Set(),
      'epic_created': new Set(),
      'version_created': new Set(),
      'issue_updated': new Set(),
      'user_joined': new Set(),
      'user_left': new Set(),
      'connection_status': new Set(),
      'error': new Set()
    };

    // パフォーマンス監視
    this.stats = {
      messagesReceived: 0,
      messagesProcessed: 0,
      averageLatency: 0,
      connectionUptime: 0,
      reconnectionCount: 0
    };
  }

  /**
   * WebSocket接続開始
   */
  async connect() {
    if (this.isConnected) {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      try {
        const wsUrl = this.buildWebSocketUrl();
        console.log(`[GridWebSocket] Connecting to: ${wsUrl}`);

        this.socket = new WebSocket(wsUrl);
        this.setupSocketEvents(resolve, reject);

        // 接続タイムアウト設定
        const timeoutId = setTimeout(() => {
          if (!this.isConnected) {
            this.socket.close();
            reject(new Error('WebSocket connection timeout'));
          }
        }, 10000);

        this.connectionTimeout = timeoutId;
      } catch (error) {
        console.error('[GridWebSocket] Connection error:', error);
        reject(error);
      }
    });
  }

  /**
   * WebSocket接続終了
   */
  disconnect() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
    }

    if (this.connectionTimeout) {
      clearTimeout(this.connectionTimeout);
    }

    if (this.socket) {
      this.socket.close(1000, 'Client disconnect');
      this.socket = null;
    }

    this.isConnected = false;
    this.emit('connection_status', { connected: false, reason: 'user_disconnect' });
  }

  /**
   * イベントリスナー登録
   */
  on(event, handler) {
    if (this.eventHandlers[event]) {
      this.eventHandlers[event].add(handler);
    } else {
      console.warn(`[GridWebSocket] Unknown event: ${event}`);
    }
    return this; // チェーンメソッド
  }

  /**
   * イベントリスナー削除
   */
  off(event, handler) {
    if (this.eventHandlers[event]) {
      this.eventHandlers[event].delete(handler);
    }
    return this;
  }

  /**
   * メッセージ送信
   */
  send(type, data) {
    if (!this.isConnected || !this.socket) {
      console.warn('[GridWebSocket] Cannot send message: not connected');
      return false;
    }

    const message = {
      type,
      data,
      user_id: this.userId,
      project_id: this.projectId,
      timestamp: new Date().toISOString(),
      client_id: this.getClientId()
    };

    try {
      this.socket.send(JSON.stringify(message));
      return true;
    } catch (error) {
      console.error('[GridWebSocket] Send error:', error);
      return false;
    }
  }

  /**
   * 楽観的更新の同期
   */
  notifyOptimisticUpdate(updateType, updateData) {
    this.send('optimistic_update', {
      type: updateType,
      data: updateData,
      local_timestamp: Date.now()
    });
  }

  /**
   * ユーザー操作通知
   */
  notifyUserAction(action, details) {
    this.send('user_action', {
      action,
      details,
      timestamp: Date.now()
    });
  }

  /**
   * プライベートメソッド群
   */

  buildWebSocketUrl() {
    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = location.host;
    const path = `/kanban/projects/${this.projectId}/websocket`;

    const params = new URLSearchParams({
      user_id: this.userId,
      client_id: this.getClientId(),
      auth_token: this.getAuthToken()
    });

    return `${protocol}//${host}${path}?${params.toString()}`;
  }

  setupSocketEvents(resolve, reject) {
    this.socket.onopen = (event) => {
      console.log('[GridWebSocket] Connected successfully');
      this.isConnected = true;
      this.reconnectAttempts = 0;
      this.stats.connectionUptime = Date.now();

      clearTimeout(this.connectionTimeout);
      this.startHeartbeat();
      this.emit('connection_status', { connected: true, event });
      resolve();
    };

    this.socket.onmessage = (event) => {
      this.handleMessage(event);
    };

    this.socket.onclose = (event) => {
      console.log('[GridWebSocket] Connection closed:', event.code, event.reason);
      this.isConnected = false;
      this.stopHeartbeat();

      this.emit('connection_status', {
        connected: false,
        code: event.code,
        reason: event.reason
      });

      // 自動再接続
      if (this.options.autoReconnect && event.code !== 1000) {
        this.attemptReconnect();
      }
    };

    this.socket.onerror = (error) => {
      console.error('[GridWebSocket] Socket error:', error);
      this.emit('error', { error, type: 'socket_error' });

      if (!this.isConnected) {
        reject(error);
      }
    };
  }

  handleMessage(event) {
    try {
      const message = JSON.parse(event.data);
      this.stats.messagesReceived++;

      // レイテンシ計算
      if (message.server_timestamp) {
        const latency = Date.now() - new Date(message.server_timestamp).getTime();
        this.updateLatencyStats(latency);
      }

      this.routeMessage(message);
      this.stats.messagesProcessed++;

    } catch (error) {
      console.error('[GridWebSocket] Message parse error:', error, event.data);
      this.emit('error', { error, type: 'message_parse_error', data: event.data });
    }
  }

  routeMessage(message) {
    const { type, data } = message;

    switch (type) {
      case 'heartbeat':
        this.send('heartbeat_ack', { timestamp: Date.now() });
        break;

      case 'grid_update':
        this.handleGridUpdate(data);
        break;

      case 'feature_moved':
        this.handleFeatureMove(data);
        break;

      case 'epic_created':
      case 'version_created':
      case 'issue_updated':
        this.emit(type, data);
        break;

      case 'user_presence':
        this.handleUserPresence(data);
        break;

      case 'conflict_detected':
        this.handleConflict(data);
        break;

      case 'server_error':
        this.emit('error', { error: data, type: 'server_error' });
        break;

      default:
        console.warn('[GridWebSocket] Unknown message type:', type);
    }
  }

  handleGridUpdate(data) {
    // 重複更新の防止
    if (data.timestamp <= this.lastUpdateTimestamp) {
      return;
    }

    this.lastUpdateTimestamp = data.timestamp;
    this.emit('grid_update', {
      ...data,
      isRemoteUpdate: true
    });
  }

  handleFeatureMove(data) {
    // 自分の操作による更新は無視
    if (data.user_id === this.userId && data.client_id === this.getClientId()) {
      return;
    }

    this.emit('feature_moved', {
      ...data,
      isRemoteUpdate: true
    });
  }

  handleUserPresence(data) {
    if (data.action === 'joined') {
      this.emit('user_joined', data.user);
    } else if (data.action === 'left') {
      this.emit('user_left', data.user);
    }
  }

  handleConflict(data) {
    console.warn('[GridWebSocket] Conflict detected:', data);
    this.emit('error', {
      type: 'optimistic_update_conflict',
      details: data,
      requiresRefresh: true
    });
  }

  attemptReconnect() {
    if (this.reconnectAttempts >= this.options.maxReconnectAttempts) {
      console.error('[GridWebSocket] Max reconnection attempts reached');
      this.emit('error', {
        type: 'max_reconnect_attempts_reached',
        attempts: this.reconnectAttempts
      });
      return;
    }

    this.reconnectAttempts++;
    this.stats.reconnectionCount++;

    const delay = this.options.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    console.log(`[GridWebSocket] Attempting reconnection ${this.reconnectAttempts}/${this.options.maxReconnectAttempts} in ${delay}ms`);

    setTimeout(() => {
      if (!this.isConnected) {
        this.connect().catch(error => {
          console.error('[GridWebSocket] Reconnection failed:', error);
        });
      }
    }, delay);
  }

  startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      if (this.isConnected) {
        this.send('heartbeat', { timestamp: Date.now() });
      }
    }, this.options.heartbeatInterval);
  }

  stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  updateLatencyStats(latency) {
    // 移動平均でレイテンシを計算
    const alpha = 0.1; // 平滑化係数
    this.stats.averageLatency = this.stats.averageLatency * (1 - alpha) + latency * alpha;
  }

  emit(event, data) {
    const handlers = this.eventHandlers[event];
    if (handlers) {
      handlers.forEach(handler => {
        try {
          handler(data);
        } catch (error) {
          console.error(`[GridWebSocket] Event handler error for ${event}:`, error);
        }
      });
    }
  }

  getClientId() {
    if (!this.clientId) {
      this.clientId = `client_${Date.now()}_${Math.random().toString(36).substring(2)}`;
    }
    return this.clientId;
  }

  getAuthToken() {
    // CSRFトークンまたはJWTトークンを取得
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : '';
  }

  /**
   * 統計情報取得
   */
  getConnectionStats() {
    return {
      ...this.stats,
      connected: this.isConnected,
      uptime: this.isConnected ? Date.now() - this.stats.connectionUptime : 0,
      reconnectAttempts: this.reconnectAttempts
    };
  }

  /**
   * シングルトンパターン実装
   */
  static getInstance(projectId, userId, options) {
    const key = `${projectId}_${userId}`;

    if (!this.instances.has(key)) {
      this.instances.set(key, new GridWebSocketService(projectId, userId, options));
    }

    return this.instances.get(key);
  }

  static removeInstance(projectId, userId) {
    const key = `${projectId}_${userId}`;
    const instance = this.instances.get(key);

    if (instance) {
      instance.disconnect();
      this.instances.delete(key);
    }
  }
}

/**
 * WebSocketイベントデータ型定義（TypeScriptドキュメント用）
 */
/*
interface GridUpdateEvent {
  type: 'grid_update';
  data: {
    updated_issues: Issue[];
    deleted_issues: number[];
    grid_changes: GridChange[];
    timestamp: string;
    user_id: number;
  };
}

interface FeatureMoveEvent {
  type: 'feature_moved';
  data: {
    issue_id: number;
    source_cell: CellCoordinate;
    target_cell: CellCoordinate;
    updated_issue: Issue;
    timestamp: string;
    user_id: number;
    client_id: string;
  };
}

interface UserPresenceEvent {
  type: 'user_presence';
  data: {
    action: 'joined' | 'left';
    user: {
      id: number;
      name: string;
      avatar_url?: string;
    };
    online_users_count: number;
  };
}
*/

export default GridWebSocketService;