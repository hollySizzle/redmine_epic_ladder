import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { FeatureCard } from '../components/Feature/FeatureCard';
import { UserStoryChildrenToggle } from '../components/common/UserStoryChildrenToggle';
import { useStore } from '../store/useStore';

describe('Collapse Integration Tests', () => {
  beforeEach(() => {
    localStorage.clear();

    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {
          f1: {
            id: 'f1',
            title: 'Feature 1',
            description: '',
            status: 'open',
            parent_epic_id: 'e1',
            user_story_ids: ['us1'],
            fixed_version_id: null,
            version_source: 'none',
            statistics: {
              total_user_stories: 1,
              completed_user_stories: 0,
              total_child_items: 1,
              child_items_by_type: { tasks: 1, tests: 0, bugs: 0 }
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          },
          f2: {
            id: 'f2',
            title: 'Feature 2',
            description: '',
            status: 'open',
            parent_epic_id: 'e1',
            user_story_ids: ['us2'],
            fixed_version_id: null,
            version_source: 'none',
            statistics: {
              total_user_stories: 1,
              completed_user_stories: 0,
              total_child_items: 1,
              child_items_by_type: { tasks: 0, tests: 1, bugs: 0 }
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          }
        },
        user_stories: {
          us1: {
            id: 'us1',
            title: 'Story 1',
            description: '',
            status: 'open',
            parent_feature_id: 'f1',
            task_ids: ['t1'],
            test_ids: [],
            bug_ids: [],
            fixed_version_id: null,
            version_source: 'none',
            statistics: {
              total_tasks: 1,
              total_tests: 0,
              total_bugs: 0,
              completed_tasks: 0,
              completed_tests: 0,
              completed_bugs: 0
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          },
          us2: {
            id: 'us2',
            title: 'Story 2',
            description: '',
            status: 'open',
            parent_feature_id: 'f2',
            task_ids: [],
            test_ids: ['test1'],
            bug_ids: [],
            fixed_version_id: null,
            version_source: 'none',
            statistics: {
              total_tasks: 0,
              total_tests: 1,
              total_bugs: 0,
              completed_tasks: 0,
              completed_tests: 0,
              completed_bugs: 0
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          }
        },
        tasks: {
          t1: { id: 't1', title: 'Task 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        tests: {
          test1: { id: 'test1', title: 'Test 1', status: 'open', result: 'pending', parent_user_story_id: 'us2', fixed_version_id: null }
        },
        bugs: {},
          users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      userStoryCollapseStates: {},
      isIssueIdVisible: true
    });
  });

  describe('Global Collapse Interaction', () => {
    it('should hide all UserStory children when "全折畳" button is clicked', async () => {
      const user = userEvent.setup();

      render(
        <>
          <UserStoryChildrenToggle />
          <FeatureCard featureId="f1" />
          <FeatureCard featureId="f2" />
        </>
      );

      // 初期状態: 全て表示
      expect(screen.getByText('Task 1')).toBeTruthy();
      expect(screen.getByText('Test 1')).toBeTruthy();

      // 全折畳ボタンをクリック
      const collapseButton = screen.getByText('全折畳');
      await user.click(collapseButton);

      // 全て非表示
      expect(screen.queryByText('Task 1')).toBeNull();
      expect(screen.queryByText('Test 1')).toBeNull();
    });

    it('should show all UserStory children when "全展開" button is clicked', async () => {
      const user = userEvent.setup();

      // 初期状態を折り畳み済みに設定
      useStore.setState({
        userStoryCollapseStates: {
          us1: true,
          us2: true
        }
      });

      render(
        <>
          <UserStoryChildrenToggle />
          <FeatureCard featureId="f1" />
          <FeatureCard featureId="f2" />
        </>
      );

      // 初期状態: 全て非表示
      expect(screen.queryByText('Task 1')).toBeNull();
      expect(screen.queryByText('Test 1')).toBeNull();

      // 全展開ボタンをクリック
      const expandButton = screen.getByText('全展開');
      await user.click(expandButton);

      // 全て表示
      expect(screen.getByText('Task 1')).toBeTruthy();
      expect(screen.getByText('Test 1')).toBeTruthy();
    });
  });

  describe('localStorage Integration', () => {
    it('should persist collapse states', async () => {
      const user = userEvent.setup();

      render(<UserStoryChildrenToggle />);

      // 全折畳ボタンをクリック
      const collapseButton = screen.getByText('全折畳');
      await user.click(collapseButton);

      // localStorageに個別状態が保存される
      const saved = localStorage.getItem('kanban_userstory_collapse_states');
      expect(saved).toBeTruthy();
      const states = JSON.parse(saved!);
      expect(states['us1']).toBe(true);
      expect(states['us2']).toBe(true);
    });
  });
});
