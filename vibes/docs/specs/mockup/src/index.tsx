import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';

console.log('✅ React application starting...');

// 開発モードでMSWを起動
if (process.env.NODE_ENV === 'development') {
  import('./mocks/browser').then(({ worker }) => {
    worker.start({
      onUnhandledRequest: 'warn',
      quiet: false,
      serviceWorker: {
        url: '/mockServiceWorker.js'
      }
    }).then(() => {
      console.log('[MSW] Mock Service Worker started');
      mountApp();
    }).catch((error) => {
      console.error('[MSW] Failed to start:', error);
      mountApp(); // エラーでもアプリは起動する
    });
  });
} else {
  mountApp();
}

function mountApp() {
  const rootElement = document.getElementById('root');

  if (rootElement) {
    const root = ReactDOM.createRoot(rootElement);
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    );
    console.log('🎯 React application mounted successfully!');
  } else {
    console.error('❌ Root element not found!');
  }
}
