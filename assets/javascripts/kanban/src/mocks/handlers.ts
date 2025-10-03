import { http, HttpResponse, delay } from 'msw';
import type {
  NormalizedAPIResponse,
  MoveFeatureRequest,
  MoveFeatureResponse,
  UpdatesResponse,
  ErrorResponse,
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
  Feature,
  UserStory,
  Task,
  Test,
  Bug,
  Version
} from '../types/normalized-api';
import { normalizedMockData } from './normalized-mock-data';

// モックデータのディープコピー (状態を保持するため)
let currentData: NormalizedAPIResponse = JSON.parse(JSON.stringify(normalizedMockData));

// 最終更新タイムスタンプ (差分更新用)
let lastUpdateTimestamp = new Date().toISOString();

// ========================================
// API Handlers
// ========================================

export const handlers = [
  // GET /api/kanban/projects/:projectId/grid
  // グリッドデータ取得
  http.get('/api/kanban/projects/:projectId/grid', async ({ params, request }) => {
    const url = new URL(request.url);
    const includeClosed = url.searchParams.get('include_closed') === 'true';

    // リアルなAPI遅延をシミュレート (開発時は削除可能)
    await delay(300);

    // include_closed=false の場合、closedステータスをフィルタ
    let responseData = JSON.parse(JSON.stringify(currentData));

    if (!includeClosed) {
      // Featureからclosedを除外
      Object.keys(responseData.entities.features).forEach(id => {
        if (responseData.entities.features[id].status === 'closed') {
          delete responseData.entities.features[id];
        }
      });

      // グリッドインデックスも更新
      Object.keys(responseData.grid.index).forEach(key => {
        responseData.grid.index[key] = responseData.grid.index[key].filter(
          (featureId: string) => responseData.entities.features[featureId]
        );
      });
    }

    // タイムスタンプ更新
    responseData.metadata.timestamp = new Date().toISOString();
    responseData.metadata.request_id = `req_${Math.random().toString(36).substring(7)}`;

    return HttpResponse.json(responseData);
  }),

  // POST /api/kanban/projects/:projectId/grid/move_feature
  // Feature移動処理
  http.post('/api/kanban/projects/:projectId/grid/move_feature', async ({ request }) => {
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

    // 古いセルから削除
    const oldCellKey = `${feature.parent_epic_id}:${feature.fixed_version_id || 'none'}`;
    currentData.grid.index[oldCellKey] = currentData.grid.index[oldCellKey].filter(
      id => id !== feature_id
    );

    // 新しいセルに追加
    const newCellKey = `${target_epic_id}:${target_version_id || 'none'}`;
    if (!currentData.grid.index[newCellKey]) {
      currentData.grid.index[newCellKey] = [];
    }
    currentData.grid.index[newCellKey].push(feature_id);

    // Featureエンティティ更新
    feature.parent_epic_id = target_epic_id;
    feature.fixed_version_id = target_version_id;
    feature.updated_on = new Date().toISOString();

    // Version伝播 (UserStory以下も更新)
    const affectedIssueIds: string[] = [];
    feature.user_story_ids.forEach(storyId => {
      const story = currentData.entities.user_stories[storyId];
      if (story) {
        story.fixed_version_id = target_version_id;
        story.version_source = 'inherited';
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
      updated_grid_index: {
        [oldCellKey]: currentData.grid.index[oldCellKey],
        [newCellKey]: currentData.grid.index[newCellKey]
      },
      propagation_result: {
        affected_issue_ids: affectedIssueIds,
        conflicts: []
      }
    };

    return HttpResponse.json(response);
  }),

  // GET /api/kanban/projects/:projectId/grid/updates
  // 差分更新取得 (ポーリング用)
  http.get('/api/kanban/projects/:projectId/grid/updates', async ({ request }) => {
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

  // POST /api/kanban/projects/:projectId/grid/reset
  // モックデータリセット (テスト用)
  http.post('/api/kanban/projects/:projectId/grid/reset', async () => {
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

  // POST /api/kanban/projects/:projectId/cards
  // Feature作成
  http.post('/api/kanban/projects/:projectId/cards', async ({ request }) => {
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

    // グリッドインデックス更新
    const cellKey = `${parent_epic_id}:${fixed_version_id || 'none'}`;
    if (!currentData.grid.index[cellKey]) {
      currentData.grid.index[cellKey] = [];
    }
    currentData.grid.index[cellKey].push(newFeatureId);

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
          index: { [cellKey]: currentData.grid.index[cellKey] }
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

  // POST /api/kanban/projects/:projectId/cards/:featureId/user_stories
  // UserStory作成
  http.post('/api/kanban/projects/:projectId/cards/:featureId/user_stories', async ({ params, request }) => {
    await delay(200);

    const { featureId } = params;
    const body = (await request.json()) as CreateUserStoryRequest;
    const { subject, description, assigned_to_id, estimated_hours } = body;

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
      fixed_version_id: parentFeature.fixed_version_id,
      version_source: 'inherited',
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

  // POST /api/kanban/projects/:projectId/cards/user_stories/:userStoryId/tasks
  // Task作成
  http.post('/api/kanban/projects/:projectId/cards/user_stories/:userStoryId/tasks', async ({ params, request }) => {
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
      assigned_to_id,
      estimated_hours,
      spent_hours: 0,
      done_ratio: 0,
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

  // POST /api/kanban/projects/:projectId/cards/user_stories/:userStoryId/tests
  // Test作成
  http.post('/api/kanban/projects/:projectId/cards/user_stories/:userStoryId/tests', async ({ params, request }) => {
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
      assigned_to_id,
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

  // POST /api/kanban/projects/:projectId/cards/user_stories/:userStoryId/bugs
  // Bug作成
  http.post('/api/kanban/projects/:projectId/cards/user_stories/:userStoryId/bugs', async ({ params, request }) => {
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
      assigned_to_id,
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
  // CRUD操作: Version
  // ========================================

  // POST /api/kanban/projects/:projectId/versions
  // Version作成
  http.post('/api/kanban/projects/:projectId/versions', async ({ params, request }) => {
    await delay(200);

    const body = (await request.json()) as CreateVersionRequest;
    const { name, description, due_date, status } = body;

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
      effective_date: due_date,
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
