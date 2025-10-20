import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useSortedEpicsAndFeatures } from './useSortedEpicsAndFeatures';
import { useStore } from '../store/useStore';

vi.mock('../store/useStore');

describe('useSortedEpicsAndFeatures', () => {
  const mockEpics = {
    '101': {
      id: '101',
      subject: 'Alpha Epic',
      statistics: { completion_percentage: 30 }
    },
    '102': {
      id: '102',
      subject: 'Beta Epic',
      statistics: { completion_percentage: 60 }
    },
    '103': {
      id: '103',
      subject: 'Gamma Epic',
      statistics: { completion_percentage: 10 }
    }
  };

  const mockFeatures = {
    '201': {
      id: '201',
      subject: 'Feature A',
      statistics: { completion_percentage: 50 }
    },
    '202': {
      id: '202',
      subject: 'Feature B',
      statistics: { completion_percentage: 80 }
    },
    '203': {
      id: '203',
      subject: 'Feature C',
      statistics: { completion_percentage: 20 }
    }
  };

  const mockGrid = {
    epic_order: ['101', '102', '103'],
    feature_order_by_epic: {
      '101': ['201', '202'],
      '102': ['203']
    },
    version_order: [],
    index: {}
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Epic sorting', () => {
    it('subject + asc: サーバー順序をそのまま使用', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.sortedEpicOrder).toEqual(['101', '102', '103']);
    });

    it('subject + desc: サーバー順序を逆順', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'subject', sort_direction: 'desc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.sortedEpicOrder).toEqual(['103', '102', '101']);
    });

    it('id + asc: ID昇順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: { ...mockGrid, epic_order: ['103', '101', '102'] },
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'id', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.sortedEpicOrder).toEqual(['101', '102', '103']);
    });

    it('id + desc: ID降順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'id', sort_direction: 'desc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.sortedEpicOrder).toEqual(['103', '102', '101']);
    });

    it('date + asc: 完了率昇順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'date', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      // 10% < 30% < 60%
      expect(result.current.sortedEpicOrder).toEqual(['103', '101', '102']);
    });

    it('date + desc: 完了率降順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'date', sort_direction: 'desc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      // 60% > 30% > 10%
      expect(result.current.sortedEpicOrder).toEqual(['102', '101', '103']);
    });
  });

  describe('Feature sorting', () => {
    it('subject + asc: サーバー順序をそのまま使用', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.getSortedFeatureIds('101')).toEqual(['201', '202']);
      expect(result.current.getSortedFeatureIds('102')).toEqual(['203']);
    });

    it('subject + desc: サーバー順序を逆順', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'subject', sort_direction: 'desc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.getSortedFeatureIds('101')).toEqual(['202', '201']);
    });

    it('id + asc: ID昇順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: {
            ...mockGrid,
            feature_order_by_epic: {
              '101': ['202', '201']
            }
          },
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'id', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.getSortedFeatureIds('101')).toEqual(['201', '202']);
    });

    it('date + asc: 完了率昇順でソート', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'date', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      // Feature: 50% < 80%
      expect(result.current.getSortedFeatureIds('101')).toEqual(['201', '202']);
    });

    it('存在しないEpicIDの場合は空配列を返す', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          grid: mockGrid,
          entities: { epics: mockEpics, features: mockFeatures },
          epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' }
        };
        return selector(state);
      });

      const { result } = renderHook(() => useSortedEpicsAndFeatures());

      expect(result.current.getSortedFeatureIds('999')).toEqual([]);
    });
  });
});
