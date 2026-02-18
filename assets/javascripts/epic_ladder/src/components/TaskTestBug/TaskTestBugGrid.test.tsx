import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { TaskTestBugGrid } from './TaskTestBugGrid';
import { useStore } from '../../store/useStore';

describe('TaskTestBugGrid - Collapse Functionality', () => {
  beforeEach(() => {
    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {
          t1: { id: 't1', title: 'Task 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        tests: {
          test1: { id: 'test1', title: 'Test 1', status: 'open', result: 'pending', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        bugs: {
          b1: { id: 'b1', title: 'Bug 1', status: 'open', severity: 'minor', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isUserStoryChildrenCollapsed: false,
      isIssueIdVisible: true
    });
  });

  describe('Rendering', () => {
    it('should render all containers when not collapsed', () => {
      render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={false}
        />
      );

      // Task/Test/Bugコンテナが表示される
      expect(screen.getByText('Task')).toBeTruthy();
      expect(screen.getByText('Test')).toBeTruthy();
      expect(screen.getByText('Bug')).toBeTruthy();
    });

    it('should not render when global collapse is enabled', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: true });

      const { container } = render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={false}
        />
      );

      // null が返されるため、何も表示されない
      expect(container.firstChild).toBeNull();
    });

    it('should not render when local collapse is enabled', () => {
      const { container } = render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={true}
        />
      );

      // null が返されるため、何も表示されない
      expect(container.firstChild).toBeNull();
    });

    it('should not render when both global and local collapse are enabled', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: true });

      const { container } = render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={true}
        />
      );

      // null が返されるため、何も表示されない
      expect(container.firstChild).toBeNull();
    });
  });

  describe('Priority Logic', () => {
    it('should hide when global collapse is ON and local is OFF', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: true });

      const { container } = render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={false}
        />
      );

      expect(container.firstChild).toBeNull();
    });

    it('should hide when global collapse is OFF and local is ON', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: false });

      const { container } = render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={true}
        />
      );

      expect(container.firstChild).toBeNull();
    });

    it('should show when both global and local collapse are OFF', () => {
      useStore.setState({ isUserStoryChildrenCollapsed: false });

      render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
          isLocalCollapsed={false}
        />
      );

      expect(screen.getByText('Task')).toBeTruthy();
      expect(screen.getByText('Test')).toBeTruthy();
      expect(screen.getByText('Bug')).toBeTruthy();
    });
  });

  describe('Default Props', () => {
    it('should default isLocalCollapsed to false', () => {
      render(
        <TaskTestBugGrid
          userStoryId="us1"
          taskIds={['t1']}
          testIds={['test1']}
          bugIds={['b1']}
        />
      );

      // isLocalCollapsed省略時はfalseなので表示される
      expect(screen.getByText('Task')).toBeTruthy();
    });
  });
});
