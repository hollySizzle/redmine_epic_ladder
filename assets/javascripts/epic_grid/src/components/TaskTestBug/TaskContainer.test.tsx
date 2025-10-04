import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { TaskContainer } from './TaskContainer';
import { useStore } from '../../store/useStore';

// モックプロンプト
global.prompt = vi.fn();
global.alert = vi.fn();

describe('TaskContainer', () => {
  describe('Rendering', () => {
    it('should render container header', () => {
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
        projectId: 'project1'
      });

      render(<TaskContainer userStoryId="us1" taskIds={[]} />);

      expect(screen.getByText('Task')).toBeTruthy();
    });

    it('should render + Add Task button', () => {
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
        projectId: 'project1'
      });

      render(<TaskContainer userStoryId="us1" taskIds={[]} />);

      const addButton = screen.getByText('+ Add Task');
      expect(addButton).toBeTruthy();
    });

    it('should render tasks passed via taskIds', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {
            t1: { id: 't1', title: 'Task 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null },
            t2: { id: 't2', title: 'Task 2', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
          },
          tests: {},
          bugs: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<TaskContainer userStoryId="us1" taskIds={['t1', 't2']} />);

      expect(screen.getByText('Task 1')).toBeTruthy();
      expect(screen.getByText('Task 2')).toBeTruthy();
    });
  });

  describe('Add Task functionality', () => {
    it('should call createTask when + Add Task is clicked', async () => {
      const user = userEvent.setup();
      const createTaskMock = vi.fn().mockResolvedValue(undefined);

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
        createTask: createTaskMock
      });

      (global.prompt as any).mockReturnValue('New Task');

      render(<TaskContainer userStoryId="us1" taskIds={[]} />);

      const addButton = screen.getByText('+ Add Task');
      await user.click(addButton);

      expect(global.prompt).toHaveBeenCalledWith('Task名を入力してください:');
      expect(createTaskMock).toHaveBeenCalledWith('us1', {
        subject: 'New Task',
        description: '',
        parent_user_story_id: 'us1'
      });
    });

    it('should not call createTask when prompt is cancelled', async () => {
      const user = userEvent.setup();
      const createTaskMock = vi.fn();

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
        createTask: createTaskMock
      });

      (global.prompt as any).mockReturnValue(null);

      render(<TaskContainer userStoryId="us1" taskIds={[]} />);

      const addButton = screen.getByText('+ Add Task');
      await user.click(addButton);

      expect(createTaskMock).not.toHaveBeenCalled();
    });

    it('should show error alert when createTask fails', async () => {
      const user = userEvent.setup();
      const createTaskMock = vi.fn().mockRejectedValue(new Error('API Error'));

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
        createTask: createTaskMock
      });

      (global.prompt as any).mockReturnValue('New Task');

      render(<TaskContainer userStoryId="us1" taskIds={[]} />);

      const addButton = screen.getByText('+ Add Task');
      await user.click(addButton);

      expect(global.alert).toHaveBeenCalledWith('Task作成に失敗しました: API Error');
    });
  });
});
