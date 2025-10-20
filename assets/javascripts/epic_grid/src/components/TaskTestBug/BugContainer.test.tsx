import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { BugContainer } from './BugContainer';
import { useStore } from '../../store/useStore';

// モックアラート
global.alert = vi.fn();

describe('BugContainer', () => {
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
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        isIssueIdVisible: true
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      expect(screen.getByText('Bug')).toBeTruthy();
    });

    it('should render + Add Bug button', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        isIssueIdVisible: true
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      const addButton = screen.getByText('+ Add Bug');
      expect(addButton).toBeTruthy();
    });

    it('should render bugs passed via bugIds', () => {
      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {
            b1: { id: 'b1', title: 'Bug 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null },
            b2: { id: 'b2', title: 'Bug 2', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
          }
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        isIssueIdVisible: true
      });

      render(<BugContainer userStoryId="us1" bugIds={['b1', 'b2']} />);

      expect(screen.getByText('Bug 1')).toBeTruthy();
      expect(screen.getByText('Bug 2')).toBeTruthy();
    });
  });

  describe('Add Bug functionality', () => {
    it('should open modal when + Add Bug is clicked', async () => {
      const user = userEvent.setup();

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        isIssueIdVisible: true
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      const addButton = screen.getByText('+ Add Bug');
      await user.click(addButton);

      expect(screen.getByText('新しいBugを追加')).toBeTruthy();
      expect(screen.getByLabelText(/Bug名/)).toBeTruthy();
    });

    it('should call createBug when modal form is submitted', async () => {
      const user = userEvent.setup();
      const createBugMock = vi.fn().mockResolvedValue(undefined);

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createBug: createBugMock
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      const addButton = screen.getByText('+ Add Bug');
      await user.click(addButton);

      await user.type(screen.getByLabelText(/Bug名/), 'New Bug');
      await user.click(screen.getByText('作成'));

      expect(createBugMock).toHaveBeenCalledWith('us1', {
        subject: 'New Bug',
        description: '',
        parent_user_story_id: 'us1'
      });
    });

    it('should not call createBug when modal is cancelled', async () => {
      const user = userEvent.setup();
      const createBugMock = vi.fn();

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createBug: createBugMock
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      const addButton = screen.getByText('+ Add Bug');
      await user.click(addButton);

      await user.click(screen.getByText('キャンセル'));

      expect(createBugMock).not.toHaveBeenCalled();
    });

    it('should show error alert when createBug fails', async () => {
      const user = userEvent.setup();
      const createBugMock = vi.fn().mockRejectedValue(new Error('API Error'));

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        isLoading: false,
        error: null,
        projectId: 'project1',
        createBug: createBugMock
      });

      render(<BugContainer userStoryId="us1" bugIds={[]} />);

      const addButton = screen.getByText('+ Add Bug');
      await user.click(addButton);

      await user.type(screen.getByLabelText(/Bug名/), 'New Bug');
      await user.click(screen.getByText('作成'));

      await vi.waitFor(() => {
        expect(global.alert).toHaveBeenCalledWith('Bug作成に失敗しました: API Error');
      });
    });
  });
});
