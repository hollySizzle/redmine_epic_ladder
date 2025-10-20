import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, fireEvent, screen } from '@testing-library/react';
import React from 'react';
import { BugItem } from './BugItem';
import { useStore } from '../../store/useStore';

// Mock StatusIndicator
vi.mock('../common/StatusIndicator', () => ({
  StatusIndicator: ({ status }: any) => <span data-testid="status">{status}</span>
}));

// Mock useDraggableAndDropTarget
vi.mock('../../hooks/useDraggableAndDropTarget', () => ({
  useDraggableAndDropTarget: () => ({ current: null })
}));

describe('BugItem - Unassigned Highlighting', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {},
        tests: {},
        bugs: {
          b1: {
            id: 'b1',
            title: 'Test Bug',
            status: 'open',
            parent_user_story_id: 'us1',
            fixed_version_id: null,
            assigned_to_id: undefined
          }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true,
      isUnassignedHighlightVisible: true
    });
  });

  it('should add unassigned class when toggle is ON and task is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: true });

    const { container } = render(<BugItem bugId="b1" />);

    const taskDiv = container.querySelector('.bug-item.unassigned');
    expect(taskDiv).toBeTruthy();
  });

  it('should NOT add unassigned class when toggle is OFF even if task is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: false });

    const { container } = render(<BugItem bugId="b1" />);

    const taskDiv = container.querySelector('.bug-item.unassigned');
    expect(taskDiv).toBeNull();
  });

  it('should NOT add unassigned class when task is assigned', () => {
    useStore.setState({
      isUnassignedHighlightVisible: true,
      entities: {
        ...useStore.getState().entities,
        bugs: {
          b1: {
            ...useStore.getState().entities.bugs.b1,
            assigned_to_id: 1
          }
        }
      }
    });

    const { container } = render(<BugItem bugId="b1" />);

    const taskDiv = container.querySelector('.bug-item.unassigned');
    expect(taskDiv).toBeNull();
  });
});

describe('BugItem - Basic Rendering', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {},
        tests: {},
        bugs: {
          b1: {
            id: 'b1',
            title: 'Test Bug',
            status: 'open',
            parent_user_story_id: 'us1',
            fixed_version_id: null,
            assigned_to_id: 1,
            start_date: '2025-01-01',
            due_date: '2025-12-31'
          }
        },
        users: {
          '1': { id: 1, firstname: 'Taro', lastname: 'Yamada' }
        }
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true,
      isAssignedToVisible: true,
      isDueDateVisible: true,
      isUnassignedHighlightVisible: false,
      isDetailPaneVisible: false,
      setSelectedEntity: vi.fn(),
      toggleDetailPane: vi.fn()
    });
  });

  it('should render task with title', () => {
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).toContain('Test Bug');
  });

  it('should return null if task not found', () => {
    const { container } = render(<BugItem bugId="nonexistent" />);
    expect(container.firstChild).toBeNull();
  });

  it('should render status indicator', () => {
    render(<BugItem bugId="b1" />);
    expect(screen.getByTestId('status')).toHaveTextContent('open');
  });
});

describe('BugItem - Issue ID Visibility', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {}, versions: {}, features: {}, user_stories: {}, tasks: {}, tests: {},
        bugs: {
          b1: { id: 'b1', title: 'Test Bug', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1'
    });
  });

  it('should show issue ID when isIssueIdVisible is true', () => {
    useStore.setState({ isIssueIdVisible: true });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).toContain('#b1');
  });

  it('should hide issue ID when isIssueIdVisible is false', () => {
    useStore.setState({ isIssueIdVisible: false });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).not.toContain('#b1');
  });
});

describe('BugItem - Assigned User Visibility', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {}, versions: {}, features: {}, user_stories: {}, tasks: {}, tests: {},
        bugs: {
          b1: { id: 'b1', title: 'Test Bug', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null, assigned_to_id: 1 }
        },
        users: {
          '1': { id: 1, firstname: 'Taro', lastname: 'Yamada' }
        }
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true
    });
  });

  it('should show assigned user when isAssignedToVisible is true', () => {
    useStore.setState({ isAssignedToVisible: true });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).toContain('Yamada Taro');
  });

  it('should hide assigned user when isAssignedToVisible is false', () => {
    useStore.setState({ isAssignedToVisible: false });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).not.toContain('Yamada Taro');
  });

  it('should not show user if not assigned', () => {
    useStore.setState({
      isAssignedToVisible: true,
      entities: {
        ...useStore.getState().entities,
        bugs: {
          b1: { ...useStore.getState().entities.bugs.b1, assigned_to_id: undefined }
        }
      }
    });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).not.toContain('Yamada');
  });
});

describe('BugItem - Due Date Visibility', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {}, versions: {}, features: {}, user_stories: {}, tasks: {}, tests: {},
        bugs: {
          b1: {
            id: 'b1',
            title: 'Test Bug',
            status: 'open',
            parent_user_story_id: 'us1',
            fixed_version_id: null,
            start_date: '2025-01-01',
            due_date: '2025-12-31'
          }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true
    });
  });

  it('should show date range when isDueDateVisible is true', () => {
    useStore.setState({ isDueDateVisible: true });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).toMatch(/1\/1~12\/31/);
  });

  it('should hide date range when isDueDateVisible is false', () => {
    useStore.setState({ isDueDateVisible: false });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.textContent).not.toMatch(/1\/1~12\/31/);
  });
});

describe('BugItem - Status Classes', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {}, versions: {}, features: {}, user_stories: {}, tasks: {}, tests: {},
        bugs: {
          b1: { id: 'b1', title: 'Test Bug', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true,
      isUnassignedHighlightVisible: false
    });
  });

  it('should apply closed class when status is closed', () => {
    useStore.setState({
      entities: {
        ...useStore.getState().entities,
        bugs: {
          b1: { ...useStore.getState().entities.bugs.b1, status: 'closed' }
        }
      }
    });
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.querySelector('.bug-item.closed')).toBeTruthy();
  });

  it('should not apply closed class when status is open', () => {
    const { container } = render(<BugItem bugId="b1" />);
    expect(container.querySelector('.bug-item.closed')).toBeNull();
  });
});

describe('BugItem - Click Handling', () => {
  let mockSetSelectedEntity: ReturnType<typeof vi.fn>;
  let mockToggleDetailPane: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    mockSetSelectedEntity = vi.fn();
    mockToggleDetailPane = vi.fn();

    useStore.setState({
      entities: {
        epics: {}, versions: {}, features: {}, user_stories: {}, tasks: {}, tests: {},
        bugs: {
          b1: { id: 'b1', title: 'Test Bug', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      isIssueIdVisible: true,
      isDetailPaneVisible: false,
      setSelectedEntity: mockSetSelectedEntity,
      toggleDetailPane: mockToggleDetailPane
    });
  });

  it('should call setSelectedEntity and toggleDetailPane when clicked', () => {
    const { container } = render(<BugItem bugId="b1" />);
    const taskDiv = container.querySelector('.bug-item');

    fireEvent.click(taskDiv!);

    expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'b1');
    expect(mockToggleDetailPane).toHaveBeenCalled();
  });

  it('should not toggle detail pane if already visible', () => {
    useStore.setState({ isDetailPaneVisible: true });

    const { container } = render(<BugItem bugId="b1" />);
    const taskDiv = container.querySelector('.bug-item');

    fireEvent.click(taskDiv!);

    expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'b1');
    expect(mockToggleDetailPane).not.toHaveBeenCalled();
  });
});
