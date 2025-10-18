import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import React from 'react';
import { BugItem } from './BugItem';
import { useStore } from '../../store/useStore';

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

  it('should add unassigned class when toggle is ON and bug is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: true });

    const { container } = render(<BugItem bugId="b1" />);

    const bugDiv = container.querySelector('.bug-item.unassigned');
    expect(bugDiv).toBeTruthy();
  });

  it('should NOT add unassigned class when toggle is OFF even if bug is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: false });

    const { container } = render(<BugItem bugId="b1" />);

    const bugDiv = container.querySelector('.bug-item.unassigned');
    expect(bugDiv).toBeNull();
  });

  it('should NOT add unassigned class when bug is assigned', () => {
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

    const bugDiv = container.querySelector('.bug-item.unassigned');
    expect(bugDiv).toBeNull();
  });
});
