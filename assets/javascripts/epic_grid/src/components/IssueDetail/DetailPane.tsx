import React, { useState, useEffect, useRef, useCallback } from 'react';
import type { SelectedEntity } from '../../types/normalized-api';
import { useStore } from '../../store/useStore';

interface DetailPaneProps {
  entity: SelectedEntity | null;
  projectId: string | null;
}

/**
 * 詳細ペインコンポーネント（汎用）
 * RedmineのIssue/Version詳細ページをiframeで表示
 */
export const DetailPane: React.FC<DetailPaneProps> = ({
  entity,
  projectId,
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const previousEntityRef = useRef(entity);
  const loadTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Zustand storeからVersionデータ取得（タイトル表示用）
  const versions = useStore(state => state.entities.versions);

  // iframeのURL生成（汎用化）
  const getIframeUrl = useCallback((): string | null => {
    if (!entity) return null;

    switch (entity.type) {
      case 'issue':
        return `/issues/${entity.id}`;
      case 'version':
        return `/versions/${entity.id}`;
      default:
        return null;
    }
  }, [entity]);

  // タイトル生成（汎用化）
  const getTitle = useCallback((): string => {
    if (!entity) return '';

    switch (entity.type) {
      case 'issue':
        return `チケット #${entity.id}`;
      case 'version': {
        const version = versions[entity.id];
        return version ? `バージョン: ${version.name}` : `バージョン #${entity.id}`;
      }
      default:
        return '';
    }
  }, [entity, versions]);

  // Entity IDが変更されたときの処理
  useEffect(() => {
    if (entity !== previousEntityRef.current) {
      previousEntityRef.current = entity;
    }

    if (entity) {
      setIsLoading(true);
      setError(null);

      // 既存のタイムアウトをクリア
      if (loadTimeoutRef.current) {
        clearTimeout(loadTimeoutRef.current);
      }

      // 3秒経過してもiframeのonLoadが発火しない場合、強制的にローディング解除
      loadTimeoutRef.current = setTimeout(() => {
        setIsLoading(false);
        loadTimeoutRef.current = null;
      }, 3000);

      return () => {
        if (loadTimeoutRef.current) {
          clearTimeout(loadTimeoutRef.current);
          loadTimeoutRef.current = null;
        }
      };
    }
  }, [entity]);

  // iframeの読み込み完了処理
  const handleIframeLoad = useCallback(() => {
    // タイムアウトをクリア（正常に読み込まれた場合）
    if (loadTimeoutRef.current) {
      clearTimeout(loadTimeoutRef.current);
      loadTimeoutRef.current = null;
    }
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
    // タイムアウトをクリア（エラー時）
    if (loadTimeoutRef.current) {
      clearTimeout(loadTimeoutRef.current);
      loadTimeoutRef.current = null;
    }
    setIsLoading(false);
    setError('詳細の読み込みに失敗しました');
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

  if (!entity) {
    return (
      <div className="issue-detail-pane issue-detail-pane--empty">
        <div className="issue-detail-pane__placeholder">
          <svg className="issue-detail-pane__placeholder-icon" width="64" height="64" viewBox="0 0 64 64" fill="none">
            <path d="M22 16h20M22 32h20M22 48h12" stroke="#ccc" strokeWidth="2" strokeLinecap="round"/>
            <rect x="8" y="8" width="48" height="48" rx="4" stroke="#ccc" strokeWidth="2" fill="none"/>
          </svg>
          <p className="issue-detail-pane__placeholder-text">
            チケットまたはバージョンを選択すると詳細が表示されます
          </p>
        </div>
      </div>
    );
  }

  const iframeUrl = getIframeUrl();
  const title = getTitle();

  return (
    <div className="issue-detail-pane">
      <div className="issue-detail-pane__header">
        <h3 className="issue-detail-pane__title">
          {title}
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
            title={title}
            style={{ display: isLoading || error ? 'none' : 'block' }}
          />
        )}
      </div>
    </div>
  );
};
