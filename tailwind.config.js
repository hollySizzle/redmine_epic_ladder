/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./assets/javascripts/react_gantt_chart/**/*.{js,jsx}",
    "./node_modules/flowbite/**/*.js",
    "./node_modules/flowbite-react/**/*.js"
  ],
  theme: {
    extend: {
      colors: {
        // Redmine適合カラーパレット
        redmine: {
          primary: {
            50: '#f8fafc',
            100: '#f1f5f9', 
            200: '#e2e8f0',
            300: '#cbd5e1',
            400: '#94a3b8',
            500: '#64748b',  // メインカラー
            600: '#475569',
            700: '#334155',
            800: '#1e293b',
            900: '#0f172a',
          },
          success: {
            50: '#ecfdf5',
            100: '#d1fae5',
            200: '#a7f3d0',
            300: '#6ee7b7',
            400: '#34d399',
            500: '#10b981',  // 完了タスク
            600: '#059669',
            700: '#047857',
            800: '#065f46',
            900: '#064e3b',
          },
          warning: {
            50: '#fffbeb',
            100: '#fef3c7',
            200: '#fde68a',
            300: '#fcd34d',
            400: '#fbbf24',
            500: '#f59e0b',  // 進行中・警告
            600: '#d97706',
            700: '#b45309',
            800: '#92400e',
            900: '#78350f',
          },
          danger: {
            50: '#fef2f2',
            100: '#fee2e2',
            200: '#fecaca',
            300: '#fca5a5',
            400: '#f87171',
            500: '#ef4444',  // 遅延・エラー
            600: '#dc2626',
            700: '#b91c1c',
            800: '#991b1b',
            900: '#7f1d1d',
          }
        }
      },
      fontFamily: {
        'redmine': ['Helvetica Neue', 'Arial', 'sans-serif'],
      },
      boxShadow: {
        'redmine': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        'redmine-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
      },
      borderRadius: {
        'redmine': '0.375rem',
      }
    },
  },
  safelist: [
    "closed-task", 
    "overdue-task",
    "gantt-action-cell",
    { pattern: /^gantt_/ },
    { pattern: /^dhx_/ }
  ],
  plugins: [
    require('flowbite/plugin')
  ],
};
