import { useEffect, useCallback, useRef, useState } from 'react';
import { useKanbanAPI } from './useKanbanAPI';

/**
 * Realtime Updates Hook
 * リアルタイム更新の購読・処理を管理するカスタムフック
 *
 * @param {number} projectId - プロジェクトID
 * @param {Function} onUpdate - 更新コールバック
 * @param {Object} options - 設定オプション
 */
export function useRealtimeUpdates(projectId, onUpdate, options = {}) {
  const { api } = useKanbanAPI(projectId);
  const [isConnected, setIsConnected] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState(null);

  const websocketRef = useRef(null);
  const pollingIntervalRef = useRef(null);
  const heartbeatIntervalRef = useRef(null);

  const {
    enableWebSocket = true,
    enablePolling = true,
    pollingInterval = 30000, // 30秒
    heartbeatInterval = 60000, // 1分
    maxReconnectAttempts = 5,
    reconnectDelay = 5000 // 5秒
  } = options;

  // WebSocket接続
  const connectWebSocket = useCallback(async () => {
    if (!enableWebSocket || websocketRef.current?.readyState === WebSocket.OPEN) {
      return;
    }

    try {
      // サーバーから接続情報を取得
      const subscriptionData = await api.subscribeToUpdates();
      const { channel } = subscriptionData.data;

      // WebSocket接続を確立
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = `${protocol}//${window.location.host}/cable`;

      websocketRef.current = new WebSocket(wsUrl);

      websocketRef.current.onopen = () => {
        setIsConnected(true);

        // チャンネルに購読
        websocketRef.current.send(JSON.stringify({
          command: 'subscribe',
          identifier: JSON.stringify({ channel })
        }));

        // ハートビート開始
        startHeartbeat();
      };

      websocketRef.current.onmessage = (event) => {
        const data = JSON.parse(event.data);

        if (data.type === 'ping') {
          // Pong応答
          websocketRef.current.send(JSON.stringify({ type: 'pong' }));
        } else if (data.message) {
          // 更新通知を処理
          handleRealtimeUpdate(data.message);
        }
      };

      websocketRef.current.onclose = () => {
        setIsConnected(false);
        stopHeartbeat();

        // 再接続を試行
        setTimeout(() => {
          if (enableWebSocket) {
            connectWebSocket();
          }
        }, reconnectDelay);
      };

      websocketRef.current.onerror = (error) => {
        console.error('WebSocket error:', error);
        setIsConnected(false);
      };

    } catch (error) {
      console.error('Failed to connect WebSocket:', error);

      // WebSocketが使用できない場合はポーリングにフォールバック
      if (enablePolling) {
        startPolling();
      }
    }
  }, [api, enableWebSocket, reconnectDelay]);

  // ポーリング開始
  const startPolling = useCallback(() => {
    if (!enablePolling || pollingIntervalRef.current) {
      return;
    }

    pollingIntervalRef.current = setInterval(async () => {
      try {
        const updates = await api.pollUpdates(lastUpdateTime?.toISOString());

        if (updates.data.updates && updates.data.updates.length > 0) {
          handlePollingUpdates(updates.data.updates);
          setLastUpdateTime(new Date(updates.data.current_timestamp));
        }
      } catch (error) {
        console.error('Polling error:', error);
      }
    }, pollingInterval);
  }, [api, enablePolling, pollingInterval, lastUpdateTime]);

  // ハートビート開始
  const startHeartbeat = useCallback(() => {
    if (heartbeatIntervalRef.current) {
      clearInterval(heartbeatIntervalRef.current);
    }

    heartbeatIntervalRef.current = setInterval(async () => {
      try {
        await api.sendHeartbeat();
      } catch (error) {
        console.error('Heartbeat failed:', error);
      }
    }, heartbeatInterval);
  }, [api, heartbeatInterval]);

  // ハートビート停止
  const stopHeartbeat = useCallback(() => {
    if (heartbeatIntervalRef.current) {
      clearInterval(heartbeatIntervalRef.current);
      heartbeatIntervalRef.current = null;
    }
  }, []);

  // リアルタイム更新処理
  const handleRealtimeUpdate = useCallback((updateData) => {
    setLastUpdateTime(new Date());

    if (onUpdate) {
      onUpdate(updateData);
    }
  }, [onUpdate]);

  // ポーリング更新処理
  const handlePollingUpdates = useCallback((updates) => {
    updates.forEach(update => {
      handleRealtimeUpdate(update);
    });
  }, [handleRealtimeUpdate]);

  // 接続開始
  const connect = useCallback(() => {
    if (enableWebSocket) {
      connectWebSocket();
    } else if (enablePolling) {
      startPolling();
    }
  }, [enableWebSocket, enablePolling, connectWebSocket, startPolling]);

  // 接続停止
  const disconnect = useCallback(async () => {
    // WebSocket切断
    if (websocketRef.current) {
      websocketRef.current.close();
      websocketRef.current = null;
    }

    // ポーリング停止
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
      pollingIntervalRef.current = null;
    }

    // ハートビート停止
    stopHeartbeat();

    // サーバー側購読停止
    try {
      await api.unsubscribeFromUpdates();
    } catch (error) {
      console.error('Failed to unsubscribe:', error);
    }

    setIsConnected(false);
  }, [api, stopHeartbeat]);

  // 自動接続
  useEffect(() => {
    connect();

    return () => {
      disconnect();
    };
  }, [connect]); // disconnectは依存に含めない（無限ループ防止）

  // ページ非表示時の処理
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // ページが非表示になったら接続を停止
        disconnect();
      } else {
        // ページが表示されたら再接続
        connect();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [connect, disconnect]);

  return {
    isConnected,
    lastUpdateTime,
    connect,
    disconnect,

    // デバッグ用
    hasWebSocket: !!websocketRef.current,
    hasPolling: !!pollingIntervalRef.current
  };
}