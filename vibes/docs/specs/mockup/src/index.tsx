import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';

console.log('✅ React application starting...');

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
