import React, { useState, useEffect, useRef, useCallback } from 'react';
import { GanttSettings } from '../utils/cookieUtils';
import './TaskDetailPane.scss';

/**
 * タスク詳細ペインコンポーネント
 * Redmineのチケット詳細ページをiframeで表示し、ポーリングで状態を同期
 */
const TaskDetailPane = ({ taskId, projectId, onTaskUpdate, pollingInterval = 30000, refreshKey }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  const iframeRef = useRef(null);
  const pollingTimerRef = useRef(null);
  const previousTaskIdRef = useRef(taskId);

  // iframeのURL生成
  const getIframeUrl = useCallback(() => {
    if (!taskId) return null;
    return `/issues/${taskId}`;
  }, [taskId]);

  // タスクステータスのポーリング
  const pollTaskStatus = useCallback(async () => {
    if (!taskId || !projectId) return;

    try {
      const response = await fetch(`/projects/${projectId}/react_gantt_chart/task/${taskId}/status`, {
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setLastUpdated(new Date());
      
      // タスクが更新されていたらコールバックを呼ぶ
      if (onTaskUpdate && data.updated) {
        onTaskUpdate(taskId, data);
      }
    } catch (err) {
      console.error('Failed to poll task status:', err);
      // エラーは静かに処理（ユーザーには表示しない）
    }
  }, [taskId, projectId, onTaskUpdate]);

  // ポーリングの開始/停止
  useEffect(() => {
    // タスクIDが変わったらポーリングをリセット
    if (taskId !== previousTaskIdRef.current) {
      previousTaskIdRef.current = taskId;
      if (pollingTimerRef.current) {
        clearInterval(pollingTimerRef.current);
      }
    }

    if (taskId && pollingInterval > 0) {
      // 即座に1回ポーリング
      pollTaskStatus();
      
      // 定期ポーリング開始
      pollingTimerRef.current = setInterval(pollTaskStatus, pollingInterval);
    }

    return () => {
      if (pollingTimerRef.current) {
        clearInterval(pollingTimerRef.current);
      }
    };
  }, [taskId, pollingInterval, pollTaskStatus]);

  // タスクIDが変更されたときの処理
  useEffect(() => {
    if (taskId) {
      setIsLoading(true);
      setError(null);
      GanttSettings.setLastSelectedTask(taskId);
    }
  }, [taskId]);

  // refreshKey が変更されたときの iframe 強制リロード
  useEffect(() => {
    if (refreshKey > 0 && iframeRef.current && taskId) {
      console.log('TaskDetailPane: refreshKey変更によりiframeをリロード', { taskId, refreshKey });
      setIsLoading(true);
      setError(null);
      
      // iframeのsrcを一度空にしてから再設定することで強制リロード
      const currentSrc = getIframeUrl();
      iframeRef.current.src = 'about:blank';
      
      setTimeout(() => {
        if (iframeRef.current) {
          iframeRef.current.src = currentSrc + '?t=' + Date.now(); // キャッシュバスターを追加
        }
      }, 100);
    }
  }, [refreshKey, taskId, getIframeUrl]);

  // iframeの読み込み完了処理
  const handleIframeLoad = useCallback(() => {
    setIsLoading(false);
    
    // iframe内のナビゲーションを監視
    try {
      const iframe = iframeRef.current;
      if (iframe && iframe.contentWindow) {
        // Same-origin policyの制約内で可能な処理
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        
        // Redmineのスタイル調整（必要に応じて）
        const style = iframeDoc.createElement('style');
        style.textContent = `
          /* 2ペインモード用のスタイル調整 */
          #header, #top-menu { display: none; }
          #main { padding: 10px; }
          #content { margin: 0; }
        `;
        iframeDoc.head.appendChild(style);
      }
    } catch (e) {
      // Same-origin policyエラーは無視
    }
  }, []);

  // iframeのエラー処理
  const handleIframeError = useCallback(() => {
    setIsLoading(false);
    setError('チケット詳細の読み込みに失敗しました');
  }, []);

  // リロードボタンのハンドラ
  const handleReload = useCallback(() => {
    if (iframeRef.current) {
      setIsLoading(true);
      setError(null);
      iframeRef.current.src = getIframeUrl();
    }
  }, [getIframeUrl]);

  if (!taskId) {
    return (
      <div className="task-detail-pane task-detail-pane--empty">
        <div className="task-detail-pane__placeholder">
          <svg className="task-detail-pane__placeholder-icon" width="64" height="64" viewBox="0 0 64 64" fill="none">
            <path d="M22 16h20M22 32h20M22 48h12" stroke="#ccc" strokeWidth="2" strokeLinecap="round"/>
            <rect x="8" y="8" width="48" height="48" rx="4" stroke="#ccc" strokeWidth="2" fill="none"/>
          </svg>
          <p className="task-detail-pane__placeholder-text">
            タスクを選択すると詳細が表示されます
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="task-detail-pane">
      <div className="task-detail-pane__header">
        <h3 className="task-detail-pane__title">
          チケット #{taskId}
        </h3>
        <div className="task-detail-pane__actions">
          {lastUpdated && (
            <span className="task-detail-pane__status">
              最終確認: {lastUpdated.toLocaleTimeString()}
            </span>
          )}
          <button
            className="task-detail-pane__reload"
            onClick={handleReload}
            title="再読み込み"
          >
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M14 8a6 6 0 11-1.5-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M12.5 4L14 2.5V5.5H11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>
      </div>

      <div className="task-detail-pane__content">
        {isLoading && (
          <div className="task-detail-pane__loading">
            <div className="task-detail-pane__spinner" />
            <p>読み込み中...</p>
          </div>
        )}

        {error && (
          <div className="task-detail-pane__error">
            <p>{error}</p>
            <button onClick={handleReload}>再試行</button>
          </div>
        )}

        <iframe
          ref={iframeRef}
          className="task-detail-pane__iframe"
          src={getIframeUrl()}
          onLoad={handleIframeLoad}
          onError={handleIframeError}
          title={`チケット #${taskId} の詳細`}
          style={{ display: isLoading || error ? 'none' : 'block' }}
        />
      </div>
    </div>
  );
};

export default React.memo(TaskDetailPane);