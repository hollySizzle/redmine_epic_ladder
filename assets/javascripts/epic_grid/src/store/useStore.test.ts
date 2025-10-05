import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from './useStore';
import { normalizedMockData } from '../mocks/normalized-mock-data';

describe('useStore - Normalized API (3D Grid)', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({
      entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
      grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
      isLoading: false,
      error: null,
      projectId: '1',
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

    it('should set selected issue ID', () => {
      const { setSelectedIssueId } = useStore.getState();

      setSelectedIssueId('us1');

      const state = useStore.getState();
      expect(state.selectedIssueId).toBe('us1');
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
});
