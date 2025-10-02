// TypeScript型定義 - Kanban Release システム
// 設計書「データ構造 詳細設計書」に基づく型安全性保証

// ========================================
// 基本型定義
// ========================================

export type IssueStatus = 'New' | 'Open' | 'Ready' | 'In Progress' | 'Assigned' |
                         'Review' | 'Ready for Test' | 'Testing' | 'QA' |
                         'Resolved' | 'Closed' | 'Rejected' | 'Failed';

export type TrackerType = 'Epic' | 'Feature' | 'UserStory' | 'Task' | 'Test' | 'Bug';

export type VersionSource = 'direct' | 'inherited';

export interface DateTime {
  readonly value: string;
  readonly timestamp: number;
}

export interface VersionReference {
  readonly id: number;
  readonly name: string;
  readonly source: VersionSource;
  readonly effective_date?: Date;
}

// ========================================
// 基本Issue型
// ========================================

export interface BaseIssue {
  readonly id: number;
  readonly subject: string;
  readonly status: IssueStatus;
  readonly tracker_type: TrackerType;
  readonly description?: string;
  readonly created_on: DateTime;
  readonly updated_on: DateTime;
  readonly due_date?: Date;
  readonly start_date?: Date;
  readonly assigned_to_id?: number;
  readonly assigned_to_name?: string;
  readonly priority_id: number;
  readonly priority_name: string;
  readonly done_ratio: number;
  readonly estimated_hours?: number;
  readonly parent_id?: number;
  readonly version?: VersionReference;
}

// ========================================
// 統計データ型定義
// ========================================

export interface EpicStatistics {
  readonly epic_id: number;
  readonly total_features: number;
  readonly total_user_stories: number;
  readonly total_child_items: number;
  readonly completed_features: number;
  readonly completed_user_stories: number;
  readonly completed_child_items: number;
  readonly completion_percentage: number;
  readonly version_consistency: boolean;
  readonly last_updated: DateTime;
  readonly estimated_completion_date?: Date;
  readonly health_score: number;
  readonly risk_assessment: RiskAssessment[];
}

export interface FeatureStatistics {
  readonly feature_id: number;
  readonly total_user_stories: number;
  readonly total_child_items: number;
  readonly child_items_by_type: ChildItemsByType;
  readonly completion_percentage: number;
  readonly version_consistency: boolean;
  readonly task_completion_rate: number;
  readonly test_pass_rate: number;
  readonly bug_fix_rate: number;
  readonly quality_score: number;
  readonly development_efficiency: number;
  readonly blocking_issues: BlockingIssue[];
  readonly last_updated: DateTime;
}

export interface UserStoryStatistics {
  readonly user_story_id: number;
  readonly total_child_items: number;
  readonly child_items_by_type: ChildItemsByType;
  readonly completed_child_items: number;
  readonly completion_percentage: number;
  readonly version_consistency: boolean;
  readonly blocking_issues: BlockingIssue[];
  readonly last_updated: DateTime;
}

export interface VersionStatistics {
  readonly version_id: number;
  readonly total_epics: number;
  readonly total_features: number;
  readonly total_issues: number;
  readonly issues_by_status: Record<IssueStatus, number>;
  readonly completion_trend: CompletionTrendPoint[];
  readonly release_readiness: number;
  readonly current_completion_rate: number;
  readonly velocity_last_week: number;
  readonly schedule_variance: ScheduleVariance;
  readonly release_feasibility: ReleaseFeasibility;
  readonly critical_issues: CriticalIssue[];
  readonly last_updated: DateTime;
}

// ========================================
// 階層構造型定義
// ========================================

export interface Epic extends BaseIssue {
  readonly tracker_type: 'Epic';
  readonly features: Feature[];
  readonly statistics: EpicStatistics;
  readonly version?: VersionReference;
}

export interface Feature extends BaseIssue {
  readonly tracker_type: 'Feature';
  readonly parent_epic_id: number;
  readonly user_stories: UserStory[];
  readonly statistics: FeatureStatistics;
  readonly version?: VersionReference;
}

export interface UserStory extends BaseIssue {
  readonly tracker_type: 'UserStory';
  readonly parent_feature_id: number;
  readonly child_items: ChildItemsGroup;
  readonly statistics: UserStoryStatistics;
  readonly expansion_state: boolean;
  readonly version?: VersionReference;
}

export interface ChildItemsGroup {
  readonly tasks: Task[];
  readonly tests: Test[];
  readonly bugs: Bug[];
}

export interface Task extends BaseIssue {
  readonly tracker_type: 'Task';
  readonly parent_user_story_id: number;
}

export interface Test extends BaseIssue {
  readonly tracker_type: 'Test';
  readonly parent_user_story_id: number;
  readonly test_result?: 'Passed' | 'Failed' | 'Pending';
}

export interface Bug extends BaseIssue {
  readonly tracker_type: 'Bug';
  readonly parent_issue_id: number; // UserStory または Feature
  readonly severity?: 'Low' | 'Medium' | 'High' | 'Critical';
}

// ========================================
// 補助型定義
// ========================================

export interface ChildItemsByType {
  readonly Task: number;
  readonly Test: number;
  readonly Bug: number;
}

export interface RiskAssessment {
  readonly type: 'progress_delay' | 'version_inconsistency' | 'insufficient_user_stories';
  readonly severity: 'low' | 'medium' | 'high';
  readonly message: string;
}

export interface BlockingIssue {
  readonly type: 'incomplete_tasks' | 'failed_tests' | 'many_unfixed_bugs' |
                'many_incomplete_user_stories' | 'low_test_pass_rate';
  readonly severity: 'low' | 'medium' | 'high';
  readonly count?: number;
  readonly rate?: number;
  readonly message: string;
  readonly issues?: Array<{ id: number; subject: string }>;
}

export interface CompletionTrendPoint {
  readonly date: Date;
  readonly completion_rate: number;
  readonly total_issues: number;
  readonly completed_issues: number;
}

export interface ScheduleVariance {
  readonly status: 'on_time' | 'overdue';
  readonly days_remaining?: number;
  readonly days_overdue?: number;
  readonly completion_needed_per_day?: number;
  readonly remaining_completion?: number;
  readonly message: string;
}

export interface ReleaseFeasibility {
  readonly feasible: boolean;
  readonly confidence: number;
  readonly current_velocity?: number;
  readonly required_velocity?: number;
  readonly message: string;
}

export interface CriticalIssue {
  readonly type: 'unhealthy_epic' | 'high_risk_feature' | 'overall_delay';
  readonly severity: 'medium' | 'high' | 'critical';
  readonly issue_id?: number;
  readonly issue_subject?: string;
  readonly health_score?: number;
  readonly release_readiness?: number;
  readonly message: string;
}

// ========================================
// 階層データ管理型
// ========================================

export interface IssueHierarchy {
  readonly epics: Epic[];
  readonly features: Feature[];
  readonly user_stories: UserStory[];
  readonly child_items: (Task | Test | Bug)[];
  readonly versions: VersionReference[];
}

export interface HierarchyStatistics {
  readonly epic: EpicStatistics[];
  readonly feature: FeatureStatistics[];
  readonly user_story: UserStoryStatistics[];
  readonly version: VersionStatistics[];
  readonly overall: OverallStatistics;
}

export interface OverallStatistics {
  readonly total_epics: number;
  readonly total_features: number;
  readonly total_user_stories: number;
  readonly total_tasks: number;
  readonly total_tests: number;
  readonly total_bugs: number;
  readonly overall_completion_rate: number;
  readonly average_health_score: number;
  readonly total_critical_issues: number;
}

// ========================================
// バリデーション関連型
// ========================================

export interface ValidationResult {
  readonly valid: boolean;
  readonly errors: ValidationError[];
}

export interface ValidationError {
  readonly field: string;
  readonly code: string;
  readonly message: string;
  readonly severity: 'error' | 'warning';
}

export interface ConsistencyReport {
  readonly consistent: boolean;
  readonly inconsistencies: InconsistencyItem[];
}

export interface InconsistencyItem {
  readonly type: 'version_mismatch' | 'circular_reference' | 'orphaned_issue' | 'invalid_hierarchy';
  readonly issue_id: number;
  readonly parent_id?: number;
  readonly expected_value?: any;
  readonly actual_value?: any;
  readonly message: string;
}

// ========================================
// 型制約・ガード関数
// ========================================

export interface TypeSafetyConstraints {
  readonly epic_can_only_contain_features: boolean;
  readonly feature_must_have_parent_epic: boolean;
  readonly user_story_must_have_parent_feature: boolean;
  readonly child_version_must_match_or_inherit_parent: boolean;
  readonly version_change_triggers_propagation: boolean;
  readonly no_circular_parent_child_reference: boolean;
  readonly max_hierarchy_depth: 4;
}

// 型ガード関数
export const isEpic = (issue: BaseIssue): issue is Epic =>
  issue.tracker_type === 'Epic';

export const isFeature = (issue: BaseIssue): issue is Feature =>
  issue.tracker_type === 'Feature';

export const isUserStory = (issue: BaseIssue): issue is UserStory =>
  issue.tracker_type === 'UserStory';

export const isTask = (issue: BaseIssue): issue is Task =>
  issue.tracker_type === 'Task';

export const isTest = (issue: BaseIssue): issue is Test =>
  issue.tracker_type === 'Test';

export const isBug = (issue: BaseIssue): issue is Bug =>
  issue.tracker_type === 'Bug';

export const isChildItem = (issue: BaseIssue): issue is Task | Test | Bug =>
  ['Task', 'Test', 'Bug'].includes(issue.tracker_type);

// ========================================
// 関数型定義
// ========================================

export type HierarchyValidator<T> = (data: T) => ValidationResult;
export type VersionConsistencyChecker = (hierarchy: IssueHierarchy) => ConsistencyReport;
export type StatisticsCalculator<T> = (items: T[]) => EpicStatistics | FeatureStatistics | UserStoryStatistics;

// ========================================
// API レスポンス型
// ========================================

export interface ApiResponse<T> {
  readonly success: boolean;
  readonly data?: T;
  readonly error?: string;
  readonly validation_errors?: ValidationError[];
}

export interface HierarchyResponse extends ApiResponse<IssueHierarchy> {
  readonly statistics: HierarchyStatistics;
  readonly last_updated: DateTime;
}

export interface StatisticsResponse extends ApiResponse<HierarchyStatistics> {
  readonly cache_hit: boolean;
  readonly calculation_time_ms: number;
}

// ========================================
// エクスポート型集約
// ========================================

export type AnyIssue = Epic | Feature | UserStory | Task | Test | Bug;
export type AnyStatistics = EpicStatistics | FeatureStatistics | UserStoryStatistics | VersionStatistics;

// デフォルトエクスポート
export default {
  // 型ガード関数
  isEpic,
  isFeature,
  isUserStory,
  isTask,
  isTest,
  isBug,
  isChildItem
};