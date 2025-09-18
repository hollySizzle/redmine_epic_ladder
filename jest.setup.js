// Jest DOM拡張をインポート
import '@testing-library/jest-dom';

// グローバルモックの設定
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));

// console.error, console.warnのモック（テスト中の不要な出力を抑制）
global.console = {
  ...console,
  error: jest.fn(),
  warn: jest.fn(),
};

// DHTMLX Ganttのモック
global.gantt = {
  init: jest.fn(),
  parse: jest.fn(),
  clearAll: jest.fn(),
  render: jest.fn(),
  config: {},
  templates: {},
  attachEvent: jest.fn(),
  detachEvent: jest.fn(),
  ext: {
    zoom: {
      setLevel: jest.fn(),
    }
  }
};

// LocalStorageのモック
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};
global.localStorage = localStorageMock;

// fetchのモック
global.fetch = jest.fn();