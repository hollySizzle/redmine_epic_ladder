import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UserStoryGrid } from './UserStoryGrid';
import { useStore } from '../../store/useStore';

// モックプロンプト
global.prompt = vi.fn();
global.alert = vi.fn();

describe('UserStoryGrid', () => {
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
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<UserStoryGrid featureId="f1" storyIds={[]} />);

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
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<UserStoryGrid featureId="f1" storyIds={['us1', 'us2']} />);

      expect(screen.getByText('User Story 1')).toBeTruthy();
      expect(screen.getByText('User Story 2')).toBeTruthy();
    });
  });

  describe('Add User Story functionality', () => {
    it('should call createUserStory when + Add User Story is clicked', async () => {
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
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createUserStory: createUserStoryMock
      });

      (global.prompt as any).mockReturnValue('New User Story');

      render(<UserStoryGrid featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      await user.click(addButton);

      expect(global.prompt).toHaveBeenCalledWith('User Story名を入力してください:');
      expect(createUserStoryMock).toHaveBeenCalledWith('f1', {
        subject: 'New User Story',
        description: '',
        parent_feature_id: 'f1'
      });
    });

    it('should not call createUserStory when prompt is cancelled', async () => {
      const user = userEvent.setup();
      const createUserStoryMock = vi.fn();

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
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createUserStory: createUserStoryMock
      });

      (global.prompt as any).mockReturnValue(null);

      render(<UserStoryGrid featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      await user.click(addButton);

      expect(createUserStoryMock).not.toHaveBeenCalled();
    });

    it('should show error alert when createUserStory fails', async () => {
      const user = userEvent.setup();
      const createUserStoryMock = vi.fn().mockRejectedValue(new Error('API Error'));

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
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createUserStory: createUserStoryMock
      });

      (global.prompt as any).mockReturnValue('New User Story');

      render(<UserStoryGrid featureId="f1" storyIds={[]} />);

      const addButton = screen.getByText('+ Add User Story');
      await user.click(addButton);

      expect(global.alert).toHaveBeenCalledWith('User Story作成に失敗しました: API Error');
    });
  });
});
