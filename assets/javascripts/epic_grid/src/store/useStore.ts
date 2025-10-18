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
  User,
  CreateEpicRequest,
  CreateFeatureRequest,
  CreateUserStoryRequest,
  CreateTaskRequest,
  CreateTestRequest,
  CreateBugRequest,
  CreateVersionRequest,
  RansackFilterParams,
  EntityType,
  SelectedEntity,
  SortField,
  SortDirection,
  EpicSortOptions,
  VersionSortOptions
} from '../types/normalized-api';
import * as API from '../api/kanban-api';

/**
 * ドロップターゲットデータ型
 * ドラッグ&ドロップ操作で使用される追加のコンテキスト情報
 */
export interface DropTargetData {
  epicId?: string;
  featureId?: string;
  versionId?: string;
  userStoryId?: string;
  [key: string]: unknown;
}

/**
 * UserStory移動の変更履歴
 */
interface UserStoryMoveChange {
  id: string;
  oldFeatureId: string;
  newFeatureId: string;
  oldVersionId: string | null;
  newVersionId: string | null;
}

/**
 * 未保存の変更を追跡する状態
 */
interface PendingChanges {
  movedUserStories: UserStoryMoveChange[];
  reorderedEpics: string[] | null;
  reorderedVersions: string[] | null;
}

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
    users: Record<number, User>;
  };

  // グリッドインデックス
  grid: {
    index: Record<string, string[]>; // "epicId:featureId:versionId" => userStory IDs (3D Grid)
    epic_order: string[];
    feature_order_by_epic: Record<string, string[]>; // epicId => feature IDs
    version_order: string[];
  };

  // メタデータ（フィルタ用マスターデータを含む）
  metadata: Metadata | null;

  // データ取得・初期化
  fetchGridData: (projectId: string) => Promise<void>;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;

  // 詳細ペイン表示（Issue/Version）
  selectedEntity: SelectedEntity | null;
  setSelectedEntity: (type: EntityType, id: string) => void;
  clearSelectedEntity: () => void;
  isDetailPaneVisible: boolean;
  toggleDetailPane: () => void;

  // 後方互換性のためのプロパティ
  selectedIssueId: string | null;

  // 縦書きモード
  isVerticalMode: boolean;
  toggleVerticalMode: () => void;

  // 担当者名表示
  isAssignedToVisible: boolean;
  toggleAssignedToVisible: () => void;

  // 期日表示
  isDueDateVisible: boolean;
  toggleDueDateVisible: () => void;

  // チケットID表示
  isIssueIdVisible: boolean;
  toggleIssueIdVisible: () => void;

  // UserStory個別折り畳み状態（localStorage永続化）
  userStoryCollapseStates: Record<string, boolean>;
  setUserStoryCollapsed: (storyId: string, collapsed: boolean) => void;
  setAllUserStoriesCollapsed: (collapsed: boolean) => void;

  // フィルタリング
  filters: RansackFilterParams;
  setFilters: (filters: RansackFilterParams) => void;
  clearFilters: () => void;

  // クローズ済みバージョン非表示（デフォルト: true）
  excludeClosedVersions: boolean;
  toggleExcludeClosedVersions: () => void;

  // ソート設定
  epicSortOptions: EpicSortOptions;
  versionSortOptions: VersionSortOptions;
  setEpicSort: (sortBy: SortField, sortDirection: SortDirection) => void;
  setVersionSort: (sortBy: SortField, sortDirection: SortDirection) => void;

  // Dirty state管理（未保存変更の追跡）
  isDirty: boolean;
  pendingChanges: PendingChanges;
  savePendingChanges: () => Promise<void>;
  discardPendingChanges: () => void;

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

  // UserStory移動
  moveUserStory: (userStoryId: string, targetFeatureId: string, targetVersionId: string | null) => Promise<void>;

  // ドラッグ&ドロップ操作
  reorderFeatures: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  reorderUserStories: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  moveUserStoryToCell: (storyId: string, epicId: string, featureId: string, versionId: string) => void;
  reorderTasks: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  reorderTests: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  reorderBugs: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  reorderEpics: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
  reorderVersions: (sourceId: string, targetId: string, targetData?: DropTargetData) => void;
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
        bugs: {},
        users: {}
      },

      grid: {
        index: {},
        epic_order: [],
        feature_order_by_epic: {},
        version_order: []
      },

      metadata: null,

      isLoading: false,
      error: null,
      projectId: null,

      // Dirty state管理の初期状態
      isDirty: false,
      pendingChanges: {
        movedUserStories: [],
        reorderedEpics: null,
        reorderedVersions: null
      },

      // 詳細ペイン表示の初期状態（Issue/Version）
      selectedEntity: null,
      selectedIssueId: null, // 後方互換性のため
      setSelectedEntity: (type: EntityType, id: string) =>
        set({
          selectedEntity: { type, id },
          selectedIssueId: type === 'issue' ? id : null
        }),
      clearSelectedEntity: () =>
        set({ selectedEntity: null, selectedIssueId: null }),
      isDetailPaneVisible: (() => {
        const saved = localStorage.getItem('kanban_detail_pane_visible');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleDetailPane: () => set((state) => {
        const newValue = !state.isDetailPaneVisible;
        localStorage.setItem('kanban_detail_pane_visible', String(newValue));
        return { isDetailPaneVisible: newValue };
      }),

      // 縦書きモードの初期状態
      isVerticalMode: (() => {
        const saved = localStorage.getItem('kanban_vertical_mode');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleVerticalMode: () => set((state) => {
        const newValue = !state.isVerticalMode;
        localStorage.setItem('kanban_vertical_mode', String(newValue));
        return { isVerticalMode: newValue };
      }),

      // 担当者名表示の初期状態
      isAssignedToVisible: (() => {
        const saved = localStorage.getItem('kanban_assigned_to_visible');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleAssignedToVisible: () => set((state) => {
        const newValue = !state.isAssignedToVisible;
        localStorage.setItem('kanban_assigned_to_visible', String(newValue));
        return { isAssignedToVisible: newValue };
      }),

      // 期日表示の初期状態
      isDueDateVisible: (() => {
        const saved = localStorage.getItem('kanban_due_date_visible');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleDueDateVisible: () => set((state) => {
        const newValue = !state.isDueDateVisible;
        localStorage.setItem('kanban_due_date_visible', String(newValue));
        return { isDueDateVisible: newValue };
      }),

      // チケットID表示の初期状態
      isIssueIdVisible: (() => {
        const saved = localStorage.getItem('kanban_issue_id_visible');
        return saved !== null ? saved === 'true' : true; // デフォルトON
      })(),
      toggleIssueIdVisible: () => set((state) => {
        const newValue = !state.isIssueIdVisible;
        localStorage.setItem('kanban_issue_id_visible', String(newValue));
        return { isIssueIdVisible: newValue };
      }),

      // UserStory個別折り畳み状態の初期値（localStorageから復元）
      userStoryCollapseStates: (() => {
        try {
          const saved = localStorage.getItem('kanban_userstory_collapse_states');
          return saved ? JSON.parse(saved) : {};
        } catch (error) {
          console.warn('Failed to parse saved collapse states:', error);
          return {};
        }
      })(),

      setUserStoryCollapsed: (storyId: string, collapsed: boolean) => set((state) => {
        state.userStoryCollapseStates[storyId] = collapsed;

        // localStorageに保存
        try {
          localStorage.setItem('kanban_userstory_collapse_states', JSON.stringify(state.userStoryCollapseStates));
        } catch (error) {
          console.warn('Failed to save collapse states to localStorage:', error);
        }
      }),

      setAllUserStoriesCollapsed: (collapsed: boolean) => set((state) => {
        const allUserStoryIds = Object.keys(state.entities.user_stories);
        allUserStoryIds.forEach(id => {
          state.userStoryCollapseStates[id] = collapsed;
        });

        // localStorageに保存
        try {
          localStorage.setItem('kanban_userstory_collapse_states', JSON.stringify(state.userStoryCollapseStates));
        } catch (error) {
          console.warn('Failed to save collapse states to localStorage:', error);
        }
      }),

      // フィルタリングの初期状態
      filters: (() => {
        try {
          const saved = localStorage.getItem('kanban_filters');
          return saved ? JSON.parse(saved) : {};
        } catch (error) {
          console.warn('Failed to parse saved filters:', error);
          return {};
        }
      })(),
      setFilters: (filters: RansackFilterParams) => {
        // localStorageに保存
        try {
          localStorage.setItem('kanban_filters', JSON.stringify(filters));
        } catch (error) {
          console.warn('Failed to save filters to localStorage:', error);
        }
        set({ filters });
        // フィルタ変更時に自動的にデータを再取得
        const projectId = get().projectId;
        if (projectId) {
          get().fetchGridData(projectId);
        }
      },
      clearFilters: () => {
        // localStorageから削除
        try {
          localStorage.removeItem('kanban_filters');
        } catch (error) {
          console.warn('Failed to remove filters from localStorage:', error);
        }
        set({ filters: {} });
        // フィルタクリア時に自動的にデータを再取得
        const projectId = get().projectId;
        if (projectId) {
          get().fetchGridData(projectId);
        }
      },

      // クローズ済みバージョン非表示の初期状態
      excludeClosedVersions: (() => {
        const saved = localStorage.getItem('kanban_exclude_closed_versions');
        return saved !== null ? saved === 'true' : true; // デフォルトON（非表示）
      })(),
      toggleExcludeClosedVersions: () => {
        const newValue = !get().excludeClosedVersions;
        localStorage.setItem('kanban_exclude_closed_versions', String(newValue));
        set({ excludeClosedVersions: newValue });

        // トグル時に自動的にデータを再取得
        const projectId = get().projectId;
        if (projectId) {
          get().fetchGridData(projectId);
        }
      },

      // ソート設定の初期状態
      epicSortOptions: (() => {
        const sortBy = localStorage.getItem('kanban_epic_sort_by') as SortField || 'subject';
        const sortDirection = localStorage.getItem('kanban_epic_sort_direction') as SortDirection || 'asc';
        return { sort_by: sortBy, sort_direction: sortDirection };
      })(),
      versionSortOptions: (() => {
        const sortBy = localStorage.getItem('kanban_version_sort_by') as SortField || 'date';
        const sortDirection = localStorage.getItem('kanban_version_sort_direction') as SortDirection || 'asc';
        return { sort_by: sortBy, sort_direction: sortDirection };
      })(),
      setEpicSort: (sortBy: SortField, sortDirection: SortDirection) => {
        localStorage.setItem('kanban_epic_sort_by', sortBy);
        localStorage.setItem('kanban_epic_sort_direction', sortDirection);
        set((state) => {
          state.epicSortOptions = { sort_by: sortBy, sort_direction: sortDirection };
        });

        // ソート変更時に自動的にデータを再取得
        const projectId = get().projectId;
        if (projectId) {
          get().fetchGridData(projectId);
        }
      },
      setVersionSort: (sortBy: SortField, sortDirection: SortDirection) => {
        localStorage.setItem('kanban_version_sort_by', sortBy);
        localStorage.setItem('kanban_version_sort_direction', sortDirection);
        set((state) => {
          state.versionSortOptions = { sort_by: sortBy, sort_direction: sortDirection };
        });

        // ソート変更時に自動的にデータを再取得
        const projectId = get().projectId;
        if (projectId) {
          get().fetchGridData(projectId);
        }
      },

      // グリッドデータ取得
      fetchGridData: async (projectId: string) => {
        set({ isLoading: true, error: null, projectId });

        try {
          const filters = get().filters;
          const excludeClosedVersions = get().excludeClosedVersions;
          const epicSortOptions = get().epicSortOptions;
          const versionSortOptions = get().versionSortOptions;

          const data = await API.fetchGridData(projectId, {
            filters,
            exclude_closed_versions: excludeClosedVersions,
            sort_options: {
              epic: epicSortOptions,
              version: versionSortOptions
            }
          });

          set((state) => {
            state.entities = data.entities;
            state.grid = data.grid;
            state.metadata = data.metadata;
            state.isLoading = false;

            // クローズ済みUserStoryを自動的に折り畳み状態にする
            // ただし、既にlocalStorageに保存されているユーザーの選択は尊重する
            Object.values(data.entities.user_stories).forEach(story => {
              if (story.status === 'closed' && !(story.id in state.userStoryCollapseStates)) {
                state.userStoryCollapseStates[story.id] = true;
              }
            });

            // localStorageに保存
            try {
              localStorage.setItem('kanban_userstory_collapse_states', JSON.stringify(state.userStoryCollapseStates));
            } catch (error) {
              console.warn('Failed to save collapse states to localStorage:', error);
            }
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

        console.log('[DEBUG] createFeature called with:', { projectId, data });

        try {
          const result = await API.createFeature(projectId, data);
          console.log('[DEBUG] API.createFeature returned:', JSON.stringify(result, null, 2));

          set((state) => {
            // 正規化データをマージ
            Object.assign(state.entities.epics, result.data.updated_entities.epics || {});
            Object.assign(state.entities.features, result.data.updated_entities.features || {});
            Object.assign(state.entities.versions, result.data.updated_entities.versions || {});

            console.log('[DEBUG] After merge - state.entities.features:', Object.keys(state.entities.features));
            console.log('[DEBUG] After merge - state.grid.feature_order_by_epic:', state.grid.feature_order_by_epic);

            // 3D Grid対応: grid.indexとfeature_order_by_epicを更新
            Object.assign(state.grid.index, result.data.grid_updates.index);
            Object.assign(state.grid.feature_order_by_epic, result.data.grid_updates.feature_order_by_epic);

            console.log('[DEBUG] After grid updates - feature_order_by_epic:', state.grid.feature_order_by_epic);
          });

          // 作成したFeatureを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
        } catch (error) {
          console.error('[DEBUG] createFeature error:', error);
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

            // 3D Grid対応: 新UserStoryをgrid.indexに追加
            // MSWハンドラーがgrid.indexを更新しているので、それを反映
            const newStory = result.data.created_entity;
            const feature = state.entities.features[featureId];
            if (feature && newStory) {
              const epicId = feature.parent_epic_id;
              const versionId = newStory.fixed_version_id || 'none';
              const cellKey = `${epicId}:${featureId}:${versionId}`;

              if (!state.grid.index[cellKey]) {
                state.grid.index[cellKey] = [];
              }
              if (!state.grid.index[cellKey].includes(newStory.id)) {
                state.grid.index[cellKey] = [...state.grid.index[cellKey], newStory.id];
              }
            }
          });

          // 作成したUserStoryを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
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

          // 作成したTaskを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
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

          // 作成したTestを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
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

          // 作成したBugを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
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

          // 作成したEpicを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('issue', createdId);
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

          // 作成したVersionを詳細ペインで表示
          const createdId = result.data.created_entity.id;
          if (!get().isDetailPaneVisible) {
            set({ isDetailPaneVisible: true });
            localStorage.setItem('kanban_detail_pane_visible', 'true');
          }
          get().setSelectedEntity('version', createdId);
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

      // UserStory移動API呼び出し
      moveUserStory: async (userStoryId: string, targetFeatureId: string, targetVersionId: string | null) => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        try {
          const result = await API.moveUserStory(projectId, {
            user_story_id: userStoryId,
            target_feature_id: targetFeatureId,
            target_version_id: targetVersionId
          });

          // 更新されたエンティティとグリッドインデックスを反映
          set((state) => {
            if (result.updated_entities.user_stories) {
              Object.assign(state.entities.user_stories, result.updated_entities.user_stories);
            }
            if (result.updated_entities.features) {
              Object.assign(state.entities.features, result.updated_entities.features);
            }
            if (result.updated_entities.tasks) {
              Object.assign(state.entities.tasks, result.updated_entities.tasks);
            }
            if (result.updated_entities.tests) {
              Object.assign(state.entities.tests, result.updated_entities.tests);
            }
            if (result.updated_entities.bugs) {
              Object.assign(state.entities.bugs, result.updated_entities.bugs);
            }
            if (result.updated_grid_index) {
              Object.assign(state.grid.index, result.updated_grid_index);
            }
          });
        } catch (error) {
          console.error('Failed to move user story:', error);
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // Feature カードの並び替え (ローカル操作)
      reorderFeatures: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          // Addボタンへのドロップの場合
          if (targetData?.isAddButton) {
            const sourceFeature = state.entities.features[sourceId];
            if (!sourceFeature) return;

            const oldCellKey = `${sourceFeature.parent_epic_id}:${sourceFeature.fixed_version_id || 'none'}`;
            const newCellKey = `${targetData.epicId}:${targetData.versionId || 'none'}`;

            // 古いセルから削除（イミュータブル）
            if (state.grid.index[oldCellKey]) {
              state.grid.index[oldCellKey] = state.grid.index[oldCellKey].filter(id => id !== sourceId);
            }

            // 新しいセルに追加（イミュータブル）
            if (!state.grid.index[newCellKey]) {
              state.grid.index[newCellKey] = [];
            }
            state.grid.index[newCellKey] = [...state.grid.index[newCellKey], sourceId];

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

          // 同じセル内での並び替え（イミュータブル）
          if (sourceCellKey === targetCellKey) {
            const cell = state.grid.index[sourceCellKey];
            if (cell) {
              const sourceIndex = cell.indexOf(sourceId);
              const targetIndex = cell.indexOf(targetId);

              if (sourceIndex !== -1 && targetIndex !== -1) {
                const newCell = [...cell];
                newCell.splice(sourceIndex, 1);
                const newTargetIndex = newCell.indexOf(targetId);
                newCell.splice(newTargetIndex + 1, 0, sourceId);
                state.grid.index[sourceCellKey] = newCell;
              }
            }
          }
          // 異なるセル間の移動（イミュータブル）
          else {
            const sourceCell = state.grid.index[sourceCellKey];
            const targetCell = state.grid.index[targetCellKey];

            if (sourceCell && targetCell) {
              const sourceIndex = sourceCell.indexOf(sourceId);
              if (sourceIndex !== -1) {
                state.grid.index[sourceCellKey] = sourceCell.filter(id => id !== sourceId);
              }

              const targetIndex = targetCell.indexOf(targetId);
              const newTargetCell = [...targetCell];
              newTargetCell.splice(targetIndex + 1, 0, sourceId);
              state.grid.index[targetCellKey] = newTargetCell;

              // Featureエンティティ更新
              sourceFeature.parent_epic_id = targetFeature.parent_epic_id;
              sourceFeature.fixed_version_id = targetFeature.fixed_version_id;
            }
          }
        }, false, 'reorderFeatures'),

      // UserStory の並び替え
      reorderUserStories: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const sourceStory = state.entities.user_stories[sourceId];
          const targetStory = state.entities.user_stories[targetId];

          if (!sourceStory || !targetStory) return;

          const sourceFeature = state.entities.features[sourceStory.parent_feature_id];
          const targetFeature = state.entities.features[targetStory.parent_feature_id];

          if (!sourceFeature || !targetFeature) return;

          // 同じFeature内の並び替え（イミュータブル）
          if (sourceStory.parent_feature_id === targetStory.parent_feature_id) {
            const stories = sourceFeature.user_story_ids;
            const sourceIndex = stories.indexOf(sourceId);
            const targetIndex = stories.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newStories = [...stories];
              newStories.splice(sourceIndex, 1);
              const newTargetIndex = newStories.indexOf(targetId);
              newStories.splice(newTargetIndex + 1, 0, sourceId);
              sourceFeature.user_story_ids = newStories;
            }
          }
          // 異なるFeature間の移動（イミュータブル）
          else {
            const sourceIndex = sourceFeature.user_story_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceFeature.user_story_ids = sourceFeature.user_story_ids.filter(id => id !== sourceId);
            }

            const targetIndex = targetFeature.user_story_ids.indexOf(targetId);
            const newTargetStories = [...targetFeature.user_story_ids];
            newTargetStories.splice(targetIndex + 1, 0, sourceId);
            targetFeature.user_story_ids = newTargetStories;

            // UserStoryの親Feature更新
            sourceStory.parent_feature_id = targetStory.parent_feature_id;
          }
        }, false, 'reorderUserStories'),

      // UserStory をセルに移動（ローカル操作 + dirty state追跡）
      moveUserStoryToCell: (storyId: string, epicId: string, featureId: string, versionId: string) =>
        set((state) => {
          const story = state.entities.user_stories[storyId];
          if (!story) return;

          const oldFeature = state.entities.features[story.parent_feature_id];
          const newFeature = state.entities.features[featureId];
          if (!oldFeature || !newFeature) return;

          // 移動前の状態を記録
          const oldFeatureId = story.parent_feature_id;
          const oldVersionId = story.fixed_version_id;
          const newVersionId = versionId === 'none' ? null : versionId;

          // 同じセルへの移動は無視
          if (oldFeatureId === featureId && oldVersionId === newVersionId) {
            console.log(`ℹ️ UserStory ${storyId} is already in the target cell`);
            return;
          }

          // 古いセルから削除（イミュータブル）
          const oldEpicId = oldFeature.parent_epic_id;
          const oldCellKey = `${oldEpicId}:${oldFeatureId}:${oldVersionId || 'none'}`;

          if (state.grid.index[oldCellKey]) {
            state.grid.index[oldCellKey] = state.grid.index[oldCellKey].filter(id => id !== storyId);
          }

          // 新しいセルに追加（イミュータブル）
          const newCellKey = `${epicId}:${featureId}:${versionId}`;
          if (!state.grid.index[newCellKey]) {
            state.grid.index[newCellKey] = [];
          }
          state.grid.index[newCellKey] = [...state.grid.index[newCellKey], storyId];

          // 古いFeatureから削除（イミュータブル）
          oldFeature.user_story_ids = oldFeature.user_story_ids.filter(id => id !== storyId);

          // 新しいFeatureに追加（イミュータブル）
          newFeature.user_story_ids = [...newFeature.user_story_ids, storyId];

          // UserStoryの親Feature更新
          story.parent_feature_id = featureId;

          // UserStoryのVersion更新
          story.fixed_version_id = newVersionId;

          // Dirty state更新: pendingChangesに追加
          const existingChangeIndex = state.pendingChanges.movedUserStories.findIndex(
            change => change.id === storyId
          );

          if (existingChangeIndex !== -1) {
            // 既存の変更を更新（最終的な移動先を記録）
            state.pendingChanges.movedUserStories[existingChangeIndex].newFeatureId = featureId;
            state.pendingChanges.movedUserStories[existingChangeIndex].newVersionId = newVersionId;
          } else {
            // 新しい変更を追加
            state.pendingChanges.movedUserStories.push({
              id: storyId,
              oldFeatureId,
              newFeatureId: featureId,
              oldVersionId,
              newVersionId
            });
          }

          // isDirtyフラグを立てる
          state.isDirty = true;

          console.log(`✅ [Local] Moved UserStory ${storyId} from ${oldCellKey} to ${newCellKey}`);
        }, false, 'moveUserStoryToCell'),

      // Task の並び替え
      reorderTasks: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const sourceTask = state.entities.tasks[sourceId];
          const targetTask = state.entities.tasks[targetId];

          if (!sourceTask || !targetTask) return;

          const sourceStory = state.entities.user_stories[sourceTask.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetTask.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え（イミュータブル）
          if (sourceTask.parent_user_story_id === targetTask.parent_user_story_id) {
            const tasks = sourceStory.task_ids;
            const sourceIndex = tasks.indexOf(sourceId);
            const targetIndex = tasks.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newTasks = [...tasks];
              newTasks.splice(sourceIndex, 1);
              const newTargetIndex = newTasks.indexOf(targetId);
              newTasks.splice(newTargetIndex + 1, 0, sourceId);
              sourceStory.task_ids = newTasks;
            }
          }
          // 異なるStory間の移動（イミュータブル）
          else {
            const sourceIndex = sourceStory.task_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.task_ids = sourceStory.task_ids.filter(id => id !== sourceId);
            }

            const targetIndex = targetStory.task_ids.indexOf(targetId);
            const newTargetTasks = [...targetStory.task_ids];
            newTargetTasks.splice(targetIndex + 1, 0, sourceId);
            targetStory.task_ids = newTargetTasks;

            // Taskの親Story更新
            sourceTask.parent_user_story_id = targetTask.parent_user_story_id;
          }
        }, false, 'reorderTasks'),

      // Test の並び替え
      reorderTests: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const sourceTest = state.entities.tests[sourceId];
          const targetTest = state.entities.tests[targetId];

          if (!sourceTest || !targetTest) return;

          const sourceStory = state.entities.user_stories[sourceTest.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetTest.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え（イミュータブル）
          if (sourceTest.parent_user_story_id === targetTest.parent_user_story_id) {
            const tests = sourceStory.test_ids;
            const sourceIndex = tests.indexOf(sourceId);
            const targetIndex = tests.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newTests = [...tests];
              newTests.splice(sourceIndex, 1);
              const newTargetIndex = newTests.indexOf(targetId);
              newTests.splice(newTargetIndex + 1, 0, sourceId);
              sourceStory.test_ids = newTests;
            }
          }
          // 異なるStory間の移動（イミュータブル）
          else {
            const sourceIndex = sourceStory.test_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.test_ids = sourceStory.test_ids.filter(id => id !== sourceId);
            }

            const targetIndex = targetStory.test_ids.indexOf(targetId);
            const newTargetTests = [...targetStory.test_ids];
            newTargetTests.splice(targetIndex + 1, 0, sourceId);
            targetStory.test_ids = newTargetTests;

            // Testの親Story更新
            sourceTest.parent_user_story_id = targetTest.parent_user_story_id;
          }
        }, false, 'reorderTests'),

      // Bug の並び替え
      reorderBugs: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const sourceBug = state.entities.bugs[sourceId];
          const targetBug = state.entities.bugs[targetId];

          if (!sourceBug || !targetBug) return;

          const sourceStory = state.entities.user_stories[sourceBug.parent_user_story_id];
          const targetStory = state.entities.user_stories[targetBug.parent_user_story_id];

          if (!sourceStory || !targetStory) return;

          // 同じStory内の並び替え（イミュータブル）
          if (sourceBug.parent_user_story_id === targetBug.parent_user_story_id) {
            const bugs = sourceStory.bug_ids;
            const sourceIndex = bugs.indexOf(sourceId);
            const targetIndex = bugs.indexOf(targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newBugs = [...bugs];
              newBugs.splice(sourceIndex, 1);
              const newTargetIndex = newBugs.indexOf(targetId);
              newBugs.splice(newTargetIndex + 1, 0, sourceId);
              sourceStory.bug_ids = newBugs;
            }
          }
          // 異なるStory間の移動（イミュータブル）
          else {
            const sourceIndex = sourceStory.bug_ids.indexOf(sourceId);
            if (sourceIndex !== -1) {
              sourceStory.bug_ids = sourceStory.bug_ids.filter(id => id !== sourceId);
            }

            const targetIndex = targetStory.bug_ids.indexOf(targetId);
            const newTargetBugs = [...targetStory.bug_ids];
            newTargetBugs.splice(targetIndex + 1, 0, sourceId);
            targetStory.bug_ids = newTargetBugs;

            // Bugの親Story更新
            sourceBug.parent_user_story_id = targetBug.parent_user_story_id;
          }
        }, false, 'reorderBugs'),

      // Epic の並び替え（ローカル操作 + dirty state追跡）
      reorderEpics: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const epicOrder = state.grid.epic_order;
          const sourceIndex = epicOrder.indexOf(sourceId);
          const targetIndex = epicOrder.indexOf(targetId);

          if (sourceIndex === -1 || targetIndex === -1) return;

          // イミュータブルに並び替え
          const newEpicOrder = [...epicOrder];
          newEpicOrder.splice(sourceIndex, 1);

          // 新しい位置を計算（削除後のインデックスを考慮）
          const newTargetIndex = newEpicOrder.indexOf(targetId);
          newEpicOrder.splice(newTargetIndex + 1, 0, sourceId);

          state.grid.epic_order = newEpicOrder;

          // Dirty state更新: epic順序を保存
          state.pendingChanges.reorderedEpics = newEpicOrder;
          state.isDirty = true;

          console.log('✅ [Local] Reordered Epics:', epicOrder);
        }, false, 'reorderEpics'),

      // Version の並び替え（ローカル操作 + dirty state追跡）
      reorderVersions: (sourceId: string, targetId: string, targetData?: DropTargetData) =>
        set((state) => {
          const versionOrder = state.grid.version_order;
          const sourceIndex = versionOrder.indexOf(sourceId);
          const targetIndex = versionOrder.indexOf(targetId);

          if (sourceIndex === -1 || targetIndex === -1) return;

          // イミュータブルに並び替え
          const newVersionOrder = [...versionOrder];
          newVersionOrder.splice(sourceIndex, 1);

          // 新しい位置を計算（削除後のインデックスを考慮）
          const newTargetIndex = newVersionOrder.indexOf(targetId);
          newVersionOrder.splice(newTargetIndex + 1, 0, sourceId);

          state.grid.version_order = newVersionOrder;

          // Dirty state更新: version順序を保存
          state.pendingChanges.reorderedVersions = newVersionOrder;
          state.isDirty = true;

          console.log('✅ [Local] Reordered Versions:', versionOrder);
        }, false, 'reorderVersions'),

      // 未保存の変更を一括保存
      savePendingChanges: async () => {
        const projectId = get().projectId;
        if (!projectId) throw new Error('Project ID not set');

        const { pendingChanges } = get();

        // 保存する変更が無い場合は何もしない
        if (
          pendingChanges.movedUserStories.length === 0 &&
          !pendingChanges.reorderedEpics &&
          !pendingChanges.reorderedVersions
        ) {
          console.log('ℹ️ No pending changes to save');
          return;
        }

        try {
          console.log('💾 Saving pending changes:', pendingChanges);

          // Batch Update API呼び出し（後で実装）
          const result = await API.batchUpdate(projectId, {
            moved_user_stories: pendingChanges.movedUserStories.map(change => ({
              id: change.id,
              target_feature_id: change.newFeatureId,
              target_version_id: change.newVersionId
            })),
            reordered_epics: pendingChanges.reorderedEpics || undefined,
            reordered_versions: pendingChanges.reorderedVersions || undefined
          });

          // サーバーからの応答でstateを更新
          set((state) => {
            if (result.updated_entities) {
              Object.assign(state.entities.epics, result.updated_entities.epics || {});
              Object.assign(state.entities.versions, result.updated_entities.versions || {});
              Object.assign(state.entities.features, result.updated_entities.features || {});
              Object.assign(state.entities.user_stories, result.updated_entities.user_stories || {});
              Object.assign(state.entities.tasks, result.updated_entities.tasks || {});
              Object.assign(state.entities.tests, result.updated_entities.tests || {});
              Object.assign(state.entities.bugs, result.updated_entities.bugs || {});
            }

            if (result.updated_grid_index) {
              Object.assign(state.grid.index, result.updated_grid_index);
            }

            // Epic/Version順序更新
            if (result.updated_epic_order) {
              state.grid.epic_order = result.updated_epic_order;
            }
            if (result.updated_version_order) {
              state.grid.version_order = result.updated_version_order;
            }

            // Dirty stateをクリア
            state.isDirty = false;
            state.pendingChanges = {
              movedUserStories: [],
              reorderedEpics: null,
              reorderedVersions: null
            };
          });

          console.log('✅ Successfully saved all pending changes');
        } catch (error) {
          console.error('❌ Failed to save pending changes:', error);
          set({ error: error instanceof Error ? error.message : 'Unknown error' });
          throw error;
        }
      },

      // 未保存の変更を破棄してリロード
      discardPendingChanges: () => {
        const projectId = get().projectId;
        if (!projectId) return;

        console.log('🔄 Discarding pending changes and reloading...');

        // 変更を破棄してグリッドデータを再取得
        set((state) => {
          state.isDirty = false;
          state.pendingChanges = {
            movedUserStories: [],
            reorderedEpics: null,
            reorderedVersions: null
          };
        });

        // データを再取得
        get().fetchGridData(projectId);
      },
    }))
  )
);
