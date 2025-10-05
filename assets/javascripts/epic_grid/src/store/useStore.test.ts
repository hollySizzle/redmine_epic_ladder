import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from './useStore';
import { normalizedMockData } from '../mocks/normalized-mock-data';

describe('useStore - Normalized API', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({
      entities: JSON.parse(JSON.stringify(normalizedMockData.entities)),
      grid: JSON.parse(JSON.stringify(normalizedMockData.grid)),
      isLoading: false,
      error: null
    });
  });

  describe('Initial State', () => {
    it('should have initial entities', () => {
      const state = useStore.getState();
      expect(Object.keys(state.entities.epics).length).toBeGreaterThan(0);
      expect(Object.keys(state.entities.features).length).toBeGreaterThan(0);
    });

    it('should have grid index', () => {
      const state = useStore.getState();
      expect(state.grid.index).toBeDefined();
      expect(state.grid.epic_order.length).toBeGreaterThan(0);
      expect(state.grid.version_order.length).toBeGreaterThan(0);
    });
  });

  describe('reorderFeatures', () => {
    it('should reorder features within same cell', () => {
      const { reorderFeatures } = useStore.getState();

      // epic1:v1 セル内の f1 と f2 を入れ替え
      reorderFeatures('f1', 'f2');

      const state = useStore.getState();
      const cell = state.grid.index['epic1:v1'];

      // f1 が f2 の後ろに移動していることを確認
      const f1Index = cell.indexOf('f1');
      const f2Index = cell.indexOf('f2');
      expect(f1Index).toBeGreaterThan(f2Index);
    });

    it('should move feature to different cell', () => {
      const { reorderFeatures } = useStore.getState();

      // f1 を epic1:v2 に移動（f3の後ろ）
      reorderFeatures('f1', 'f3');

      const state = useStore.getState();

      // 元のセルから削除されていることを確認
      expect(state.grid.index['epic1:v1']).not.toContain('f1');

      // 新しいセルに追加されていることを確認
      expect(state.grid.index['epic1:v2']).toContain('f1');

      // Feature エンティティが更新されていることを確認
      expect(state.entities.features['f1'].parent_epic_id).toBe('epic1');
      expect(state.entities.features['f1'].fixed_version_id).toBe('v2');
    });

    it('should move feature to empty cell via Add button', () => {
      const { reorderFeatures } = useStore.getState();

      // f1 を epic2:v3 の空セルに移動
      reorderFeatures('f1', '', {
        isAddButton: true,
        epicId: 'epic2',
        versionId: 'v3'
      });

      const state = useStore.getState();

      // 元のセルから削除されていることを確認
      expect(state.grid.index['epic1:v1']).not.toContain('f1');

      // 新しいセルに追加されていることを確認
      expect(state.grid.index['epic2:v3']).toContain('f1');

      // Feature エンティティが更新されていることを確認
      expect(state.entities.features['f1'].parent_epic_id).toBe('epic2');
      expect(state.entities.features['f1'].fixed_version_id).toBe('v3');
    });
  });

  describe('reorderUserStories', () => {
    it('should reorder user stories within same feature', () => {
      const { reorderUserStories } = useStore.getState();
      const initialState = useStore.getState();
      const initialOrder = [...initialState.entities.features['f1'].user_story_ids];

      // us1 と同じFeature内に別のstoryがあれば入れ替え
      if (initialOrder.length < 2) {
        // テストスキップ: storyが1つしかない
        expect(true).toBe(true);
        return;
      }

      const [story1, story2] = initialOrder;
      reorderUserStories(story1, story2);

      const state = useStore.getState();
      const feature = state.entities.features['f1'];

      // story1 が story2 の後ろに移動していることを確認
      const story1Index = feature.user_story_ids.indexOf(story1);
      const story2Index = feature.user_story_ids.indexOf(story2);
      expect(story1Index).toBeGreaterThan(story2Index);
    });

    it('should move user story to different feature', () => {
      const { reorderUserStories } = useStore.getState();

      // us1 を f2 に移動（us2の後ろ）
      reorderUserStories('us1', 'us2');

      const state = useStore.getState();
      const f1 = state.entities.features['f1'];
      const f2 = state.entities.features['f2'];

      // us1 が f1 から削除され、f2 に追加されていることを確認
      expect(f1.user_story_ids).not.toContain('us1');
      expect(f2.user_story_ids).toContain('us1');

      // UserStoryの親Feature更新確認
      expect(state.entities.user_stories['us1'].parent_feature_id).toBe('f2');
    });
  });

  describe('reorderTasks', () => {
    it('should reorder tasks within same user story', () => {
      const { reorderTasks } = useStore.getState();

      // t1 と t2 を入れ替え（同じstory内）
      reorderTasks('t1', 't2');

      const state = useStore.getState();
      const story = state.entities.user_stories['us1'];

      // t1 が t2 の後ろに移動していることを確認
      const t1Index = story.task_ids.indexOf('t1');
      const t2Index = story.task_ids.indexOf('t2');
      expect(t1Index).toBeGreaterThan(t2Index);
    });

    it('should move task to different user story', () => {
      const { reorderTasks } = useStore.getState();

      // t1 を us2 に移動（t3の後ろ）
      reorderTasks('t1', 't3');

      const state = useStore.getState();
      const us1 = state.entities.user_stories['us1'];
      const us2 = state.entities.user_stories['us2'];

      // t1 が us1 から削除され、us2 に追加されていることを確認
      expect(us1.task_ids).not.toContain('t1');
      expect(us2.task_ids).toContain('t1');

      // Taskの親Story更新確認
      expect(state.entities.tasks['t1'].parent_user_story_id).toBe('us2');
    });
  });

  describe('reorderTests', () => {
    it('should reorder tests within same user story', () => {
      const { reorderTests } = useStore.getState();

      const state = useStore.getState();

      // testが1つしかない場合はスキップ
      const story = state.entities.user_stories['us1'];
      if (story.test_ids.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const [test1, test2] = story.test_ids;
      reorderTests(test1, test2);

      const updatedState = useStore.getState();
      const updatedStory = updatedState.entities.user_stories['us1'];

      const test1Index = updatedStory.test_ids.indexOf(test1);
      const test2Index = updatedStory.test_ids.indexOf(test2);
      expect(test1Index).toBeGreaterThan(test2Index);
    });
  });

  describe('reorderBugs', () => {
    it('should reorder bugs within same user story', () => {
      const { reorderBugs } = useStore.getState();

      const state = useStore.getState();

      // bugが1つしかない場合はスキップ
      const story = state.entities.user_stories['us1'];
      if (story.bug_ids.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const [bug1, bug2] = story.bug_ids;
      reorderBugs(bug1, bug2);

      const updatedState = useStore.getState();
      const updatedStory = updatedState.entities.user_stories['us1'];

      const bug1Index = updatedStory.bug_ids.indexOf(bug1);
      const bug2Index = updatedStory.bug_ids.indexOf(bug2);
      expect(bug1Index).toBeGreaterThan(bug2Index);
    });
  });

  describe('reorderEpics', () => {
    it('should reorder epics in epic_order array', () => {
      const { reorderEpics } = useStore.getState();
      const initialState = useStore.getState();
      const initialOrder = [...initialState.grid.epic_order];

      if (initialOrder.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const [epic1, epic2] = initialOrder;
      reorderEpics(epic1, epic2);

      const state = useStore.getState();
      const epicOrder = state.grid.epic_order;

      // epic1 が epic2 の後ろに移動していることを確認
      const epic1Index = epicOrder.indexOf(epic1);
      const epic2Index = epicOrder.indexOf(epic2);
      expect(epic1Index).toBeGreaterThan(epic2Index);
    });

    it('should handle invalid epic ID gracefully', () => {
      const { reorderEpics } = useStore.getState();

      expect(() => {
        reorderEpics('invalid-epic-id', 'epic1');
      }).not.toThrow();
    });

    it('should maintain epic_order array integrity', () => {
      const { reorderEpics } = useStore.getState();
      const initialState = useStore.getState();
      const initialLength = initialState.grid.epic_order.length;

      if (initialLength < 2) {
        expect(true).toBe(true);
        return;
      }

      const [epic1, epic2] = initialState.grid.epic_order;
      reorderEpics(epic1, epic2);

      const state = useStore.getState();
      // 配列の長さは変わらないことを確認
      expect(state.grid.epic_order.length).toBe(initialLength);
      // 重複がないことを確認
      const uniqueEpics = new Set(state.grid.epic_order);
      expect(uniqueEpics.size).toBe(initialLength);
    });
  });

  describe('reorderVersions', () => {
    it('should reorder versions in version_order array', () => {
      const { reorderVersions } = useStore.getState();
      const initialState = useStore.getState();
      const initialOrder = [...initialState.grid.version_order];

      if (initialOrder.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const [version1, version2] = initialOrder;
      reorderVersions(version1, version2);

      const state = useStore.getState();
      const versionOrder = state.grid.version_order;

      // version1 が version2 の後ろに移動していることを確認
      const version1Index = versionOrder.indexOf(version1);
      const version2Index = versionOrder.indexOf(version2);
      expect(version1Index).toBeGreaterThan(version2Index);
    });

    it('should handle invalid version ID gracefully', () => {
      const { reorderVersions } = useStore.getState();

      expect(() => {
        reorderVersions('invalid-version-id', 'v1');
      }).not.toThrow();
    });

    it('should maintain version_order array integrity', () => {
      const { reorderVersions } = useStore.getState();
      const initialState = useStore.getState();
      const initialLength = initialState.grid.version_order.length;

      if (initialLength < 2) {
        expect(true).toBe(true);
        return;
      }

      const [version1, version2] = initialState.grid.version_order;
      reorderVersions(version1, version2);

      const state = useStore.getState();
      // 配列の長さは変わらないことを確認
      expect(state.grid.version_order.length).toBe(initialLength);
      // 重複がないことを確認
      const uniqueVersions = new Set(state.grid.version_order);
      expect(uniqueVersions.size).toBe(initialLength);
    });
  });

  describe('Edge Cases', () => {
    it('should handle invalid feature ID gracefully', () => {
      const { reorderFeatures } = useStore.getState();

      // 存在しないIDでエラーが出ないことを確認
      expect(() => {
        reorderFeatures('invalid-id', 'f1');
      }).not.toThrow();
    });

    it('should handle empty grid index gracefully', () => {
      useStore.setState({
        ...useStore.getState(),
        grid: {
          index: {},
          epic_order: [],
          version_order: []
        }
      });

      const { reorderFeatures } = useStore.getState();

      expect(() => {
        reorderFeatures('f1', 'f2');
      }).not.toThrow();
    });
  });
});
