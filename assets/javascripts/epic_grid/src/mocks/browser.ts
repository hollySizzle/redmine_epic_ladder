import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

// ブラウザ用MSWワーカー
export const worker = setupWorker(...handlers);

// 開発モードでワーカーを起動
// data-disable-msw="true" 属性がある場合はスキップ（E2Eテスト用）
export const startMocking = async () => {
  const rootElement = document.getElementById('kanban-root');
  const disableMSW = rootElement?.getAttribute('data-disable-msw') === 'true';

  if (disableMSW) {
    console.log('[MSW] Disabled via data-disable-msw attribute (E2E test mode)');
    return;
  }

  if (process.env.NODE_ENV === 'development') {
    await worker.start();
    console.log('[MSW] Mock Service Worker started');
  } else {
    console.log('[MSW] Skipped (production mode)');
  }
};
