import { afterEach, beforeAll, afterAll } from 'vitest';
import { cleanup } from '@testing-library/react';
import * as matchers from '@testing-library/jest-dom/matchers';
import { expect } from 'vitest';
import { server } from './mocks/server';

// jest-dom matchers を vitest に追加
expect.extend(matchers);

// MSWサーバーのセットアップ
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  server.resetHandlers();
  cleanup();
});
afterAll(() => server.close());
