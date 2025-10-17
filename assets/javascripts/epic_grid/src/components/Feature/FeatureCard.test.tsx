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
        bugs: {},
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      userStoryCollapseStates: {}
    });
  });

  describe('Rendering', () => {
    it('should render feature card with title and status', () => {
      render(<FeatureCard featureId="f1" />);

      expect(screen.getByText('Test Feature')).toBeTruthy();
    });

    it('should render closed class when status is closed', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          features: {
            f1: {
              ...useStore.getState().entities.features.f1,
              status: 'closed'
            }
          }
        }
      });

      const { container } = render(<FeatureCard featureId="f1" />);

      const featureCard = container.querySelector('.feature-card.closed');
      expect(featureCard).toBeTruthy();
    });
  });

  describe('Interaction', () => {
    it('should set selectedIssueId when header is clicked', async () => {
      const user = userEvent.setup();

      render(<FeatureCard featureId="f1" />);

      const header = screen.getByText('Test Feature');

      // ヘッダーをクリック
      await user.click(header);

      // selectedIssueIdが設定される
      expect(useStore.getState().selectedIssueId).toBe('f1');
    });
  });

  describe('Child Components', () => {
    it('should display child user stories and their tasks', () => {
      render(<FeatureCard featureId="f1" />);

      // UserStoryが表示されている
      expect(screen.getByText('Test Story')).toBeTruthy();
      // Taskが表示されている
      expect(screen.getByText('Task 1')).toBeTruthy();
    });
  });
});
