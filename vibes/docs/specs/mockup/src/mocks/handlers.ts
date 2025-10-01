import { http, HttpResponse, delay } from 'msw';
import type {
  NormalizedAPIResponse,
  MoveFeatureRequest,
  MoveFeatureResponse,
  UpdatesResponse,
  ErrorResponse
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
          featureId => responseData.entities.features[featureId]
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
