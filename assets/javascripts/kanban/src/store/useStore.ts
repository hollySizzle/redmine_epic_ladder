import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { devtools } from 'zustand/middleware';
import type {
  NormalizedAPIResponse,
  Epic,
  Version,
  Feature,
  UserStory,
  Task,
  Test,
  Bug,
  CreateEpicRequest,
  CreateFeatureRequest,
  CreateUserStoryRequest,
  CreateTaskRequest,
  CreateTestRequest,
  CreateBugRequest,
  CreateVersionRequest
} from '../types/normalized-api';
import * as API from '../api/kanban-api';

interface StoreState {
  // 正規化されたエンティティ
  entities: {
    epics: Record<string, Epic>;
    versions: Record<string, Version>;
    features: Record<string, Feature>;
    user_stories: Record<string, UserStory>;
    tasks: Record<string, Task>;
    tests: Record<string, Test>;
    bugs: Record<string, Bug>;
  };

  // グリッドインデックス
  grid: {
    index: Record<string, string[]>; // "epicId:versionId" => feature IDs
    epic_order: string[];
    version_order: string[];
  };

  // データ取得・初期化
  fetchGridData: (projectId: string) => Promise<void>;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;

  // Issue詳細表示
  selectedIssueId: string | null;
  setSelectedIssueId: (issueId: string | null) => void;
  isDetailPaneVisible: boolean;
  toggleDetailPane: () => void;

  // CRUD操作
  createFeature: (data: CreateFeatureRequest) => Promise<void>;
  createUserStory: (featureId: string, data: CreateUserStoryRequest) => Promise<void>;
  createTask: (userStoryId: string, data: CreateTaskRequest) => Promise<void>;
  createTest: (userStoryId: string, data: CreateTestRequest) => Promise<void>;
  createBug: (userStoryId: string, data: CreateBugRequest) => Promise<void>;
  createEpic: (data: CreateEpicRequest) => Promise<void>;
  createVersion: (data: CreateVersionRequest) => Promise<void>;

  // Feature移動
  moveFeature: (featureId: string, targetEpicId: string, targetVersionId: string | null) => Promise<void>;

  // ドラッグ&ドロップ操作
  reorderFeatures: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderUserStories: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderTasks: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderTests: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderBugs: (sourceId: string, targetId: string, targetData?: any) => void;
}

export const useStore = create<StoreState>()(
  devtools(
    immer((set, get) => ({
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
        index: {},
        epic_order: [],
        version_order: []
      },

      isLoading: false,
      error: null,
      projectId: null,

      // Issue詳細表示の初期状態
      selectedIssueId: null,
      setSelectedIssueId: (issueId: string | null) => set({ selectedIssueId: issueId }),
      isDetailPaneVisible: (() => {
        const saved = localStorage.getItem('kanban_detail_pane_visible');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleDetailPane: () => set((state) => {
        const newValue = !state.isDetailPaneVisible;
        localStorage.setItem('kanban_detail_pane_visible', String(newValue));
        return { isDetailPaneVisible: newValue };
      }),

      // グリッドデータ取得
      fetchGridData: async (projectId: string) => {
        set({ isLoading: true, error: null, projectId });

        try {
          const data = await API.fetchGridData(projectId);

          set({
            entities: data.entities,
            grid: data.grid,
            isLoading: false
          });
        } catch (error) {
          set({
            isLoading: false,
            error: error instanceof Error ? error.message : 'Unknown error'
          });
        }
      },

      // Feature作成
      createFeature: async (data: CreateFeatureRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createFeature(projectId, data);

          set((state) => {
            // 正規化データをマージ
            Object.assign(state.entities.epics, result.data.updated_entities.epics || {});
            Object.assign(state.entities.features, result.data.updated_entities.features || {});
            Object.assign(state.entities.versions, result.data.updated_entities.versions || {});
            Object.assign(state.grid.index, result.data.grid_updates.index);
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // UserStory作成
      createUserStory: async (featureId: string, data: CreateUserStoryRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createUserStory(projectId, featureId, data);

          set((state) => {
            Object.assign(state.entities.features, result.data.updated_entities.features || {});
            Object.assign(state.entities.user_stories, result.data.updated_entities.user_stories || {});
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Task作成
      createTask: async (userStoryId: string, data: CreateTaskRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createTask(projectId, userStoryId, data);

          set((state) => {
            Object.assign(state.entities.user_stories, result.data.updated_entities.user_stories || {});
            Object.assign(state.entities.tasks, result.data.updated_entities.tasks || {});
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Test作成
      createTest: async (userStoryId: string, data: CreateTestRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createTest(projectId, userStoryId, data);

          set((state) => {
            Object.assign(state.entities.user_stories, result.data.updated_entities.user_stories || {});
            Object.assign(state.entities.tests, result.data.updated_entities.tests || {});
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Bug作成
      createBug: async (userStoryId: string, data: CreateBugRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createBug(projectId, userStoryId, data);

          set((state) => {
            Object.assign(state.entities.user_stories, result.data.updated_entities.user_stories || {});
            Object.assign(state.entities.bugs, result.data.updated_entities.bugs || {});
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Epic作成
      createEpic: async (data: CreateEpicRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createEpic(projectId, data);

          set((state) => {
            // 正規化データをマージ
            Object.assign(state.entities.epics, result.data.updated_entities.epics || {});
            // グリッド順序更新
            if (result.data.grid_updates.epic_order) {
              state.grid.epic_order = result.data.grid_updates.epic_order;
            }
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Version作成
      createVersion: async (data: CreateVersionRequest) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.createVersion(projectId, data);

          set((state) => {
            // 正規化データをマージ
            Object.assign(state.entities.versions, result.data.updated_entities.versions || {});
            // グリッド順序更新
            if (result.data.grid_updates.version_order) {
              state.grid.version_order = result.data.grid_updates.version_order;
            }
          });
        } catch (error) {
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Feature移動API呼び出し
      moveFeature: async (featureId: string, targetEpicId: string, targetVersionId: string | null) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.moveFeature(projectId, {
            feature_id: featureId,
            target_epic_id: targetEpicId,
            target_version_id: targetVersionId
          });

          // 更新されたエンティティとグリッドインデックスを反映
          set((state) => {
            if (result.updated_entities.features) {
              Object.assign(state.entities.features, result.updated_entities.features);
            }
            if (result.updated_grid_index) {
              Object.assign(state.grid.index, result.updated_grid_index);
            }
          });
        } catch (error) {
          console.error('Failed to move feature:', error);
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Feature カードの並び替え (ローカル操作)
      reorderFeatures: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // Addボタンへのドロップの場合
          if (targetData?.isAddButton) {
            const sourceFeature = state.entities.features[sourceId];
            if (!sourceFeature) return;

            const oldCellKey = `${sourceFeature.parent_epic_id}:${sourceFeature.fixed_version_id || 'none'}`;
            const newCellKey = `${targetData.epicId}:${targetData.versionId || 'none'}`;

            // 古いセルから削除
            const oldCell = state.grid.index[oldCellKey];
            if (oldCell) {
              const index = oldCell.indexOf(sourceId);
              if (index !== -1) {
                oldCell.splice(index, 1);
              }
            }

            // 新しいセルに追加
            if (!state.grid.index[newCellKey]) {
              state.grid.index[newCellKey] = [];
            }
            state.grid.index[newCellKey].push(sourceId);

            // Featureエンティティ更新
            sourceFeature.parent_epic_id = targetData.epicId;
            sourceFeature.fixed_version_id = targetData.versionId || null;

            return;
          }

          // Feature間のドロップ
          const sourceFeature = state.entities.features[sourceId];
          const targetFeature = state.entities.features[targetId];

          if (!sourceFeature || !targetFeature) return;

          const sourceCellKey = `${sourceFeature.parent_epic_id}:${sourceFeature.fixed_version_id || 'none'}`;
          const targetCellKey = `${targetFeature.parent_epic_id}:${targetFeature.fixed_version_id || 'none'}`;

          // 同じセル内での並び替え
          if (sourceCellKey === targetCellKey) {
            const cell = state.grid.index[sourceCellKey];
            if (cell) {
              const sourceIndex = cell.indexOf(sourceId);
              const targetIndex = cell.indexOf(targetId);

              if (sourceIndex !== -1 && targetIndex !== -1) {
                cell.splice(sourceIndex, 1);
                const newTargetIndex = cell.indexOf(targetId);
                cell.splice(newTargetIndex + 1, 0, sourceId);
              }
            }
          }
          // 異なるセル間の移動
          else {
            const sourceCell = state.grid.index[sourceCellKey];
            const targetCell = state.grid.index[targetCellKey];

            if (sourceCell && targetCell) {
              const sourceIndex = sourceCell.indexOf(sourceId);
              if (sourceIndex !== -1) {
                sourceCell.splice(sourceIndex, 1);
              }

              const targetIndex = targetCell.indexOf(targetId);
              targetCell.splice(targetIndex + 1, 0, sourceId);

              // Featureエンティティ更新
              sourceFeature.parent_epic_id = targetFeature.parent_epic_id;
              sourceFeature.fixed_version_id = targetFeature.fixed_version_id;
            }
          }
        }, false, 'reorderFeatures'),

      // UserStory の並び替え
      reorderUserStories: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          const sourceStory = state.entities.user_stories[sourceId];
          const targetStory = state.entities.user_stories[targetId];

          if (!sourceStory || !targetStory) return;

          const sourceFeature = state.entities.features[sourceStory.parent_feature_id];
          const targetFeature = state.entities.features[targetStory.parent_feature_id];

          if (!sourceFeature || !targetFeature) return;

          // 同じFeature内の並び替え
          if (sourceStory.parent_feature_id === targetStory.parent_feature_id) {
            const stories = sourceFeature.user_story_ids;
            const sourceIndex = stories.indexOf(sourceId);
            const targetIndex = stories.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              stories.splice(sourceIndex, 1);
              const newTargetIndex = stories.indexOf(targetId);
              stories.splice(newTargetIndex + 1, 0, sourceId);
            }
          }
          // 異なるFeature間の移動
          else {
            const sourceIndex = sourceFeature.user_story_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceFeature.user_story_ids.splice(sourceIndex, 1);
            }

            const targetIndex = targetFeature.user_story_ids.indexOf(targetId);
            targetFeature.user_story_ids.splice(targetIndex + 1, 0, sourceId);

            // UserStoryの親Feature更新
            sourceStory.parent_feature_id = targetStory.parent_feature_id;
          }
        }, false, 'reorderUserStories'),

      // Task の並び替え
      reorderTasks: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          const sourceTask = state.entities.tasks[sourceId];
          const targetTask = state.entities.tasks[targetId];

          if (!sourceTask || !targetTask) return;

          const sourceStory = state.entities.user_stories[sourceTask.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetTask.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え
          if (sourceTask.parent_user_story_id === targetTask.parent_user_story_id) {
            const tasks = sourceStory.task_ids;
            const sourceIndex = tasks.indexOf(sourceId);
            const targetIndex = tasks.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              tasks.splice(sourceIndex, 1);
              const newTargetIndex = tasks.indexOf(targetId);
              tasks.splice(newTargetIndex + 1, 0, sourceId);
            }
          }
          // 異なるStory間の移動
          else {
            const sourceIndex = sourceStory.task_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.task_ids.splice(sourceIndex, 1);
            }

            const targetIndex = targetStory.task_ids.indexOf(targetId);
            targetStory.task_ids.splice(targetIndex + 1, 0, sourceId);

            // Taskの親Story更新
            sourceTask.parent_user_story_id = targetTask.parent_user_story_id;
          }
        }, false, 'reorderTasks'),

      // Test の並び替え
      reorderTests: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          const sourceTest = state.entities.tests[sourceId];
          const targetTest = state.entities.tests[targetId];

          if (!sourceTest || !targetTest) return;

          const sourceStory = state.entities.user_stories[sourceTest.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetTest.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え
          if (sourceTest.parent_user_story_id === targetTest.parent_user_story_id) {
            const tests = sourceStory.test_ids;
            const sourceIndex = tests.indexOf(sourceId);
            const targetIndex = tests.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              tests.splice(sourceIndex, 1);
              const newTargetIndex = tests.indexOf(targetId);
              tests.splice(newTargetIndex + 1, 0, sourceId);
            }
          }
          // 異なるStory間の移動
          else {
            const sourceIndex = sourceStory.test_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.test_ids.splice(sourceIndex, 1);
            }

            const targetIndex = targetStory.test_ids.indexOf(targetId);
            targetStory.test_ids.splice(targetIndex + 1, 0, sourceId);

            // Testの親Story更新
            sourceTest.parent_user_story_id = targetTest.parent_user_story_id;
          }
        }, false, 'reorderTests'),

      // Bug の並び替え
      reorderBugs: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          const sourceBug = state.entities.bugs[sourceId];
          const targetBug = state.entities.bugs[targetId];

          if (!sourceBug || !targetBug) return;

          const sourceStory = state.entities.user_stories[sourceBug.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetBug.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え
          if (sourceBug.parent_user_story_id === targetBug.parent_user_story_id) {
            const bugs = sourceStory.bug_ids;
            const sourceIndex = bugs.indexOf(sourceId);
            const targetIndex = bugs.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              bugs.splice(sourceIndex, 1);
              const newTargetIndex = bugs.indexOf(targetId);
              bugs.splice(newTargetIndex + 1, 0, sourceId);
            }
          }
          // 異なるStory間の移動
          else {
            const sourceIndex = sourceStory.bug_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.bug_ids.splice(sourceIndex, 1);
            }

            const targetIndex = targetStory.bug_ids.indexOf(targetId);
            targetStory.bug_ids.splice(targetIndex + 1, 0, sourceId);

            // Bugの親Story更新
            sourceBug.parent_user_story_id = targetBug.parent_user_story_id;
          }
        }, false, 'reorderBugs'),
    }))
  )
);
