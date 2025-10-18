import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import React from 'react';
import { TaskItem } from './TaskItem';
import { useStore } from '../../store/useStore';

describe('TaskItem - Unassigned Highlighting', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {
          t1: {
            id: 't1',
            title: 'Test Task',
            status: 'open',
            parent_user_story_id: 'us1',
            fixed_version_id: null,
            assigned_to_id: undefined
          }
        },
        tests: {},
        bugs: {},
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

    const { container } = render(<TaskItem taskId="t1" />);

    const taskDiv = container.querySelector('.task-item.unassigned');
    expect(taskDiv).toBeTruthy();
  });

  it('should NOT add unassigned class when toggle is OFF even if task is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: false });

    const { container } = render(<TaskItem taskId="t1" />);

    const taskDiv = container.querySelector('.task-item.unassigned');
    expect(taskDiv).toBeNull();
  });

  it('should NOT add unassigned class when task is assigned', () => {
    useStore.setState({
      isUnassignedHighlightVisible: true,
      entities: {
        ...useStore.getState().entities,
        tasks: {
          t1: {
            ...useStore.getState().entities.tasks.t1,
            assigned_to_id: 1
          }
        }
      }
    });

    const { container } = render(<TaskItem taskId="t1" />);

    const taskDiv = container.querySelector('.task-item.unassigned');
    expect(taskDiv).toBeNull();
  });
});
