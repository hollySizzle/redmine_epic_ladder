import React, { useState, useEffect } from 'react';
import { getOptimisticUpdateService } from '../services/OptimisticUpdateService.js';

/**
 * OptimisticUpdateIndicator - 楽観的更新状態表示コンポーネント
 * 設計書仕様: ユーザーフィードバック、ロードバランス、エラー状態表示
 */
export const OptimisticUpdateIndicator = ({
  projectId,
  compact = false,
  showStatistics = false,
  onRetryUpdate = null
}) => {
  const [updateStats, setUpdateStats] = useState(null);
  const [recentUpdates, setRecentUpdates] = useState([]);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    if (!projectId) return;

    const optimisticService = getOptimisticUpdateService();

    // 定期的な統計情報更新
    const interval = setInterval(() => {
      const stats = optimisticService.getStatistics();
      const updates = optimisticService.getUpdateHistory(10);

      setUpdateStats(stats);
      setRecentUpdates(updates);

      // アクティブな更新がある場合のみ表示
      setIsVisible(stats.pendingUpdates > 0 || stats.recentConflicts > 0);
    }, 1000);

    return () => clearInterval(interval);
  }, [projectId]);

  if (!isVisible || !updateStats) {
    return null;
  }

  const renderCompactIndicator = () => (
    <div className="optimistic-update-indicator compact">
      <div className="indicator-content">
        {updateStats.pendingUpdates > 0 && (
          <div className="pending-indicator">
            <div className="spinner" />
            <span className="pending-count">{updateStats.pendingUpdates}</span>
          </div>
        )}

        {updateStats.recentConflicts > 0 && (
          <div className="conflict-indicator" title="更新の衝突が発生しました">
            <span className="conflict-icon">⚠️</span>
            <span className="conflict-count">{updateStats.recentConflicts}</span>
          </div>
        )}
      </div>
    </div>
  );

  const renderFullIndicator = () => (
    <div className="optimistic-update-indicator full">
      <div className="indicator-header">
        <h4>リアルタイム更新状況</h4>
        <div className="connection-status">
          <span className={`status-dot ${updateStats.pendingUpdates === 0 ? 'connected' : 'updating'}`} />
          <span className="status-text">
            {updateStats.pendingUpdates === 0 ? '同期済み' : `${updateStats.pendingUpdates}件更新中`}
          </span>
        </div>
      </div>

      <div className="indicator-body">
        {/* 統計情報 */}
        {showStatistics && (
          <div className="statistics-section">
            <div className="stat-group">
              <div className="stat-item">
                <span className="stat-label">総更新数:</span>
                <span className="stat-value">{updateStats.totalUpdates}</span>
              </div>
              <div className="stat-item">
                <span className="stat-label">成功率:</span>
                <span className="stat-value">
                  {updateStats.totalUpdates > 0
                    ? Math.round((updateStats.successfulUpdates / updateStats.totalUpdates) * 100)
                    : 100
                  }%
                </span>
              </div>
              <div className="stat-item">
                <span className="stat-label">平均レスポンス:</span>
                <span className="stat-value">{Math.round(updateStats.averageLatency)}ms</span>
              </div>
            </div>
          </div>
        )}

        {/* 進行中の更新 */}
        {updateStats.pendingUpdates > 0 && (
          <div className="pending-updates-section">
            <h5>処理中の更新</h5>
            {recentUpdates
              .filter(update => update.status === 'pending')
              .slice(0, 3)
              .map(update => (
                <div key={update.id} className="update-item pending">
                  <div className="update-info">
                    <span className="update-type">{getUpdateTypeLabel(update.type)}</span>
                    <span className="update-time">
                      {formatElapsedTime(Date.now() - update.timestamp)}
                    </span>
                  </div>
                  <div className="update-progress">
                    <div className="progress-bar" />
                  </div>
                </div>
              ))
            }
          </div>
        )}

        {/* 最近の衝突 */}
        {updateStats.recentConflicts > 0 && (
          <div className="conflicts-section">
            <h5>更新の衝突</h5>
            {recentUpdates
              .filter(update => update.status === 'failed')
              .slice(0, 2)
              .map(update => (
                <div key={update.id} className="update-item conflict">
                  <div className="update-info">
                    <span className="update-type">{getUpdateTypeLabel(update.type)}</span>
                    <span className="error-message">{update.error?.message || '不明なエラー'}</span>
                  </div>
                  <div className="update-actions">
                    {onRetryUpdate && (
                      <button
                        className="retry-button"
                        onClick={() => onRetryUpdate(update)}
                        title="再試行"
                      >
                        🔄
                      </button>
                    )}
                  </div>
                </div>
              ))
            }
          </div>
        )}

        {/* 成功した更新 */}
        {recentUpdates.filter(u => u.status === 'success').length > 0 && (
          <div className="success-updates-section">
            <h5>最近の更新</h5>
            {recentUpdates
              .filter(update => update.status === 'success')
              .slice(0, 2)
              .map(update => (
                <div key={update.id} className="update-item success">
                  <div className="update-info">
                    <span className="update-type">{getUpdateTypeLabel(update.type)}</span>
                    <span className="update-time">
                      {formatElapsedTime(Date.now() - update.completedAt)}前
                    </span>
                  </div>
                  <div className="success-icon">✓</div>
                </div>
              ))
            }
          </div>
        )}
      </div>
    </div>
  );

  return compact ? renderCompactIndicator() : renderFullIndicator();
};

// ヘルパー関数
function getUpdateTypeLabel(type) {
  const labels = {
    'move_feature': 'Feature移動',
    'create_epic': 'Epic作成',
    'create_version': 'Version作成',
    'assign_version': 'Version割当',
    'update_issue': 'Issue更新'
  };
  return labels[type] || type;
}

function formatElapsedTime(ms) {
  const seconds = Math.floor(ms / 1000);
  if (seconds < 60) return `${seconds}秒`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}分`;
  const hours = Math.floor(minutes / 60);
  return `${hours}時間`;
}

/**
 * OptimisticUpdateToast - トースト通知コンポーネント
 */
export const OptimisticUpdateToast = ({
  message,
  type = 'info',
  duration = 3000,
  onClose
}) => {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
      onClose?.();
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  if (!isVisible) return null;

  const getTypeIcon = () => {
    switch (type) {
      case 'success': return '✓';
      case 'error': return '✗';
      case 'warning': return '⚠️';
      case 'info':
      default: return 'ℹ️';
    }
  };

  return (
    <div className={`optimistic-update-toast ${type}`}>
      <div className="toast-content">
        <span className="toast-icon">{getTypeIcon()}</span>
        <span className="toast-message">{message}</span>
      </div>
      <button
        className="toast-close"
        onClick={() => {
          setIsVisible(false);
          onClose?.();
        }}
      >
        ×
      </button>
    </div>
  );
};

/**
 * OptimisticUpdateDebugPanel - 開発者用デバッグパネル
 */
export const OptimisticUpdateDebugPanel = ({ projectId }) => {
  const [debugInfo, setDebugInfo] = useState(null);
  const [isExpanded, setIsExpanded] = useState(false);

  useEffect(() => {
    if (!projectId || !isExpanded) return;

    const optimisticService = getOptimisticUpdateService();

    const interval = setInterval(() => {
      const stats = optimisticService.getStatistics();
      const history = optimisticService.getUpdateHistory(20);

      setDebugInfo({
        statistics: stats,
        updateHistory: history,
        timestamp: new Date().toISOString()
      });
    }, 2000);

    return () => clearInterval(interval);
  }, [projectId, isExpanded]);

  if (!debugInfo) return null;

  return (
    <div className="optimistic-update-debug-panel">
      <div className="debug-header">
        <button
          className="debug-toggle"
          onClick={() => setIsExpanded(!isExpanded)}
        >
          {isExpanded ? '🔽' : '▶️'} Optimistic Update Debug
        </button>
      </div>

      {isExpanded && (
        <div className="debug-content">
          <div className="debug-section">
            <h4>Statistics</h4>
            <pre>{JSON.stringify(debugInfo.statistics, null, 2)}</pre>
          </div>

          <div className="debug-section">
            <h4>Recent Updates ({debugInfo.updateHistory.length})</h4>
            <div className="update-list">
              {debugInfo.updateHistory.map(update => (
                <div key={update.id} className={`debug-update ${update.status}`}>
                  <div className="update-summary">
                    <span className="update-id">{update.id}</span>
                    <span className="update-type">{update.type}</span>
                    <span className="update-status">{update.status}</span>
                  </div>
                  {update.error && (
                    <div className="update-error">
                      Error: {update.error.message}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="debug-actions">
            <button
              onClick={() => {
                const service = getOptimisticUpdateService();
                service.clearHistory();
                setDebugInfo({ ...debugInfo, updateHistory: [] });
              }}
            >
              Clear History
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default OptimisticUpdateIndicator;