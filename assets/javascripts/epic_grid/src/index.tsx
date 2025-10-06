import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import { startMocking } from './mocks/browser';
import { useStore } from './store/useStore';

console.log('✅ React application starting...');

// Expose store globally for debugging/E2E tests
(window as any).useStore = useStore;

// MSWを初期化してからReactアプリをマウント
startMocking().then(() => {
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
}).catch((error) => {
  console.error('❌ Failed to start MSW:', error);
});
