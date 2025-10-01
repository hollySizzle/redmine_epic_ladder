import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { App } from './App';
import { useStore } from './store/useStore';

describe('App - Integration Tests', () => {
  beforeEach(() => {
    // テスト前にストアをリセット
    useStore.setState({ cells: useStore.getState().cells });
  });

  it('should render Epic × Version grid structure', () => {
    render(<App />);

    // タイトルが表示されること
    expect(screen.getByText(/🔬 ネストGrid検証/)).toBeInTheDocument();

    // Epic ヘッダーが表示されること
    expect(screen.getByText('施設・ユーザー管理')).toBeInTheDocument();
    expect(screen.getByText('開診スケジュール')).toBeInTheDocument();

    // Version ヘッダーが表示されること
    expect(screen.getByText('Version-1')).toBeInTheDocument();
    expect(screen.getByText('Version-2')).toBeInTheDocument();
    expect(screen.getByText('Version-3')).toBeInTheDocument();
  });

  it('should render Feature cards in correct cells', () => {
    render(<App />);

    // Feature が表示されること
    expect(screen.getByText('登録画面')).toBeInTheDocument();
    expect(screen.getByText('一覧画面')).toBeInTheDocument();
    expect(screen.getByText('編集画面')).toBeInTheDocument();
    expect(screen.getByText('スケジュール登録')).toBeInTheDocument();
  });

  it('should render UserStories within Features', () => {
    render(<App />);

    // UserStory が表示されること
    expect(screen.getByText('US#101 ユーザー登録フォーム')).toBeInTheDocument();
    expect(screen.getByText('US#102 ユーザー一覧表示')).toBeInTheDocument();
    expect(screen.getByText('US#103 ユーザー編集機能')).toBeInTheDocument();
    expect(screen.getByText('US#201 スケジュール登録画面')).toBeInTheDocument();
  });

  it('should render Tasks, Tests, and Bugs within UserStories', () => {
    render(<App />);

    // Task が表示されること
    expect(screen.getByText('バリデーション実装')).toBeInTheDocument();
    expect(screen.getByText('UI設計完了')).toBeInTheDocument();
    expect(screen.getByText('一覧API実装')).toBeInTheDocument();

    // Test が表示されること
    expect(screen.getByText('単体テスト作成')).toBeInTheDocument();

    // Bug が表示されること
    expect(screen.getByText('バリデーションエラー修正')).toBeInTheDocument();
  });

  it('should display status indicators correctly', () => {
    render(<App />);

    // Open status indicators
    const openIndicators = document.querySelectorAll('.status-indicator.status-open');
    expect(openIndicators.length).toBeGreaterThan(0);

    // Closed status indicators
    const closedIndicators = document.querySelectorAll('.status-indicator.status-closed');
    expect(closedIndicators.length).toBeGreaterThan(0);
  });

  it('should render Legend component', () => {
    render(<App />);

    // Legend タイトルが表示されること
    expect(screen.getByText('Grid階層構造')).toBeInTheDocument();

    // Legend 項目が表示されること (class="legend-item"内のテキストのみチェック)
    const legendSection = document.querySelector('.legend');
    expect(legendSection).toBeInTheDocument();
    expect(legendSection?.textContent).toContain('レベル1:');
    expect(legendSection?.textContent).toContain('Epic × Version Grid');
    expect(legendSection?.textContent).toContain('レベル2:');
    expect(legendSection?.textContent).toContain('FeatureCardGrid');
    expect(legendSection?.textContent).toContain('レベル3:');
    expect(legendSection?.textContent).toContain('UserStoryGrid');
    expect(legendSection?.textContent).toContain('レベル4:');
    expect(legendSection?.textContent).toContain('TaskGrid');
    expect(legendSection?.textContent).toContain('未完了');
    expect(legendSection?.textContent).toContain('完了');
  });

  it('should have draggable elements with correct data attributes', () => {
    render(<App />);

    // Feature card が draggable であること
    const featureCards = document.querySelectorAll('.feature-card:not([data-add-button])');
    expect(featureCards.length).toBeGreaterThan(0);
    featureCards.forEach(card => {
      expect(card.getAttribute('data-feature')).toBeTruthy();
    });

    // User story が draggable であること
    const userStories = document.querySelectorAll('.user-story');
    expect(userStories.length).toBeGreaterThan(0);
    userStories.forEach(story => {
      expect(story.getAttribute('data-story')).toBeTruthy();
    });

    // Task が draggable であること
    const tasks = document.querySelectorAll('.task-item:not([data-add-button])');
    expect(tasks.length).toBeGreaterThan(0);
    tasks.forEach(task => {
      expect(task.getAttribute('data-task')).toBeTruthy();
    });
  });

  it('should render Add buttons', () => {
    render(<App />);

    // Add Feature buttons が表示されること
    const addFeatureButtons = screen.getAllByText('+ Add Feature');
    expect(addFeatureButtons.length).toBeGreaterThan(0);

    // Add Epic button が表示されること
    expect(screen.getByText('+ New Epic')).toBeInTheDocument();

    // Add Version button が表示されること
    expect(screen.getByText('+ New Version')).toBeInTheDocument();
  });

  it('should display correct feature counts per cell', () => {
    const { container } = render(<App />);

    // epic1 × v1 セルには 2つの Feature があること
    const epic1v1Cell = container.querySelector('[data-epic="epic1"][data-version="v1"]');
    const epic1v1Features = epic1v1Cell?.querySelectorAll('.feature-card:not([data-add-button])');
    expect(epic1v1Features?.length).toBe(2); // f1, f2

    // epic1 × v2 セルには 1つの Feature があること
    const epic1v2Cell = container.querySelector('[data-epic="epic1"][data-version="v2"]');
    const epic1v2Features = epic1v2Cell?.querySelectorAll('.feature-card:not([data-add-button])');
    expect(epic1v2Features?.length).toBe(1); // f3

    // epic2 × v2 セルには 1つの Feature があること
    const epic2v2Cell = container.querySelector('[data-epic="epic2"][data-version="v2"]');
    const epic2v2Features = epic2v2Cell?.querySelectorAll('.feature-card:not([data-add-button])');
    expect(epic2v2Features?.length).toBe(1); // f4
  });
});
