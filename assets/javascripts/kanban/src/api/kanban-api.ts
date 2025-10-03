/**
 * Kanban API Client
 *
 * MSWモック/Rails API両対応のAPI呼び出しレイヤー
 * すべてのAPI通信はこのファイルを経由する
 */

import type {
  NormalizedAPIResponse,
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
  UpdatesResponse,
  ErrorResponse
} from '../types/normalized-api';

// ========================================
// エラーハンドリング
// ========================================

class KanbanAPIError extends Error {
  constructor(
    message: string,
    public code: string,
    public status: number,
    public details?: any
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
  options: { include_closed?: boolean } = {}
): Promise<NormalizedAPIResponse> {
  const params = new URLSearchParams();
  if (options.include_closed !== undefined) {
    params.append('include_closed', String(options.include_closed));
  }

  const url = `/api/kanban/projects/${projectId}/grid${params.toString() ? `?${params}` : ''}`;
  const response = await fetch(url);
  return handleResponse<NormalizedAPIResponse>(response);
}

/**
 * 差分更新取得（ポーリング用）
 */
export async function fetchUpdates(
  projectId: number | string,
  since: string
): Promise<UpdatesResponse> {
  const url = `/api/kanban/projects/${projectId}/grid/updates?since=${encodeURIComponent(since)}`;
  const response = await fetch(url);
  return handleResponse<UpdatesResponse>(response);
}

// ========================================
// CREATE操作
// ========================================

/**
 * Feature作成
 */
export async function createFeature(
  projectId: number | string,
  data: CreateFeatureRequest
): Promise<CreateFeatureResponse> {
  const response = await fetch(`/api/kanban/projects/${projectId}/cards`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
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
    `/api/kanban/projects/${projectId}/cards/${featureId}/user_stories`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
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
    `/api/kanban/projects/${projectId}/cards/user_stories/${userStoryId}/tasks`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
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
    `/api/kanban/projects/${projectId}/cards/user_stories/${userStoryId}/tests`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
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
    `/api/kanban/projects/${projectId}/cards/user_stories/${userStoryId}/bugs`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
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
  const response = await fetch(`/api/kanban/projects/${projectId}/versions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
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
  const response = await fetch(`/api/kanban/projects/${projectId}/grid/move_feature`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  return handleResponse<MoveFeatureResponse>(response);
}

// ========================================
// DELETE操作
// ========================================

// TODO: 削除APIは後で実装

// ========================================
// デバッグ/テスト用
// ========================================

/**
 * モックデータリセット（開発/テスト用）
 */
export async function resetMockData(projectId: number | string): Promise<void> {
  const response = await fetch(`/api/kanban/projects/${projectId}/grid/reset`, {
    method: 'POST'
  });
  await handleResponse(response);
}
