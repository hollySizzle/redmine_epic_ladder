import { afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import * as matchers from '@testing-library/jest-dom/matchers';
import { expect } from 'vitest';

// jest-dom matchers を vitest に追加
expect.extend(matchers);

// テスト後のクリーンアップ
afterEach(() => {
  cleanup();
});
