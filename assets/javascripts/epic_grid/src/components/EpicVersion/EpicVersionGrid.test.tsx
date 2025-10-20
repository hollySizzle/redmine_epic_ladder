import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { EpicVersionGrid } from './EpicVersionGrid';
import { useStore } from '../../store/useStore';

// Mock子コンポーネント
vi.mock('../UserStory/UserStoryGridForCell', () => ({
  UserStoryGridForCell: ({ epicId, featureId, versionId }: any) => (
    <div data-testid={`us-grid-${epicId}-${featureId}-${versionId}`}>UserStoryGrid</div>
  )
}));

vi.mock('../common/AddButton', () => ({
  AddButton: ({ type, label }: any) => (
    <button data-testid={`add-${type}`}>{label}</button>
  )
}));

vi.mock('../common/IssueFormModal', () => ({
  IssueFormModal: () => <div data-testid="issue-form-modal">IssueFormModal</div>
}));

vi.mock('../common/VersionFormModal', () => ({
  VersionFormModal: () => <div data-testid="version-form-modal">VersionFormModal</div>
}));

vi.mock('../../hooks/useDraggableAndDropTarget', () => ({
  useDraggableAndDropTarget: () => ({ current: null })
}));

vi.mock('../../hooks/useDropTarget', () => ({
  useDropTarget: () => ({ current: null })
}));

describe('EpicVersionGrid', () => {
  const mockGrid = {
    epic_order: ['epic-1', 'epic-2'],
    version_order: ['v1', 'v2', 'none'],
    epic_features: {
      'epic-1': ['feature-1', 'feature-2'],
      'epic-2': ['feature-3'],
    },
    feature_order_by_epic: {
      'epic-1': ['feature-1', 'feature-2'],
      'epic-2': ['feature-3'],
    },
    feature_expansion_states: {
      'epic-1:feature-1:v1': false,
      'epic-1:feature-1:v2': false,
      'epic-1:feature-1:none': false,
      'epic-1:feature-2:v1': false,
      'epic-1:feature-2:v2': false,
      'epic-1:feature-2:none': false,
      'epic-2:feature-3:v1': false,
      'epic-2:feature-3:v2': false,
      'epic-2:feature-3:none': false,
    },
    index: {
      'epic-1:feature-1:v1': ['us-1'],
      'epic-1:feature-1:v2': [],
      'epic-1:feature-1:none': [],
      'epic-1:feature-2:v1': ['us-2'],
      'epic-1:feature-2:v2': ['us-3'],
      'epic-1:feature-2:none': [],
      'epic-2:feature-3:v1': [],
      'epic-2:feature-3:v2': [],
      'epic-2:feature-3:none': [],
    },
    epic_version_user_stories: {
      'epic-1': {
        'v1': {
          'feature-1': ['us-1'],
          'feature-2': ['us-2'],
        },
        'v2': {
          'feature-1': [],
          'feature-2': ['us-3'],
        },
        'none': {
          'feature-1': [],
          'feature-2': [],
        },
      },
      'epic-2': {
        'v1': {
          'feature-3': [],
        },
        'v2': {
          'feature-3': [],
        },
        'none': {
          'feature-3': [],
        },
      },
    },
  };

  const mockEntities = {
    epics: {
      'epic-1': { id: 'epic-1', subject: 'Epic 1' },
      'epic-2': { id: 'epic-2', subject: 'Epic 2' },
    },
    features: {
      'feature-1': { id: 'feature-1', subject: 'Feature 1', parent_epic_id: 'epic-1' },
      'feature-2': { id: 'feature-2', subject: 'Feature 2', parent_epic_id: 'epic-1' },
      'feature-3': { id: 'feature-3', subject: 'Feature 3', parent_epic_id: 'epic-2' },
    },
    versions: {
      'v1': { id: 1, name: 'Version 1.0', effective_date: '2025-12-31' },
      'v2': { id: 2, name: 'Version 2.0', effective_date: '2026-06-30' },
    },
    users: {},
  };

  const defaultState = {
    grid: mockGrid,
    entities: mockEntities,
    createEpic: vi.fn(),
    createVersion: vi.fn(),
    createFeature: vi.fn(),
    setSelectedEntity: vi.fn(),
    toggleDetailPane: vi.fn(),
    isDetailPaneVisible: false,
    epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' },
    versionSortOptions: { sort_by: 'effective_date', sort_direction: 'asc' },
    filters: {},
    hideEmptyEpicsVersions: false,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState(defaultState as any);
  });

  describe('Rendering', () => {
    it('should render grid container', () => {
      const { container } = render(<EpicVersionGrid />);

      expect(container.querySelector('.epic-feature-version-grid')).toBeInTheDocument();
    });

    it('should render epic headers', () => {
      render(<EpicVersionGrid />);

      expect(screen.getByText('Epic 1')).toBeInTheDocument();
      expect(screen.getByText('Epic 2')).toBeInTheDocument();
    });

    it('should render version headers', () => {
      render(<EpicVersionGrid />);

      expect(screen.getByText(/Version 1.0/)).toBeInTheDocument();
      expect(screen.getByText(/Version 2.0/)).toBeInTheDocument();
    });

    it('should render feature cells', () => {
      render(<EpicVersionGrid />);

      expect(screen.getByText('Feature 1')).toBeInTheDocument();
      expect(screen.getByText('Feature 2')).toBeInTheDocument();
      expect(screen.getByText('Feature 3')).toBeInTheDocument();
    });

    it('should render add buttons', () => {
      render(<EpicVersionGrid />);

      expect(screen.getByTestId('add-epic')).toBeInTheDocument();
      expect(screen.getByTestId('add-version')).toBeInTheDocument();
    });
  });

  describe('Grid Structure', () => {
    it('should render correct number of epic rows', () => {
      const { container } = render(<EpicVersionGrid />);

      const epicCells = container.querySelectorAll('[data-epic]');
      expect(epicCells.length).toBeGreaterThan(0);
    });

    it('should render version columns', () => {
      const { container } = render(<EpicVersionGrid />);

      const versionCells = container.querySelectorAll('[data-version]');
      expect(versionCells.length).toBeGreaterThan(0);
    });

    it('should render user story cells', () => {
      render(<EpicVersionGrid />);

      // epic-1, feature-1, v1 has us-1
      expect(screen.getByTestId('us-grid-epic-1-feature-1-v1')).toBeInTheDocument();
    });
  });

  describe('Empty State', () => {
    it('should handle empty grid', () => {
      useStore.setState({
        ...defaultState,
        grid: {
          epic_order: [],
          version_order: [],
          epic_features: {},
          feature_order_by_epic: {},
          feature_expansion_states: {},
          index: {},
          epic_version_user_stories: {},
        },
      } as any);

      const { container } = render(<EpicVersionGrid />);

      expect(container.querySelector('.epic-feature-version-grid')).toBeInTheDocument();
    });
  });

  describe('Date Display', () => {
    it('should render version dates', () => {
      render(<EpicVersionGrid />);

      // formatDate outputs "12/31" and "6/30" format
      expect(screen.getByText(/12\/31/)).toBeInTheDocument();
      expect(screen.getByText(/6\/30/)).toBeInTheDocument();
    });
  });
});
