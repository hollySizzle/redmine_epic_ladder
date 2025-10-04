import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import { worker } from './mocks/browser';

console.log('✅ React application starting...');

// MSWを強制的に有効化（Redmine統合テスト用）
// TODO: 本番APIが完成したら process.env.NODE_ENV === 'development' に戻す

// MSW Service Worker のURLを取得（Redmineから注入される）
const serviceWorkerUrl = (window as any).MSW_SERVICE_WORKER_URL || '/mockServiceWorker.js';
console.log('🔧 MSW Service Worker URL:', serviceWorkerUrl);

worker.start({
  serviceWorker: {
    url: serviceWorkerUrl
  }
}).then(() => {
  console.log('[MSW] Mock Service Worker started');
  mountApp();
}).catch((error) => {
  console.error('[MSW] Failed to start:', error);
  mountApp(); // エラーでもアプリは起動する
});

function mountApp() {
  const rootElement = document.getElementById('kanban-root');

  if (rootElement) {
    const root = ReactDOM.createRoot(rootElement);
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    );
    console.log('🎯 React application mounted successfully!');
  } else {
    console.error('❌ Root element not found! Looking for #kanban-root');
  }
}
