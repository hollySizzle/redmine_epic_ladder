import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

// ブラウザ用MSWワーカー
export const worker = setupWorker(...handlers);

// タイムアウト付きPromise
const withTimeout = <T>(promise: Promise<T>, timeoutMs: number): Promise<T> => {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error(`Timeout after ${timeoutMs}ms`)), timeoutMs)
    )
  ]);
};

// 開発モードでワーカーを起動
// MSWは npm run dev (localhost:8080) でのみ動作
// Redmine本番/テスト環境では実APIを使用
export const startMocking = async () => {
  // localhost:8080 (webpack dev server) でのみMSWを起動
  const isLocalDev = window.location.hostname === 'localhost' && window.location.port === '8080';

  if (isLocalDev) {
    console.log('[MSW] 🚀 Starting Mock Service Worker...');
    console.log('[MSW] Environment:', {
      hostname: window.location.hostname,
      port: window.location.port,
      origin: window.location.origin,
      pathname: window.location.pathname
    });
    console.log('[MSW] Service Worker URL: /mockServiceWorker.js');
    console.log('[MSW] Service Worker support:', 'serviceWorker' in navigator);

    // Service Workerがサポートされているか確認
    if (!('serviceWorker' in navigator)) {
      throw new Error('Service Worker is not supported in this browser');
    }

    try {
      console.log('[MSW] 📝 Starting Service Worker registration...');

      // Service Workerを直接起動（上書き登録）
      await worker.start({
        serviceWorker: {
          url: '/mockServiceWorker.js',
          options: {
            scope: '/'
          }
        },
        onUnhandledRequest: 'bypass', // 未定義のリクエストは実APIに通す
        quiet: false // ログを表示
      });

      console.log('[MSW] ✅ Mock Service Worker started successfully (localhost:8080 development mode)');

      // 登録されたService Workerの情報を確認
      const registrations = await navigator.serviceWorker.getRegistrations();
      console.log('[MSW] 📋 Registered Service Workers:', registrations.length);
      registrations.forEach((reg, index) => {
        console.log(`[MSW] SW #${index + 1}:`, {
          scope: reg.scope,
          active: !!reg.active,
          installing: !!reg.installing,
          waiting: !!reg.waiting
        });
      });

    } catch (error) {
      console.error('[MSW] ❌ Failed to start Mock Service Worker:', error);
      console.error('[MSW] Error type:', error instanceof Error ? error.constructor.name : typeof error);
      console.error('[MSW] Error message:', error instanceof Error ? error.message : String(error));

      // Service Workerの現在の状態を確認
      try {
        const registrations = await navigator.serviceWorker.getRegistrations();
        console.error('[MSW] 🔍 Current Service Worker registrations:', registrations.length);
        if (registrations.length === 0) {
          console.error('[MSW] ⚠️ No Service Workers are registered!');
        } else {
          registrations.forEach((reg, index) => {
            console.error(`[MSW] SW #${index + 1}:`, {
              scope: reg.scope,
              active: !!reg.active,
              installing: !!reg.installing,
              waiting: !!reg.waiting
            });
          });
        }
      } catch (e) {
        console.error('[MSW] Failed to get Service Worker registrations:', e);
      }

      throw error;
    }
  } else {
    console.log('[MSW] ⏭️  Skipped - Using real API (hostname:', window.location.hostname, 'port:', window.location.port, ')');
  }
};
