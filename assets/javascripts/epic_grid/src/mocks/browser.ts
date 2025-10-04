import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

// ブラウザ用MSWワーカー
export const worker = setupWorker(...handlers);

// 開発モードでワーカーを起動
export const startMocking = async () => {
  if (process.env.NODE_ENV === 'development') {
    await worker.start();
    console.log('[MSW] Mock Service Worker started');
  }
};
