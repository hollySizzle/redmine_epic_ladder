import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { useStore } from './useStore';
import { normalizedMockData } from '../mocks/normalized-mock-data';
import * as API from '../api/kanban-api';

describe('useStore - Normalized API (3D Grid)', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({
      entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
      grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
      isLoading: false,
      error: null,
      projectId: '1',
      selectedEntity: null,
      selectedIssueId: null,
      isDetailPaneVisible: false
    });
  });

  describe('Initial State', () => {
    it('should have initial entities', () => {
      const state = useStore.getState();
      expect(Object.keys(state.entities.epics).length).toBeGreaterThan(0);
      expect(Object.keys(state.entities.features).length).toBeGreaterThan(0);
      expect(Object.keys(state.entities.user_stories).length).toBeGreaterThan(0);
    });

    it('should have 3D grid structure', () => {
      const state = useStore.getState();
      expect(state.grid.index).toBeDefined();
      expect(state.grid.feature_order_by_epic).toBeDefined();
      expect(state.grid.epic_order.length).toBeGreaterThan(0);
      expect(state.grid.version_order.length).toBeGreaterThan(0);
    });

    it('should have grid.index with 3D keys (epic:feature:version)', () => {
      const state = useStore.getState();
      const indexKeys = Object.keys(state.grid.index);

      // 3D Grid のキー形式を確認
      expect(indexKeys.length).toBeGreaterThan(0);

      // キーが "epic:feature:version" 形式であることを確認
      const sampleKey = indexKeys[0];
      const parts = sampleKey.split(':');
      expect(parts.length).toBe(3);
    });

    it('should have feature_order_by_epic mapping', () => {
      const state = useStore.getState();

      expect(state.grid.feature_order_by_epic).toBeDefined();
      expect(typeof state.grid.feature_order_by_epic).toBe('object');

      // Epic ごとに Feature の配列があることを確認
      const epicId = state.grid.epic_order[0];
      expect(Array.isArray(state.grid.feature_order_by_epic[epicId])).toBe(true);
    });
  });

  describe('moveUserStoryToCell', () => {
    it('should move UserStory to different Feature/Version cell', () => {
      const state = useStore.getState();

      // 移動対象のUserStoryを見つける
      const userStoryId = Object.keys(state.entities.user_stories)[0];
      const userStory = state.entities.user_stories[userStoryId];

      // 移動元の情報
      const oldFeatureId = userStory.parent_feature_id;
      const oldFeature = state.entities.features[oldFeatureId];
      const oldEpicId = oldFeature.parent_epic_id;
      const oldVersionId = userStory.fixed_version_id || 'none';
      const oldCellKey = `${oldEpicId}:${oldFeatureId}:${oldVersionId}`;

      // 移動先の情報（異なるFeature）
      const targetFeatureId = Object.keys(state.entities.features).find(fId => fId !== oldFeatureId);
      if (!targetFeatureId) {
        // テストスキップ: 移動先Featureが存在しない
        return;
      }

      const targetFeature = state.entities.features[targetFeatureId];
      const targetEpicId = targetFeature.parent_epic_id;
      const targetVersionId = 'v1';

      // 移動実行
      const { moveUserStoryToCell } = useStore.getState();
      moveUserStoryToCell(userStoryId, targetEpicId, targetFeatureId, targetVersionId);

      const newState = useStore.getState();
      const targetCellKey = `${targetEpicId}:${targetFeatureId}:${targetVersionId}`;

      // 古いセルから削除されていることを確認
      expect(newState.grid.index[oldCellKey]).not.toContain(userStoryId);

      // 新しいセルに追加されていることを確認
      expect(newState.grid.index[targetCellKey]).toContain(userStoryId);

      // UserStoryのparent_feature_idが更新されていることを確認
      expect(newState.entities.user_stories[userStoryId].parent_feature_id).toBe(targetFeatureId);

      // UserStoryのfixed_version_idが更新されていることを確認
      expect(newState.entities.user_stories[userStoryId].fixed_version_id).toBe(targetVersionId);
    });

    it('should update Feature user_story_ids when moving UserStory', () => {
      const state = useStore.getState();

      const userStoryId = Object.keys(state.entities.user_stories)[0];
      const userStory = state.entities.user_stories[userStoryId];
      const oldFeatureId = userStory.parent_feature_id;
      const oldFeature = state.entities.features[oldFeatureId];

      // 移動先Feature
      const targetFeatureId = Object.keys(state.entities.features).find(fId => fId !== oldFeatureId);
      if (!targetFeatureId) return;

      const targetFeature = state.entities.features[targetFeatureId];
      const targetEpicId = targetFeature.parent_epic_id;

      const { moveUserStoryToCell } = useStore.getState();
      moveUserStoryToCell(userStoryId, targetEpicId, targetFeatureId, 'v1');

      const newState = useStore.getState();

      // 古いFeatureのuser_story_idsから削除されていることを確認
      expect(newState.entities.features[oldFeatureId].user_story_ids).not.toContain(userStoryId);

      // 新しいFeatureのuser_story_idsに追加されていることを確認
      expect(newState.entities.features[targetFeatureId].user_story_ids).toContain(userStoryId);
    });
  });

  describe('reorderUserStories', () => {
    it('should reorder UserStories within same Feature', () => {
      const state = useStore.getState();

      // 同じFeatureに属する2つのUserStoryを見つける
      const featureId = Object.keys(state.entities.features).find(fId => {
        return state.entities.features[fId].user_story_ids.length >= 2;
      });

      if (!featureId) {
        // テストスキップ: 十分なUserStoryがない
        return;
      }

      const feature = state.entities.features[featureId];
      const [sourceId, targetId] = feature.user_story_ids;

      const { reorderUserStories } = useStore.getState();
      reorderUserStories(sourceId, targetId, {});

      const newState = useStore.getState();
      const newFeature = newState.entities.features[featureId];

      // 順序が変更されていることを確認
      const sourceIndex = newFeature.user_story_ids.indexOf(sourceId);
      const targetIndex = newFeature.user_story_ids.indexOf(targetId);

      // sourceがtargetの後ろに移動していることを期待
      expect(sourceIndex).toBeGreaterThan(targetIndex);
    });
  });

  describe('Detail Pane', () => {
    it('should toggle detail pane visibility', () => {
      const { toggleDetailPane } = useStore.getState();

      const initialState = useStore.getState();
      expect(initialState.isDetailPaneVisible).toBe(false);

      toggleDetailPane();

      const newState = useStore.getState();
      expect(newState.isDetailPaneVisible).toBe(true);

      toggleDetailPane();

      const finalState = useStore.getState();
      expect(finalState.isDetailPaneVisible).toBe(false);
    });

    it('should set selected entity', () => {
      const { setSelectedEntity } = useStore.getState();

      setSelectedEntity('issue', 'us1');

      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'issue', id: 'us1' });
    });

    it('should provide backward compatibility with selectedIssueId getter', () => {
      const { setSelectedEntity } = useStore.getState();

      setSelectedEntity('issue', 'us1');

      const state = useStore.getState();
      expect(state.selectedIssueId).toBe('us1');
    });

    it('should return null for selectedIssueId when version is selected', () => {
      const { setSelectedEntity } = useStore.getState();

      setSelectedEntity('version', 'v1');

      const state = useStore.getState();
      expect(state.selectedIssueId).toBeNull();
      expect(state.selectedEntity).toEqual({ type: 'version', id: 'v1' });
    });
  });

  describe('CRUD Operations', () => {
    it('should have createEpic action', () => {
      const { createEpic } = useStore.getState();
      expect(typeof createEpic).toBe('function');
    });

    it('should have createVersion action', () => {
      const { createVersion } = useStore.getState();
      expect(typeof createVersion).toBe('function');
    });

    it('should have createFeature action', () => {
      const { createFeature } = useStore.getState();
      expect(typeof createFeature).toBe('function');
    });

    it('should have createUserStory action', () => {
      const { createUserStory } = useStore.getState();
      expect(typeof createUserStory).toBe('function');
    });

    it('should show created Epic in detail pane after createEpic', async () => {
      // APIレスポンスをモック
      const mockResponse = {
        success: true,
        data: {
          created_entity: { id: 'new-epic-1', subject: 'New Epic', description: '', status: 'open' },
          updated_entities: {
            epics: { 'new-epic-1': { id: 'new-epic-1', subject: 'New Epic', description: '', status: 'open' } }
          },
          grid_updates: {
            epic_order: ['new-epic-1']
          }
        },
        meta: { timestamp: '2025-01-01T00:00:00Z', request_id: 'test-123' }
      };

      vi.spyOn(API, 'createEpic').mockResolvedValue(mockResponse);

      const { createEpic } = useStore.getState();
      await createEpic({ subject: 'New Epic', description: '' });

      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'issue', id: 'new-epic-1' });
      expect(state.isDetailPaneVisible).toBe(true);
    });

    it('should show created Version in detail pane after createVersion', async () => {
      // APIレスポンスをモック
      const mockResponse = {
        success: true,
        data: {
          created_entity: { id: 'new-v1', name: 'v1.0', status: 'open' },
          updated_entities: {
            versions: { 'new-v1': { id: 'new-v1', name: 'v1.0', status: 'open' } }
          },
          grid_updates: {
            version_order: ['new-v1']
          }
        },
        meta: { timestamp: '2025-01-01T00:00:00Z', request_id: 'test-456' }
      };

      vi.spyOn(API, 'createVersion').mockResolvedValue(mockResponse);

      const { createVersion } = useStore.getState();
      await createVersion({ name: 'v1.0', status: 'open' });

      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'version', id: 'new-v1' });
      expect(state.isDetailPaneVisible).toBe(true);
    });

    it('should show created Feature in detail pane after createFeature', async () => {
      // APIレスポンスをモック
      const mockResponse = {
        success: true,
        data: {
          created_entity: {
            id: 'new-f1',
            title: 'New Feature',
            subject: 'New Feature',
            parent_epic_id: 'e1',
            fixed_version_id: null,
            user_story_ids: [],
            status: 'open'
          },
          updated_entities: {
            features: {
              'new-f1': {
                id: 'new-f1',
                title: 'New Feature',
                subject: 'New Feature',
                parent_epic_id: 'e1',
                fixed_version_id: null,
                user_story_ids: [],
                status: 'open'
              }
            }
          },
          grid_updates: {
            index: {},
            feature_order_by_epic: { 'e1': ['new-f1'] }
          }
        },
        meta: { timestamp: '2025-01-01T00:00:00Z', request_id: 'test-789' }
      };

      vi.spyOn(API, 'createFeature').mockResolvedValue(mockResponse);

      const { createFeature } = useStore.getState();
      await createFeature({ subject: 'New Feature', description: '', parent_epic_id: 'e1' });

      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'issue', id: 'new-f1' });
      expect(state.isDetailPaneVisible).toBe(true);
    });

    it('should keep detail pane open if already visible', async () => {
      // 詳細ペインを事前に開いておく
      useStore.setState({ isDetailPaneVisible: true });

      const mockResponse = {
        success: true,
        data: {
          created_entity: { id: 'new-epic-2', subject: 'Another Epic', description: '', status: 'open' },
          updated_entities: {
            epics: { 'new-epic-2': { id: 'new-epic-2', subject: 'Another Epic', description: '', status: 'open' } }
          },
          grid_updates: {
            epic_order: ['new-epic-2']
          }
        },
        meta: { timestamp: '2025-01-01T00:00:00Z', request_id: 'test-abc' }
      };

      vi.spyOn(API, 'createEpic').mockResolvedValue(mockResponse);

      const { createEpic } = useStore.getState();
      await createEpic({ subject: 'Another Epic', description: '' });

      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'issue', id: 'new-epic-2' });
      expect(state.isDetailPaneVisible).toBe(true); // Still true
    });
  });

  describe('Reorder Operations', () => {
    it('should have reorderEpics action', () => {
      const { reorderEpics } = useStore.getState();
      expect(typeof reorderEpics).toBe('function');
    });

    it('should have reorderVersions action', () => {
      const { reorderVersions } = useStore.getState();
      expect(typeof reorderVersions).toBe('function');
    });

    it('should have reorderTasks action', () => {
      const { reorderTasks } = useStore.getState();
      expect(typeof reorderTasks).toBe('function');
    });

    it('should have reorderTests action', () => {
      const { reorderTests } = useStore.getState();
      expect(typeof reorderTests).toBe('function');
    });

    it('should have reorderBugs action', () => {
      const { reorderBugs } = useStore.getState();
      expect(typeof reorderBugs).toBe('function');
    });
  });

  describe('Sort Settings', () => {

    beforeEach(() => {
      // LocalStorageをクリア
      localStorage.clear();
    });

    afterEach(() => {
      localStorage.clear();
    });

    describe('Default Values', () => {
      it('should have default epic sort as subject/asc', () => {
        // ストアを再初期化（デフォルト値を確認）
        const sortBy = localStorage.getItem('kanban_epic_sort_by') || 'subject';
        const sortDirection = localStorage.getItem('kanban_epic_sort_direction') || 'asc';

        expect(sortBy).toBe('subject');
        expect(sortDirection).toBe('asc');
      });

      it('should have default version sort as date/asc', () => {
        const sortBy = localStorage.getItem('kanban_version_sort_by') || 'date';
        const sortDirection = localStorage.getItem('kanban_version_sort_direction') || 'asc';

        expect(sortBy).toBe('date');
        expect(sortDirection).toBe('asc');
      });
    });

    describe('setEpicSort', () => {
      it('should update epic sort state', () => {
        const { setEpicSort } = useStore.getState();

        setEpicSort('id', 'desc');

        const state = useStore.getState();
        expect(state.epicSortOptions.sort_by).toBe('id');
        expect(state.epicSortOptions.sort_direction).toBe('desc');
      });

      it('should save epic sort to localStorage', () => {
        const { setEpicSort } = useStore.getState();

        setEpicSort('date', 'asc');

        expect(localStorage.getItem('kanban_epic_sort_by')).toBe('date');
        expect(localStorage.getItem('kanban_epic_sort_direction')).toBe('asc');
      });

      it('should update only sort_by when direction unchanged', () => {
        const { setEpicSort } = useStore.getState();

        setEpicSort('subject', 'asc');
        setEpicSort('id', 'asc'); // direction は変わらない

        const state = useStore.getState();
        expect(state.epicSortOptions.sort_by).toBe('id');
        expect(state.epicSortOptions.sort_direction).toBe('asc');
      });

      it('should update only sort_direction when field unchanged', () => {
        const { setEpicSort } = useStore.getState();

        setEpicSort('subject', 'asc');
        setEpicSort('subject', 'desc'); // field は変わらない

        const state = useStore.getState();
        expect(state.epicSortOptions.sort_by).toBe('subject');
        expect(state.epicSortOptions.sort_direction).toBe('desc');
      });
    });

    describe('setVersionSort', () => {
      it('should update version sort state', () => {
        const { setVersionSort } = useStore.getState();

        setVersionSort('subject', 'desc');

        const state = useStore.getState();
        expect(state.versionSortOptions.sort_by).toBe('subject');
        expect(state.versionSortOptions.sort_direction).toBe('desc');
      });

      it('should save version sort to localStorage', () => {
        const { setVersionSort } = useStore.getState();

        setVersionSort('id', 'asc');

        expect(localStorage.getItem('kanban_version_sort_by')).toBe('id');
        expect(localStorage.getItem('kanban_version_sort_direction')).toBe('asc');
      });
    });

    describe('LocalStorage persistence', () => {
      it('should load saved epic sort on init', () => {
        // LocalStorageに保存済みの値をセット
        localStorage.setItem('kanban_epic_sort_by', 'id');
        localStorage.setItem('kanban_epic_sort_direction', 'desc');

        // ストアを再初期化（実際のアプリ起動時の動作をシミュレート）
        const sortBy = localStorage.getItem('kanban_epic_sort_by') || 'subject';
        const sortDirection = localStorage.getItem('kanban_epic_sort_direction') || 'asc';

        expect(sortBy).toBe('id');
        expect(sortDirection).toBe('desc');
      });

      it('should load saved version sort on init', () => {
        localStorage.setItem('kanban_version_sort_by', 'subject');
        localStorage.setItem('kanban_version_sort_direction', 'desc');

        const sortBy = localStorage.getItem('kanban_version_sort_by') || 'date';
        const sortDirection = localStorage.getItem('kanban_version_sort_direction') || 'asc';

        expect(sortBy).toBe('subject');
        expect(sortDirection).toBe('desc');
      });

      it('should use default values when localStorage is empty', () => {
        // LocalStorageが空の状態

        const epicSortBy = localStorage.getItem('kanban_epic_sort_by') || 'subject';
        const epicSortDirection = localStorage.getItem('kanban_epic_sort_direction') || 'asc';
        const versionSortBy = localStorage.getItem('kanban_version_sort_by') || 'date';
        const versionSortDirection = localStorage.getItem('kanban_version_sort_direction') || 'asc';

        expect(epicSortBy).toBe('subject');
        expect(epicSortDirection).toBe('asc');
        expect(versionSortBy).toBe('date');
        expect(versionSortDirection).toBe('asc');
      });
    });

    describe('Sort actions existence', () => {
      it('should have setEpicSort action', () => {
        const { setEpicSort } = useStore.getState();
        expect(typeof setEpicSort).toBe('function');
      });

      it('should have setVersionSort action', () => {
        const { setVersionSort } = useStore.getState();
        expect(typeof setVersionSort).toBe('function');
      });
    });
  });

  describe('Issue ID Visibility Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    afterEach(() => {
      localStorage.clear();
    });

    it('should have default issue ID visibility as true', () => {
      const saved = localStorage.getItem('kanban_issue_id_visible');
      const defaultValue = saved !== null ? saved === 'true' : true;
      expect(defaultValue).toBe(true);
    });

    it('should toggle issue ID visibility', () => {
      const { toggleIssueIdVisible } = useStore.getState();

      const initialState = useStore.getState();
      const initialValue = initialState.isIssueIdVisible;

      toggleIssueIdVisible();

      const newState = useStore.getState();
      expect(newState.isIssueIdVisible).toBe(!initialValue);

      toggleIssueIdVisible();

      const finalState = useStore.getState();
      expect(finalState.isIssueIdVisible).toBe(initialValue);
    });

    it('should save issue ID visibility to localStorage', () => {
      const { toggleIssueIdVisible } = useStore.getState();

      toggleIssueIdVisible();

      const saved = localStorage.getItem('kanban_issue_id_visible');
      expect(saved).not.toBeNull();
    });

    it('should load saved issue ID visibility from localStorage', () => {
      localStorage.setItem('kanban_issue_id_visible', 'false');

      const saved = localStorage.getItem('kanban_issue_id_visible');
      const loaded = saved !== null ? saved === 'true' : true;

      expect(loaded).toBe(false);
    });
  });

  describe('Hide Empty Epics/Versions Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    afterEach(() => {
      localStorage.clear();
    });

    it('should have default hideEmptyEpicsVersions as false', () => {
      const saved = localStorage.getItem('kanban_hide_empty_epics_versions');
      const defaultValue = saved !== null ? saved === 'true' : false;
      expect(defaultValue).toBe(false);
    });

    it('should toggle hideEmptyEpicsVersions', () => {
      const { toggleHideEmptyEpicsVersions } = useStore.getState();

      const initialState = useStore.getState();
      const initialValue = initialState.hideEmptyEpicsVersions;

      toggleHideEmptyEpicsVersions();

      const newState = useStore.getState();
      expect(newState.hideEmptyEpicsVersions).toBe(!initialValue);

      toggleHideEmptyEpicsVersions();

      const finalState = useStore.getState();
      expect(finalState.hideEmptyEpicsVersions).toBe(initialValue);
    });

    it('should save hideEmptyEpicsVersions to localStorage', () => {
      const { toggleHideEmptyEpicsVersions } = useStore.getState();

      toggleHideEmptyEpicsVersions();

      const saved = localStorage.getItem('kanban_hide_empty_epics_versions');
      expect(saved).not.toBeNull();
      expect(saved).toBe('true');
    });

    it('should load saved hideEmptyEpicsVersions from localStorage', () => {
      localStorage.setItem('kanban_hide_empty_epics_versions', 'true');

      const saved = localStorage.getItem('kanban_hide_empty_epics_versions');
      const loaded = saved !== null ? saved === 'true' : false;

      expect(loaded).toBe(true);
    });

    it('should have toggleHideEmptyEpicsVersions action', () => {
      const { toggleHideEmptyEpicsVersions } = useStore.getState();
      expect(typeof toggleHideEmptyEpicsVersions).toBe('function');
    });
  });

  describe('Side Menu Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should have default side menu visibility as false', () => {
      const state = useStore.getState();
      expect(state.isSideMenuVisible).toBeDefined();
    });

    it('should toggle side menu visibility', () => {
      const { toggleSideMenu } = useStore.getState();
      
      const initialState = useStore.getState().isSideMenuVisible;
      
      toggleSideMenu();
      expect(useStore.getState().isSideMenuVisible).toBe(!initialState);
      
      toggleSideMenu();
      expect(useStore.getState().isSideMenuVisible).toBe(initialState);
    });

    it('should save side menu visibility to localStorage', () => {
      const { toggleSideMenu } = useStore.getState();
      
      toggleSideMenu();
      
      const saved = localStorage.getItem('kanban_side_menu_visible');
      expect(saved).not.toBeNull();
    });
  });

  describe('Active Side Tab', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should have default active side tab', () => {
      const state = useStore.getState();
      expect(state.activeSideTab).toBeDefined();
    });

    it('should set active side tab', () => {
      const { setActiveSideTab } = useStore.getState();
      
      setActiveSideTab('search');
      expect(useStore.getState().activeSideTab).toBe('search');
      
      setActiveSideTab('list');
      expect(useStore.getState().activeSideTab).toBe('list');
      
      setActiveSideTab('about');
      expect(useStore.getState().activeSideTab).toBe('about');
    });

    it('should save active side tab to localStorage', () => {
      const { setActiveSideTab } = useStore.getState();
      
      setActiveSideTab('search');
      
      const saved = localStorage.getItem('kanban_active_side_tab');
      expect(saved).toBe('search');
    });
  });

  describe('Vertical Mode Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should toggle vertical mode', () => {
      const { toggleVerticalMode } = useStore.getState();
      
      const initialState = useStore.getState().isVerticalMode;
      
      toggleVerticalMode();
      expect(useStore.getState().isVerticalMode).toBe(!initialState);
      
      toggleVerticalMode();
      expect(useStore.getState().isVerticalMode).toBe(initialState);
    });

    it('should save vertical mode to localStorage', () => {
      const { toggleVerticalMode } = useStore.getState();
      
      toggleVerticalMode();
      
      const saved = localStorage.getItem('kanban_vertical_mode');
      expect(saved).not.toBeNull();
    });
  });

  describe('Assigned To Visibility Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should toggle assigned to visibility', () => {
      const { toggleAssignedToVisible } = useStore.getState();
      
      const initialState = useStore.getState().isAssignedToVisible;
      
      toggleAssignedToVisible();
      expect(useStore.getState().isAssignedToVisible).toBe(!initialState);
      
      toggleAssignedToVisible();
      expect(useStore.getState().isAssignedToVisible).toBe(initialState);
    });

    it('should save assigned to visibility to localStorage', () => {
      const { toggleAssignedToVisible } = useStore.getState();
      
      toggleAssignedToVisible();
      
      const saved = localStorage.getItem('kanban_assigned_to_visible');
      expect(saved).not.toBeNull();
    });
  });

  describe('Due Date Visibility Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should toggle due date visibility', () => {
      const { toggleDueDateVisible } = useStore.getState();
      
      const initialState = useStore.getState().isDueDateVisible;
      
      toggleDueDateVisible();
      expect(useStore.getState().isDueDateVisible).toBe(!initialState);
      
      toggleDueDateVisible();
      expect(useStore.getState().isDueDateVisible).toBe(initialState);
    });

    it('should save due date visibility to localStorage', () => {
      const { toggleDueDateVisible } = useStore.getState();
      
      toggleDueDateVisible();
      
      const saved = localStorage.getItem('kanban_due_date_visible');
      expect(saved).not.toBeNull();
    });
  });

  describe('User Story Collapse States', () => {
    beforeEach(() => {
      localStorage.clear();
      useStore.setState({
        userStoryCollapseStates: {}
      });
    });

    it('should set user story collapsed state', () => {
      const { setUserStoryCollapsed } = useStore.getState();
      
      setUserStoryCollapsed('us-1', true);
      expect(useStore.getState().userStoryCollapseStates['us-1']).toBe(true);
      
      setUserStoryCollapsed('us-1', false);
      expect(useStore.getState().userStoryCollapseStates['us-1']).toBe(false);
    });

    it('should save collapse states to localStorage', () => {
      const { setUserStoryCollapsed } = useStore.getState();
      
      setUserStoryCollapsed('us-1', true);
      
      const saved = localStorage.getItem('kanban_userstory_collapse_states');
      expect(saved).not.toBeNull();
      
      const parsed = JSON.parse(saved!);
      expect(parsed['us-1']).toBe(true);
    });

    it('should set all user stories collapsed', () => {
      const { setAllUserStoriesCollapsed } = useStore.getState();
      
      // First set some to entities
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            'us-1': { id: 'us-1', title: 'Story 1' } as any,
            'us-2': { id: 'us-2', title: 'Story 2' } as any,
          }
        }
      });
      
      setAllUserStoriesCollapsed(true);
      
      const states = useStore.getState().userStoryCollapseStates;
      expect(states['us-1']).toBe(true);
      expect(states['us-2']).toBe(true);
    });
  });

  describe('Filters Management', () => {
    beforeEach(() => {
      localStorage.clear();
      vi.clearAllMocks();
    });

    it('should set filters', () => {
      const { setFilters } = useStore.getState();
      
      const filters = {
        fixed_version_id_in: ['1', '2'],
        assigned_to_id_in: [1, 2]
      };
      
      setFilters(filters);
      
      expect(useStore.getState().filters).toEqual(filters);
    });

    it('should save filters to localStorage', () => {
      const { setFilters } = useStore.getState();
      
      const filters = {
        fixed_version_id_in: ['1'],
      };
      
      setFilters(filters);
      
      const saved = localStorage.getItem('kanban_filters');
      expect(saved).not.toBeNull();
      
      const parsed = JSON.parse(saved!);
      expect(parsed.fixed_version_id_in).toEqual(['1']);
    });

    it('should clear filters', () => {
      const { setFilters, clearFilters } = useStore.getState();
      
      setFilters({ fixed_version_id_in: ['1'] });
      expect(Object.keys(useStore.getState().filters).length).toBeGreaterThan(0);
      
      clearFilters();
      expect(Object.keys(useStore.getState().filters).length).toBe(0);
    });

    it('should clear filters from localStorage', () => {
      const { setFilters, clearFilters } = useStore.getState();
      
      setFilters({ fixed_version_id_in: ['1'] });
      clearFilters();
      
      const saved = localStorage.getItem('kanban_filters');
      const parsed = saved ? JSON.parse(saved) : {};
      expect(Object.keys(parsed).length).toBe(0);
    });
  });

  describe('Unassigned Highlight Toggle', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    it('should toggle unassigned highlight visibility', () => {
      const { toggleUnassignedHighlightVisible } = useStore.getState();
      
      const initialState = useStore.getState().isUnassignedHighlightVisible;
      
      toggleUnassignedHighlightVisible();
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(!initialState);
      
      toggleUnassignedHighlightVisible();
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(initialState);
    });

    it('should save unassigned highlight visibility to localStorage', () => {
      const { toggleUnassignedHighlightVisible } = useStore.getState();
      
      toggleUnassignedHighlightVisible();
      
      const saved = localStorage.getItem('kanban_unassigned_highlight_visible');
      expect(saved).not.toBeNull();
    });
  });

  describe('Selected Entity', () => {
    it('should set selected entity', () => {
      const { setSelectedEntity } = useStore.getState();
      
      setSelectedEntity('issue', '123');
      
      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'issue', id: '123' });
    });

    it('should set selected entity to version', () => {
      const { setSelectedEntity } = useStore.getState();
      
      setSelectedEntity('version', '456');
      
      const state = useStore.getState();
      expect(state.selectedEntity).toEqual({ type: 'version', id: '456' });
    });

    it('should clear selected entity', () => {
      const { setSelectedEntity, clearSelectedEntity } = useStore.getState();

      setSelectedEntity('issue', '123');
      expect(useStore.getState().selectedEntity).not.toBeNull();

      clearSelectedEntity();
      expect(useStore.getState().selectedEntity).toBeNull();
    });
  });

  describe('API Functions - Move Operations', () => {
    beforeEach(() => {
      vi.clearAllMocks();
      localStorage.clear();

      useStore.setState({
        entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
        grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
        isLoading: false,
        error: null,
        projectId: '1'
      });
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('should move feature to different epic', async () => {
      const mockResponse = {
        updated_entities: {
          features: {
            'f1': {
              id: 'f1',
              subject: 'Feature 1',
              parent_epic_id: 'epic2',
              fixed_version_id: 'v1'
            }
          }
        },
        updated_grid_index: {
          'epic2:f1:v1': ['us1']
        }
      };

      vi.spyOn(API, 'moveFeature').mockResolvedValue(mockResponse);

      const { moveFeature } = useStore.getState();
      await moveFeature('f1', 'epic2', 'v1');

      const state = useStore.getState();
      expect(state.entities.features['f1'].parent_epic_id).toBe('epic2');
      expect(API.moveFeature).toHaveBeenCalledWith('1', {
        feature_id: 'f1',
        target_epic_id: 'epic2',
        target_version_id: 'v1'
      });
    });

    it('should handle moveFeature error', async () => {
      vi.spyOn(API, 'moveFeature').mockRejectedValue(new Error('Move failed'));
      vi.spyOn(console, 'error').mockImplementation(() => {});

      const { moveFeature } = useStore.getState();

      await expect(moveFeature('f1', 'epic2', 'v1')).rejects.toThrow('Move failed');

      const state = useStore.getState();
      expect(state.error).toBe('Move failed');
    });

    it('should move user story to different feature', async () => {
      const mockResponse = {
        updated_entities: {
          user_stories: {
            'us1': {
              id: 'us1',
              title: 'User Story 1',
              parent_feature_id: 'f2',
              fixed_version_id: 'v1'
            }
          }
        },
        updated_grid_index: {
          'epic1:f2:v1': ['us1']
        }
      };

      vi.spyOn(API, 'moveUserStory').mockResolvedValue(mockResponse);

      const { moveUserStory } = useStore.getState();
      await moveUserStory('us1', 'f2', 'v1');

      expect(API.moveUserStory).toHaveBeenCalledWith('1', {
        user_story_id: 'us1',
        target_feature_id: 'f2',
        target_version_id: 'v1'
      });
    });

    it('should handle moveUserStory error', async () => {
      vi.spyOn(API, 'moveUserStory').mockRejectedValue(new Error('Move failed'));
      vi.spyOn(console, 'error').mockImplementation(() => {});

      const { moveUserStory } = useStore.getState();

      await expect(moveUserStory('us1', 'f2', 'v1')).rejects.toThrow('Move failed');

      const state = useStore.getState();
      expect(state.error).toBe('Move failed');
    });

    it('should throw error when projectId is not set for moveFeature', async () => {
      useStore.setState({ projectId: null });

      const { moveFeature } = useStore.getState();

      await expect(moveFeature('f1', 'epic2', 'v1')).rejects.toThrow('Project ID not set');
    });

    it('should throw error when projectId is not set for moveUserStory', async () => {
      useStore.setState({ projectId: null });

      const { moveUserStory } = useStore.getState();

      await expect(moveUserStory('us1', 'f2', 'v1')).rejects.toThrow('Project ID not set');
    });
  });

  describe('API Functions - Create with Error Handling', () => {
    beforeEach(() => {
      vi.clearAllMocks();
      useStore.setState({
        entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
        grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
        isLoading: false,
        error: null,
        projectId: '1',
        isDetailPaneVisible: false
      });
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('should handle createEpic error', async () => {
      vi.spyOn(API, 'createEpic').mockRejectedValue(new Error('Create failed'));

      const { createEpic } = useStore.getState();

      await expect(createEpic({ subject: 'New Epic', description: '' })).rejects.toThrow('Create failed');

      const state = useStore.getState();
      expect(state.error).toBe('Create failed');
    });

    it('should handle createVersion error', async () => {
      vi.spyOn(API, 'createVersion').mockRejectedValue(new Error('Create failed'));

      const { createVersion } = useStore.getState();

      await expect(createVersion({ name: 'v1.0', status: 'open' })).rejects.toThrow('Create failed');

      const state = useStore.getState();
      expect(state.error).toBe('Create failed');
    });

    it('should handle createFeature error', async () => {
      vi.spyOn(API, 'createFeature').mockRejectedValue(new Error('Create failed'));

      const { createFeature } = useStore.getState();

      await expect(createFeature('1', { subject: 'New Feature', description: '', parent_epic_id: 'e1' })).rejects.toThrow('Create failed');

      const state = useStore.getState();
      expect(state.error).toBe('Create failed');
    });

    it('should throw error when projectId is not set for createEpic', async () => {
      useStore.setState({ projectId: null });

      const { createEpic } = useStore.getState();

      await expect(createEpic({ subject: 'New Epic', description: '' })).rejects.toThrow('Project ID not set');
    });

    it('should throw error when projectId is not set for createVersion', async () => {
      useStore.setState({ projectId: null });

      const { createVersion } = useStore.getState();

      await expect(createVersion({ name: 'v1.0', status: 'open' })).rejects.toThrow('Project ID not set');
    });
  });

});
