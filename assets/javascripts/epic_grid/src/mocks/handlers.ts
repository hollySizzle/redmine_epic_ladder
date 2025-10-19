import { http, HttpResponse, delay, PathParams } from 'msw';
import type {
  NormalizedAPIResponse,
  RansackFilterParams,
  MoveFeatureRequest,
  MoveFeatureResponse,
  MoveUserStoryRequest,
  MoveUserStoryResponse,
  ReorderEpicsRequest,
  ReorderEpicsResponse,
  ReorderVersionsRequest,
  ReorderVersionsResponse,
  UpdatesResponse,
  ErrorResponse,
  CreateEpicRequest,
  CreateEpicResponse,
  CreateFeatureRequest,
  CreateFeatureResponse,
  CreateUserStoryRequest,
  CreateUserStoryResponse,
  CreateTaskRequest,
  CreateTaskResponse,
  CreateTestRequest,
  CreateTestResponse,
  CreateBugRequest,
  CreateBugResponse,
  CreateVersionRequest,
  CreateVersionResponse,
  Epic,
  Feature,
  UserStory,
  Task,
  Test,
  Bug,
  Version,
  User
} from '../types/normalized-api';
import type { BatchUpdateRequest, BatchUpdateResponse } from '../api/kanban-api';
import { normalizedMockData } from './normalized-mock-data';
import { naturalSortKey, compareNaturalSort } from '../utils/naturalSort';

// モックデータのディープコピー (状態を保持するため)
let currentData: NormalizedAPIResponse = JSON.parse(JSON.stringify(normalizedMockData));

// 最終更新タイムスタンプ (差分更新用)
let lastUpdateTimestamp = new Date().toISOString();

// ========================================
// フィルタヘルパー関数
// ========================================

/**
 * Ransackフィルタを適用してエンティティをフィルタリング
 * 基本的なフィルタのみ対応（_in, _eq, _null）
 */

/**
 * URLクエリパラメータからソートオプションを抽出
 */
function extractSortOptionsFromURL(url: URL): { epic_sort_by?: string; epic_sort_direction?: string; version_sort_by?: string; version_sort_direction?: string } {
  return {
    epic_sort_by: url.searchParams.get('sort_options[epic][sort_by]') || undefined,
    epic_sort_direction: url.searchParams.get('sort_options[epic][sort_direction]') || undefined,
    version_sort_by: url.searchParams.get('sort_options[version][sort_by]') || undefined,
    version_sort_direction: url.searchParams.get('sort_options[version][sort_direction]') || undefined
  };
}

function applyRansackFilters<T extends {
  fixed_version_id?: string | null;
  status?: string;
  assigned_to_id?: number;
  tracker_id?: number;
  parent_epic_id?: string;
  parent_feature_id?: string;
  parent_user_story_id?: string;
}>(
  entities: Record<string, T>,
  filters: RansackFilterParams
): Record<string, T> {
  if (!filters || Object.keys(filters).length === 0) {
    return entities;
  }

  const filtered: Record<string, T> = {};

  Object.entries(entities).forEach(([id, entity]) => {
    let matches = true;

    // バージョンフィルタ (fixed_version_id_in)
    if (filters.fixed_version_id_in && filters.fixed_version_id_in.length > 0) {
      const versionId = entity.fixed_version_id;
      if (!versionId || !filters.fixed_version_id_in.includes(versionId)) {
        matches = false;
      }
    }

    // バージョンフィルタ (fixed_version_id_eq)
    if (filters.fixed_version_id_eq !== undefined) {
      if (entity.fixed_version_id !== filters.fixed_version_id_eq) {
        matches = false;
      }
    }

    // バージョンNULLフィルタ
    if (filters.fixed_version_id_null !== undefined) {
      const isNull = entity.fixed_version_id === null || entity.fixed_version_id === undefined;
      if (filters.fixed_version_id_null !== isNull) {
        matches = false;
      }
    }

    // ステータスフィルタ (status_id_in) - statusを文字列から推測
    // MSWモックでは status: 'open' | 'closed' なので、簡易マッピング
    if (filters.status_id_in && filters.status_id_in.length > 0) {
      // 簡易実装: status文字列をIDに変換（実際のRedmineではID使用）
      // open=1, in_progress=2, closed=5 と仮定
      const statusIdMap: Record<string, number> = { open: 1, in_progress: 2, closed: 5 };
      const statusId = entity.status ? statusIdMap[entity.status] : undefined;
      if (!statusId || !filters.status_id_in.includes(statusId)) {
        matches = false;
      }
    }

    // 担当者フィルタ (assigned_to_id_in)
    if (filters.assigned_to_id_in && filters.assigned_to_id_in.length > 0) {
      if (!entity.assigned_to_id || !filters.assigned_to_id_in.includes(entity.assigned_to_id)) {
        matches = false;
      }
    }

    // 担当者NULLフィルタ
    if (filters.assigned_to_id_null !== undefined) {
      const isNull = entity.assigned_to_id === null || entity.assigned_to_id === undefined;
      if (filters.assigned_to_id_null !== isNull) {
        matches = false;
      }
    }

    // トラッカーフィルタ (tracker_id_in)
    if (filters.tracker_id_in && filters.tracker_id_in.length > 0) {
      if (!entity.tracker_id || !filters.tracker_id_in.includes(entity.tracker_id)) {
        matches = false;
      }
    }

    // 親IDフィルタ (parent_id_in) - Epic/Feature/UserStoryの親子関係
    if (filters.parent_id_in && filters.parent_id_in.length > 0) {
      const parentId = entity.parent_epic_id || entity.parent_feature_id || entity.parent_user_story_id;
      if (!parentId || !filters.parent_id_in.includes(parentId)) {
        matches = false;
      }
    }

    // バージョン期日フィルタ (fixed_version_effective_date_gteq/lteq)
    // Issueのfixed_version_idからVersionエンティティを参照して期日をチェック
    if (versions && entity.fixed_version_id) {
      const version = versions[entity.fixed_version_id];
      if (version && version.effective_date) {
        // 期日がgteq（〜以降）でフィルタ
        if (filters.fixed_version_effective_date_gteq) {
          if (version.effective_date < filters.fixed_version_effective_date_gteq) {
            matches = false;
          }
        }
        // 期日がlteq（〜以前）でフィルタ
        if (filters.fixed_version_effective_date_lteq) {
          if (version.effective_date > filters.fixed_version_effective_date_lteq) {
            matches = false;
          }
        }
      } else if (filters.fixed_version_effective_date_gteq || filters.fixed_version_effective_date_lteq) {
        // Versionが存在しない、またはeffective_dateがnullの場合は除外
        matches = false;
      }
    } else if (filters.fixed_version_effective_date_gteq || filters.fixed_version_effective_date_lteq) {
      // fixed_version_idがnullの場合は期日フィルタで除外
      matches = false;
    }

    if (matches) {
      filtered[id] = entity;
    }
  });

  return filtered;
}

/**
 * URLクエリパラメータからRansackフィルタを抽出
 */
function extractFiltersFromURL(url: URL): RansackFilterParams {
  const filters: RansackFilterParams = {};

  // fixed_version_id_in (カンマ区切り)
  const versionIds = url.searchParams.get('fixed_version_id_in');
  if (versionIds) {
    filters.fixed_version_id_in = versionIds.split(',');
  }

  // status_id_in (カンマ区切り)
  const statusIds = url.searchParams.get('status_id_in');
  if (statusIds) {
    filters.status_id_in = statusIds.split(',').map(Number);
  }

  // assigned_to_id_in (カンマ区切り)
  const assigneeIds = url.searchParams.get('assigned_to_id_in');
  if (assigneeIds) {
    filters.assigned_to_id_in = assigneeIds.split(',').map(Number);
  }

  // tracker_id_in (カンマ区切り)
  const trackerIds = url.searchParams.get('tracker_id_in');
  if (trackerIds) {
    filters.tracker_id_in = trackerIds.split(',').map(Number);
  }

  // parent_id_in (カンマ区切り) - Epic/Featureフィルタ用
  const parentIds = url.searchParams.get('parent_id_in');
  if (parentIds) {
    filters.parent_id_in = parentIds.split(',');
  }

  // _null フィルタ
  const versionNull = url.searchParams.get('fixed_version_id_null');
  if (versionNull !== null) {
    filters.fixed_version_id_null = versionNull === 'true';
  }

  const assigneeNull = url.searchParams.get('assigned_to_id_null');
  if (assigneeNull !== null) {
    filters.assigned_to_id_null = assigneeNull === 'true';
  }

  // バージョン期日フィルタ
  const effectiveDateFrom = url.searchParams.get('fixed_version_effective_date_gteq');
  if (effectiveDateFrom) {
    filters.fixed_version_effective_date_gteq = effectiveDateFrom;
  }

  const effectiveDateTo = url.searchParams.get('fixed_version_effective_date_lteq');
  if (effectiveDateTo) {
    filters.fixed_version_effective_date_lteq = effectiveDateTo;
  }

  return filters;
}

// ========================================
// API Handlers
// ========================================

export const handlers = [
  // GET /api/epic_grid/projects/:projectId/grid
  // グリッドデータ取得
  http.get('/api/epic_grid/projects/:projectId/grid', async ({ params, request }: { params: PathParams; request: Request }) => {
    const url = new URL(request.url);
    const includeClosed = url.searchParams.get('include_closed') === 'true';
    const excludeClosedVersions = url.searchParams.get('exclude_closed_versions') === 'true';

    // Ransackフィルタを抽出
    const filters = extractFiltersFromURL(url);

    // ソートオプションを抽出
    const sortOptions = extractSortOptionsFromURL(url);

    // リアルなAPI遅延をシミュレート (開発時は削除可能)
    await delay(300);

    // データをディープコピー
    let responseData = JSON.parse(JSON.stringify(currentData));

    // Ransackフィルタを適用（Versionエンティティを渡して期日フィルタを有効化）
    if (Object.keys(filters).length > 0) {
      responseData.entities.epics = applyRansackFilters(responseData.entities.epics, filters, responseData.entities.versions);
      responseData.entities.features = applyRansackFilters(responseData.entities.features, filters, responseData.entities.versions);
      responseData.entities.user_stories = applyRansackFilters(responseData.entities.user_stories, filters, responseData.entities.versions);
      responseData.entities.tasks = applyRansackFilters(responseData.entities.tasks, filters, responseData.entities.versions);
      responseData.entities.tests = applyRansackFilters(responseData.entities.tests, filters, responseData.entities.versions);
      responseData.entities.bugs = applyRansackFilters(responseData.entities.bugs, filters, responseData.entities.versions);
    }

    // exclude_closed_versions=true の場合、クローズ済みバージョンを除外
    if (excludeClosedVersions) {
      // Versionからclosedを除外
      Object.keys(responseData.entities.versions).forEach(id => {
        if (responseData.entities.versions[id].status === 'closed') {
          delete responseData.entities.versions[id];
        }
      });

      // version_order からも削除
      responseData.grid.version_order = responseData.grid.version_order.filter(
        (vId: string) => responseData.entities.versions[vId]
      );

      // grid.index からクローズ済みバージョンのセルを削除
      Object.keys(responseData.grid.index).forEach(cellKey => {
        // cellKey = "epicId:featureId:versionId"
        const versionId = cellKey.split(':')[2];
        if (versionId !== 'none' && !responseData.entities.versions[versionId]) {
          delete responseData.grid.index[cellKey];
        }
      });
    }

    // include_closed=false の場合、closedステータスをフィルタ (既存ロジック維持)

    if (!includeClosed) {
      // Featureからclosedを除外
      Object.keys(responseData.entities.features).forEach(id => {
        if (responseData.entities.features[id].status === 'closed') {
          delete responseData.entities.features[id];
        }
      });

      // UserStoryからclosedを除外
      Object.keys(responseData.entities.user_stories).forEach(id => {
        if (responseData.entities.user_stories[id].status === 'closed') {
          delete responseData.entities.user_stories[id];
        }
      });

      // grid.indexも更新 (closedのUserStoryを削除)
      Object.keys(responseData.grid.index).forEach(key => {
        responseData.grid.index[key] = responseData.grid.index[key].filter(
          (userStoryId: string) => responseData.entities.user_stories[userStoryId]
        );
      });

      // feature_order_by_epicからclosedのFeatureを削除
      Object.keys(responseData.grid.feature_order_by_epic).forEach(epicId => {
        responseData.grid.feature_order_by_epic[epicId] = responseData.grid.feature_order_by_epic[epicId].filter(
          (featureId: string) => responseData.entities.features[featureId]
        );
      });
    }

    // Ransackフィルタ適用後のgrid更新
    if (Object.keys(filters).length > 0) {
      // epic_order: フィルタ後に存在するEpicのみ
      responseData.grid.epic_order = responseData.grid.epic_order.filter(
        (epicId: string) => responseData.entities.epics[epicId]
      );

      // feature_order_by_epic: フィルタ後に存在するFeatureのみ
      Object.keys(responseData.grid.feature_order_by_epic).forEach(epicId => {
        responseData.grid.feature_order_by_epic[epicId] = responseData.grid.feature_order_by_epic[epicId].filter(
          (featureId: string) => responseData.entities.features[featureId]
        );
      });

      // grid.index: フィルタ後に存在するUserStoryのみ
      Object.keys(responseData.grid.index).forEach(key => {
        responseData.grid.index[key] = responseData.grid.index[key].filter(
          (userStoryId: string) => responseData.entities.user_stories[userStoryId]
        );
      });
    }

    // ========================================
    // ソート処理（自然順ソート）
    // ========================================
    if (sortOptions.epic_sort_by === 'subject') {
      // Epic順序を自然順ソート
      const epicOrder = responseData.grid.epic_order.filter(
        (epicId: string) => responseData.entities.epics[epicId]
      );

      const sortedEpics = epicOrder.sort((aId, bId) => {
        const epicA = responseData.entities.epics[aId];
        const epicB = responseData.entities.epics[bId];
        if (!epicA || !epicB) return 0;

        const keyA = naturalSortKey(epicA.subject);
        const keyB = naturalSortKey(epicB.subject);
        return compareNaturalSort(keyA, keyB);
      });

      // 降順の場合は逆順
      if (sortOptions.epic_sort_direction === 'desc') {
        sortedEpics.reverse();
      }

      responseData.grid.epic_order = sortedEpics;

      // Feature順序も同様に自然順ソート（Epic内のFeature）
      Object.keys(responseData.grid.feature_order_by_epic).forEach(epicId => {
        const featureIds = responseData.grid.feature_order_by_epic[epicId].filter(
          (featureId: string) => responseData.entities.features[featureId]
        );

        const sortedFeatures = featureIds.sort((aId, bId) => {
          const featureA = responseData.entities.features[aId];
          const featureB = responseData.entities.features[bId];
          if (!featureA || !featureB) return 0;

          const keyA = naturalSortKey(featureA.title);
          const keyB = naturalSortKey(featureB.title);
          return compareNaturalSort(keyA, keyB);
        });

        // 降順の場合は逆順
        if (sortOptions.epic_sort_direction === 'desc') {
          sortedFeatures.reverse();
        }

        responseData.grid.feature_order_by_epic[epicId] = sortedFeatures;
      });
    }

    // タイムスタンプ更新
    responseData.metadata.timestamp = new Date().toISOString();
    responseData.metadata.request_id = `req_${Math.random().toString(36).substring(7)}`;

    return HttpResponse.json(responseData);
  }),

  // POST /api/epic_grid/projects/:projectId/grid/move_feature
  // Feature移動処理
  http.post('/api/epic_grid/projects/:projectId/grid/move_feature', async ({ request }: { request: Request }) => {
    await delay(200);

    const body = (await request.json()) as MoveFeatureRequest;
    const { feature_id, target_epic_id, target_version_id } = body;

    // Feature存在確認
    const feature = currentData.entities.features[feature_id];
    if (!feature) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Feature ${feature_id} not found`,
          details: {
            field: 'feature_id'
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // Epic存在確認
    const targetEpic = currentData.entities.epics[target_epic_id];
    if (!targetEpic) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Epic ${target_epic_id} not found`,
          details: {
            field: 'target_epic_id'
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    const oldEpicId = feature.parent_epic_id;
    const oldVersionId = feature.fixed_version_id;

    // feature_order_by_epicを更新 (3D Grid対応)
    // 古いEpicから削除
    if (currentData.grid.feature_order_by_epic[oldEpicId]) {
      currentData.grid.feature_order_by_epic[oldEpicId] =
        currentData.grid.feature_order_by_epic[oldEpicId].filter(id => id !== feature_id);
    }

    // 新しいEpicに追加
    if (!currentData.grid.feature_order_by_epic[target_epic_id]) {
      currentData.grid.feature_order_by_epic[target_epic_id] = [];
    }
    currentData.grid.feature_order_by_epic[target_epic_id].push(feature_id);

    // Featureエンティティ更新
    feature.parent_epic_id = target_epic_id;
    feature.fixed_version_id = target_version_id;
    feature.updated_on = new Date().toISOString();

    // grid.indexの全UserStoryセルを更新 (3D Grid対応)
    const affectedIssueIds: string[] = [];

    feature.user_story_ids.forEach(storyId => {
      const story = currentData.entities.user_stories[storyId];
      if (story) {
        // 古いセルから削除
        currentData.grid.version_order.forEach(vId => {
          const oldCellKey = `${oldEpicId}:${feature_id}:${vId}`;
          if (currentData.grid.index[oldCellKey]) {
            currentData.grid.index[oldCellKey] =
              currentData.grid.index[oldCellKey].filter(id => id !== storyId);
          }
        });

        // 新しいセルに追加
        const newCellKey = `${target_epic_id}:${feature_id}:${target_version_id || 'none'}`;
        if (!currentData.grid.index[newCellKey]) {
          currentData.grid.index[newCellKey] = [];
        }
        currentData.grid.index[newCellKey].push(storyId);

        // UserStoryエンティティ更新
        story.fixed_version_id = target_version_id;
        story.version_source = target_version_id ? 'direct' : 'none';
        story.updated_on = new Date().toISOString();
        affectedIssueIds.push(storyId);

        // Task/Test/Bug も更新
        [...story.task_ids, ...story.test_ids, ...story.bug_ids].forEach(childId => {
          const task = currentData.entities.tasks[childId];
          const test = currentData.entities.tests[childId];
          const bug = currentData.entities.bugs[childId];

          if (task) {
            task.fixed_version_id = target_version_id;
            task.updated_on = new Date().toISOString();
            affectedIssueIds.push(childId);
          }
          if (test) {
            test.fixed_version_id = target_version_id;
            test.updated_on = new Date().toISOString();
            affectedIssueIds.push(childId);
          }
          if (bug) {
            bug.fixed_version_id = target_version_id;
            bug.updated_on = new Date().toISOString();
            affectedIssueIds.push(childId);
          }
        });
      }
    });

    // タイムスタンプ更新
    lastUpdateTimestamp = new Date().toISOString();

    // レスポンス構築
    const response: MoveFeatureResponse = {
      success: true,
      updated_entities: {
        features: {
          [feature_id]: feature
        }
      },
      updated_grid_index: currentData.grid.index,
      propagation_result: {
        affected_issue_ids: affectedIssueIds,
        conflicts: []
      }
    };

    return HttpResponse.json(response);
  }),

  // GET /api/epic_grid/projects/:projectId/grid/updates
  // 差分更新取得 (ポーリング用)
  http.get('/api/epic_grid/projects/:projectId/grid/updates', async ({ request }: { request: Request }) => {
    const url = new URL(request.url);
    const since = url.searchParams.get('since');

    await delay(100);

    // 実際のアプリでは since 以降の変更を抽出
    // ここでは簡易実装
    const hasChanges = since ? new Date(since) < new Date(lastUpdateTimestamp) : false;

    const response: UpdatesResponse = {
      updated_entities: hasChanges ? {
        features: currentData.entities.features
      } : {},
      deleted_entities: {},
      grid_changes: hasChanges ? {
        updated_cells: currentData.grid.index,
        removed_cells: []
      } : undefined,
      current_timestamp: new Date().toISOString(),
      has_changes: hasChanges
    };

    return HttpResponse.json(response);
  }),

  // POST /api/epic_grid/projects/:projectId/grid/reset
  // モックデータリセット (テスト用)
  http.post('/api/epic_grid/projects/:projectId/grid/reset', async () => {
    currentData = JSON.parse(JSON.stringify(normalizedMockData));
    lastUpdateTimestamp = new Date().toISOString();

    return HttpResponse.json({
      success: true,
      message: 'Mock data has been reset'
    });
  }),

  // ========================================
  // CRUD操作: Feature
  // ========================================

  // POST /api/epic_grid/projects/:projectId/cards
  // Feature作成
  http.post('/api/epic_grid/projects/:projectId/cards', async ({ request }: { request: Request }) => {
    await delay(200);

    const body = (await request.json()) as CreateFeatureRequest;
    const { subject, description, parent_epic_id, fixed_version_id, assigned_to_id, priority_id } = body;

    // Epic存在確認
    const parentEpic = currentData.entities.epics[parent_epic_id];
    if (!parentEpic) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Epic ${parent_epic_id} not found`,
          details: { field: 'parent_epic_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 新規Feature作成
    const newFeatureId = `f-new-${Date.now()}`;
    const newFeature: Feature = {
      id: newFeatureId,
      title: subject,
      description: description || '',
      status: 'open',
      parent_epic_id,
      user_story_ids: [],
      fixed_version_id,
      version_source: fixed_version_id ? 'direct' : 'none',
      statistics: {
        total_user_stories: 0,
        completed_user_stories: 0,
        total_child_items: 0,
        child_items_by_type: { tasks: 0, tests: 0, bugs: 0 },
        completion_percentage: 0
      },
      assigned_to_id,
      priority_id,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 2
    };

    // エンティティ追加
    currentData.entities.features[newFeatureId] = newFeature;

    // feature_order_by_epic更新 (3D Grid対応)
    if (!currentData.grid.feature_order_by_epic[parent_epic_id]) {
      currentData.grid.feature_order_by_epic[parent_epic_id] = [];
    }
    currentData.grid.feature_order_by_epic[parent_epic_id].push(newFeatureId);

    // 親Epic更新
    parentEpic.feature_ids.push(newFeatureId);
    parentEpic.statistics.total_features += 1;
    parentEpic.updated_on = new Date().toISOString();

    // Version統計更新
    if (fixed_version_id && currentData.entities.versions[fixed_version_id]) {
      const version = currentData.entities.versions[fixed_version_id];
      version.issue_count += 1;
      version.statistics.total_issues += 1;
      version.updated_on = new Date().toISOString();
    }

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateFeatureResponse = {
      success: true,
      data: {
        created_entity: newFeature,
        updated_entities: {
          epics: { [parent_epic_id]: parentEpic },
          features: { [newFeatureId]: newFeature },
          ...(fixed_version_id && currentData.entities.versions[fixed_version_id] ? {
            versions: { [fixed_version_id]: currentData.entities.versions[fixed_version_id] }
          } : {})
        },
        grid_updates: {
          index: currentData.grid.index,
          feature_order_by_epic: currentData.grid.feature_order_by_epic
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: UserStory
  // ========================================

  // POST /api/epic_grid/projects/:projectId/cards/:featureId/user_stories
  // UserStory作成
  http.post('/api/epic_grid/projects/:projectId/cards/:featureId/user_stories', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const { featureId } = params;
    const body = (await request.json()) as CreateUserStoryRequest;
    const { subject, description, assigned_to_id, estimated_hours, fixed_version_id } = body;

    // Feature存在確認
    const parentFeature = currentData.entities.features[featureId as string];
    if (!parentFeature) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Feature ${featureId} not found`,
          details: { field: 'parent_feature_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 新規UserStory作成
    const newStoryId = `us-new-${Date.now()}`;
    const newUserStory: UserStory = {
      id: newStoryId,
      title: subject,
      description: description || '',
      status: 'open',
      parent_feature_id: featureId as string,
      task_ids: [],
      test_ids: [],
      bug_ids: [],
      fixed_version_id: fixed_version_id || null, // クライアント指定を優先（未指定時はnull）
      version_source: fixed_version_id ? 'direct' : 'none',
      expansion_state: true,
      statistics: {
        total_tasks: 0,
        completed_tasks: 0,
        total_tests: 0,
        passed_tests: 0,
        total_bugs: 0,
        resolved_bugs: 0,
        completion_percentage: 0
      },
      assigned_to_id,
      estimated_hours,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 3
    };

    // エンティティ追加
    currentData.entities.user_stories[newStoryId] = newUserStory;

    // 親Feature更新
    parentFeature.user_story_ids.push(newStoryId);
    parentFeature.statistics.total_user_stories += 1;
    parentFeature.updated_on = new Date().toISOString();

    // grid.index更新 (3D Grid対応)
    // Epic × Feature × Version の3次元セルにUserStoryを追加
    // UserStory個別のVersionを使用（Featureは無関係）
    const epicId = parentFeature.parent_epic_id;
    const versionId = newUserStory.fixed_version_id || 'none';
    const cellKey = `${epicId}:${featureId}:${versionId}`;

    if (!currentData.grid.index[cellKey]) {
      currentData.grid.index[cellKey] = [];
    }
    currentData.grid.index[cellKey].push(newStoryId);

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateUserStoryResponse = {
      success: true,
      data: {
        created_entity: newUserStory,
        updated_entities: {
          features: { [featureId as string]: parentFeature },
          user_stories: { [newStoryId]: newUserStory }
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: Task
  // ========================================

  // POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tasks
  // Task作成
  http.post('/api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tasks', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const { userStoryId } = params;
    const body = (await request.json()) as CreateTaskRequest;
    const { subject, description, assigned_to_id, estimated_hours } = body;

    // UserStory存在確認
    const parentStory = currentData.entities.user_stories[userStoryId as string];
    if (!parentStory) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `UserStory ${userStoryId} not found`,
          details: { field: 'parent_user_story_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 新規Task作成
    const newTaskId = `task-new-${Date.now()}`;
    const newTask: Task = {
      id: newTaskId,
      title: subject,
      description: description || '',
      status: 'open',
      parent_user_story_id: userStoryId as string,
      fixed_version_id: parentStory.fixed_version_id,
      assigned_to_id: assigned_to_id ?? parentStory.assigned_to_id, // UserStoryの担当者を引き継ぐ
      estimated_hours,
      spent_hours: 0,
      done_ratio: 0,
      start_date: parentStory.start_date,
      due_date: parentStory.due_date,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 4
    };

    // エンティティ追加
    currentData.entities.tasks[newTaskId] = newTask;

    // 親UserStory更新
    parentStory.task_ids.push(newTaskId);
    parentStory.statistics.total_tasks += 1;
    parentStory.updated_on = new Date().toISOString();

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateTaskResponse = {
      success: true,
      data: {
        created_entity: newTask,
        updated_entities: {
          user_stories: { [userStoryId as string]: parentStory },
          tasks: { [newTaskId]: newTask }
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: Test
  // ========================================

  // POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tests
  // Test作成
  http.post('/api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/tests', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const { userStoryId } = params;
    const body = (await request.json()) as CreateTestRequest;
    const { subject, description, assigned_to_id } = body;

    // UserStory存在確認
    const parentStory = currentData.entities.user_stories[userStoryId as string];
    if (!parentStory) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `UserStory ${userStoryId} not found`,
          details: { field: 'parent_user_story_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 新規Test作成
    const newTestId = `test-new-${Date.now()}`;
    const newTest: Test = {
      id: newTestId,
      title: subject,
      description: description || '',
      status: 'open',
      parent_user_story_id: userStoryId as string,
      fixed_version_id: parentStory.fixed_version_id,
      test_result: 'pending',
      assigned_to_id: assigned_to_id ?? parentStory.assigned_to_id, // UserStoryの担当者を引き継ぐ
      start_date: parentStory.start_date,
      due_date: parentStory.due_date,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 5
    };

    // エンティティ追加
    currentData.entities.tests[newTestId] = newTest;

    // 親UserStory更新
    parentStory.test_ids.push(newTestId);
    parentStory.statistics.total_tests += 1;
    parentStory.updated_on = new Date().toISOString();

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateTestResponse = {
      success: true,
      data: {
        created_entity: newTest,
        updated_entities: {
          user_stories: { [userStoryId as string]: parentStory },
          tests: { [newTestId]: newTest }
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: Bug
  // ========================================

  // POST /api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/bugs
  // Bug作成
  http.post('/api/epic_grid/projects/:projectId/cards/user_stories/:userStoryId/bugs', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const { userStoryId } = params;
    const body = (await request.json()) as CreateBugRequest;
    const { subject, description, assigned_to_id, severity } = body;

    // UserStory存在確認
    const parentStory = currentData.entities.user_stories[userStoryId as string];
    if (!parentStory) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `UserStory ${userStoryId} not found`,
          details: { field: 'parent_user_story_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 新規Bug作成
    const newBugId = `bug-new-${Date.now()}`;
    const newBug: Bug = {
      id: newBugId,
      title: subject,
      description: description || '',
      status: 'open',
      parent_user_story_id: userStoryId as string,
      fixed_version_id: parentStory.fixed_version_id,
      severity: severity || 'minor',
      assigned_to_id: assigned_to_id ?? parentStory.assigned_to_id, // UserStoryの担当者を引き継ぐ
      start_date: parentStory.start_date,
      due_date: parentStory.due_date,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 6
    };

    // エンティティ追加
    currentData.entities.bugs[newBugId] = newBug;

    // 親UserStory更新
    parentStory.bug_ids.push(newBugId);
    parentStory.statistics.total_bugs += 1;
    parentStory.updated_on = new Date().toISOString();

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateBugResponse = {
      success: true,
      data: {
        created_entity: newBug,
        updated_entities: {
          user_stories: { [userStoryId as string]: parentStory },
          bugs: { [newBugId]: newBug }
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: Epic
  // ========================================

  // POST /api/epic_grid/projects/:projectId/epics
  // Epic作成
  http.post('/api/epic_grid/projects/:projectId/epics', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const body = (await request.json()) as CreateEpicRequest;
    const { subject, description, fixed_version_id, status } = body;

    // バリデーション: subject必須
    if (!subject || subject.trim() === '') {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'validation_error',
          message: 'Epic subject is required',
          details: {
            field: 'subject',
            validation_errors: [{
              field: 'subject',
              message: 'Subject cannot be blank',
              code: 'blank'
            }]
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 400 });
    }

    // 新規Epic作成
    const newEpicId = `epic-new-${Date.now()}`;
    const newEpic: Epic = {
      id: newEpicId,
      subject: subject.trim(),
      description: description || '',
      status: status || 'open',
      fixed_version_id: fixed_version_id || null,
      feature_ids: [],
      statistics: {
        total_features: 0,
        completed_features: 0,
        total_user_stories: 0,
        total_child_items: 0,
        completion_percentage: 0
      },
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      tracker_id: 1
    };

    // エンティティ追加
    currentData.entities.epics[newEpicId] = newEpic;

    // グリッド順序更新 (新しいEpicを最後に追加)
    if (!currentData.grid.epic_order.includes(newEpicId)) {
      currentData.grid.epic_order.push(newEpicId);
    }

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateEpicResponse = {
      success: true,
      data: {
        created_entity: newEpic,
        updated_entities: {
          epics: { [newEpicId]: newEpic }
        },
        grid_updates: {
          epic_order: currentData.grid.epic_order
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // ========================================
  // CRUD操作: Version
  // ========================================

  // POST /api/epic_grid/projects/:projectId/versions
  // Version作成
  http.post('/api/epic_grid/projects/:projectId/versions', async ({ params, request }: { params: PathParams; request: Request }) => {
    await delay(200);

    const body = (await request.json()) as CreateVersionRequest;
    const { name, description, effective_date, status } = body;

    // バリデーション: name必須
    if (!name || name.trim() === '') {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'validation_error',
          message: 'Version name is required',
          details: {
            field: 'name',
            validation_errors: [{
              field: 'name',
              message: 'Name cannot be blank',
              code: 'blank'
            }]
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 400 });
    }

    // 新規Version作成
    const newVersionId = `v-new-${Date.now()}`;
    const newVersion: Version = {
      id: newVersionId,
      name: name.trim(),
      description: description || '',
      effective_date,
      status: status || 'open',
      issue_count: 0,
      statistics: {
        total_issues: 0,
        completed_issues: 0,
        completion_rate: 0
      },
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString()
    };

    // エンティティ追加
    currentData.entities.versions[newVersionId] = newVersion;

    // グリッド順序更新 (新しいVersionを最後に追加)
    if (!currentData.grid.version_order.includes(newVersionId)) {
      currentData.grid.version_order.push(newVersionId);
    }

    lastUpdateTimestamp = new Date().toISOString();

    const response: CreateVersionResponse = {
      success: true,
      data: {
        created_entity: newVersion,
        updated_entities: {
          versions: { [newVersionId]: newVersion }
        },
        grid_updates: {
          version_order: currentData.grid.version_order
        }
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response, { status: 201 });
  }),

  // POST /api/epic_grid/projects/:projectId/grid/reorder_epics
  // Epic並び替え処理
  http.post('/api/epic_grid/projects/:projectId/grid/reorder_epics', async ({ request }: { request: Request }) => {
    await delay(100);

    const body = (await request.json()) as ReorderEpicsRequest;
    const { source_epic_id, target_epic_id, position } = body;

    // Epic存在確認
    if (!currentData.entities.epics[source_epic_id]) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Epic ${source_epic_id} not found`,
          details: { field: 'source_epic_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    if (!currentData.entities.epics[target_epic_id]) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Epic ${target_epic_id} not found`,
          details: { field: 'target_epic_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 並び替え実行
    const epicOrder = currentData.grid.epic_order;
    const sourceIndex = epicOrder.indexOf(source_epic_id);
    const targetIndex = epicOrder.indexOf(target_epic_id);

    if (sourceIndex !== -1) {
      epicOrder.splice(sourceIndex, 1);
    }

    const newTargetIndex = epicOrder.indexOf(target_epic_id);
    const insertPosition = position === 'before' ? newTargetIndex : newTargetIndex + 1;
    epicOrder.splice(insertPosition, 0, source_epic_id);

    lastUpdateTimestamp = new Date().toISOString();

    const response: ReorderEpicsResponse = {
      success: true,
      data: {
        epic_order: currentData.grid.epic_order
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response);
  }),

  // POST /api/epic_grid/projects/:projectId/grid/reorder_versions
  // Version並び替え処理
  http.post('/api/epic_grid/projects/:projectId/grid/reorder_versions', async ({ request }: { request: Request }) => {
    await delay(100);

    const body = (await request.json()) as ReorderVersionsRequest;
    const { source_version_id, target_version_id, position } = body;

    // Version存在確認
    if (!currentData.entities.versions[source_version_id]) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Version ${source_version_id} not found`,
          details: { field: 'source_version_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    if (!currentData.entities.versions[target_version_id]) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Version ${target_version_id} not found`,
          details: { field: 'target_version_id' }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // 並び替え実行
    const versionOrder = currentData.grid.version_order;
    const sourceIndex = versionOrder.indexOf(source_version_id);
    const targetIndex = versionOrder.indexOf(target_version_id);

    if (sourceIndex !== -1) {
      versionOrder.splice(sourceIndex, 1);
    }

    const newTargetIndex = versionOrder.indexOf(target_version_id);
    const insertPosition = position === 'before' ? newTargetIndex : newTargetIndex + 1;
    versionOrder.splice(insertPosition, 0, source_version_id);

    lastUpdateTimestamp = new Date().toISOString();

    const response: ReorderVersionsResponse = {
      success: true,
      data: {
        version_order: currentData.grid.version_order
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: `req_${Math.random().toString(36).substring(7)}`
      }
    };

    return HttpResponse.json(response);
  }),

  // POST /api/epic_grid/projects/:projectId/grid/move_user_story
  // UserStory移動処理
  http.post('/api/epic_grid/projects/:projectId/grid/move_user_story', async ({ request }: { request: Request }) => {
    await delay(200);

    const body = (await request.json()) as MoveUserStoryRequest;
    const { user_story_id, target_feature_id, target_version_id } = body;

    // UserStory存在確認
    const userStory = currentData.entities.user_stories[user_story_id];
    if (!userStory) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `UserStory ${user_story_id} not found`,
          details: {
            field: 'user_story_id'
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    // Feature存在確認
    const targetFeature = currentData.entities.features[target_feature_id];
    if (!targetFeature) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: {
          code: 'not_found',
          message: `Feature ${target_feature_id} not found`,
          details: {
            field: 'target_feature_id'
          }
        },
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: `req_${Math.random().toString(36).substring(7)}`
        }
      };
      return HttpResponse.json(errorResponse, { status: 404 });
    }

    const oldFeatureId = userStory.parent_feature_id;
    const oldVersionId = userStory.fixed_version_id;
    const oldFeature = currentData.entities.features[oldFeatureId];

    // 古いFeatureからUserStoryを削除
    if (oldFeature) {
      oldFeature.user_story_ids = oldFeature.user_story_ids.filter(id => id !== user_story_id);
      oldFeature.statistics.total_user_stories -= 1;
      oldFeature.updated_on = new Date().toISOString();
    }

    // 新しいFeatureにUserStoryを追加
    if (!targetFeature.user_story_ids.includes(user_story_id)) {
      targetFeature.user_story_ids.push(user_story_id);
      targetFeature.statistics.total_user_stories += 1;
    }
    targetFeature.updated_on = new Date().toISOString();

    // UserStoryエンティティ更新
    userStory.parent_feature_id = target_feature_id;
    userStory.fixed_version_id = target_version_id;
    userStory.version_source = 'direct';
    userStory.updated_on = new Date().toISOString();

    // grid.indexを更新 (3D Grid対応)
    const affectedIssueIds: string[] = [user_story_id];

    // 古いセルから削除
    currentData.grid.version_order.forEach(vId => {
      const oldEpicId = oldFeature?.parent_epic_id;
      if (oldEpicId) {
        const oldCellKey = `${oldEpicId}:${oldFeatureId}:${vId}`;
        if (currentData.grid.index[oldCellKey]) {
          currentData.grid.index[oldCellKey] = currentData.grid.index[oldCellKey].filter(id => id !== user_story_id);
        }
      }
    });

    // 新しいセルに追加
    const newEpicId = targetFeature.parent_epic_id;
    const newCellKey = `${newEpicId}:${target_feature_id}:${target_version_id || 'none'}`;
    if (!currentData.grid.index[newCellKey]) {
      currentData.grid.index[newCellKey] = [];
    }
    if (!currentData.grid.index[newCellKey].includes(user_story_id)) {
      currentData.grid.index[newCellKey].push(user_story_id);
    }

    // Task/Test/Bug も更新
    [...userStory.task_ids, ...userStory.test_ids, ...userStory.bug_ids].forEach(childId => {
      const task = currentData.entities.tasks[childId];
      const test = currentData.entities.tests[childId];
      const bug = currentData.entities.bugs[childId];

      if (task) {
        task.fixed_version_id = target_version_id;
        task.updated_on = new Date().toISOString();
        affectedIssueIds.push(childId);
      }
      if (test) {
        test.fixed_version_id = target_version_id;
        test.updated_on = new Date().toISOString();
        affectedIssueIds.push(childId);
      }
      if (bug) {
        bug.fixed_version_id = target_version_id;
        bug.updated_on = new Date().toISOString();
        affectedIssueIds.push(childId);
      }
    });

    // タイムスタンプ更新
    lastUpdateTimestamp = new Date().toISOString();

    // 部分的なグリッドインデックス更新を構築 (バックエンドと同じ動作)
    const partialGridIndex: Record<string, string[]> = {};

    // 古いセルの更新された値を追加
    currentData.grid.version_order.forEach(vId => {
      const oldEpicId = oldFeature?.parent_epic_id;
      if (oldEpicId) {
        const oldCellKey = `${oldEpicId}:${oldFeatureId}:${vId}`;
        if (currentData.grid.index[oldCellKey]) {
          partialGridIndex[oldCellKey] = currentData.grid.index[oldCellKey];
        }
      }
    });

    // 新しいセルを追加 (既に上で定義済みの変数を再利用)
    partialGridIndex[newCellKey] = currentData.grid.index[newCellKey];

    // レスポンス構築
    const response: MoveUserStoryResponse = {
      success: true,
      updated_entities: {
        user_stories: {
          [user_story_id]: userStory
        },
        features: {
          [target_feature_id]: targetFeature,
          ...(oldFeature ? { [oldFeatureId]: oldFeature } : {})
        }
      },
      updated_grid_index: partialGridIndex,
      propagation_result: {
        affected_issue_ids: affectedIssueIds,
        conflicts: []
      }
    };

    return HttpResponse.json(response);
  }),

  // POST /api/epic_grid/projects/:projectId/grid/batch_update
  // バッチ更新処理（D&D操作の一括保存）
  http.post('/api/epic_grid/projects/:projectId/grid/batch_update', async ({ request }: { request: Request }) => {
    await delay(300); // API遅延シミュレート

    const body = await request.json() as BatchUpdateRequest;
    console.log('📦 MSW: batch_update called:', body);

    const updatedEntities: BatchUpdateResponse['updated_entities'] = {};
    const updatedGridIndex: Record<string, string[]> = {};

    // ========================================
    // UserStory移動の一括処理
    // ========================================
    if (body.moved_user_stories && body.moved_user_stories.length > 0) {
      const userStories: Record<string, UserStory> = {};
      const features: Record<string, Feature> = {};

      body.moved_user_stories.forEach(move => {
        const { id: userStoryId, target_feature_id, target_version_id } = move;

        const userStory = currentData.entities.user_stories[userStoryId];
        if (!userStory) {
          console.error(`❌ UserStory not found: ${userStoryId}`);
          return;
        }

        const oldFeatureId = userStory.parent_feature_id;
        const oldFeature = currentData.entities.features[oldFeatureId];
        const targetFeature = currentData.entities.features[target_feature_id];

        if (!targetFeature) {
          console.error(`❌ Target feature not found: ${target_feature_id}`);
          return;
        }

        // UserStoryの移動処理（move_user_storyのロジックを再利用）
        const oldVersionId = userStory.fixed_version_id;

        // 古いFeatureから削除
        if (oldFeature) {
          oldFeature.user_story_ids = oldFeature.user_story_ids.filter(id => id !== userStoryId);
          features[oldFeatureId] = oldFeature;
        }

        // 新しいFeatureに追加
        if (!targetFeature.user_story_ids.includes(userStoryId)) {
          targetFeature.user_story_ids.push(userStoryId);
        }
        features[target_feature_id] = targetFeature;

        // UserStory更新
        userStory.parent_feature_id = target_feature_id;
        userStory.fixed_version_id = target_version_id;
        userStories[userStoryId] = userStory;

        // Grid index更新（全versionに対して処理）
        const oldEpicId = oldFeature?.parent_epic_id;
        const newEpicId = targetFeature.parent_epic_id;

        currentData.grid.version_order.forEach(vId => {
          // 古いセルの更新
          if (oldEpicId && oldFeature) {
            const oldCellKey = `${oldEpicId}:${oldFeatureId}:${vId}`;
            if (currentData.grid.index[oldCellKey]) {
              currentData.grid.index[oldCellKey] = currentData.grid.index[oldCellKey].filter(
                id => id !== userStoryId
              );
              updatedGridIndex[oldCellKey] = currentData.grid.index[oldCellKey];
            }
          }

          // 新しいセルの更新
          const newCellKey = `${newEpicId}:${target_feature_id}:${vId}`;
          if (vId === (target_version_id || 'none')) {
            if (!currentData.grid.index[newCellKey]) {
              currentData.grid.index[newCellKey] = [];
            }
            if (!currentData.grid.index[newCellKey].includes(userStoryId)) {
              currentData.grid.index[newCellKey].push(userStoryId);
            }
            updatedGridIndex[newCellKey] = currentData.grid.index[newCellKey];
          }
        });

        console.log(`✅ Moved UserStory ${userStoryId} → Feature ${target_feature_id}, Version ${target_version_id}`);
      });

      updatedEntities.user_stories = userStories;
      updatedEntities.features = features;
    }

    // ========================================
    // Epic並び替え
    // ========================================
    let updatedEpicOrder: string[] | undefined;
    if (body.reordered_epics) {
      currentData.grid.epic_order = [...body.reordered_epics];
      updatedEpicOrder = [...body.reordered_epics];
      console.log('✅ Reordered Epics:', updatedEpicOrder);
    }

    // ========================================
    // Version並び替え
    // ========================================
    let updatedVersionOrder: string[] | undefined;
    if (body.reordered_versions) {
      currentData.grid.version_order = [...body.reordered_versions];
      updatedVersionOrder = [...body.reordered_versions];
      console.log('✅ Reordered Versions:', updatedVersionOrder);
    }

    // レスポンス構築
    const response: BatchUpdateResponse = {
      success: true,
      updated_entities: updatedEntities,
      updated_grid_index: updatedGridIndex,
      updated_epic_order: updatedEpicOrder,
      updated_version_order: updatedVersionOrder
    };

    lastUpdateTimestamp = new Date().toISOString();
    console.log('📦 MSW: batch_update response:', response);

    return HttpResponse.json(response);
  })
];

// ========================================
// デバッグ用ヘルパー
// ========================================

// 現在のモックデータ状態を取得 (開発ツール用)
export const getCurrentMockData = () => JSON.parse(JSON.stringify(currentData));

// モックデータを手動更新 (開発ツール用)
export const setMockData = (data: NormalizedAPIResponse) => {
  currentData = JSON.parse(JSON.stringify(data));
  lastUpdateTimestamp = new Date().toISOString();
};
