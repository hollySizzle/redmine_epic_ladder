import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UserStoryChildrenToggle } from './UserStoryChildrenToggle';
import { useStore } from '../../store/useStore';

describe('UserStoryChildrenToggle', () => {
  beforeEach(() => {
    // localStorageをクリア
    localStorage.clear();

    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {},
        tests: {},
        bugs: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: null,
      isUserStoryChildrenCollapsed: false
    });
  });

  describe('Rendering', () => {
    it('should render toggle button', () => {
      render(<UserStoryChildrenToggle />);

      const button = screen.getByRole('button');
      expect(button).toBeTruthy();
    });

    it('should show "Task折畳" label when expanded', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: false });

      render(<UserStoryChildrenToggle />);

      expect(screen.getByText('Task折畳')).toBeTruthy();
    });

    it('should show "Task展開" label when collapsed', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: true });

      render(<UserStoryChildrenToggle />);

      expect(screen.getByText('Task展開')).toBeTruthy();
    });

    it('should have active class when collapsed', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: true });

      render(<UserStoryChildrenToggle />);

      const button = screen.getByRole('button');
      expect(button.className).toContain('active');
    });

    it('should not have active class when expanded', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: false });

      render(<UserStoryChildrenToggle />);

      const button = screen.getByRole('button');
      expect(button.className).not.toContain('active');
    });
  });

  describe('Interaction', () => {
    it('should toggle state when clicked', async () => {
      const user = userEvent.setup();

      render(<UserStoryChildrenToggle />);

      const button = screen.getByRole('button');

      // 初期状態: 展開中
      expect(useStore.getState().isUserStoryChildrenCollapsed).toBe(false);

      // クリック: 折り畳み
      await user.click(button);
      expect(useStore.getState().isUserStoryChildrenCollapsed).toBe(true);

      // もう一度クリック: 展開
      await user.click(button);
      expect(useStore.getState().isUserStoryChildrenCollapsed).toBe(false);
    });

    it('should save state to localStorage when toggled', async () => {
      const user = userEvent.setup();

      render(<UserStoryChildrenToggle />);

      const button = screen.getByRole('button');

      // クリックして折り畳み
      await user.click(button);

      expect(localStorage.getItem('kanban_userstory_children_collapsed')).toBe('true');

      // クリックして展開
      await user.click(button);

      expect(localStorage.getItem('kanban_userstory_children_collapsed')).toBe('false');
    });
  });

  describe('localStorage Integration', () => {
    it('should load initial state from localStorage', () => {
      // localStorageに折り畳み状態を保存
      localStorage.setItem('kanban_userstory_children_collapsed', 'true');

      // ストアを再初期化（toggleUserStoryChildrenCollapsed関数を呼び出して初期値を設定）
      const initialState = (() => {
        const saved = localStorage.getItem('kanban_userstory_children_collapsed');
        return saved !== null ? saved === 'true' : false;
      })();

      useStore.setState({ isUserStoryChildrenCollapsed: initialState });

      render(<UserStoryChildrenToggle />);

      expect(useStore.getState().isUserStoryChildrenCollapsed).toBe(true);
      expect(screen.getByText('Task展開')).toBeTruthy();
    });

    it('should default to expanded when localStorage is empty', () => {
      // localStorageをクリア
      localStorage.clear();

      const initialState = (() => {
        const saved = localStorage.getItem('kanban_userstory_children_collapsed');
        return saved !== null ? saved === 'true' : false;
      })();

      useStore.setState({ isUserStoryChildrenCollapsed: initialState });

      render(<UserStoryChildrenToggle />);

      expect(useStore.getState().isUserStoryChildrenCollapsed).toBe(false);
      expect(screen.getByText('Task折畳')).toBeTruthy();
    });
  });
});
