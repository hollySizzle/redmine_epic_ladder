import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import { useStore } from './store/useStore';

console.log('✅ React application starting...');

// Expose store globally for debugging/E2E tests
(window as any).useStore = useStore;

// 開発環境でのみMSWを起動
const mountApp = () => {
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
};

if (process.env.NODE_ENV === 'development') {
  // 開発環境: MSWを起動してからアプリをマウント
  import('./mocks/browser')
    .then(({ startMocking }) => {
      startMocking()
        .then(() => {
          console.log('✅ MSW initialization completed');
          mountApp();
        })
        .catch((error) => {
          console.error('❌ Failed to start MSW:', error);
          console.warn('⚠️ Mounting React app without MSW...');
          mountApp();
        });
    })
    .catch((error) => {
      console.error('❌ Failed to load MSW module:', error);
      console.warn('⚠️ Mounting React app without MSW...');
      mountApp();
    });
} else {
  // 本番環境: 直接アプリをマウント
  mountApp();
}
