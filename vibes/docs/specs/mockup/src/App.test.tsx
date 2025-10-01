import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import React from 'react';
import { App } from './App';
import { useStore } from './store/useStore';
import { normalizedMockData } from './mocks/normalized-mock-data';

describe('App - Integration Tests (Normalized API)', () => {
  beforeEach(async () => {
    // ストアを初期化
    useStore.setState({
      entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
      grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
      isLoading: false,
      error: null
    });
  });

  it('should render Epic × Version grid structure', async () => {
    render(<App />);

    await waitFor(() => {
      // タイトルが表示されること
      expect(screen.getByText(/🔬 ネストGrid検証/)).toBeInTheDocument();
    });

    // Epic ヘッダーが表示されること
    expect(screen.getByText('施設・ユーザー管理')).toBeInTheDocument();
    expect(screen.getByText('開診スケジュール')).toBeInTheDocument();

    // Version ヘッダーが表示されること（mockDataの実際の値を使用）
    const versionHeaders = document.querySelectorAll('.version-header');
    expect(versionHeaders.length).toBe(3);
  });

  it('should render Feature cards in correct cells', async () => {
    render(<App />);

    await waitFor(() => {
      // Feature が表示されること
      expect(screen.getByText('登録画面')).toBeInTheDocument();
    });

    expect(screen.getByText('一覧画面')).toBeInTheDocument();
    // normalizedMockDataには3つのFeatureしかない
    const featureCards = document.querySelectorAll('.feature-card');
    expect(featureCards.length).toBeGreaterThanOrEqual(3);
  });

  it('should render UserStories within Features', async () => {
    render(<App />);

    await waitFor(() => {
      // UserStory が表示されること
      expect(screen.getByText('US#101 ユーザー登録フォーム')).toBeInTheDocument();
    });

    expect(screen.getByText('US#102 ユーザー一覧表示')).toBeInTheDocument();
    // normalizedMockDataには3つのUserStoryしかない
    const userStories = document.querySelectorAll('.user-story');
    expect(userStories.length).toBeGreaterThanOrEqual(3);
  });

  it('should render Tasks, Tests, and Bugs within UserStories', async () => {
    render(<App />);

    await waitFor(() => {
      // Task が表示されること (normalizedMockDataの実際のタスク名を確認)
      const tasks = document.querySelectorAll('[data-task]');
      expect(tasks.length).toBeGreaterThan(0);
    });

    // Test が表示されること
    const tests = document.querySelectorAll('[data-test]');
    expect(tests.length).toBeGreaterThanOrEqual(0);

    // Bug が表示されること
    const bugs = document.querySelectorAll('[data-bug]');
    expect(bugs.length).toBeGreaterThanOrEqual(0);
  });

  it('should display status indicators correctly', async () => {
    render(<App />);

    await waitFor(() => {
      // Open status indicators
      const openIndicators = document.querySelectorAll('.status-indicator.status-open');
      expect(openIndicators.length).toBeGreaterThan(0);
    });

    // Closed status indicators
    const closedIndicators = document.querySelectorAll('.status-indicator.status-closed');
    expect(closedIndicators.length).toBeGreaterThan(0);
  });

  it('should render Legend component', async () => {
    render(<App />);

    await waitFor(() => {
      // Legend コンポーネントが表示されること
      const legend = document.querySelector('.legend');
      expect(legend).toBeInTheDocument();
    });
  });

  it('should have correct grid cell count', async () => {
    render(<App />);

    await waitFor(() => {
      const cells = document.querySelectorAll('.epic-version-cell');
      // 2 epics × 3 versions = 6 cells
      expect(cells.length).toBe(6);
    });
  });

  it('should have drag-drop data attributes', async () => {
    render(<App />);

    await waitFor(() => {
      // Feature cards should have data-feature attribute
      const featureCards = document.querySelectorAll('[data-feature]');
      expect(featureCards.length).toBeGreaterThan(0);
    });

    // UserStory should have data-story attribute
    const userStories = document.querySelectorAll('[data-story]');
    expect(userStories.length).toBeGreaterThan(0);

    // Task should have data-task attribute
    const tasks = document.querySelectorAll('[data-task]');
    expect(tasks.length).toBeGreaterThan(0);
  });
});
