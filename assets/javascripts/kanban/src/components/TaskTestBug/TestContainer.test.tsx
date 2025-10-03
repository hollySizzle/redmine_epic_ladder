import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { TestContainer } from './TestContainer';
import { useStore } from '../../store/useStore';

// モックプロンプト
global.prompt = vi.fn();
global.alert = vi.fn();

describe('TestContainer', () => {
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

      render(<TestContainer userStoryId="us1" testIds={[]} />);

      expect(screen.getByText('Test')).toBeTruthy();
    });

    it('should render + Add Test button', () => {
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

      render(<TestContainer userStoryId="us1" testIds={[]} />);

      const addButton = screen.getByText('+ Add Test');
      expect(addButton).toBeTruthy();
    });

    it('should render tests passed via testIds', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {
            test1: { id: 'test1', title: 'Test 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null },
            test2: { id: 'test2', title: 'Test 2', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
          },
          bugs: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<TestContainer userStoryId="us1" testIds={['test1', 'test2']} />);

      expect(screen.getByText('Test 1')).toBeTruthy();
      expect(screen.getByText('Test 2')).toBeTruthy();
    });
  });

  describe('Add Test functionality', () => {
    it('should call createTest when + Add Test is clicked', async () => {
      const user = userEvent.setup();
      const createTestMock = vi.fn().mockResolvedValue(undefined);

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
        createTest: createTestMock
      });

      (global.prompt as any).mockReturnValue('New Test');

      render(<TestContainer userStoryId="us1" testIds={[]} />);

      const addButton = screen.getByText('+ Add Test');
      await user.click(addButton);

      expect(global.prompt).toHaveBeenCalledWith('Test名を入力してください:');
      expect(createTestMock).toHaveBeenCalledWith('us1', {
        subject: 'New Test',
        description: '',
        parent_user_story_id: 'us1'
      });
    });

    it('should not call createTest when prompt is cancelled', async () => {
      const user = userEvent.setup();
      const createTestMock = vi.fn();

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
        createTest: createTestMock
      });

      (global.prompt as any).mockReturnValue(null);

      render(<TestContainer userStoryId="us1" testIds={[]} />);

      const addButton = screen.getByText('+ Add Test');
      await user.click(addButton);

      expect(createTestMock).not.toHaveBeenCalled();
    });

    it('should show error alert when createTest fails', async () => {
      const user = userEvent.setup();
      const createTestMock = vi.fn().mockRejectedValue(new Error('API Error'));

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
        createTest: createTestMock
      });

      (global.prompt as any).mockReturnValue('New Test');

      render(<TestContainer userStoryId="us1" testIds={[]} />);

      const addButton = screen.getByText('+ Add Test');
      await user.click(addButton);

      expect(global.alert).toHaveBeenCalledWith('Test作成に失敗しました: API Error');
    });
  });
});
