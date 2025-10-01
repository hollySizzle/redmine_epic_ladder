import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// テスト用MSWサーバー
export const server = setupServer(...handlers);

// テストセットアップヘルパー
export const setupMSW = () => {
  beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
};
