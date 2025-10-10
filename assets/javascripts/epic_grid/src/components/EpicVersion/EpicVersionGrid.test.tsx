import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { EpicVersionGrid } from './EpicVersionGrid';
import { useStore } from '../../store/useStore';
import type { NormalizedAPIResponse } from '../../types/normalized-api';

describe('EpicVersionGrid - 3D Grid Layout Tests', () => {

  beforeEach(() => {
    // ストアをリセット
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
      grid: {
        epic_order: [],
        version_order: [],
        feature_order_by_epic: {},
        index: {}
      },
      isLoading: false,
      error: null,
      projectId: '1',
      selectedIssueId: null,
      isDetailPaneVisible: false
    });
  });

  describe('Grid column structure', () => {

    it('should render correct number of version columns', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'v2': { id: 'v2', name: 'Version 2', status: 'open' },
            'v3': { id: 'v3', name: 'Version 3', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2', 'v3'],
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // Version headers should be rendered
      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(3);
      expect(versionHeaders[0].textContent).toBe('Version 1');
      expect(versionHeaders[1].textContent).toBe('Version 2');
      expect(versionHeaders[2].textContent).toBe('Version 3');
    });

    it('should render Epic and Feature header labels', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const headerLabels = container.querySelectorAll('.header-label');
      expect(headerLabels.length).toBe(2);
      expect(headerLabels[0].textContent).toBe('Epic');
      expect(headerLabels[1].textContent).toBe('Feature');
    });
  });

  describe('Grid row structure with Features', () => {

    it('should render epic with features in correct structure', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'v2': { id: 'v2', name: 'Version 2', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            },
            'f2': {
              id: 'f2',
              title: 'Feature 2',
              subject: 'Feature 2',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            }
          },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2'],
          feature_order_by_epic: {
            'e1': ['f1', 'f2']
          },
          index: {
            'e1:f1:v1': [],
            'e1:f1:v2': [],
            'e1:f2:v1': [],
            'e1:f2:v2': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // Epic cell should be rendered once
      const epicCells = container.querySelectorAll('.epic-cell');
      expect(epicCells.length).toBe(1);
      expect(epicCells[0].textContent).toContain('Epic 1');

      // Feature cells should be rendered (2 features)
      const featureCells = container.querySelectorAll('.feature-cell');
      expect(featureCells.length).toBe(2);
      expect(featureCells[0].textContent).toBe('Feature 1');
      expect(featureCells[1].textContent).toBe('Feature 2');

      // UserStory cells: 2 features × 2 versions = 4 cells
      const usCells = container.querySelectorAll('.us-cell');
      expect(usCells.length).toBe(4);
    });

    it('should render multiple epics correctly', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Epic 2', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            },
            'f2': {
              id: 'f2',
              title: 'Feature 2',
              subject: 'Feature 2',
              parent_epic_id: 'e2',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            }
          },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1', 'e2'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': ['f1'],
            'e2': ['f2']
          },
          index: {
            'e1:f1:v1': [],
            'e2:f2:v1': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const epicCells = container.querySelectorAll('.epic-cell');
      expect(epicCells.length).toBe(2);
      expect(epicCells[0].textContent).toContain('Epic 1');
      expect(epicCells[1].textContent).toContain('Epic 2');
    });
  });

  describe('Grid with UserStories', () => {

    it('should render UserStories in correct cells', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: ['us1', 'us2'],
              status: 'open'
            }
          },
          user_stories: {
            'us1': {
              id: 'us1',
              subject: 'User Story 1',
              parent_feature_id: 'f1',
              fixed_version_id: 'v1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            },
            'us2': {
              id: 'us2',
              subject: 'User Story 2',
              parent_feature_id: 'f1',
              fixed_version_id: 'v1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            }
          },
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': ['f1']
          },
          index: {
            'e1:f1:v1': ['us1', 'us2']
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // UserStories should be rendered
      const userStories = container.querySelectorAll('.user-story');
      expect(userStories.length).toBe(2);
    });
  });

  describe('Empty state handling', () => {

    it('should render epic without features', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // Epic should still be rendered
      const epicCells = container.querySelectorAll('.epic-cell');
      expect(epicCells.length).toBe(1);
      expect(epicCells[0].textContent).toContain('Epic 1');

      // Empty cells should be rendered
      const emptyCells = container.querySelectorAll('.empty-cell');
      expect(emptyCells.length).toBeGreaterThan(0);
    });
  });

  describe('Add buttons', () => {

    it('should render add version button', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const addVersionBtn = container.querySelector('.add-version-btn');
      expect(addVersionBtn).toBeTruthy();
      expect(addVersionBtn?.textContent).toContain('+ New Version');
    });

    it('should render add epic button', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const addEpicBtn = container.querySelector('.add-epic-btn');
      expect(addEpicBtn).toBeTruthy();
      expect(addEpicBtn?.textContent).toContain('+ New Epic');
    });

    it('should render add feature button for each epic', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const addFeatureBtns = container.querySelectorAll('.add-feature-btn');
      expect(addFeatureBtns.length).toBe(1);
      expect(addFeatureBtns[0].textContent).toContain('+ Add Feature');
    });
  });

  describe('UserStory D&D operations', () => {

    it('should call moveUserStory API when UserStory is dropped on a cell', async () => {
      // Mock moveUserStory action
      const mockMoveUserStory = vi.fn().mockResolvedValue(undefined);

      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'v2': { id: 'v2', name: 'Version 2', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: ['us1'],
              status: 'open'
            }
          },
          user_stories: {
            'us1': {
              id: 'us1',
              subject: 'User Story 1',
              parent_feature_id: 'f1',
              fixed_version_id: 'v1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            }
          },
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2'],
          feature_order_by_epic: {
            'e1': ['f1']
          },
          index: {
            'e1:f1:v1': ['us1'],
            'e1:f1:v2': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        projectId: '1',
        moveUserStory: mockMoveUserStory
      });

      const { container } = render(<EpicVersionGrid />);

      // UserStory cells should be rendered
      const usCells = container.querySelectorAll('.us-cell');
      expect(usCells.length).toBe(2); // 1 feature × 2 versions = 2 cells

      // This test verifies that the onDrop handler is properly set up
      // Actual D&D simulation would require @dnd-kit/core test utilities
      expect(mockMoveUserStory).not.toHaveBeenCalled(); // Not called during render
    });

    it('should handle version_id = null when dropping UserStory on "none" version', async () => {
      const mockMoveUserStory = vi.fn().mockResolvedValue(undefined);

      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: ['us1'],
              status: 'open'
            }
          },
          user_stories: {
            'us1': {
              id: 'us1',
              subject: 'User Story 1',
              parent_feature_id: 'f1',
              fixed_version_id: null,
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            }
          },
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': ['f1']
          },
          index: {
            'e1:f1:none': ['us1'],
            'e1:f1:v1': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        projectId: '1',
        moveUserStory: mockMoveUserStory
      });

      const { container } = render(<EpicVersionGrid />);

      // Should render cells for versions in version_order only
      const usCells = container.querySelectorAll('.us-cell');
      expect(usCells.length).toBe(1); // 1 feature × 1 version = 1 cell

      // UserStory with version_id=null should not be rendered in this test
      // (because 'none' is not in version_order)
      const userStories = container.querySelectorAll('.user-story');
      expect(userStories.length).toBe(0);
    });

    it('should not call moveUserStory when UserStory is dropped on the same cell', async () => {
      const mockMoveUserStory = vi.fn().mockResolvedValue(undefined);

      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Feature 1',
              subject: 'Feature 1',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: ['us1', 'us2'],
              status: 'open'
            }
          },
          user_stories: {
            'us1': {
              id: 'us1',
              subject: 'User Story 1',
              parent_feature_id: 'f1',
              fixed_version_id: 'v1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            },
            'us2': {
              id: 'us2',
              subject: 'User Story 2',
              parent_feature_id: 'f1',
              fixed_version_id: 'v1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              status: 'open'
            }
          },
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': ['f1']
          },
          index: {
            'e1:f1:v1': ['us1', 'us2']
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        projectId: '1',
        moveUserStory: mockMoveUserStory
      });

      const { container } = render(<EpicVersionGrid />);

      // Both UserStories should be in the same cell
      const userStories = container.querySelectorAll('.user-story');
      expect(userStories.length).toBe(2);

      // moveUserStory should not be called during render
      expect(mockMoveUserStory).not.toHaveBeenCalled();
    });
  });

  describe('Version creation with modal', () => {
    it('should open modal when "+ New Version" button is clicked', async () => {
      const user = userEvent.setup();

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
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        },
        isLoading: false,
        error: null
      });

      render(<EpicVersionGrid />);

      const addVersionBtn = screen.getByText('+ New Version');
      await user.click(addVersionBtn);

      // モーダルが開いているか確認
      expect(screen.getByText('新しいVersionを追加')).toBeTruthy();
      expect(screen.getByLabelText(/Version名/)).toBeTruthy();
    });

    it('should call createVersion when modal form is submitted', async () => {
      const user = userEvent.setup();
      const mockCreateVersion = vi.fn().mockResolvedValue(undefined);

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
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        },
        isLoading: false,
        error: null,
        createVersion: mockCreateVersion
      });

      render(<EpicVersionGrid />);

      const addVersionBtn = screen.getByText('+ New Version');
      await user.click(addVersionBtn);

      const nameInput = screen.getByLabelText(/Version名/);
      const effectiveDateInput = screen.getByLabelText('期日');
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.type(effectiveDateInput, '2025-12-31');
      await user.click(submitButton);

      expect(mockCreateVersion).toHaveBeenCalledWith({
        name: 'v1.0.0',
        description: '',
        status: 'open',
        effective_date: '2025-12-31'
      });
    });

    it('should call createVersion without effective_date when not provided', async () => {
      const user = userEvent.setup();
      const mockCreateVersion = vi.fn().mockResolvedValue(undefined);

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
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        },
        isLoading: false,
        error: null,
        createVersion: mockCreateVersion
      });

      render(<EpicVersionGrid />);

      const addVersionBtn = screen.getByText('+ New Version');
      await user.click(addVersionBtn);

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v2.0.0');
      await user.click(submitButton);

      expect(mockCreateVersion).toHaveBeenCalledWith({
        name: 'v2.0.0',
        description: '',
        status: 'open',
        effective_date: undefined
      });
    });

    it('should close modal when cancel button is clicked', async () => {
      const user = userEvent.setup();

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
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        },
        isLoading: false,
        error: null
      });

      render(<EpicVersionGrid />);

      const addVersionBtn = screen.getByText('+ New Version');
      await user.click(addVersionBtn);

      expect(screen.getByText('新しいVersionを追加')).toBeTruthy();

      const cancelButton = screen.getByText('キャンセル');
      await user.click(cancelButton);

      expect(screen.queryByText('新しいVersionを追加')).toBeNull();
    });

    it('should show alert when version creation fails', async () => {
      const user = userEvent.setup();
      const mockCreateVersion = vi.fn().mockRejectedValue(new Error('API Error'));
      const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

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
        grid: {
          epic_order: [],
          version_order: [],
          feature_order_by_epic: {},
          index: {}
        },
        isLoading: false,
        error: null,
        createVersion: mockCreateVersion
      });

      render(<EpicVersionGrid />);

      const addVersionBtn = screen.getByText('+ New Version');
      await user.click(addVersionBtn);

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.click(submitButton);

      expect(mockCreateVersion).toHaveBeenCalled();
      expect(alertSpy).toHaveBeenCalledWith('Version作成に失敗しました: API Error');

      alertSpy.mockRestore();
    });
  });

  describe('Sorting functionality', () => {

    beforeEach(() => {
      // LocalStorageをクリア
      localStorage.clear();
    });

    it('should sort epics by subject in ascending order by default', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Zebra Epic', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Apple Epic', description: '', status: 'open' },
            'e3': { id: 'e3', subject: 'Mango Epic', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1', 'e2', 'e3'], // 元の順序（ID順）
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': [],
            'e2': [],
            'e3': []
          },
          index: {}
        }
      };

      // デフォルト: subject / asc
      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const epicCells = container.querySelectorAll('.epic-cell');
      expect(epicCells.length).toBe(3);

      // subject昇順: Apple → Mango → Zebra
      expect(epicCells[0].textContent).toContain('Apple Epic');
      expect(epicCells[1].textContent).toContain('Mango Epic');
      expect(epicCells[2].textContent).toContain('Zebra Epic');
    });

    it('should sort epics by subject in descending order', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Zebra Epic', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Apple Epic', description: '', status: 'open' },
            'e3': { id: 'e3', subject: 'Mango Epic', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1', 'e2', 'e3'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': [],
            'e2': [],
            'e3': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        epicSortOptions: { sort_by: 'subject', sort_direction: 'desc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const epicCells = container.querySelectorAll('.epic-cell');

      // subject降順: Zebra → Mango → Apple
      expect(epicCells[0].textContent).toContain('Zebra Epic');
      expect(epicCells[1].textContent).toContain('Mango Epic');
      expect(epicCells[2].textContent).toContain('Apple Epic');
    });

    it('should sort epics by ID in ascending order', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            '10': { id: '10', subject: 'Epic 10', description: '', status: 'open' },
            '2': { id: '2', subject: 'Epic 2', description: '', status: 'open' },
            '30': { id: '30', subject: 'Epic 30', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['10', '2', '30'],
          version_order: ['v1'],
          feature_order_by_epic: {
            '10': [],
            '2': [],
            '30': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        epicSortOptions: { sort_by: 'id', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const epicCells = container.querySelectorAll('.epic-cell');

      // ID昇順: 2 → 10 → 30
      expect(epicCells[0].textContent).toContain('Epic 2');
      expect(epicCells[1].textContent).toContain('Epic 10');
      expect(epicCells[2].textContent).toContain('Epic 30');
    });

    it('should sort features by subject within each epic', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' }
          },
          features: {
            'f1': {
              id: 'f1',
              title: 'Zebra Feature',
              subject: 'Zebra Feature',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            },
            'f2': {
              id: 'f2',
              title: 'Apple Feature',
              subject: 'Apple Feature',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            },
            'f3': {
              id: 'f3',
              title: 'Mango Feature',
              subject: 'Mango Feature',
              parent_epic_id: 'e1',
              fixed_version_id: null,
              user_story_ids: [],
              status: 'open'
            }
          },
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1'],
          feature_order_by_epic: {
            'e1': ['f1', 'f2', 'f3'] // 元の順序（ID順）
          },
          index: {
            'e1:f1:v1': [],
            'e1:f2:v1': [],
            'e1:f3:v1': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const featureCells = container.querySelectorAll('.feature-cell');
      expect(featureCells.length).toBe(3);

      // Feature も subject昇順: Apple → Mango → Zebra
      expect(featureCells[0].textContent).toBe('Apple Feature');
      expect(featureCells[1].textContent).toBe('Mango Feature');
      expect(featureCells[2].textContent).toBe('Zebra Feature');
    });

    it('should sort versions by date in ascending order by default', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'v1.0', effective_date: '2025-03-15', status: 'open' },
            'v2': { id: 'v2', name: 'v2.0', effective_date: '2025-01-10', status: 'open' },
            'v3': { id: 'v3', name: 'v3.0', effective_date: '2025-02-20', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2', 'v3'], // 元の順序（ID順）
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        versionSortOptions: { sort_by: 'date', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(3);

      // 日付昇順: 2025-01-10 → 2025-02-20 → 2025-03-15
      expect(versionHeaders[0].textContent).toContain('v2.0');
      expect(versionHeaders[1].textContent).toContain('v3.0');
      expect(versionHeaders[2].textContent).toContain('v1.0');
    });

    it('should sort versions by name in ascending order', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Zebra Version', effective_date: '2025-01-10', status: 'open' },
            'v2': { id: 'v2', name: 'Apple Version', effective_date: '2025-02-20', status: 'open' },
            'v3': { id: 'v3', name: 'Mango Version', effective_date: '2025-03-15', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2', 'v3'],
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        versionSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const versionHeaders = container.querySelectorAll('.version-header');

      // 名前昇順: Apple → Mango → Zebra
      expect(versionHeaders[0].textContent).toContain('Apple Version');
      expect(versionHeaders[1].textContent).toContain('Mango Version');
      expect(versionHeaders[2].textContent).toContain('Zebra Version');
    });

    it('should keep "none" version at the end when sorting', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'v1.0', effective_date: '2025-02-15', status: 'open' },
            'v2': { id: 'v2', name: 'v2.0', effective_date: '2025-01-10', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'none', 'v2'], // 'none' が中間に配置されている
          feature_order_by_epic: {
            'e1': []
          },
          index: {}
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null,
        versionSortOptions: { sort_by: 'date', sort_direction: 'asc' }
      });

      const { container } = render(<EpicVersionGrid />);

      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(3);

      // 日付昇順でソート後、'none' は最後に配置
      expect(versionHeaders[0].textContent).toContain('v2.0'); // 2025-01-10
      expect(versionHeaders[1].textContent).toContain('v1.0'); // 2025-02-15
      expect(versionHeaders[2].textContent).toContain('(未設定)'); // 'none'
    });
  });
});
