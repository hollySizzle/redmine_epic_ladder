import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { FeatureCard } from './FeatureCard';
import { useStore } from '../../store/useStore';

describe('FeatureCard - Collapse Functionality', () => {
  beforeEach(() => {
    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {
          f1: {
            id: 'f1',
            title: 'Test Feature',
            description: '',
            status: 'open',
            parent_epic_id: 'e1',
            user_story_ids: ['us1'],
            fixed_version_id: null,
            version_source: 'none',
            statistics: {
              total_user_stories: 1,
              completed_user_stories: 0,
              total_child_items: 0,
              child_items_by_type: { tasks: 0, tests: 0, bugs: 0 }
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          }
        },
        user_stories: {
          us1: {
            id: 'us1',
            title: 'Test Story',
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
          }
        },
        tasks: {
          t1: { id: 't1', title: 'Task 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        tests: {},
        bugs: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isUserStoryChildrenCollapsed: false
    });
  });

  describe('Rendering', () => {
    it('should render feature card with collapse toggle button', () => {
      render(<FeatureCard featureId="f1" />);

      expect(screen.getByText('Test Feature')).toBeTruthy();

      // 折り畳みボタンがある
      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');
      expect(toggleButton).toBeTruthy();
    });

    it('should show ▼ icon when expanded', () => {
      render(<FeatureCard featureId="f1" />);

      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should show ▶ icon when collapsed', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // アイコンが変わる
      const collapsedButton = screen.getByTitle('UserStory配下を展開');
      expect(collapsedButton.textContent).toBe('▶');
    });
  });

  describe('Interaction', () => {
    it('should toggle local collapse state when button clicked', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      // 初期状態: 展開中
      let toggleButton = screen.getByTitle('UserStory配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');

      // クリック: 折り畳み
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('UserStory配下を展開');
      expect(toggleButton.textContent).toBe('▶');

      // もう一度クリック: 展開
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('UserStory配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should not propagate click to header when toggle clicked', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');

      // トグルボタンをクリック
      await user.click(toggleButton);

      // selectedIssueIdは設定されない（stopPropagationが効いている）
      expect(useStore.getState().selectedIssueId).toBeNull();
    });

    it('should set selectedIssueId when header (not toggle) is clicked', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      const header = screen.getByText('Test Feature');

      // ヘッダーをクリック
      await user.click(header);

      // selectedIssueIdが設定される
      expect(useStore.getState().selectedIssueId).toBe('f1');
    });
  });

  describe('UserStoryGrid Integration', () => {
    it('should pass isLocalCollapsed=false to UserStoryGrid initially', () => {
      const { container } = render(<FeatureCard featureId="f1" />);

      // UserStoryGridが表示されている（Task 1が見える）
      expect(screen.getByText('Task 1')).toBeTruthy();
    });

    it('should pass isLocalCollapsed=true to UserStoryGrid when collapsed', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // TaskTestBugGridがnullを返すので、Task 1が見えなくなる
      expect(screen.queryByText('Task 1')).toBeNull();
    });
  });

  describe('State Persistence', () => {
    it('should not persist local collapse state (resets on remount)', async () => {
      const user = userEvent.setup();

      const { unmount } = render(<FeatureCard featureId="f1" />);

      // 折り畳む
      const toggleButton = screen.getByTitle('UserStory配下を折り畳み');
      await user.click(toggleButton);

      // 確認: 折り畳まれている
      expect(screen.getByTitle('UserStory配下を展開')).toBeTruthy();

      // アンマウント
      unmount();

      // 再マウント
      render(<FeatureCard featureId="f1" />);

      // 展開状態にリセットされている
      expect(screen.getByTitle('UserStory配下を折り畳み')).toBeTruthy();
      expect(screen.getByText('Task 1')).toBeTruthy();
    });
  });
});
