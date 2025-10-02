import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import React from 'react';
import { EpicVersionGrid } from './EpicVersionGrid';
import { useStore } from '../../store/useStore';
import type { NormalizedAPIResponse } from '../../types/normalized-api';

describe('EpicVersionGrid - Dynamic Layout Tests', () => {

  describe('Grid column count adjusts to version count', () => {

    it('should have 4 columns for 3 versions (1 epic-header + 3 version columns)', () => {
      // 3つのversionを持つデータをセットアップ
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
          index: {
            'e1:v1': [],
            'e1:v2': [],
            'e1:v3': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const grid = container.querySelector('.epic-version-grid');
      expect(grid).toBeTruthy();

      const style = grid?.getAttribute('style');
      expect(style).toContain('repeat(3');

      // ヘッダー: 1 label + 3 versions = 4要素
      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(3);

      // Epic行: 1 epic-header + 3 cells = 4要素
      const epicHeaders = container.querySelectorAll('.epic-header');
      expect(epicHeaders.length).toBe(1);

      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(3);
    });

    it('should have 3 columns for 2 versions (1 epic-header + 2 version columns)', () => {
      // 2つのversionを持つデータをセットアップ
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'v2': { id: 'v2', name: 'Version 2', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2'],
          index: {
            'e1:v1': [],
            'e1:v2': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const grid = container.querySelector('.epic-version-grid');
      const style = grid?.getAttribute('style');
      expect(style).toContain('repeat(2');

      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(2);

      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(2);
    });

    it('should have 6 columns for 5 versions (1 epic-header + 5 version columns)', () => {
      // 5つのversionを持つデータをセットアップ
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'v2': { id: 'v2', name: 'Version 2', status: 'open' },
            'v3': { id: 'v3', name: 'Version 3', status: 'open' },
            'v4': { id: 'v4', name: 'Version 4', status: 'open' },
            'v5': { id: 'v5', name: 'Version 5', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'v2', 'v3', 'v4', 'v5'],
          index: {
            'e1:v1': [],
            'e1:v2': [],
            'e1:v3': [],
            'e1:v4': [],
            'e1:v5': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const grid = container.querySelector('.epic-version-grid');
      const style = grid?.getAttribute('style');
      expect(style).toContain('repeat(5');

      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(5);

      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(5);
    });
  });

  describe('Grid row count adjusts to epic count', () => {

    it('should have 1 header row + 2 epic rows for 2 epics', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Epic 2', description: '', status: 'open' }
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
          epic_order: ['e1', 'e2'],
          version_order: ['v1'],
          index: {
            'e1:v1': [],
            'e2:v1': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // Epic headers: 2つ
      const epicHeaders = container.querySelectorAll('.epic-header');
      expect(epicHeaders.length).toBe(2);
      expect(epicHeaders[0].textContent).toBe('Epic 1');
      expect(epicHeaders[1].textContent).toBe('Epic 2');

      // Cells: 2 epics × 1 version = 2 cells
      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(2);
    });

    it('should have 1 header row + 3 epic rows for 3 epics', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Epic 2', description: '', status: 'open' },
            'e3': { id: 'e3', subject: 'Epic 3', description: '', status: 'open' }
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
          index: {
            'e1:v1': [],
            'e2:v1': [],
            'e3:v1': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      const epicHeaders = container.querySelectorAll('.epic-header');
      expect(epicHeaders.length).toBe(3);

      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(3);
    });
  });

  describe('Grid layout with multiple epics and versions', () => {

    it('should create correct grid for 2 epics × 3 versions = 6 cells', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' },
            'e2': { id: 'e2', subject: 'Epic 2', description: '', status: 'open' }
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
          epic_order: ['e1', 'e2'],
          version_order: ['v1', 'v2', 'v3'],
          index: {
            'e1:v1': [],
            'e1:v2': [],
            'e1:v3': [],
            'e2:v1': [],
            'e2:v2': [],
            'e2:v3': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // Grid columns: 1 epic-header + 3 versions
      const grid = container.querySelector('.epic-version-grid');
      const style = grid?.getAttribute('style');
      expect(style).toContain('repeat(3');

      // Epic headers: 2つ
      const epicHeaders = container.querySelectorAll('.epic-header');
      expect(epicHeaders.length).toBe(2);

      // Version headers: 3つ
      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(3);

      // Cells: 2 epics × 3 versions = 6 cells
      const cells = container.querySelectorAll('.epic-version-cell');
      expect(cells.length).toBe(6);
    });

    it('should filter out "none" version from grid columns', () => {
      const mockData: NormalizedAPIResponse = {
        entities: {
          epics: {
            'e1': { id: 'e1', subject: 'Epic 1', description: '', status: 'open' }
          },
          versions: {
            'v1': { id: 'v1', name: 'Version 1', status: 'open' },
            'none': { id: 'none', name: 'No Version', status: 'open' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {}
        },
        grid: {
          epic_order: ['e1'],
          version_order: ['v1', 'none'],
          index: {
            'e1:v1': [],
            'e1:none': []
          }
        }
      };

      useStore.setState({
        ...mockData,
        isLoading: false,
        error: null
      });

      const { container } = render(<EpicVersionGrid />);

      // "none"を除外するので、versionは1つ
      const grid = container.querySelector('.epic-version-grid');
      const style = grid?.getAttribute('style');
      expect(style).toContain('repeat(1');

      const versionHeaders = container.querySelectorAll('.version-header');
      expect(versionHeaders.length).toBe(1);
      expect(versionHeaders[0].textContent).toBe('Version 1');

      // "none"は表示されない
      expect(container.textContent).not.toContain('No Version');
    });
  });
});
