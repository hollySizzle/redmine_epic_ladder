/**
 * Kanban API Client
 *
 * MSWモック/Rails API両対応のAPI呼び出しレイヤー
 * すべてのAPI通信はこのファイルを経由する
 */

import type {
  NormalizedAPIResponse,
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
  MoveFeatureRequest,
  MoveFeatureResponse,
  MoveUserStoryRequest,
  MoveUserStoryResponse,
  ReorderEpicsRequest,
  ReorderEpicsResponse,
  ReorderVersionsRequest,
  ReorderVersionsResponse,
  UpdatesResponse,
  ErrorResponse
} from '../types/normalized-api';

// ========================================
// Batch Update Request/Response Types
// ========================================

/**
 * バッチ更新リクエスト
 * D&D操作をまとめて保存
 */
export interface BatchUpdateRequest {
  moved_user_stories?: Array<{
    id: string;
    target_feature_id: string;
    target_version_id: string | null;
  }>;
  reordered_epics?: string[];
  reordered_versions?: string[];
}

/**
 * バッチ更新レスポンス
 */
export interface BatchUpdateResponse {
  success: boolean;
  updated_entities?: {
    epics?: Record<string, any>;
    versions?: Record<string, any>;
    features?: Record<string, any>;
    user_stories?: Record<string, any>;
    tasks?: Record<string, any>;
    tests?: Record<string, any>;
    bugs?: Record<string, any>;
  };
  updated_grid_index?: Record<string, string[]>;
  updated_epic_order?: string[];
  updated_version_order?: string[];
}

// ========================================
// 認証ヘルパー
// ========================================

/**
 * CSRFトークンを取得
 */
function getCSRFToken(): string | null {
  // Redmineのメタタグからトークン取得
  const metaTag = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement;
  if (metaTag) {
    return metaTag.content;
  }
  
  // フォールバック: authenticity_tokenフィールドから取得
  const tokenField = document.querySelector('input[name="authenticity_token"]') as HTMLInputElement;
  if (tokenField) {
    return tokenField.value;
  }
  
  return null;
}

/**
 * 共通のリクエストヘッダーを生成
 */
function getRequestHeaders(includeContentType: boolean = false): HeadersInit {
  const headers: HeadersInit = {
    'X-Requested-With': 'XMLHttpRequest' // Ajaxリクエストであることを示す
  };
  
  const csrfToken = getCSRFToken();
  if (csrfToken) {
    headers['X-CSRF-Token'] = csrfToken;
  }
  
  if (includeContentType) {
    headers['Content-Type'] = 'application/json';
  }
  
  return headers;
}

// ========================================
// エラーハンドリング
// ========================================

class KanbanAPIError extends Error {
  constructor(
    message: string,
    public code: string,
    public status: number,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'KanbanAPIError';
  }
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const errorData: ErrorResponse = await response.json();
    throw new KanbanAPIError(
      errorData.error.message,
      errorData.error.code,
      response.status,
      errorData.error.details
    );
  }
  return response.json();
}

// ========================================
// READ操作
// ========================================

/**
 * グリッドデータ取得
 */
export async function fetchGridData(
  projectId: number | string,
  options: {
    include_closed?: boolean;
    exclude_closed_versions?: boolean;
    filters?: Record<string, any>;
    sort_options?: GridSortOptions;
  } = {}
): Promise<NormalizedAPIResponse> {
  const params = new URLSearchParams();
  if (options.include_closed !== undefined) {
    params.append('include_closed', String(options.include_closed));
  }
  if (options.exclude_closed_versions !== undefined) {
    params.append('exclude_closed_versions', String(options.exclude_closed_versions));
  }

  // Ransackフィルタをクエリパラメータに追加
  if (options.filters) {
    Object.entries(options.filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        if (Array.isArray(value)) {
          // 配列の場合は filters[key][] として複数追加
          value.forEach(v => params.append(`filters[${key}][]`, String(v)));
        } else {
          params.append(`filters[${key}]`, String(value));
        }
      }
    });
  }

  // ソートオプションをクエリパラメータに追加
  if (options.sort_options) {
    if (options.sort_options.epic) {
      params.append('sort_options[epic][sort_by]', options.sort_options.epic.sort_by);
      params.append('sort_options[epic][sort_direction]', options.sort_options.epic.sort_direction);
    }
    if (options.sort_options.version) {
      params.append('sort_options[version][sort_by]', options.sort_options.version.sort_by);
      params.append('sort_options[version][sort_direction]', options.sort_options.version.sort_direction);
    }
  }

  const url = `/api/epic_grid/projects/${projectId}/grid${params.toString() ? `?${params}` : ''}`;
  const response = await fetch(url, {
    credentials: 'same-origin', // セッションクッキーを含める
    headers: getRequestHeaders()
  });
  return handleResponse<NormalizedAPIResponse>(response);
}

/**
 * 差分更新取得（ポーリング用）
 */
export async function fetchUpdates(
  projectId: number | string,
  since: string
): Promise<UpdatesResponse> {
  const url = `/api/epic_grid/projects/${projectId}/grid/updates?since=${encodeURIComponent(since)}`;
  const response = await fetch(url, {
    credentials: 'same-origin',
    headers: getRequestHeaders()
  });
  return handleResponse<UpdatesResponse>(response);
}

// ========================================
// CREATE操作
// ========================================

/**
 * Epic作成
 */
export async function createEpic(
  projectId: number | string,
  data: CreateEpicRequest
): Promise<CreateEpicResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/epics`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<CreateEpicResponse>(response);
}

/**
 * Feature作成
 */
export async function createFeature(
  projectId: number | string,
  data: CreateFeatureRequest
): Promise<CreateFeatureResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/cards`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<CreateFeatureResponse>(response);
}

/**
 * UserStory作成
 */
export async function createUserStory(
  projectId: number | string,
  featureId: string,
  data: CreateUserStoryRequest
): Promise<CreateUserStoryResponse> {
  const response = await fetch(
    `/api/epic_grid/projects/${projectId}/cards/${featureId}/user_stories`,
    {
      method: 'POST',
      credentials: 'same-origin',
      headers: getRequestHeaders(true),
      body: JSON.stringify(data)
    }
  );
  return handleResponse<CreateUserStoryResponse>(response);
}

/**
 * Task作成
 */
export async function createTask(
  projectId: number | string,
  userStoryId: string,
  data: CreateTaskRequest
): Promise<CreateTaskResponse> {
  const response = await fetch(
    `/api/epic_grid/projects/${projectId}/cards/user_stories/${userStoryId}/tasks`,
    {
      method: 'POST',
      credentials: 'same-origin',
      headers: getRequestHeaders(true),
      body: JSON.stringify(data)
    }
  );
  return handleResponse<CreateTaskResponse>(response);
}

/**
 * Test作成
 */
export async function createTest(
  projectId: number | string,
  userStoryId: string,
  data: CreateTestRequest
): Promise<CreateTestResponse> {
  const response = await fetch(
    `/api/epic_grid/projects/${projectId}/cards/user_stories/${userStoryId}/tests`,
    {
      method: 'POST',
      credentials: 'same-origin',
      headers: getRequestHeaders(true),
      body: JSON.stringify(data)
    }
  );
  return handleResponse<CreateTestResponse>(response);
}

/**
 * Bug作成
 */
export async function createBug(
  projectId: number | string,
  userStoryId: string,
  data: CreateBugRequest
): Promise<CreateBugResponse> {
  const response = await fetch(
    `/api/epic_grid/projects/${projectId}/cards/user_stories/${userStoryId}/bugs`,
    {
      method: 'POST',
      credentials: 'same-origin',
      headers: getRequestHeaders(true),
      body: JSON.stringify(data)
    }
  );
  return handleResponse<CreateBugResponse>(response);
}

/**
 * Version作成
 */
export async function createVersion(
  projectId: number | string,
  data: CreateVersionRequest
): Promise<CreateVersionResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/versions`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<CreateVersionResponse>(response);
}

// ========================================
// UPDATE操作
// ========================================

/**
 * Feature移動
 */
export async function moveFeature(
  projectId: number | string,
  data: MoveFeatureRequest
): Promise<MoveFeatureResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/move_feature`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<MoveFeatureResponse>(response);
}

/**
 * UserStory移動
 */
export async function moveUserStory(
  projectId: number | string,
  data: MoveUserStoryRequest
): Promise<MoveUserStoryResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/move_user_story`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<MoveUserStoryResponse>(response);
}

/**
 * Epic並び替え
 */
export async function reorderEpics(
  projectId: number | string,
  data: ReorderEpicsRequest
): Promise<ReorderEpicsResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/reorder_epics`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<ReorderEpicsResponse>(response);
}

/**
 * Version並び替え
 */
export async function reorderVersions(
  projectId: number | string,
  data: ReorderVersionsRequest
): Promise<ReorderVersionsResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/reorder_versions`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<ReorderVersionsResponse>(response);
}

/**
 * バッチ更新（D&D操作の一括保存）
 */
export async function batchUpdate(
  projectId: number | string,
  data: BatchUpdateRequest
): Promise<BatchUpdateResponse> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/batch_update`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders(true),
    body: JSON.stringify(data)
  });
  return handleResponse<BatchUpdateResponse>(response);
}

// ========================================
// DELETE操作
// ========================================

/**
 * TODO: 削除API実装予定
 *
 * 実装予定のエンドポイント:
 * - DELETE /api/epic_grid/projects/:project_id/epics/:id
 * - DELETE /api/epic_grid/projects/:project_id/versions/:id
 * - DELETE /api/epic_grid/projects/:project_id/features/:id
 * - DELETE /api/epic_grid/projects/:project_id/user_stories/:id
 * - DELETE /api/epic_grid/projects/:project_id/tasks/:id
 * - DELETE /api/epic_grid/projects/:project_id/tests/:id
 * - DELETE /api/epic_grid/projects/:project_id/bugs/:id
 *
 * 削除時の考慮事項:
 * - 子要素の連鎖削除またはorphan処理
 * - grid.indexからの削除
 * - feature_order_by_epicの更新
 * - ソフトデリート vs ハードデリート
 */

// ========================================
// デバッグ/テスト用
// ========================================

/**
 * モックデータリセット（開発/テスト用）
 */
export async function resetMockData(projectId: number | string): Promise<void> {
  const response = await fetch(`/api/epic_grid/projects/${projectId}/grid/reset`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: getRequestHeaders()
  });
  await handleResponse(response);
}
