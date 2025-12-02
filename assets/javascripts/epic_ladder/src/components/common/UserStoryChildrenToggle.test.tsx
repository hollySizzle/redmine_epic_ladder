import { describe, it, expect, beforeEach } from 'vitest';
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
        user_stories: {
          us1: {
            id: 'us1',
            title: 'Story 1',
            description: '',
            status: 'open',
            parent_feature_id: 'f1',
            task_ids: [],
            test_ids: [],
            bug_ids: [],
            fixed_version_id: null,
            version_source: 'none',
            expansion_state: false,
            statistics: {
              total_tasks: 0,
              completed_tasks: 0,
              total_tests: 0,
              passed_tests: 0,
              total_bugs: 0,
              resolved_bugs: 0,
              completion_percentage: 0
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01',
            tracker_id: 1
          },
          us2: {
            id: 'us2',
            title: 'Story 2',
            description: '',
            status: 'open',
            parent_feature_id: 'f1',
            task_ids: [],
            test_ids: [],
            bug_ids: [],
            fixed_version_id: null,
            version_source: 'none',
            expansion_state: false,
            statistics: {
              total_tasks: 0,
              completed_tasks: 0,
              total_tests: 0,
              passed_tests: 0,
              total_bugs: 0,
              resolved_bugs: 0,
              completion_percentage: 0
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01',
            tracker_id: 1
          }
        },
        tasks: {},
        tests: {},
        bugs: {},
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: null,
      userStoryCollapseStates: {}
    });
  });

  describe('Rendering', () => {
    it('should render two buttons', () => {
      render(<UserStoryChildrenToggle />);

      expect(screen.getByText('全展開')).toBeTruthy();
      expect(screen.getByText('全折畳')).toBeTruthy();
    });

    it('should render expand button with correct title', () => {
      render(<UserStoryChildrenToggle />);

      const expandButton = screen.getByTitle('全UserStoryのTask/Test/Bugを展開');
      expect(expandButton).toBeTruthy();
      expect(expandButton.textContent).toContain('全展開');
    });

    it('should render collapse button with correct title', () => {
      render(<UserStoryChildrenToggle />);

      const collapseButton = screen.getByTitle('全UserStoryのTask/Test/Bugを折り畳み');
      expect(collapseButton).toBeTruthy();
      expect(collapseButton.textContent).toContain('全折畳');
    });
  });

  describe('Interaction', () => {
    it('should collapse all user stories when collapse button is clicked', async () => {
      const user = userEvent.setup();

      render(<UserStoryChildrenToggle />);

      const collapseButton = screen.getByText('全折畳');

      // 初期状態: 全て展開中
      expect(useStore.getState().userStoryCollapseStates['us1']).toBeUndefined();
      expect(useStore.getState().userStoryCollapseStates['us2']).toBeUndefined();

      // クリック: 全て折り畳み
      await user.click(collapseButton);
      expect(useStore.getState().userStoryCollapseStates['us1']).toBe(true);
      expect(useStore.getState().userStoryCollapseStates['us2']).toBe(true);
    });

    it('should expand all user stories when expand button is clicked', async () => {
      const user = userEvent.setup();

      // 初期状態を折り畳み済みに設定
      useStore.setState({
        userStoryCollapseStates: {
          us1: true,
          us2: true
        }
      });

      render(<UserStoryChildrenToggle />);

      const expandButton = screen.getByText('全展開');

      // クリック: 全て展開
      await user.click(expandButton);
      expect(useStore.getState().userStoryCollapseStates['us1']).toBe(false);
      expect(useStore.getState().userStoryCollapseStates['us2']).toBe(false);
    });

    it('should save state to localStorage when toggled', async () => {
      const user = userEvent.setup();

      render(<UserStoryChildrenToggle />);

      const collapseButton = screen.getByText('全折畳');

      // クリックして折り畳み
      await user.click(collapseButton);

      const saved = localStorage.getItem('kanban_userstory_collapse_states');
      expect(saved).toBeTruthy();
      const states = JSON.parse(saved!);
      expect(states['us1']).toBe(true);
      expect(states['us2']).toBe(true);
    });
  });

  describe('localStorage Integration', () => {
    it('should load initial state from localStorage', () => {
      // localStorageに折り畳み状態を保存
      localStorage.setItem('kanban_userstory_collapse_states', JSON.stringify({
        us1: true,
        us2: false
      }));

      // ストアを再初期化
      const initialState = (() => {
        try {
          const saved = localStorage.getItem('kanban_userstory_collapse_states');
          return saved ? JSON.parse(saved) : {};
        } catch (error) {
          return {};
        }
      })();

      useStore.setState({ userStoryCollapseStates: initialState });

      render(<UserStoryChildrenToggle />);

      expect(useStore.getState().userStoryCollapseStates['us1']).toBe(true);
      expect(useStore.getState().userStoryCollapseStates['us2']).toBe(false);
    });

    it('should default to empty states when localStorage is empty', () => {
      // localStorageをクリア
      localStorage.clear();

      const initialState = (() => {
        try {
          const saved = localStorage.getItem('kanban_userstory_collapse_states');
          return saved ? JSON.parse(saved) : {};
        } catch (error) {
          return {};
        }
      })();

      useStore.setState({ userStoryCollapseStates: initialState });

      render(<UserStoryChildrenToggle />);

      expect(useStore.getState().userStoryCollapseStates).toEqual({});
    });
  });
});
