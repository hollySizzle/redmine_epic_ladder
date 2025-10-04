/**
 * API Endpoints Definition (Single Source of Truth)
 *
 * このファイルが全APIエンドポイントの仕様を定義します。
 * 型定義: normalized-api.ts
 */

/**
 * APIエンドポイントパス生成関数
 */
export const API_ENDPOINTS = {
  /**
   * カンバングリッドデータ取得
   * GET /api/kanban/projects/:project_id/grid
   *
   * Response: NormalizedAPIResponse
   * Request params: GridDataRequest (optional query params)
   */
  getGrid: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/grid`,

  /**
   * 差分更新取得
   * GET /api/kanban/projects/:project_id/updates
   *
   * Response: UpdatesResponse
   * Request params: UpdatesRequest (query params)
   */
  getUpdates: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/updates`,

  /**
   * Feature移動
   * PATCH /api/kanban/projects/:project_id/features/:feature_id/move
   *
   * Request body: MoveFeatureRequest
   * Response: MoveFeatureResponse
   */
  moveFeature: (projectId: string | number, featureId: string) =>
    `/api/kanban/projects/${projectId}/features/${featureId}/move`,

  /**
   * Epic作成
   * POST /api/kanban/projects/:project_id/epics
   */
  createEpic: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/epics`,

  /**
   * Version作成
   * POST /api/kanban/projects/:project_id/versions
   */
  createVersion: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/versions`,

  /**
   * Feature作成
   * POST /api/kanban/projects/:project_id/features
   */
  createFeature: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/features`,

  /**
   * UserStory作成
   * POST /api/kanban/projects/:project_id/user_stories
   */
  createUserStory: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/user_stories`,

  /**
   * Task作成
   * POST /api/kanban/projects/:project_id/tasks
   */
  createTask: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/tasks`,

  /**
   * Test作成
   * POST /api/kanban/projects/:project_id/tests
   */
  createTest: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/tests`,

  /**
   * Bug作成
   * POST /api/kanban/projects/:project_id/bugs
   */
  createBug: (projectId: string | number) =>
    `/api/kanban/projects/${projectId}/bugs`,
} as const;

/**
 * APIエンドポイント型（文字列リテラル型として推論）
 */
export type APIEndpoint = ReturnType<typeof API_ENDPOINTS[keyof typeof API_ENDPOINTS]>;

/**
 * HTTPメソッド定義
 */
export const HTTP_METHODS = {
  GET: 'GET',
  POST: 'POST',
  PATCH: 'PATCH',
  PUT: 'PUT',
  DELETE: 'DELETE',
} as const;

export type HTTPMethod = typeof HTTP_METHODS[keyof typeof HTTP_METHODS];

/**
 * API設定
 */
export const API_CONFIG = {
  baseURL: '/api/kanban',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
} as const;
