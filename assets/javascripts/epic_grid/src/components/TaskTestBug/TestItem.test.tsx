import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import React from 'react';
import { TestItem } from './TestItem';
import { useStore } from '../../store/useStore';

describe('TestItem - Unassigned Highlighting', () => {
  beforeEach(() => {
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {},
        tasks: {},
        tests: {
          test1: {
            id: 'test1',
            title: 'Test Item',
            status: 'open',
            parent_user_story_id: 'us1',
            fixed_version_id: null,
            assigned_to_id: undefined
          }
        },
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

  it('should add unassigned class when toggle is ON and test is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: true });

    const { container } = render(<TestItem testId="test1" />);

    const testDiv = container.querySelector('.test-item.unassigned');
    expect(testDiv).toBeTruthy();
  });

  it('should NOT add unassigned class when toggle is OFF even if test is unassigned', () => {
    useStore.setState({ isUnassignedHighlightVisible: false });

    const { container } = render(<TestItem testId="test1" />);

    const testDiv = container.querySelector('.test-item.unassigned');
    expect(testDiv).toBeNull();
  });

  it('should NOT add unassigned class when test is assigned', () => {
    useStore.setState({
      isUnassignedHighlightVisible: true,
      entities: {
        ...useStore.getState().entities,
        tests: {
          test1: {
            ...useStore.getState().entities.tests.test1,
            assigned_to_id: 1
          }
        }
      }
    });

    const { container } = render(<TestItem testId="test1" />);

    const testDiv = container.querySelector('.test-item.unassigned');
    expect(testDiv).toBeNull();
  });
});
