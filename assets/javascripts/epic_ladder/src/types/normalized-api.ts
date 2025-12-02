/**
 * Normalized API Type Definitions (Single Source of Truth)
 *
 * このファイルが全API仕様の型定義を管理します。
 * エンドポイント定義: api-endpoints.ts
 *
 * 使用例:
 * ```typescript
 * import { NormalizedAPIResponse } from './types/normalized-api';
 * const data: NormalizedAPIResponse = await response.json();
 * ```
 */

// ========================================
// 共通型定義
// ========================================

export type IssueStatus = 'open' | 'in_progress' | 'closed';
export type VersionStatus = 'open' | 'locked' | 'closed';
export type VersionSource = 'direct' | 'inherited' | 'none';
export type TestResult = 'passed' | 'failed' | 'pending';
export type BugSeverity = 'critical' | 'major' | 'minor';

// Detail Pane用のエンティティタイプ
export type EntityType = 'issue' | 'version';

export interface SelectedEntity {
  type: EntityType;
  id: string;
}

// ========================================
// 検索関連型定義
// ========================================

export type SearchTarget = 'subject' | 'description' | 'all';

export interface SearchFilters {
  query: string;
  searchTarget: SearchTarget;
  // Phase 3: ステータスフィルター（将来実装）
  statusIds?: number[];
  // 将来拡張用: 優先度、担当者など
  priorityIds?: number[];
  assigneeIds?: number[];
}

export interface SearchResult {
  id: string;
  type: 'epic' | 'feature' | 'user-story' | 'task' | 'test' | 'bug';
  subject: string;
  isExactIdMatch?: boolean; // ID完全一致の場合true
  due_date?: string | null; // ソート用の期限日（YYYY-MM-DD形式、nullの場合は期限なし）
  status: string; // ステータス（フィルタリング用）
}

// ========================================
// エンティティ型定義
// ========================================

export interface Epic {
  // 基本情報
  id: string;
  subject: string;
  description?: string;
  status: IssueStatus;

  // Version関連
  fixed_version_id: string | null;

  // 階層関連
  feature_ids: string[];

  // 統計情報
  statistics: {
    total_features: number;
    completed_features: number;
    total_user_stories: number;
    total_child_items: number;
    completion_percentage: number;
  };

  // メタデータ
  created_on: string;
  updated_on: string;
  author_id?: number;
  tracker_id: number;
}

export interface Version {
  id: string;
  name: string;
  description?: string;
  effective_date?: string;
  status: VersionStatus;

  // 統計情報
  issue_count: number;
  statistics: {
    total_issues: number;
    completed_issues: number;
    completion_rate: number;
  };

  // メタデータ
  created_on: string;
  updated_on: string;
}

export interface Feature {
  id: string;
  title: string;
  description?: string;
  status: IssueStatus;

  // 階層関連
  parent_epic_id: string;
  user_story_ids: string[];

  // Version関連
  fixed_version_id: string | null;
  version_source: VersionSource;

  // 統計情報
  statistics: {
    total_user_stories: number;
    completed_user_stories: number;
    total_child_items: number;
    child_items_by_type: {
      tasks: number;
      tests: number;
      bugs: number;
    };
    completion_percentage: number;
  };

  // 担当者・メタデータ
  assigned_to_id?: number;
  priority_id?: number;
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

export interface UserStory {
  id: string;
  title: string;
  description?: string;
  status: IssueStatus;

  // 階層関連
  parent_feature_id: string;
  task_ids: string[];
  test_ids: string[];
  bug_ids: string[];

  // Version関連
  fixed_version_id: string | null;
  version_source: VersionSource;

  // UI状態
  expansion_state: boolean;

  // 統計情報
  statistics: {
    total_tasks: number;
    completed_tasks: number;
    total_tests: number;
    passed_tests: number;
    total_bugs: number;
    resolved_bugs: number;
    completion_percentage: number;
  };

  // メタデータ
  assigned_to_id?: number;
  estimated_hours?: number;
  done_ratio?: number;
  start_date?: string | null;
  due_date?: string | null;
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

export interface Task {
  id: string;
  title: string;
  description?: string;
  status: IssueStatus;

  // 階層関連
  parent_user_story_id: string;

  // Version関連
  fixed_version_id: string | null;

  // 作業情報
  assigned_to_id?: number;
  estimated_hours?: number;
  spent_hours?: number;
  done_ratio?: number;
  start_date?: string | null;
  due_date?: string | null;

  // メタデータ
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

export interface Test {
  id: string;
  title: string;
  description?: string;
  status: IssueStatus;

  // 階層関連
  parent_user_story_id: string;

  // Version関連
  fixed_version_id: string | null;

  // テスト結果
  test_result?: TestResult;

  // メタデータ
  assigned_to_id?: number;
  start_date?: string | null;
  due_date?: string | null;
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

export interface Bug {
  id: string;
  title: string;
  description?: string;
  status: IssueStatus;

  // 階層関連
  parent_user_story_id: string;

  // Version関連
  fixed_version_id: string | null;

  // Bug情報
  severity?: BugSeverity;

  // メタデータ
  assigned_to_id?: number;
  start_date?: string | null;
  due_date?: string | null;
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

export interface User {
  id: number;
  login: string;
  firstname: string;
  lastname: string;
  mail?: string;
  admin?: boolean;
}

/**
 * IssueStatusEntity
 * Redmineの環境に依存するIssueStatus情報
 */
export interface IssueStatusEntity {
  id: number;
  name: string;
  is_closed: boolean;
}

/**
 * TrackerEntity
 * プロジェクトで利用可能なTracker情報
 */
export interface TrackerEntity {
  id: number;
  name: string;
  description?: string;
}

// ========================================
// グリッドインデックス型定義
// ========================================

export interface GridIndex {
  // Epic × Feature × Version マッピング (3次元グリッド)
  index: Record<string, string[]>;  // "{epicId}:{featureId}:{versionId}" => userStory IDs

  // 表示順序
  epic_order: string[];
  feature_order_by_epic: Record<string, string[]>;  // epicId => feature IDs
  version_order: string[];
}

// ========================================
// メタデータ型定義
// ========================================

export interface ColumnConfig {
  id: string;
  name: string;
  status_ids: number[];
  position: number;
}

export interface Metadata {
  project: {
    id: number;
    name: string;
    identifier: string;
    description?: string;
    created_on: string;
  };

  user_permissions: {
    view_issues: boolean;
    edit_issues: boolean;
    add_issues: boolean;
    delete_issues: boolean;
    manage_versions: boolean;
    manage_project: boolean;
  };

  grid_configuration: {
    default_expanded: boolean;
    show_statistics: boolean;
    show_closed_issues: boolean;
    columns: ColumnConfig[];
  };

  // フィルタ用マスターデータ（環境依存）
  available_statuses: IssueStatusEntity[];
  available_trackers: TrackerEntity[];

  api_version: string;
  timestamp: string;
  request_id: string;
}

// ========================================
// ========================================
// API レスポンス型定義
// ========================================

export interface NormalizedAPIResponse {
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

  grid: GridIndex;
  metadata: Metadata;
}

// ========================================
// Ransackフィルタパラメータ型定義
// ========================================

/**
 * Ransack検索パラメータ
 * Ransack predicatesについて:
 * - _eq: 等しい (例: status_id_eq: 1)
 * - _in: 含まれる (例: status_id_in: [1,2,3])
 * - _cont: 部分一致 (例: subject_cont: "test")
 * - _gteq: 以上 (例: created_on_gteq: "2025-01-01")
 * - _lteq: 以下 (例: created_on_lteq: "2025-12-31")
 * - _null: NULL判定 (例: fixed_version_id_null: true)
 *
 * 使用例:
 * ```typescript
 * const filters: RansackFilterParams = {
 *   status_id_in: [1, 2],           // ステータスID 1または2
 *   fixed_version_id_eq: "5",       // バージョンID 5
 *   assigned_to_id_null: false,     // 担当者が設定されている
 *   subject_cont: "機能",            // 件名に「機能」を含む
 *   created_on_gteq: "2025-01-01",  // 2025年以降作成
 * };
 * ```
 */
export interface RansackFilterParams {
  // ステータスフィルタ
  status_id_eq?: number;
  status_id_in?: number[];

  // トラッカーフィルタ
  tracker_id_eq?: number;
  tracker_id_in?: number[];

  // バージョンフィルタ
  fixed_version_id_eq?: string;
  fixed_version_id_in?: string[];
  fixed_version_id_null?: boolean;

  // 担当者フィルタ
  assigned_to_id_eq?: number;
  assigned_to_id_in?: number[];
  assigned_to_id_null?: boolean;

  // 親Issueフィルタ
  parent_id_eq?: string;
  parent_id_in?: string[];
  parent_id_null?: boolean;

  // 優先度フィルタ
  priority_id_eq?: number;
  priority_id_in?: number[];

  // 件名フィルタ
  subject_cont?: string;
  subject_eq?: string;

  // 日付フィルタ
  created_on_gteq?: string;  // YYYY-MM-DD
  created_on_lteq?: string;
  updated_on_gteq?: string;
  updated_on_lteq?: string;
  start_date_gteq?: string;
  start_date_lteq?: string;
  due_date_gteq?: string;
  due_date_lteq?: string;

  // バージョン期日フィルタ（Ransack関連検索）
  fixed_version_effective_date_gteq?: string;  // YYYY-MM-DD (期日がこの日以降のバージョン)
  fixed_version_effective_date_lteq?: string;  // YYYY-MM-DD (期日がこの日以前のバージョン)

  // 進捗フィルタ
  done_ratio_gteq?: number;
  done_ratio_lteq?: number;
  estimated_hours_gteq?: number;
  estimated_hours_lteq?: number;

  // 関連オブジェクトでの検索
  tracker_name_eq?: string;
  tracker_name_in?: string[];
  status_name_eq?: string;
  status_name_in?: string[];
}

// ========================================
// ソート設定型定義
// ========================================

/**
 * ソートフィールド
 * - date: 日付順（Epic: start_date, Version: effective_date）
 * - id: ID順
 * - subject: 件名順（Epicのみ、Versionはname）
 */
export type SortField = 'date' | 'id' | 'subject';

/**
 * ソート方向
 * - asc: 昇順
 * - desc: 降順
 */
export type SortDirection = 'asc' | 'desc';

/**
 * Epicソート設定
 */
export interface EpicSortOptions {
  sort_by: SortField;
  sort_direction: SortDirection;
}

/**
 * Versionソート設定
 */
export interface VersionSortOptions {
  sort_by: SortField;
  sort_direction: SortDirection;
}

/**
 * グリッドソート設定
 */
export interface GridSortOptions {
  epic?: EpicSortOptions;
  version?: VersionSortOptions;
}

// ========================================
// API リクエスト型定義
// ========================================

export interface GridDataRequest {
  include_closed?: boolean;

  // バージョンフィルタ（デフォルト: クローズ済みバージョンを除外）
  exclude_closed_versions?: boolean;

  // Ransackフィルタパラメータ
  filters?: RansackFilterParams;

  // ソート設定（フロントエンド実装、将来的にバックエンド対応）
  sort_options?: GridSortOptions;

  // 旧形式（後方互換性のため残す）
  epic_ids?: string[];
  version_ids?: string[];
  assigned_to_ids?: number[];
  updated_since?: string;
}

export interface MoveFeatureRequest {
  feature_id: string;
  target_epic_id: string;
  target_version_id: string | null;
  position?: number;
}

export interface MoveFeatureResponse {
  success: boolean;

  updated_entities: {
    features?: Record<string, Feature>;
    epics?: Record<string, Epic>;
    versions?: Record<string, Version>;
  };

  updated_grid_index: Record<string, string[]>;

  propagation_result?: {
    affected_issue_ids: string[];
    conflicts: Array<{
      issue_id: string;
      message: string;
    }>;
  };
}

export interface MoveUserStoryRequest {
  user_story_id: string;
  target_feature_id: string;
  target_version_id: string | null;
  position?: number;
}

export interface MoveUserStoryResponse {
  success: boolean;

  updated_entities: {
    user_stories?: Record<string, UserStory>;
    features?: Record<string, Feature>;
    versions?: Record<string, Version>;
    tasks?: Record<string, Task>;
    tests?: Record<string, Test>;
    bugs?: Record<string, Bug>;
  };

  updated_grid_index: Record<string, string[]>;

  propagation_result?: {
    affected_issue_ids: string[];
    conflicts: Array<{
      issue_id: string;
      message: string;
    }>;
  };
}

export interface ReorderEpicsRequest {
  source_epic_id: string;
  target_epic_id: string;
  position: 'before' | 'after';
}

export interface ReorderEpicsResponse {
  success: true;
  data: {
    epic_order: string[];
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

export interface ReorderVersionsRequest {
  source_version_id: string;
  target_version_id: string;
  position: 'before' | 'after';
}

export interface ReorderVersionsResponse {
  success: true;
  data: {
    version_order: string[];
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

export interface UpdatesRequest {
  since: string;
  entity_types?: string[];
}

export interface UpdatesResponse {
  updated_entities: {
    epics?: Record<string, Epic>;
    versions?: Record<string, Version>;
    features?: Record<string, Feature>;
    user_stories?: Record<string, UserStory>;
    tasks?: Record<string, Task>;
    tests?: Record<string, Test>;
    bugs?: Record<string, Bug>;
  };

  deleted_entities: {
    epic_ids?: string[];
    version_ids?: string[];
    feature_ids?: string[];
    user_story_ids?: string[];
    task_ids?: string[];
    test_ids?: string[];
    bug_ids?: string[];
  };

  grid_changes?: {
    updated_cells: Record<string, string[]>;
    removed_cells: string[];
  };

  current_timestamp: string;
  has_changes: boolean;
}

// ========================================
// CRUD操作 リクエスト/レスポンス型定義
// ========================================

// Feature作成
export interface CreateFeatureRequest {
  subject: string;
  description?: string;
  parent_epic_id: string;
  fixed_version_id: string | null;
  assigned_to_id?: number;
  priority_id?: number;
}

export interface CreateFeatureResponse {
  success: true;
  data: {
    created_entity: Feature;
    updated_entities: {
      epics?: Record<string, Epic>;
      features?: Record<string, Feature>;
      versions?: Record<string, Version>;
    };
    grid_updates: {
      index: Record<string, string[]>;
      feature_order_by_epic: Record<string, string[]>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// UserStory作成
export interface CreateUserStoryRequest {
  subject: string;
  description?: string;
  parent_feature_id: string;
  assigned_to_id?: number;
  estimated_hours?: number;
  fixed_version_id?: string; // バージョン指定（セル指定時に使用）
}

export interface CreateUserStoryResponse {
  success: true;
  data: {
    created_entity: UserStory;
    updated_entities: {
      features?: Record<string, Feature>;
      user_stories?: Record<string, UserStory>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// Task作成
export interface CreateTaskRequest {
  subject: string;
  description?: string;
  parent_user_story_id: string;
  assigned_to_id?: number;
  estimated_hours?: number;
}

export interface CreateTaskResponse {
  success: true;
  data: {
    created_entity: Task;
    updated_entities: {
      user_stories?: Record<string, UserStory>;
      tasks?: Record<string, Task>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// Test作成
export interface CreateTestRequest {
  subject: string;
  description?: string;
  parent_user_story_id: string;
  assigned_to_id?: number;
}

export interface CreateTestResponse {
  success: true;
  data: {
    created_entity: Test;
    updated_entities: {
      user_stories?: Record<string, UserStory>;
      tests?: Record<string, Test>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// Bug作成
export interface CreateBugRequest {
  subject: string;
  description?: string;
  parent_user_story_id: string;
  assigned_to_id?: number;
  severity?: BugSeverity;
}

export interface CreateBugResponse {
  success: true;
  data: {
    created_entity: Bug;
    updated_entities: {
      user_stories?: Record<string, UserStory>;
      bugs?: Record<string, Bug>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// Epic作成
export interface CreateEpicRequest {
  subject: string;
  description?: string;
  fixed_version_id?: string | null;
  status?: IssueStatus;
}

export interface CreateEpicResponse {
  success: true;
  data: {
    created_entity: Epic;
    updated_entities: {
      epics?: Record<string, Epic>;
    };
    grid_updates: {
      epic_order: string[];
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// Version作成
export interface CreateVersionRequest {
  name: string;
  description?: string;
  effective_date?: string;
  status?: VersionStatus;
}

export interface CreateVersionResponse {
  success: true;
  data: {
    created_entity: Version;
    updated_entities: {
      versions?: Record<string, Version>;
    };
    grid_updates: {
      version_order: string[];
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// 更新操作 (共通パターン)
export interface UpdateEntityRequest {
  id: string;
  subject?: string;
  description?: string;
  status?: IssueStatus;
  assigned_to_id?: number;
  estimated_hours?: number;
  done_ratio?: number;
}

export interface UpdateEntityResponse<T> {
  success: true;
  data: {
    updated_entity: T;
    updated_entities: {
      epics?: Record<string, Epic>;
      features?: Record<string, Feature>;
      user_stories?: Record<string, UserStory>;
      tasks?: Record<string, Task>;
      tests?: Record<string, Test>;
      bugs?: Record<string, Bug>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// 削除操作 (共通パターン)
export interface DeleteEntityRequest {
  id: string;
}

export interface DeleteEntityResponse {
  success: true;
  data: {
    deleted_id: string;
    updated_entities: {
      epics?: Record<string, Epic>;
      features?: Record<string, Feature>;
      user_stories?: Record<string, UserStory>;
    };
    grid_updates?: {
      index: Record<string, string[]>;
    };
  };
  meta: {
    timestamp: string;
    request_id: string;
  };
}

// ========================================
// エラーレスポンス型定義
// ========================================

export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: {
      field?: string;
      validation_errors?: Array<{
        field: string;
        message: string;
        code: string;
      }>;
    };
  };
  metadata: {
    timestamp: string;
    request_id: string;
  };
}

// ========================================
// 型インデックス(エクスポート確認用)
// ========================================

/**
 * 全エクスポート型のリスト
 *
 * Common Types:
 * - IssueStatus
 * - VersionStatus
 * - VersionSource
 * - TestResult
 * - BugSeverity
 *
 * Entity Types:
 * - Epic
 * - Version
 * - Feature
 * - UserStory
 * - Task
 * - Test
 * - Bug
 *
 * Grid Types:
 * - GridIndex
 *
 * Metadata Types:
 * - ColumnConfig
 * - Metadata
 *
 * API Types:
 * - NormalizedAPIResponse
 * - GridDataRequest
 * - MoveFeatureRequest
 * - MoveFeatureResponse
 * - MoveUserStoryRequest
 * - MoveUserStoryResponse
 * - UpdatesRequest
 * - UpdatesResponse
 * - ErrorResponse
 *
 * CRUD Types:
 * - CreateEpicRequest / CreateEpicResponse
 * - CreateFeatureRequest / CreateFeatureResponse
 * - CreateUserStoryRequest / CreateUserStoryResponse
 * - CreateTaskRequest / CreateTaskResponse
 * - CreateTestRequest / CreateTestResponse
 * - CreateBugRequest / CreateBugResponse
 * - CreateVersionRequest / CreateVersionResponse
 * - UpdateEntityRequest / UpdateEntityResponse<T>
 * - DeleteEntityRequest / DeleteEntityResponse
 */
