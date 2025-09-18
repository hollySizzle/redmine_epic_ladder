module.exports = {
  // テスト環境
  testEnvironment: 'jsdom',
  
  // モジュールファイル拡張子
  moduleFileExtensions: ['js', 'jsx', 'json'],
  
  // テストファイルのパターン
  testMatch: [
    '**/__tests__/**/*.(js|jsx)',
    '**/?(*.)+(spec|test).(js|jsx)'
  ],
  
  // トランスフォーム設定
  transform: {
    '^.+\\.(js|jsx)$': 'babel-jest',
  },
  
  // node_modulesのトランスフォーム設定
  transformIgnorePatterns: [
    'node_modules/(?!(dhtmlx-gantt)/)'
  ],
  
  // モジュール名マッパー（エイリアス設定）
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
    '\\.(jpg|jpeg|png|gif|svg)$': '<rootDir>/__mocks__/fileMock.js',
    'dhtmlx-gantt': '<rootDir>/__mocks__/dhtmlx-gantt.js'
  },
  
  // セットアップファイル
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  
  // カバレッジ設定
  collectCoverageFrom: [
    'assets/javascripts/react_gantt_chart/**/*.{js,jsx}',
    '!assets/javascripts/react_gantt_chart/dist/**',
    '!assets/javascripts/react_gantt_chart/index.jsx',
    '!**/node_modules/**',
  ],
  
  // カバレッジディレクトリ
  coverageDirectory: 'coverage',
  
  // テスト実行前にクリアするモック
  clearMocks: true,
  
  // テストパス無視パターン
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
  ],
  
  // モジュールディレクトリ
  moduleDirectories: ['node_modules', 'assets/javascripts'],
  
  // グローバル設定
  globals: {
    NODE_ENV: 'test'
  }
};