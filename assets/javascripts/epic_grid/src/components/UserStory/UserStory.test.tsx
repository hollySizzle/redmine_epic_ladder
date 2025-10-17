import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UserStory } from './UserStory';
import { useStore } from '../../store/useStore';

describe('UserStory - Collapse Functionality', () => {
  beforeEach(() => {
    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {
          us1: {
            id: 'us1',
            title: 'Test User Story',
            description: '',
            status: 'open',
            parent_feature_id: 'f1',
            task_ids: ['t1'],
            test_ids: ['test1'],
            bug_ids: ['b1'],
            fixed_version_id: null,
            version_source: 'none',
            assigned_to_id: null,
            start_date: null,
            due_date: null,
            statistics: {
              total_tasks: 1,
              total_tests: 1,
              total_bugs: 1,
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
          test1: { id: 'test1', title: 'Test 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        bugs: {
          b1: { id: 'b1', title: 'Bug 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isUserStoryChildrenCollapsed: false,
      isAssignedToVisible: false,
      isDueDateVisible: false
    });
  });

  describe('Rendering', () => {
    it('should render user story with collapse toggle button', () => {
      render(<UserStory storyId="us1" />);

      expect(screen.getByText('Test User Story')).toBeTruthy();

      // 折り畳みボタンがある
      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton).toBeTruthy();
    });

    it('should show ▼ icon when expanded', () => {
      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should show ▶ icon when collapsed', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // アイコンが変わる
      const collapsedButton = screen.getByTitle('Task/Test/Bug配下を展開');
      expect(collapsedButton.textContent).toBe('▶');
    });
  });

  describe('Interaction', () => {
    it('should toggle own collapse state when button clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      // 初期状態: 展開中
      let toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');

      // クリック: 折り畳み
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('Task/Test/Bug配下を展開');
      expect(toggleButton.textContent).toBe('▶');

      // もう一度クリック: 展開
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should not propagate click to header when toggle clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // トグルボタンをクリック
      await user.click(toggleButton);

      // selectedIssueIdは設定されない（stopPropagationが効いている）
      expect(useStore.getState().selectedIssueId).toBeNull();
    });

    it('should set selectedIssueId when header (not toggle) is clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const header = screen.getByText('Test User Story');

      // ヘッダーをクリック
      await user.click(header);

      // selectedIssueIdが設定される
      expect(useStore.getState().selectedIssueId).toBe('us1');
    });
  });

  describe('TaskTestBugGrid Integration', () => {
    it('should display child items initially', () => {
      render(<UserStory storyId="us1" />);

      // 子要素が表示されている
      expect(screen.getByText('Task 1')).toBeTruthy();
      expect(screen.getByText('Test 1')).toBeTruthy();
      expect(screen.getByText('Bug 1')).toBeTruthy();
    });

    it('should hide child items when collapsed', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // TaskTestBugGridがnullを返すので、子要素が見えなくなる
      expect(screen.queryByText('Task 1')).toBeNull();
      expect(screen.queryByText('Test 1')).toBeNull();
      expect(screen.queryByText('Bug 1')).toBeNull();
    });
  });

  describe('Parent Collapse State (isLocalCollapsed prop)', () => {
    it('should respect parent collapse state even when own state is expanded', () => {
      render(<UserStory storyId="us1" isLocalCollapsed={true} />);

      // 親から折り畳まれているので、子要素は見えない
      expect(screen.queryByText('Task 1')).toBeNull();
      expect(screen.queryByText('Test 1')).toBeNull();
      expect(screen.queryByText('Bug 1')).toBeNull();
    });

    it('should hide children when either parent or own collapse is true', async () => {
      const user = userEvent.setup();

      const { rerender } = render(<UserStory storyId="us1" isLocalCollapsed={false} />);

      // 初期状態: 子要素が見える
      expect(screen.getByText('Task 1')).toBeTruthy();

      // 自分自身を折り畳む
      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      await user.click(toggleButton);

      // 子要素が見えなくなる
      expect(screen.queryByText('Task 1')).toBeNull();

      // 自分自身を展開
      await user.click(screen.getByTitle('Task/Test/Bug配下を展開'));

      // 子要素が見える
      expect(screen.getByText('Task 1')).toBeTruthy();

      // 親から折り畳み指示を受ける
      rerender(<UserStory storyId="us1" isLocalCollapsed={true} />);

      // 自分が展開状態でも、親の指示で子要素が見えなくなる
      expect(screen.queryByText('Task 1')).toBeNull();
    });
  });

  describe('State Persistence', () => {
    it('should not persist own collapse state (resets on remount)', async () => {
      const user = userEvent.setup();

      const { unmount } = render(<UserStory storyId="us1" />);

      // 折り畳む
      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      await user.click(toggleButton);

      // 確認: 折り畳まれている
      expect(screen.getByTitle('Task/Test/Bug配下を展開')).toBeTruthy();

      // アンマウント
      unmount();

      // 再マウント
      render(<UserStory storyId="us1" />);

      // 展開状態にリセットされている
      expect(screen.getByTitle('Task/Test/Bug配下を折り畳み')).toBeTruthy();
      expect(screen.getByText('Task 1')).toBeTruthy();
    });
  });

  describe('Edge Cases', () => {
    it('should render toggle button even with no children', () => {
      // 子要素がないUserStoryを作成
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us2: {
              id: 'us2',
              title: 'Empty User Story',
              description: '',
              status: 'open',
              parent_feature_id: 'f1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              fixed_version_id: null,
              version_source: 'none',
              assigned_to_id: null,
              start_date: null,
              due_date: null,
              statistics: {
                total_tasks: 0,
                total_tests: 0,
                total_bugs: 0,
                completed_tasks: 0,
                completed_tests: 0,
                completed_bugs: 0
              },
              created_on: '2025-01-01',
              updated_on: '2025-01-01'
            }
          }
        }
      });

      render(<UserStory storyId="us2" />);

      // ボタンは表示される
      expect(screen.getByTitle('Task/Test/Bug配下を折り畳み')).toBeTruthy();
    });

    it('should handle closed status correctly', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              status: 'closed'
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // closedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.closed');
      expect(userStoryDiv).toBeTruthy();
    });
  });
});
