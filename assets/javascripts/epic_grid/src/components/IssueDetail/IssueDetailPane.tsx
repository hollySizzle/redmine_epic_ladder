import React, { useState, useEffect, useRef, useCallback } from 'react';

interface IssueDetailPaneProps {
  issueId: string | null;
  projectId: string | null;
  onIssueUpdate?: (issueId: string, data: any) => void;
  pollingInterval?: number;
  refreshKey?: number;
}

/**
 * Issue詳細ペインコンポーネント
 * Redmineのチケット詳細ページをiframeで表示
 */
export const IssueDetailPane: React.FC<IssueDetailPaneProps> = ({
  issueId,
  projectId,
  onIssueUpdate,
  pollingInterval = 30000,
  refreshKey = 0
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const previousIssueIdRef = useRef(issueId);

  // iframeのURL生成
  const getIframeUrl = useCallback(() => {
    if (!issueId) return null;
    return `/issues/${issueId}`;
  }, [issueId]);

  // Issue IDが変更されたときの処理
  useEffect(() => {
    if (issueId !== previousIssueIdRef.current) {
      previousIssueIdRef.current = issueId;
    }

    if (issueId) {
      setIsLoading(true);
      setError(null);
    }
  }, [issueId]);

  // refreshKey が変更されたときの iframe 強制リロード
  useEffect(() => {
    if (refreshKey > 0 && iframeRef.current && issueId) {
      console.log('IssueDetailPane: refreshKey変更によりiframeをリロード', { issueId, refreshKey });
      setIsLoading(true);
      setError(null);

      // iframeのsrcを一度空にしてから再設定することで強制リロード
      const currentSrc = getIframeUrl();
      if (currentSrc) {
        iframeRef.current.src = 'about:blank';

        setTimeout(() => {
          if (iframeRef.current && currentSrc) {
            iframeRef.current.src = currentSrc + '?t=' + Date.now(); // キャッシュバスターを追加
          }
        }, 100);
      }
    }
  }, [refreshKey, issueId, getIframeUrl]);

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
          .contextual { position: sticky; top: 0; background: white; z-index: 10; }
        `;
        iframeDoc.head.appendChild(style);
      }
    } catch (e) {
      // Same-origin policyエラーは無視
      console.debug('Same-origin policy制約により、iframe内のスタイル調整をスキップ');
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
      const url = getIframeUrl();
      if (url) {
        iframeRef.current.src = url + '?t=' + Date.now();
      }
    }
  }, [getIframeUrl]);

  if (!issueId) {
    return (
      <div className="issue-detail-pane issue-detail-pane--empty">
        <div className="issue-detail-pane__placeholder">
          <svg className="issue-detail-pane__placeholder-icon" width="64" height="64" viewBox="0 0 64 64" fill="none">
            <path d="M22 16h20M22 32h20M22 48h12" stroke="#ccc" strokeWidth="2" strokeLinecap="round"/>
            <rect x="8" y="8" width="48" height="48" rx="4" stroke="#ccc" strokeWidth="2" fill="none"/>
          </svg>
          <p className="issue-detail-pane__placeholder-text">
            チケットを選択すると詳細が表示されます
          </p>
        </div>
      </div>
    );
  }

  const iframeUrl = getIframeUrl();

  return (
    <div className="issue-detail-pane">
      <div className="issue-detail-pane__header">
        <h3 className="issue-detail-pane__title">
          チケット #{issueId}
        </h3>
        <div className="issue-detail-pane__actions">
          <button
            className="issue-detail-pane__reload"
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

      <div className="issue-detail-pane__content">
        {isLoading && (
          <div className="issue-detail-pane__loading">
            <div className="issue-detail-pane__spinner" />
            <p>読み込み中...</p>
          </div>
        )}

        {error && (
          <div className="issue-detail-pane__error">
            <p>{error}</p>
            <button onClick={handleReload}>再試行</button>
          </div>
        )}

        {iframeUrl && (
          <iframe
            ref={iframeRef}
            className="issue-detail-pane__iframe"
            src={iframeUrl}
            onLoad={handleIframeLoad}
            onError={handleIframeError}
            title={`チケット #${issueId} の詳細`}
            style={{ display: isLoading || error ? 'none' : 'block' }}
          />
        )}
      </div>
    </div>
  );
};
