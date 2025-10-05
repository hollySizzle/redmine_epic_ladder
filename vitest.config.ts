import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./assets/javascripts/epic_grid/src/test-setup.ts'],
    include: ['assets/javascripts/epic_grid/src/**/*.test.{ts,tsx}'],
    exclude: ['node_modules', 'dist'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './assets/javascripts/epic_grid/src'),
    },
  },
});
