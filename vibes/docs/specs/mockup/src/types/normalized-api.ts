// 正規化API型定義
// 仕様書: @vibes/logics/api_integration/normalized_api_specification.md

// ========================================
// 共通型定義
// ========================================

export type IssueStatus = 'open' | 'in_progress' | 'closed';
export type VersionStatus = 'open' | 'locked' | 'closed';
export type VersionSource = 'direct' | 'inherited' | 'none';
export type TestResult = 'passed' | 'failed' | 'pending';
export type BugSeverity = 'critical' | 'major' | 'minor';

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
  created_on: string;
  updated_on: string;
  tracker_id: number;
}

// ========================================
// グリッドインデックス型定義
// ========================================

export interface GridIndex {
  // Epic × Version マッピング
  index: Record<string, string[]>;  // "{epicId}:{versionId}" => feature IDs

  // 表示順序
  epic_order: string[];
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

  api_version: string;
  timestamp: string;
  request_id: string;
}

// ========================================
// 統計情報型定義
// ========================================

export interface VersionStats {
  total: number;
  completed: number;
  completion_rate: number;
  by_status: Record<string, number>;
}

export interface Statistics {
  overview: {
    total_issues: number;
    completed_issues: number;
    completion_rate: number;
    total_epics: number;
    total_features: number;
    total_user_stories: number;
  };

  by_version: Record<string, VersionStats>;
  by_status: Record<string, number>;
  by_tracker: Record<string, number>;

  trend?: {
    completion_history: Array<{
      date: string;
      completion_rate: number;
    }>;
    velocity: number;
  };
}

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
  };

  grid: GridIndex;
  metadata: Metadata;
  statistics: Statistics;
}

// ========================================
// API リクエスト型定義
// ========================================

export interface GridDataRequest {
  include_closed?: boolean;
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
  updated_statistics?: Partial<Statistics>;

  propagation_result?: {
    affected_issue_ids: string[];
    conflicts: Array<{
      issue_id: string;
      message: string;
    }>;
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

  updated_statistics?: Partial<Statistics>;
  current_timestamp: string;
  has_changes: boolean;
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
