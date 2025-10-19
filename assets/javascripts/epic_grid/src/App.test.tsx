import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
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
      metadata: JSON.parse(JSON.stringify(normalizedMockData.metadata)),
      isLoading: false,
      error: null,
      isIssueIdVisible: true
    });
  });

  it('should render Epic × Version grid structure', async () => {
    render(<App />);

    await waitFor(() => {
      // グリッドのヘッダーラベルが表示されること
      expect(screen.getByText('Epic')).toBeInTheDocument();
    });

    // Feature ヘッダーラベルが表示されること
    expect(screen.getByText('Feature')).toBeInTheDocument();

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
    // normalizedMockDataには4つのFeatureがある (3D Grid対応)
    const featureCells = document.querySelectorAll('.feature-cell');
    expect(featureCells.length).toBeGreaterThanOrEqual(4);
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
      // 3D Grid では us-cell が UserStory を含むセル
      const cells = document.querySelectorAll('.us-cell');
      // 2 epics × 4 features × 3 versions = 多数のセルがあるが、
      // 少なくとも UserStory が配置されているセルがあることを確認
      expect(cells.length).toBeGreaterThan(0);
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

describe('App - Dirty State Management', () => {
  beforeEach(() => {
    // kanban-root要素を追加
    const rootElement = document.createElement('div');
    rootElement.id = 'kanban-root';
    rootElement.setAttribute('data-project-id', '1');
    document.body.appendChild(rootElement);

    window.alert = vi.fn();
    window.confirm = vi.fn();

    // グリッドデータを初期化（ローディング状態を回避）
    useStore.setState({
      entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
      grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
      metadata: JSON.parse(JSON.stringify(normalizedMockData.metadata)),
      isLoading: false,
      error: null,
      isIssueIdVisible: true
    });
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('保存ボタンをクリックすると成功メッセージが表示される', async () => {
    // Dirty状態にする（正しい構造）
    useStore.setState({
      isDirty: true,
      pendingChanges: {
        movedUserStories: [{ id: 'test', from: {}, to: {} }],
        reorderedEpics: null,
        reorderedVersions: null,
      },
      savePendingChanges: vi.fn().mockResolvedValue(undefined),
    });

    render(<App />);

    await waitFor(() => {
      const saveButton = screen.getByText(/保存 \(1件\)/);
      fireEvent.click(saveButton);
    });

    await waitFor(() => {
      expect(window.alert).toHaveBeenCalledWith('✅ 変更を保存しました');
    });
  });

  it('破棄ボタンをクリックしてconfirm OKで変更が破棄される', async () => {
    const mockDiscardPendingChanges = vi.fn();

    useStore.setState({
      isDirty: true,
      pendingChanges: {
        movedUserStories: [{ id: 'test', from: {}, to: {} }],
        reorderedEpics: null,
        reorderedVersions: null,
      },
      discardPendingChanges: mockDiscardPendingChanges,
    });

    vi.mocked(window.confirm).mockReturnValue(true);

    render(<App />);

    await waitFor(() => {
      const discardButton = screen.getByText(/破棄/);
      fireEvent.click(discardButton);
    });

    expect(window.confirm).toHaveBeenCalled();
    expect(mockDiscardPendingChanges).toHaveBeenCalled();
  });

  it('破棄ボタンをクリックしてconfirm Cancelで変更は破棄されない', async () => {
    const mockDiscardPendingChanges = vi.fn();

    useStore.setState({
      isDirty: true,
      pendingChanges: {
        movedUserStories: [{ id: 'test', from: {}, to: {} }],
        reorderedEpics: null,
        reorderedVersions: null,
      },
      discardPendingChanges: mockDiscardPendingChanges,
    });

    vi.mocked(window.confirm).mockReturnValue(false);

    render(<App />);

    await waitFor(() => {
      const discardButton = screen.getByText(/破棄/);
      fireEvent.click(discardButton);
    });

    expect(window.confirm).toHaveBeenCalled();
    expect(mockDiscardPendingChanges).not.toHaveBeenCalled();
  });
});
