# データ構造設計仕様書

## 🔗 関連ドキュメント
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
- @vibes/logics/ui_components/kanban_grid/kanban_grid_layout_specification.md
- @vibes/logics/ui_components/api_integration/api_integration_specification.md
- @vibes/rules/technical_architecture_standards.md

## 1. 概要

ワイヤーフレーム準拠のカンバンシステムにおけるデータ構造定義。React-Ruby間のデータフロー、階層構造管理、状態管理の統一仕様。

## 2. 階層データ構造

### 2.1 Issue階層定義

```
Epic (トラッカー: Epic)
└── Feature (トラッカー: Feature)
    └── UserStory (トラッカー: UserStory)
        ├── Task (トラッカー: Task)
        ├── Test (トラッカー: Test)
        └── Bug (トラッカー: Bug)
```

### 2.2 TypeScript型定義

```typescript
// assets/javascripts/kanban/types/kanban.types.ts

// 基本Issue型
export interface BaseIssue {
  id: number;
  subject: string;
  description?: string;
  status: string;
  priority?: string;
  assigned_to?: string;
  created_on: string;
  updated_on: string;
  tracker: string;
}

// バージョン型
export interface Version {
  id: number;
  name: string;
  description?: string;
  effective_date?: string;
  status: 'open' | 'locked' | 'closed';
  sharing: 'none' | 'descendants' | 'hierarchy' | 'tree' | 'system';
  issue_count?: number;
}

// バージョン参照型（Issue内で使用）
export interface VersionReference {
  id: number;
  name: string;
  source: 'direct' | 'inherited' | 'none';
}

// Epic型
export interface Epic {
  issue: BaseIssue & {
    tracker: 'Epic';
    fixed_version?: VersionReference;
  };
  features: Feature[];
  statistics: {
    total_features: number;
    total_user_stories: number;
    total_tasks: number;
    completed_percentage: number;
  };
}

// Feature型
export interface Feature {
  issue: BaseIssue & {
    tracker: 'Feature';
    parent_id?: number;
    fixed_version?: VersionReference;
  };
  user_stories: UserStory[];
  statistics: {
    total_user_stories: number;
    total_tasks: number;
    total_tests: number;
    total_bugs: number;
    completed_tasks: number;
    pending_tests: number;
    open_bugs: number;
  };
}

// UserStory型
export interface UserStory {
  issue: BaseIssue & {
    tracker: 'UserStory';
    parent_id: number;
    fixed_version?: VersionReference;
    blocks_relations?: BlocksRelation[];
  };
  tasks: Task[];
  tests: Test[];
  bugs: Bug[];
  expanded?: boolean; // UI表示状態
}

// Task型
export interface Task {
  id: number;
  subject: string;
  status: string;
  assigned_to?: string;
  estimated_hours?: number;
  spent_hours?: number;
  parent_id: number;
  created_on: string;
  updated_on: string;
  tracker: 'Task';
}

// Test型
export interface Test {
  id: number;
  subject: string;
  status: string;
  assigned_to?: string;
  test_type?: 'unit' | 'integration' | 'e2e' | 'manual';
  auto_generated?: boolean;
  parent_id: number;
  created_on: string;
  updated_on: string;
  tracker: 'Test';
}

// Bug型
export interface Bug {
  id: number;
  subject: string;
  status: string;
  priority?: string;
  assigned_to?: string;
  severity?: 'low' | 'medium' | 'high' | 'critical';
  parent_id: number;
  created_on: string;
  updated_on: string;
  tracker: 'Bug';
}

// Blocks関係型
export interface BlocksRelation {
  id: number;
  blocked_issue_id: number;
  blocking_issue_id: number;
  relation_type: 'blocks';
  delay?: number;
}

// Grid関連型
export interface GridData {
  project: ProjectMetadata;
  versions: Version[];
  epics: Epic[];
  orphan_features: Feature[]; // 親Epicが存在しないFeature
  columns: KanbanColumn[];
  metadata: GridMetadata;
}

export interface ProjectMetadata {
  id: number;
  name: string;
  identifier: string;
  description?: string;
}

export interface KanbanColumn {
  id: string;
  name: string;
  statuses: string[];
  color?: string;
  order: number;
}

export interface GridMetadata {
  total_epics: number;
  total_features: number;
  total_user_stories: number;
  total_versions: number;
  last_updated: string;
  user_permissions: UserPermissions;
}

export interface UserPermissions {
  view_issues: boolean;
  edit_issues: boolean;
  add_issues: boolean;
  delete_issues: boolean;
  manage_versions: boolean;
  view_time_entries: boolean;
}
```

## 3. API レスポンス構造

### 3.1 Grid Data API Response

```json
{
  "project": {
    "id": 1,
    "name": "サンプルプロジェクト",
    "identifier": "sample",
    "description": "サンプルプロジェクトの説明"
  },
  "versions": [
    {
      "id": 1,
      "name": "Version-1",
      "description": "最初のバージョン",
      "effective_date": "2024-03-31T23:59:59Z",
      "status": "open",
      "sharing": "none",
      "issue_count": 5
    }
  ],
  "epics": [
    {
      "issue": {
        "id": 1,
        "subject": "施設・ユーザー管理",
        "description": "施設とユーザーの管理機能",
        "status": "進行中",
        "priority": "高",
        "assigned_to": "プロジェクトマネージャー",
        "created_on": "2024-01-15T09:00:00Z",
        "updated_on": "2024-01-20T15:30:00Z",
        "tracker": "Epic",
        "fixed_version": {
          "id": 1,
          "name": "Version-1",
          "source": "direct"
        }
      },
      "features": [
        {
          "issue": {
            "id": 101,
            "subject": "ユーザー登録機能",
            "description": "新規ユーザーの登録機能",
            "status": "進行中",
            "assigned_to": "開発チームリーダー",
            "created_on": "2024-01-16T10:00:00Z",
            "updated_on": "2024-01-22T14:00:00Z",
            "tracker": "Feature",
            "parent_id": 1,
            "fixed_version": {
              "id": 1,
              "name": "Version-1",
              "source": "inherited"
            }
          },
          "user_stories": [
            {
              "issue": {
                "id": 201,
                "subject": "ユーザー登録フォーム",
                "description": "ユーザー情報入力フォームの実装",
                "status": "進行中",
                "assigned_to": "フロントエンドエンジニア",
                "created_on": "2024-01-17T11:00:00Z",
                "updated_on": "2024-01-23T09:15:00Z",
                "tracker": "UserStory",
                "parent_id": 101,
                "fixed_version": {
                  "id": 1,
                  "name": "Version-1",
                  "source": "inherited"
                }
              },
              "tasks": [
                {
                  "id": 301,
                  "subject": "バリデーション実装",
                  "status": "進行中",
                  "assigned_to": "田中太郎",
                  "estimated_hours": 8,
                  "spent_hours": 5,
                  "parent_id": 201,
                  "created_on": "2024-01-18T09:30:00Z",
                  "updated_on": "2024-01-23T16:45:00Z",
                  "tracker": "Task"
                },
                {
                  "id": 302,
                  "subject": "UI設計完了",
                  "status": "完了",
                  "assigned_to": "佐藤花子",
                  "estimated_hours": 6,
                  "spent_hours": 6,
                  "parent_id": 201,
                  "created_on": "2024-01-18T10:00:00Z",
                  "updated_on": "2024-01-21T17:30:00Z",
                  "tracker": "Task"
                }
              ],
              "tests": [
                {
                  "id": 401,
                  "subject": "単体テスト作成",
                  "status": "未着手",
                  "assigned_to": null,
                  "test_type": "unit",
                  "auto_generated": true,
                  "parent_id": 201,
                  "created_on": "2024-01-18T12:00:00Z",
                  "updated_on": "2024-01-18T12:00:00Z",
                  "tracker": "Test"
                }
              ],
              "bugs": [
                {
                  "id": 501,
                  "subject": "バリデーションエラー修正",
                  "status": "対応中",
                  "priority": "中",
                  "assigned_to": "山田一郎",
                  "severity": "medium",
                  "parent_id": 201,
                  "created_on": "2024-01-22T13:20:00Z",
                  "updated_on": "2024-01-23T10:30:00Z",
                  "tracker": "Bug"
                }
              ],
              "expanded": true
            }
          ],
          "statistics": {
            "total_user_stories": 1,
            "total_tasks": 2,
            "total_tests": 1,
            "total_bugs": 1,
            "completed_tasks": 1,
            "pending_tests": 1,
            "open_bugs": 1
          }
        }
      ],
      "statistics": {
        "total_features": 1,
        "total_user_stories": 1,
        "total_tasks": 2,
        "completed_percentage": 40
      }
    }
  ],
  "orphan_features": [],
  "columns": [
    {
      "id": "todo",
      "name": "ToDo",
      "statuses": ["新規", "未着手"],
      "color": "#f1f1f1",
      "order": 1
    },
    {
      "id": "in_progress",
      "name": "In Progress",
      "statuses": ["進行中", "対応中"],
      "color": "#fff3cd",
      "order": 2
    },
    {
      "id": "ready_for_test",
      "name": "Ready for Test",
      "statuses": ["レビュー待ち", "テスト待ち"],
      "color": "#d1ecf1",
      "order": 3
    },
    {
      "id": "released",
      "name": "Released",
      "statuses": ["解決", "完了"],
      "color": "#d4edda",
      "order": 4
    }
  ],
  "metadata": {
    "total_epics": 3,
    "total_features": 8,
    "total_user_stories": 12,
    "total_versions": 3,
    "last_updated": "2024-01-23T18:00:00Z",
    "user_permissions": {
      "view_issues": true,
      "edit_issues": true,
      "add_issues": true,
      "delete_issues": false,
      "manage_versions": true,
      "view_time_entries": true
    }
  }
}
```

## 4. 状態管理データ構造

### 4.1 React Context State

```typescript
// assets/javascripts/kanban/contexts/KanbanContext.types.ts

export interface KanbanState {
  // データ
  gridData: GridData | null;
  loading: boolean;
  error: string | null;

  // UI状態
  selectedCards: Set<number>;
  expandedUserStories: Map<number, boolean>;
  draggedCard: DraggedCard | null;

  // フィルタ・検索
  filters: KanbanFilters;
  searchQuery: string;

  // 設定
  viewMode: 'grid' | 'list';
  compactMode: boolean;
  showAssignee: boolean;
  showVersion: boolean;
}

export interface KanbanFilters {
  versionId?: number | null;
  assigneeId?: number | null;
  statusId?: number | null;
  trackerId?: number | null;
  epicId?: number | null;
}

export interface DraggedCard {
  type: 'Feature' | 'UserStory' | 'Task' | 'Test' | 'Bug';
  issue: BaseIssue;
  source: {
    epicId?: number;
    versionId?: number;
    parentId?: number;
  };
}

// Action型
export type KanbanAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_GRID_DATA'; payload: GridData }
  | { type: 'UPDATE_FEATURE'; payload: Feature }
  | { type: 'ADD_USER_STORY'; payload: { featureId: number; userStory: UserStory } }
  | { type: 'UPDATE_USER_STORY'; payload: { featureId: number; userStory: UserStory } }
  | { type: 'DELETE_USER_STORY'; payload: { featureId: number; userStoryId: number } }
  | { type: 'ADD_TASK'; payload: { userStoryId: number; task: Task } }
  | { type: 'UPDATE_TASK'; payload: { userStoryId: number; task: Task } }
  | { type: 'DELETE_TASK'; payload: { userStoryId: number; taskId: number } }
  | { type: 'TOGGLE_CARD_SELECTION'; payload: number }
  | { type: 'CLEAR_SELECTION' }
  | { type: 'TOGGLE_USER_STORY_EXPANSION'; payload: number }
  | { type: 'SET_DRAGGED_CARD'; payload: DraggedCard | null }
  | { type: 'SET_FILTERS'; payload: KanbanFilters }
  | { type: 'SET_SEARCH_QUERY'; payload: string }
  | { type: 'SET_VIEW_MODE'; payload: 'grid' | 'list' }
  | { type: 'SET_COMPACT_MODE'; payload: boolean };
```

### 4.2 Redux Store Structure (代替案)

```typescript
// assets/javascripts/kanban/store/store.types.ts

export interface RootState {
  kanban: KanbanSliceState;
  ui: UISliceState;
  auth: AuthSliceState;
}

export interface KanbanSliceState {
  projects: {
    [projectId: number]: ProjectKanbanState;
  };
  currentProjectId: number | null;
}

export interface ProjectKanbanState {
  gridData: GridData | null;
  lastUpdated: string | null;
  loading: boolean;
  error: string | null;
  optimisticUpdates: Map<string, OptimisticUpdate>;
}

export interface UISliceState {
  selectedCards: Set<number>;
  expandedUserStories: Map<number, boolean>;
  dragState: DragState;
  filters: KanbanFilters;
  searchQuery: string;
  viewSettings: ViewSettings;
  modal: ModalState;
}

export interface ViewSettings {
  viewMode: 'grid' | 'list';
  compactMode: boolean;
  showAssignee: boolean;
  showVersion: boolean;
  gridColumnWidth: number;
  featureCardHeight: number;
}

export interface ModalState {
  type: 'none' | 'create_epic' | 'create_feature' | 'create_user_story' | 'create_task' | 'edit_issue';
  data: any;
  isOpen: boolean;
}

export interface OptimisticUpdate {
  id: string;
  type: 'create' | 'update' | 'delete' | 'move';
  timestamp: number;
  originalData: any;
  optimisticData: any;
  status: 'pending' | 'confirmed' | 'failed';
}
```

## 5. Ruby側データモデル拡張

### 5.1 Issue Model 拡張

```ruby
# app/models/issue_extension.rb (concerns)
module IssueExtension
  extend ActiveSupport::Concern

  included do
    # スコープ定義
    scope :epics, -> { joins(:tracker).where(trackers: { name: 'Epic' }) }
    scope :features, -> { joins(:tracker).where(trackers: { name: 'Feature' }) }
    scope :user_stories, -> { joins(:tracker).where(trackers: { name: 'UserStory' }) }
    scope :tasks, -> { joins(:tracker).where(trackers: { name: 'Task' }) }
    scope :tests, -> { joins(:tracker).where(trackers: { name: 'Test' }) }
    scope :bugs, -> { joins(:tracker).where(trackers: { name: 'Bug' }) }

    # バージョン継承関連
    scope :with_inherited_version, -> { includes(:fixed_version, :parent) }

    # 統計用スコープ
    scope :completed, -> { joins(:status).where(issue_statuses: { is_closed: true }) }
    scope :in_progress, -> { joins(:status).where(issue_statuses: { name: ['進行中', '対応中'] }) }

    # バリデーション
    validates :subject, presence: true, length: { maximum: 255 }
    validates :tracker_id, presence: true
    validates :project_id, presence: true
    validates :author_id, presence: true
    validates :status_id, presence: true

    # コールバック
    after_update :propagate_version_if_changed
    after_create :auto_generate_test_if_user_story
  end

  # インスタンスメソッド
  def hierarchy_level
    case tracker.name
    when 'Epic' then 1
    when 'Feature' then 2
    when 'UserStory' then 3
    when 'Task', 'Test', 'Bug' then 4
    else 0
    end
  end

  def epic
    return self if tracker.name == 'Epic'
    return parent.epic if parent
    nil
  end

  def feature
    return self if tracker.name == 'Feature'
    return parent.feature if parent && parent.tracker.name == 'Feature'
    return parent.parent if parent&.parent&.tracker&.name == 'Feature'
    nil
  end

  def user_story
    return self if tracker.name == 'UserStory'
    return parent if parent&.tracker&.name == 'UserStory'
    nil
  end

  def effective_version
    return fixed_version if fixed_version

    # 親から継承
    current = parent
    while current
      return current.fixed_version if current.fixed_version
      current = current.parent
    end

    nil
  end

  def version_source
    return 'direct' if fixed_version
    return 'inherited' if effective_version
    'none'
  end

  def children_by_tracker(tracker_name)
    children.joins(:tracker).where(trackers: { name: tracker_name })
  end

  def completion_percentage
    return 0 if children.empty?

    completed_count = children.completed.count
    total_count = children.count

    (completed_count.to_f / total_count * 100).round(2)
  end

  def has_blocking_relations?
    IssueRelation.where(
      issue_from: self,
      relation_type: 'blocks'
    ).exists?
  end

  def blocked_by_issues
    Issue.joins(:relations_to)
         .where(issue_relations: {
           issue_to: self,
           relation_type: 'blocks'
         })
  end

  def status_column
    case status.name
    when '新規', '未着手'
      'todo'
    when '進行中', '対応中'
      'in_progress'
    when 'レビュー待ち', 'テスト待ち'
      'ready_for_test'
    when '解決', '完了'
      'released'
    else
      'todo'
    end
  end

  private

  def propagate_version_if_changed
    return unless saved_change_to_fixed_version_id?
    return unless fixed_version

    Kanban::VersionPropagationService.new(self, fixed_version).execute_async
  end

  def auto_generate_test_if_user_story
    return unless tracker.name == 'UserStory'

    Kanban::TestGenerationService.new(self, author).execute_if_needed_async
  end
end

# Issue クラスにinclude
Issue.include(IssueExtension)
```

### 5.2 データビルダーサービス

```ruby
# app/services/kanban/data_serializer_service.rb
class Kanban::DataSerializerService
  def initialize(project, user)
    @project = project
    @user = user
  end

  def serialize_grid_data(epics, versions, orphan_features)
    {
      project: serialize_project(@project),
      versions: versions.map { |v| serialize_version(v) },
      epics: epics.map { |e| serialize_epic(e) },
      orphan_features: orphan_features.map { |f| serialize_feature(f) },
      columns: kanban_columns,
      metadata: serialize_metadata(epics, versions)
    }
  end

  def serialize_epic(epic)
    {
      issue: serialize_base_issue(epic),
      features: epic.children.features
                    .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                    .map { |f| serialize_feature(f) },
      statistics: calculate_epic_statistics(epic)
    }
  end

  def serialize_feature(feature)
    {
      issue: serialize_base_issue(feature),
      user_stories: feature.children.user_stories
                           .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                           .map { |us| serialize_user_story(us) },
      statistics: calculate_feature_statistics(feature)
    }
  end

  def serialize_user_story(user_story)
    {
      issue: serialize_base_issue(user_story).merge(
        blocks_relations: serialize_blocks_relations(user_story)
      ),
      tasks: user_story.children_by_tracker('Task').map { |t| serialize_task(t) },
      tests: user_story.children_by_tracker('Test').map { |t| serialize_test(t) },
      bugs: user_story.children_by_tracker('Bug').map { |b| serialize_bug(b) },
      expanded: false # デフォルトは折り畳み
    }
  end

  private

  def serialize_project(project)
    {
      id: project.id,
      name: project.name,
      identifier: project.identifier,
      description: project.description
    }
  end

  def serialize_base_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      description: issue.description,
      status: issue.status.name,
      priority: issue.priority&.name,
      assigned_to: issue.assigned_to&.name,
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601,
      tracker: issue.tracker.name,
      parent_id: issue.parent_id,
      fixed_version: serialize_version_reference(issue)
    }
  end

  def serialize_version_reference(issue)
    version = issue.effective_version
    return nil unless version

    {
      id: version.id,
      name: version.name,
      source: issue.version_source
    }
  end

  def serialize_version(version)
    {
      id: version.id,
      name: version.name,
      description: version.description,
      effective_date: version.effective_date&.iso8601,
      status: version.status,
      sharing: version.sharing,
      issue_count: version.issues.count
    }
  end

  def serialize_task(task)
    {
      id: task.id,
      subject: task.subject,
      status: task.status.name,
      assigned_to: task.assigned_to&.name,
      estimated_hours: task.estimated_hours,
      spent_hours: task.spent_hours,
      parent_id: task.parent_id,
      created_on: task.created_on.iso8601,
      updated_on: task.updated_on.iso8601,
      tracker: 'Task'
    }
  end

  def serialize_test(test)
    {
      id: test.id,
      subject: test.subject,
      status: test.status.name,
      assigned_to: test.assigned_to&.name,
      test_type: extract_test_type(test),
      auto_generated: extract_auto_generated(test),
      parent_id: test.parent_id,
      created_on: test.created_on.iso8601,
      updated_on: test.updated_on.iso8601,
      tracker: 'Test'
    }
  end

  def serialize_bug(bug)
    {
      id: bug.id,
      subject: bug.subject,
      status: bug.status.name,
      priority: bug.priority&.name,
      assigned_to: bug.assigned_to&.name,
      severity: extract_severity(bug),
      parent_id: bug.parent_id,
      created_on: bug.created_on.iso8601,
      updated_on: bug.updated_on.iso8601,
      tracker: 'Bug'
    }
  end

  def serialize_blocks_relations(issue)
    issue.relations_from
         .where(relation_type: 'blocks')
         .includes(:issue_to)
         .map do |relation|
      {
        id: relation.id,
        blocked_issue_id: relation.issue_to_id,
        blocking_issue_id: relation.issue_from_id,
        relation_type: 'blocks',
        delay: relation.delay
      }
    end
  end

  def calculate_epic_statistics(epic)
    features = epic.children.features.includes(:children)

    {
      total_features: features.count,
      total_user_stories: features.sum { |f| f.children.user_stories.count },
      total_tasks: features.sum { |f| f.children.user_stories.sum { |us| us.children_by_tracker('Task').count } },
      completed_percentage: epic.completion_percentage
    }
  end

  def calculate_feature_statistics(feature)
    user_stories = feature.children.user_stories.includes(:children)

    {
      total_user_stories: user_stories.count,
      total_tasks: user_stories.sum { |us| us.children_by_tracker('Task').count },
      total_tests: user_stories.sum { |us| us.children_by_tracker('Test').count },
      total_bugs: user_stories.sum { |us| us.children_by_tracker('Bug').count },
      completed_tasks: user_stories.sum { |us| us.children_by_tracker('Task').completed.count },
      pending_tests: user_stories.sum { |us| us.children_by_tracker('Test').where.not(issue_statuses: { is_closed: true }).count },
      open_bugs: user_stories.sum { |us| us.children_by_tracker('Bug').where.not(issue_statuses: { is_closed: true }).count }
    }
  end

  def serialize_metadata(epics, versions)
    {
      total_epics: epics.count,
      total_features: @project.issues.features.count,
      total_user_stories: @project.issues.user_stories.count,
      total_versions: versions.count,
      last_updated: Time.current.iso8601,
      user_permissions: {
        view_issues: @user.allowed_to?(:view_issues, @project),
        edit_issues: @user.allowed_to?(:edit_issues, @project),
        add_issues: @user.allowed_to?(:add_issues, @project),
        delete_issues: @user.allowed_to?(:delete_issues, @project),
        manage_versions: @user.allowed_to?(:manage_versions, @project),
        view_time_entries: @user.allowed_to?(:view_time_entries, @project)
      }
    }
  end

  def kanban_columns
    [
      { id: 'todo', name: 'ToDo', statuses: ['新規', '未着手'], color: '#f1f1f1', order: 1 },
      { id: 'in_progress', name: 'In Progress', statuses: ['進行中', '対応中'], color: '#fff3cd', order: 2 },
      { id: 'ready_for_test', name: 'Ready for Test', statuses: ['レビュー待ち', 'テスト待ち'], color: '#d1ecf1', order: 3 },
      { id: 'released', name: 'Released', statuses: ['解決', '完了'], color: '#d4edda', order: 4 }
    ]
  end

  def extract_test_type(test)
    # カスタムフィールドや件名から推定
    subject = test.subject.downcase

    return 'unit' if subject.include?('単体') || subject.include?('unit')
    return 'integration' if subject.include?('結合') || subject.include?('integration')
    return 'e2e' if subject.include?('e2e') || subject.include?('エンドツーエンド')
    return 'manual' if subject.include?('手動') || subject.include?('manual')

    'unit' # デフォルト
  end

  def extract_auto_generated(test)
    # カスタムフィールドまたはサブジェクトから判定
    test.description&.include?('自動生成') || false
  end

  def extract_severity(bug)
    # プライオリティやカスタムフィールドから推定
    case bug.priority&.name
    when '低'
      'low'
    when '中', '標準'
      'medium'
    when '高'
      'high'
    when '緊急', '即座'
      'critical'
    else
      'medium'
    end
  end
end
```

## 6. データ変換ユーティリティ

### 6.1 Frontend データ変換

```javascript
// assets/javascripts/kanban/utils/DataTransformUtils.js

export class DataTransformUtils {
  // API レスポンスを内部状態に変換
  static transformGridResponse(response) {
    return {
      ...response,
      epics: response.epics.map(epic => ({
        ...epic,
        features: epic.features.map(feature => ({
          ...feature,
          user_stories: feature.user_stories.map(userStory => ({
            ...userStory,
            expanded: false // 初期状態は折り畳み
          }))
        }))
      }))
    };
  }

  // グリッドセル用データフラット化
  static flattenForGridCells(gridData) {
    const cellMap = new Map();

    gridData.epics.forEach(epic => {
      epic.features.forEach(feature => {
        const versionId = feature.issue.fixed_version?.id || 'no-version';
        const cellKey = `${epic.issue.id}-${versionId}`;

        if (!cellMap.has(cellKey)) {
          cellMap.set(cellKey, []);
        }
        cellMap.get(cellKey).push(feature);
      });
    });

    // 孤立Feature
    gridData.orphan_features.forEach(feature => {
      const versionId = feature.issue.fixed_version?.id || 'no-version';
      const cellKey = `no-epic-${versionId}`;

      if (!cellMap.has(cellKey)) {
        cellMap.set(cellKey, []);
      }
      cellMap.get(cellKey).push(feature);
    });

    return cellMap;
  }

  // 検索用インデックス構築
  static buildSearchIndex(gridData) {
    const index = [];

    gridData.epics.forEach(epic => {
      index.push({
        id: epic.issue.id,
        type: 'Epic',
        subject: epic.issue.subject,
        description: epic.issue.description,
        assignedTo: epic.issue.assigned_to
      });

      epic.features.forEach(feature => {
        index.push({
          id: feature.issue.id,
          type: 'Feature',
          epicId: epic.issue.id,
          subject: feature.issue.subject,
          description: feature.issue.description,
          assignedTo: feature.issue.assigned_to
        });

        feature.user_stories.forEach(userStory => {
          index.push({
            id: userStory.issue.id,
            type: 'UserStory',
            epicId: epic.issue.id,
            featureId: feature.issue.id,
            subject: userStory.issue.subject,
            description: userStory.issue.description,
            assignedTo: userStory.issue.assigned_to
          });

          // Task, Test, Bugも同様にインデックス化
          [...userStory.tasks, ...userStory.tests, ...userStory.bugs].forEach(item => {
            index.push({
              id: item.id,
              type: item.tracker,
              epicId: epic.issue.id,
              featureId: feature.issue.id,
              userStoryId: userStory.issue.id,
              subject: item.subject,
              assignedTo: item.assigned_to
            });
          });
        });
      });
    });

    return index;
  }

  // フィルタリング
  static applyFilters(gridData, filters) {
    if (!filters || Object.keys(filters).length === 0) {
      return gridData;
    }

    const filteredEpics = gridData.epics.map(epic => {
      const filteredFeatures = epic.features.filter(feature => {
        return this.matchesFilters(feature, filters);
      });

      return { ...epic, features: filteredFeatures };
    }).filter(epic => epic.features.length > 0);

    const filteredOrphanFeatures = gridData.orphan_features.filter(feature => {
      return this.matchesFilters(feature, filters);
    });

    return {
      ...gridData,
      epics: filteredEpics,
      orphan_features: filteredOrphanFeatures
    };
  }

  static matchesFilters(feature, filters) {
    if (filters.versionId && feature.issue.fixed_version?.id !== filters.versionId) {
      return false;
    }

    if (filters.assigneeId) {
      const hasAssignedStory = feature.user_stories.some(us =>
        us.issue.assigned_to === filters.assigneeId ||
        us.tasks.some(task => task.assigned_to === filters.assigneeId) ||
        us.tests.some(test => test.assigned_to === filters.assigneeId) ||
        us.bugs.some(bug => bug.assigned_to === filters.assigneeId)
      );
      if (!hasAssignedStory) return false;
    }

    if (filters.statusId) {
      const hasMatchingStatus = feature.user_stories.some(us =>
        us.issue.status === filters.statusId ||
        us.tasks.some(task => task.status === filters.statusId) ||
        us.tests.some(test => test.status === filters.statusId) ||
        us.bugs.some(bug => bug.status === filters.statusId)
      );
      if (!hasMatchingStatus) return false;
    }

    return true;
  }

  // 統計計算
  static calculateStatistics(gridData) {
    const stats = {
      totalEpics: gridData.epics.length,
      totalFeatures: 0,
      totalUserStories: 0,
      totalTasks: 0,
      totalTests: 0,
      totalBugs: 0,
      completedTasks: 0,
      pendingTests: 0,
      openBugs: 0,
      byVersion: new Map(),
      byAssignee: new Map(),
      byStatus: new Map()
    };

    gridData.epics.forEach(epic => {
      stats.totalFeatures += epic.features.length;

      epic.features.forEach(feature => {
        stats.totalUserStories += feature.user_stories.length;

        feature.user_stories.forEach(userStory => {
          stats.totalTasks += userStory.tasks.length;
          stats.totalTests += userStory.tests.length;
          stats.totalBugs += userStory.bugs.length;

          stats.completedTasks += userStory.tasks.filter(t => t.status === '完了').length;
          stats.pendingTests += userStory.tests.filter(t => t.status !== '完了').length;
          stats.openBugs += userStory.bugs.filter(b => b.status !== '完了').length;

          // バージョン別統計
          const versionKey = feature.issue.fixed_version?.name || 'No Version';
          if (!stats.byVersion.has(versionKey)) {
            stats.byVersion.set(versionKey, { features: 0, userStories: 0, tasks: 0 });
          }
          const versionStats = stats.byVersion.get(versionKey);
          versionStats.features += 1;
          versionStats.userStories += 1;
          versionStats.tasks += userStory.tasks.length;
        });
      });
    });

    return stats;
  }
}
```

---

*ワイヤーフレーム準拠カンバンシステムのデータ構造設計。型安全性とパフォーマンスを両立するReact-Ruby統合データフロー*