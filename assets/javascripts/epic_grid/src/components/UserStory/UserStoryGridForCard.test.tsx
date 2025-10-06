import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UserStoryGridForCard } from './UserStoryGridForCard';
import { useStore } from '../../store/useStore';

// モックアラート
global.alert = vi.fn();

describe('UserStoryGridForCard', () => {
  describe('Rendering', () => {
    it('should render + Add User Story button', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: { f1: { id: 'f1', title: 'Feature 1', status: 'open', parent_epic_id: 'e1', user_story_ids: [], fixed_version_id: null, version_source: 'none' } },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<UserStoryGridForCard featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      expect(addButton).toBeTruthy();
    });

    it('should render user stories passed via storyIds', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {
            us1: { id: 'us1', title: 'User Story 1', status: 'open', parent_feature_id: 'f1', task_ids: [], test_ids: [], bug_ids: [], fixed_version_id: null, version_source: 'none', expansion_state: false },
            us2: { id: 'us2', title: 'User Story 2', status: 'open', parent_feature_id: 'f1', task_ids: [], test_ids: [], bug_ids: [], fixed_version_id: null, version_source: 'none', expansion_state: false }
          },
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<UserStoryGridForCard featureId="f1" storyIds={['us1', 'us2']} />);

      expect(screen.getByText('User Story 1')).toBeTruthy();
      expect(screen.getByText('User Story 2')).toBeTruthy();
    });
  });

  describe('Add User Story functionality', () => {
    it('should open modal when + Add User Story is clicked', async () => {
      const user = userEvent.setup();

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: { f1: { id: 'f1', title: 'Feature 1', status: 'open', parent_epic_id: 'e1', user_story_ids: [], fixed_version_id: null, version_source: 'none' } },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<UserStoryGridForCard featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      await user.click(addButton);

      expect(screen.getByText('新しいUser Storyを追加')).toBeTruthy();
      expect(screen.getByLabelText(/User Story名/)).toBeTruthy();
    });

    it('should call createUserStory when modal form is submitted', async () => {
      const user = userEvent.setup();
      const createUserStoryMock = vi.fn().mockResolvedValue(undefined);

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: { f1: { id: 'f1', title: 'Feature 1', status: 'open', parent_epic_id: 'e1', user_story_ids: [], fixed_version_id: null, version_source: 'none' } },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createUserStory: createUserStoryMock
      });

      render(<UserStoryGridForCard featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      await user.click(addButton);

      await user.type(screen.getByLabelText(/User Story名/), 'New User Story');
      await user.click(screen.getByText('作成'));

      expect(createUserStoryMock).toHaveBeenCalledWith('f1', {
        subject: 'New User Story',
        description: '',
        parent_feature_id: 'f1'
      });
    });
  });
});
