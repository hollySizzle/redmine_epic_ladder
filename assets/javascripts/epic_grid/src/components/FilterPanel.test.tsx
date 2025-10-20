import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { FilterPanel } from './FilterPanel';
import { useStore } from '../store/useStore';

describe('FilterPanel', () => {
  const mockSetFilters = vi.fn();
  const mockClearFilters = vi.fn();
  const mockToggleExcludeClosedVersions = vi.fn();
  const mockToggleHideEmptyEpicsVersions = vi.fn();

  const defaultState = {
    entities: {
      versions: {
        '1': { id: 1, name: 'v1.0', status: 'open', effective_date: '2025-12-31' },
        '2': { id: 2, name: 'v2.0', status: 'open', effective_date: '2026-06-30' },
      },
      users: {
        '1': { id: 1, firstname: 'User', lastname: '1' },
        '2': { id: 2, firstname: 'User', lastname: '2' },
      },
      epics: {},
      features: {},
      userStories: {},
      tasks: {},
      tests: {},
      bugs: {},
    },
    metadata: {
      available_statuses: [
        { id: 1, name: 'New' },
        { id: 2, name: 'In Progress' },
      ],
      available_trackers: [
        { id: 1, name: 'Bug' },
        { id: 2, name: 'Feature' },
      ],
    },
    filters: {},
    setFilters: mockSetFilters,
    clearFilters: mockClearFilters,
    excludeClosedVersions: false,
    toggleExcludeClosedVersions: mockToggleExcludeClosedVersions,
    hideEmptyEpicsVersions: false,
    toggleHideEmptyEpicsVersions: mockToggleHideEmptyEpicsVersions,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState(defaultState as any);
  });

  describe('Rendering', () => {
    it('should render filter button', () => {
      render(<FilterPanel />);

      expect(screen.getByText(/🔍 フィルタ/)).toBeInTheDocument();
    });

    it('should toggle expansion when button clicked', () => {
      render(<FilterPanel />);

      const button = screen.getByText(/🔍 フィルタ/);

      // Initially collapsed - check for filter dropdown
      expect(screen.queryByText('クローズ済みバージョンを非表示')).not.toBeInTheDocument();

      // Click to expand
      fireEvent.click(button);
      expect(screen.getByText('クローズ済みバージョンを非表示')).toBeInTheDocument();

      // Click to collapse
      fireEvent.click(button);
      expect(screen.queryByText('クローズ済みバージョンを非表示')).not.toBeInTheDocument();
    });
  });

  describe('Version Filter', () => {
    it('should render version checkboxes when expanded', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText('v1.0')).toBeInTheDocument();
      expect(screen.getByText('v2.0')).toBeInTheDocument();
    });

    it('should show exclude closed versions toggle', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText(/クローズ済みバージョンを非表示/)).toBeInTheDocument();
    });
  });

  describe('User Filter', () => {
    it('should render user checkboxes when expanded', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText('User 1')).toBeInTheDocument();
      expect(screen.getByText('User 2')).toBeInTheDocument();
    });
  });

  describe('Status Filter', () => {
    it('should render status checkboxes when expanded', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText('New')).toBeInTheDocument();
      expect(screen.getByText('In Progress')).toBeInTheDocument();
    });
  });

  describe('Tracker Filter', () => {
    it('should render tracker checkboxes when expanded', () => {
      const { container } = render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      // Check within tracker section
      const trackerSection = Array.from(container.querySelectorAll('.filter-section'))
        .find(section => section.querySelector('h4')?.textContent === 'トラッカー');

      expect(trackerSection?.textContent).toContain('Bug');
      expect(trackerSection?.textContent).toContain('Feature');
    });
  });

  describe('Filter Actions', () => {
    it('should show apply button when expanded', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText('適用')).toBeInTheDocument();
    });

    it('should show clear button when expanded', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText('クリア')).toBeInTheDocument();
    });

    it('should call clearFilters when clear button clicked', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));
      fireEvent.click(screen.getByText('クリア'));

      expect(mockClearFilters).toHaveBeenCalled();
    });
  });

  describe('Empty State', () => {
    it('should show hide empty toggle', () => {
      render(<FilterPanel />);

      fireEvent.click(screen.getByText(/🔍 フィルタ/));

      expect(screen.getByText(/ヒットしなかったEpic\/Versionを非表示/)).toBeInTheDocument();
    });
  });

  describe('Active Filters Display', () => {
    it('should show filter count when filters applied', () => {
      useStore.setState({
        ...defaultState,
        filters: {
          fixed_version_id_in: ['1'],
          assigned_to_id_in: [1, 2],
        },
      } as any);

      render(<FilterPanel />);

      expect(screen.getByText(/🔍 フィルタ \(2\)/)).toBeInTheDocument();
    });

    it('should not show count when no filters', () => {
      render(<FilterPanel />);

      expect(screen.getByText('🔍 フィルタ')).toBeInTheDocument();
      expect(screen.queryByText(/🔍 フィルタ \(/)).not.toBeInTheDocument();
    });
  });
});
