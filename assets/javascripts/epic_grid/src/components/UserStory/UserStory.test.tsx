import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { UserStory } from './UserStory';
import { useStore } from '../../store/useStore';

// Mock子コンポーネント
vi.mock('../TaskTestBug/TaskTestBugGrid', () => ({
  TaskTestBugGrid: ({ userStoryId, isLocalCollapsed }: any) => (
    <div data-testid="task-test-bug-grid" data-story-id={userStoryId} data-collapsed={isLocalCollapsed}>
      TaskTestBugGrid
    </div>
  )
}));

vi.mock('../common/StatusIndicator', () => ({
  StatusIndicator: ({ status }: any) => (
    <span data-testid="status-indicator" data-status={status}>Status</span>
  )
}));

vi.mock('../../hooks/useDraggableAndDropTarget', () => ({
  useDraggableAndDropTarget: () => ({ current: null })
}));

describe('UserStory', () => {
  const mockSetSelectedEntity = vi.fn();
  const mockToggleDetailPane = vi.fn();
  const mockSetUserStoryCollapsed = vi.fn();

  const mockUserStory = {
    id: 'us-1',
    title: 'Test User Story',
    status: 'open' as const,
    assigned_to_id: 1,
    due_date: '2025-12-31',
    start_date: '2025-01-01',
    task_ids: ['task-1'],
    test_ids: ['test-1'],
    bug_ids: ['bug-1'],
  };

  const mockUser = {
    id: 1,
    firstname: 'Taro',
    lastname: 'Yamada',
  };

  const defaultState = {
    entities: {
      user_stories: {
        'us-1': mockUserStory,
      },
      users: {
        '1': mockUser,
      },
      tasks: {},
      tests: {},
      bugs: {},
    },
    setSelectedEntity: mockSetSelectedEntity,
    toggleDetailPane: mockToggleDetailPane,
    isDetailPaneVisible: false,
    isAssignedToVisible: true,
    isDueDateVisible: true,
    isIssueIdVisible: true,
    isUnassignedHighlightVisible: false,
    userStoryCollapseStates: {},
    setUserStoryCollapsed: mockSetUserStoryCollapsed,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState(defaultState as any);
  });

  describe('Rendering', () => {
    it('should render user story', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByText('Test User Story')).toBeInTheDocument();
    });

    it('should render null if story not found', () => {
      const { container } = render(<UserStory storyId="non-existent" />);

      expect(container.firstChild).toBeNull();
    });

    it('should render status indicator', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByTestId('status-indicator')).toBeInTheDocument();
      expect(screen.getByTestId('status-indicator')).toHaveAttribute('data-status', 'open');
    });

    it('should render TaskTestBugGrid', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByTestId('task-test-bug-grid')).toBeInTheDocument();
      expect(screen.getByTestId('task-test-bug-grid')).toHaveAttribute('data-story-id', 'us-1');
    });
  });

  describe('Issue ID Display', () => {
    it('should show issue ID when isIssueIdVisible is true', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByText('#us-1')).toBeInTheDocument();
    });

    it('should hide issue ID when isIssueIdVisible is false', () => {
      useStore.setState({ ...defaultState, isIssueIdVisible: false } as any);

      render(<UserStory storyId="us-1" />);

      expect(screen.queryByText('#us-1')).not.toBeInTheDocument();
    });
  });

  describe('Assigned User Display', () => {
    it('should show assigned user when isAssignedToVisible is true', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByText(/Yamada Taro/)).toBeInTheDocument();
    });

    it('should hide assigned user when isAssignedToVisible is false', () => {
      useStore.setState({ ...defaultState, isAssignedToVisible: false } as any);

      render(<UserStory storyId="us-1" />);

      expect(screen.queryByText(/Yamada Taro/)).not.toBeInTheDocument();
    });

    it('should not show user if not assigned', () => {
      useStore.setState({
        ...defaultState,
        entities: {
          ...defaultState.entities,
          user_stories: {
            'us-1': { ...mockUserStory, assigned_to_id: undefined },
          },
        },
      } as any);

      render(<UserStory storyId="us-1" />);

      expect(screen.queryByText(/Yamada/)).not.toBeInTheDocument();
    });
  });

  describe('Due Date Display', () => {
    it('should show date range when isDueDateVisible is true', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByText(/2025/)).toBeInTheDocument();
    });

    it('should hide date range when isDueDateVisible is false', () => {
      useStore.setState({ ...defaultState, isDueDateVisible: false } as any);

      render(<UserStory storyId="us-1" />);

      expect(screen.queryByText(/2025/)).not.toBeInTheDocument();
    });
  });

  describe('Collapse/Expand', () => {
    it('should show collapse button', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByTitle(/Task\/Test\/Bug配下を折り畳み/)).toBeInTheDocument();
    });

    it('should toggle collapse state when button clicked', () => {
      render(<UserStory storyId="us-1" />);

      const button = screen.getByTitle(/Task\/Test\/Bug配下を折り畳み/);
      fireEvent.click(button);

      expect(mockSetUserStoryCollapsed).toHaveBeenCalledWith('us-1', true);
    });

    it('should show expand button when collapsed', () => {
      useStore.setState({
        ...defaultState,
        userStoryCollapseStates: { 'us-1': true },
      } as any);

      render(<UserStory storyId="us-1" />);

      expect(screen.getByTitle(/Task\/Test\/Bug配下を展開/)).toBeInTheDocument();
      expect(screen.getByText('▶')).toBeInTheDocument();
    });

    it('should show collapse button when expanded', () => {
      render(<UserStory storyId="us-1" />);

      expect(screen.getByText('▼')).toBeInTheDocument();
    });
  });

  describe('Header Click', () => {
    it('should select entity and toggle detail pane', () => {
      render(<UserStory storyId="us-1" />);

      const header = screen.getByText('Test User Story').closest('.user-story-header');
      fireEvent.click(header!);

      expect(mockToggleDetailPane).toHaveBeenCalled();
      expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'us-1');
    });

    it('should not toggle detail pane if already visible', () => {
      useStore.setState({ ...defaultState, isDetailPaneVisible: true } as any);

      render(<UserStory storyId="us-1" />);

      const header = screen.getByText('Test User Story').closest('.user-story-header');
      fireEvent.click(header!);

      expect(mockToggleDetailPane).not.toHaveBeenCalled();
      expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'us-1');
    });
  });

  describe('CSS Classes', () => {
    it('should apply closed class when status is closed', () => {
      useStore.setState({
        ...defaultState,
        entities: {
          ...defaultState.entities,
          user_stories: {
            'us-1': { ...mockUserStory, status: 'closed' },
          },
        },
      } as any);

      const { container } = render(<UserStory storyId="us-1" />);
      
      expect(container.querySelector('.user-story.closed')).toBeInTheDocument();
    });

    it('should apply user-story class', () => {
      const { container } = render(<UserStory storyId="us-1" />);
      
      expect(container.querySelector('.user-story')).toBeInTheDocument();
    });
  });
});
