import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

// ブラウザ用MSWワーカー
export const worker = setupWorker(...handlers);

// 開発モードでワーカーを起動
// MSWは npm run dev (localhost:8080) でのみ動作
// Redmine本番/テスト環境では実APIを使用
export const startMocking = async () => {
  // localhost:8080 (webpack dev server) でのみMSWを起動
  const isLocalDev = window.location.hostname === 'localhost' && window.location.port === '8080';

  if (isLocalDev) {
    await worker.start({
      onUnhandledRequest: 'bypass' // 未定義のリクエストは実APIに通す
    });
    console.log('[MSW] ✅ Mock Service Worker started (localhost:8080 development mode)');
  } else {
    console.log('[MSW] ⏭️  Skipped - Using real API (hostname:', window.location.hostname, 'port:', window.location.port, ')');
  }
};
