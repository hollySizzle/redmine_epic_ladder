# MCP Tools Reference

This document is **auto-generated** from Ruby source code.
Do not edit manually. Run `rake mcp:generate_docs` to regenerate.

**Total Tools**: 24

---

## AddIssueCommentTool

**Description**: Adds a comment (note) to an issue.

**Class**: `EpicLadder::McpTools::AddIssueCommentTool`

**Overview**:

チケットコメント追加MCPツール
チケットにコメント（ノート）を追加する

**Examples**:

```
ユーザー: 「Task #9999にコメント追加: 実装完了、レビュー待ち」
AI: AddIssueCommentToolを呼び出し
結果: Task #9999にコメントが追加される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `comment` (string, **required**): Comment content

---

## AssignToVersionTool

**Description**: Assigns an issue (UserStory recommended) to a Version. For UserStory, child Task/Bug/Test issues are also assigned. Start/due dates are auto-set based on version.

**Class**: `EpicLadder::McpTools::AssignToVersionTool`

**Overview**:

チケットをVersionに割り当てるMCPツール
UserStoryをVersionに割り当て、配下のTask/Bug/Testも自動的に同じVersionに設定する
バージョンの期日に基づいて開始日・終了日も自動設定する

**Examples**:

```
ユーザー: 「UserStory #123をVersion 1.2に割り当てて」
AI: AssignToVersionToolを呼び出し
結果: UserStory #123とその配下のTask/Bug/Testが全てVersion 1.2に設定され、
      開始日・終了日も自動設定される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `version_id` (string, **required**): Target Version ID
- `update_parent` (boolean, optional): Also update parent issue (default: false)
- `propagate_to_children` (boolean, optional): Propagate version and dates to children (default: true)

---

## CreateBugTool

**Description**: Creates a Bug (defect) issue. Example: 'Form validation not working'

**Class**: `EpicLadder::McpTools::CreateBugTool`

**Overview**:

Bug作成MCPツール
Bug（発生した不具合）チケットを作成する

**Examples**:

```
ユーザー: 「申込フォームのバリデーションが効かないBugを作って」
AI: CreateBugToolを呼び出し
結果: Bug #1003が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `description` (string, **required**): Bug description (natural language OK)
- `parent_user_story_id` (string, **required**): Parent UserStory ID (required for hierarchy)
- `version_id` (string, optional): Version ID (inherits from parent if omitted)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateEpicTool

**Description**: Creates an Epic (top-level category) issue. Example: 'User Journey'

**Class**: `EpicLadder::McpTools::CreateEpicTool`

**Overview**:

Epic作成MCPツール
Epic（大分類）チケットを作成する

**Examples**:

```
ユーザー: 「ユーザー動線のEpicを作って」
AI: CreateEpicToolを呼び出し
結果: Epic #1000が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `subject` (string, **required**): Epic subject/title
- `description` (string, optional): Epic description (optional)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateFeatureTool

**Description**: Creates a Feature (intermediate category) issue under an Epic. Example: 'CTA Button'

**Class**: `EpicLadder::McpTools::CreateFeatureTool`

**Overview**:

Feature作成MCPツール
Feature（分類を行うための中間層）チケットを作成する

**Examples**:

```
ユーザー: 「CTAのFeatureを作って」
AI: CreateFeatureToolを呼び出し
結果: Feature #1001が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `subject` (string, **required**): Feature subject/title
- `parent_epic_id` (string, **required**): Parent Epic issue ID
- `description` (string, optional): Feature description (optional)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateTaskTool

**Description**: Creates a Task issue from natural language. Example: 'Refactor shopping cart'

**Class**: `EpicLadder::McpTools::CreateTaskTool`

**Overview**:

タスク作成MCPツール
自然言語からTaskチケットを作成する

**Examples**:

```
ユーザー: 「カートのリファクタリングタスクを作って」
AI: CreateTaskToolを呼び出し
結果: Task #9999が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `description` (string, **required**): Task description (natural language OK)
- `parent_user_story_id` (string, **required**): Parent UserStory ID (required for hierarchy)
- `version_id` (string, optional): Version ID (inherits from parent if omitted)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateTestTool

**Description**: Creates a Test (verification/QA) issue. Example: 'E2E test for registration flow'

**Class**: `EpicLadder::McpTools::CreateTestTool`

**Overview**:

Test作成MCPツール
Test（やるべきテストや検証）チケットを作成する

**Examples**:

```
ユーザー: 「申込完了までのE2Eテストを作るTestチケットを作って」
AI: CreateTestToolを呼び出し
結果: Test #1004が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `description` (string, **required**): Test description (natural language OK)
- `parent_user_story_id` (string, **required**): Parent UserStory ID (required for hierarchy)
- `version_id` (string, optional): Version ID (inherits from parent if omitted)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateUserStoryTool

**Description**: Creates a UserStory (user requirement/goal) issue under a Feature. Example: 'Build registration form'

**Class**: `EpicLadder::McpTools::CreateUserStoryTool`

**Overview**:

UserStory作成MCPツール
UserStory（ユーザの要求など､ざっくりとした目標）チケットを作成する

**Examples**:

```
ユーザー: 「申込画面を作るUserStoryを作って」
AI: CreateUserStoryToolを呼び出し
結果: UserStory #1002が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `subject` (string, **required**): UserStory subject/title
- `parent_feature_id` (string, **required**): Parent Feature issue ID
- `version_id` (string, optional): Target Version ID (release milestone)
- `description` (string, optional): UserStory description (optional)
- `assigned_to_id` (string, optional): Assignee user ID (defaults to current user)

---

## CreateVersionTool

**Description**: Creates a Version (release milestone). Example: 'Sprint 2025-02 (due 2025-02-28)'

**Class**: `EpicLadder::McpTools::CreateVersionTool`

**Overview**:

Version作成MCPツール
Version（リリース予定）を作成する

**Examples**:

```
ユーザー: 「Sprint 2025-02のVersionを作って」
AI: CreateVersionToolを呼び出し
結果: Version「Sprint 2025-02」が作成される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `name` (string, **required**): Version name
- `effective_date` (string, **required**): Release date (YYYY-MM-DD format)
- `description` (string, optional): Version description (optional)
- `status` (string, optional): Status (open/locked/closed, default: open)

---

## GetIssueDetailTool

**Description**: Gets issue details, comments (update history), and child issues.

**Class**: `EpicLadder::McpTools::GetIssueDetailTool`

**Overview**:

チケット詳細取得MCPツール
チケットの詳細情報、コメント（Journal）、子チケットを取得する

**Examples**:

```
ユーザー: 「UserStory #123の詳細とコメントを見せて」
AI: GetIssueDetailToolを呼び出し
結果: チケット詳細+コメント+子チケット情報が返却される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID

---

## GetProjectStructureTool

**Description**: Visualizes project hierarchy (Epic->Feature->UserStory). Useful for PMs to understand project structure.

**Class**: `EpicLadder::McpTools::GetProjectStructureTool`

**Overview**:

プロジェクト構造取得MCPツール
プロジェクトのEpic階層構造を可視化する

**Examples**:

```
ユーザー: 「sakura-ecプロジェクトの構造を見せて」
AI: GetProjectStructureToolを呼び出し
結果: Epic→Feature→UserStoryの階層構造が返却される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `version_id` (string, optional): Filter by Version ID (optional)
- `status` (string, optional): Filter by status (open/closed, optional; include_closed recommended)
- `max_depth` (integer, optional): Hierarchy depth: 1=Epic, 2=+Feature, 3=+UserStory, 4=+Task/Bug/Test (default: 3)
- `include_closed` (boolean, optional): Include closed issues (default: false, open only)

---

## ListEpicsTool

**Description**: Lists Epic issues in a project. Can filter by assignee and status.

**Class**: `EpicLadder::McpTools::ListEpicsTool`

**Overview**:

Epic一覧取得MCPツール
プロジェクト内のEpicを一覧取得する

**Examples**:

```
ユーザー: 「sakura-ecプロジェクトのEpic一覧を見せて」
AI: ListEpicsToolを呼び出し
結果: Epic一覧が返却される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `assigned_to_id` (string, optional): Filter by assignee ID (optional)
- `status` (string, optional): Filter by status (open/closed, optional)
- `limit` (number, optional): Max results (default: 50)

---

## ListProjectMembersTool

**Description**: Lists project members. Use this to find assignee candidates.

**Class**: `EpicLadder::McpTools::ListProjectMembersTool`

**Overview**:

プロジェクトメンバー一覧取得MCPツール
プロジェクトに所属するメンバーを一覧取得する
チケットの担当者を設定する際に、担当可能なユーザーを探すのに使用

**Examples**:

```
ユーザー: 「sakura-ecプロジェクトのメンバー一覧を見せて」
AI: ListProjectMembersToolを呼び出し
結果: メンバー一覧が返却される
```

```
ユーザー: 「このタスクを担当できる人は誰？」
AI: ListProjectMembersToolを呼び出し
結果: 担当者候補となるメンバー一覧が返却される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `role_name` (string, optional): Filter by role name (optional)
- `limit` (number, optional): Max results (default: 100)

---

## ListStatusesTool

**Description**: Lists available statuses. When project_id is specified, returns statuses available in that project's workflow.

**Class**: `EpicLadder::McpTools::ListStatusesTool`

**Overview**:

ステータス一覧取得MCPツール
プロジェクトのワークフローで使用可能なステータスを一覧取得する

**Examples**:

```
ユーザー: 「ステータス一覧を見せて」
AI: ListStatusesToolを呼び出し
結果: ステータス一覧が返却される
```

```
ユーザー: 「sakura-ecプロジェクトで使えるステータスは？」
AI: ListStatusesToolをproject_id指定で呼び出し
結果: プロジェクトのワークフローで使用可能なステータスが返却される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, returns all statuses if omitted)
- `include_closed` (boolean, optional): Include closed statuses (default: true)

---

## ListUserStoriesTool

**Description**: Lists UserStory issues in a project. Can filter by version, assignee, and status.

**Class**: `EpicLadder::McpTools::ListUserStoriesTool`

**Overview**:

UserStory一覧取得MCPツール
プロジェクト内のUserStoryを一覧取得する

**Examples**:

```
ユーザー: 「sakura-ecプロジェクトのUserStory一覧を見せて」
AI: ListUserStoriesToolを呼び出し
結果: UserStory一覧が返却される
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `version_id` (string, optional): Filter by Version ID (optional)
- `assigned_to_id` (string, optional): Filter by assignee ID (optional)
- `status` (string, optional): Filter by status (open/closed, optional)
- `limit` (number, optional): Max results (default: 50)

---

## ListVersionsTool

**Description**: Lists versions in a project. Default: open status only, sorted by due date ascending.

**Class**: `EpicLadder::McpTools::ListVersionsTool`

**Overview**:

バージョン一覧取得MCPツール
プロジェクト内のバージョンを一覧取得する

**Examples**:

```
ユーザー: 「sakura-ecプロジェクトのバージョン一覧を見せて」
AI: ListVersionsToolを呼び出し
結果: バージョン一覧が返却される（デフォルトはopen、期日近い順）
```

**Parameters**:

- `project_id` (string, optional): Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)
- `status` (string, optional): Filter by status (open/locked/closed/all, default: open)
- `sort` (string, optional): Sort order (effective_date_asc/effective_date_desc/name_asc/name_desc, default: effective_date_asc)
- `limit` (number, optional): Max results (default: 50)

---

## MoveToNextVersionTool

**Description**: Moves an issue (UserStory recommended) to the next Version (reschedule). Child Task/Bug/Test issues are also moved.

**Class**: `EpicLadder::McpTools::MoveToNextVersionTool`

**Overview**:

チケットを次のVersionに移動するMCPツール
スケジュール変更（リスケ）を簡単に行う

**Examples**:

```
ユーザー: 「UserStory #123を次のVersionに移動して（リスケ）」
AI: MoveToNextVersionToolを呼び出し
結果: UserStory #123とその配下が次のVersionに移動される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `confirmed` (boolean, optional): Confirmation flag (required for dangerous operations)

---

## UpdateCustomFieldsTool

**Description**: Updates custom fields of an issue. Fields can be specified by ID (number) or name (string).

**Class**: `EpicLadder::McpTools::UpdateCustomFieldsTool`

**Overview**:

カスタムフィールド更新MCPツール
チケットのカスタムフィールドを更新する

**Examples**:

```
ユーザー: 「Task #9999のカスタムフィールド『見積時間』を8に更新して」
AI: UpdateCustomFieldsToolを呼び出し
結果: Task #9999のカスタムフィールドが更新される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `custom_fields` (object, **required**): Custom field values. Key is field ID or name, value is the new value. Example: {"Estimated Hours": "8", "Priority Level": "High"}

---

## UpdateIssueAssigneeTool

**Description**: Changes the assignee of an issue.

**Class**: `EpicLadder::McpTools::UpdateIssueAssigneeTool`

**Overview**:

チケット担当者変更MCPツール
チケットの担当者を変更する

**Examples**:

```
ユーザー: 「Task #9999の担当者を田中さん（ID:5）にして」
AI: UpdateIssueAssigneeToolを呼び出し
結果: Task #9999の担当者が田中さんになる
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `assigned_to_id` (string, **required**): Assignee user ID (null to unassign)

---

## UpdateIssueDescriptionTool

**Description**: Updates the description of an issue.

**Class**: `EpicLadder::McpTools::UpdateIssueDescriptionTool`

**Overview**:

チケット説明更新MCPツール
チケットのdescriptionを更新する

**Examples**:

```
ユーザー: 「Task #9999の説明を更新して」
AI: UpdateIssueDescriptionToolを呼び出し
結果: Task #9999の説明が更新される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `description` (string, **required**): New description text

---

## UpdateIssueParentTool

**Description**: Changes the parent-child relationship of an issue. Set parent_issue_id to null to remove parent.

**Class**: `EpicLadder::McpTools::UpdateIssueParentTool`

**Overview**:

チケット親子関係更新MCPツール
チケットの親チケットを変更する

**Examples**:

```
ユーザー: 「Task #9999を UserStory #8888 の配下に移動して」
AI: UpdateIssueParentToolを呼び出し
結果: Task #9999の親がUserStory #8888になる
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID to move
- `parent_issue_id` (string, **required**): New parent issue ID (null or empty to remove parent)
- `inherit_version_and_dates` (boolean, optional): Inherit version and dates from new parent (default: false)

---

## UpdateIssueProgressTool

**Description**: Updates issue progress (done ratio). Specify an integer from 0 to 100.

**Class**: `EpicLadder::McpTools::UpdateIssueProgressTool`

**Overview**:

チケット進捗率更新MCPツール
チケットの進捗率を更新する（0%→50%→100%）

**Examples**:

```
ユーザー: 「Task #9999の進捗率を50%にして」
AI: UpdateIssueProgressToolを呼び出し
結果: Task #9999の進捗率が50%になる
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `progress` (number, **required**): Progress percentage (0-100 integer)

---

## UpdateIssueStatusTool

**Description**: Updates issue status. Example: 'Open', 'In Progress', 'Closed'

**Class**: `EpicLadder::McpTools::UpdateIssueStatusTool`

**Overview**:

チケットステータス更新MCPツール
チケットのステータスを更新する（Open→InProgress→Closed）

**Examples**:

```
ユーザー: 「Task #9999をClosedにして」
AI: UpdateIssueStatusToolを呼び出し
結果: Task #9999がClosedになる
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `status_name` (string, **required**): Status name (e.g., 'Open', 'In Progress', 'Closed')
- `confirmed` (boolean, optional): Confirmation flag (required for dangerous operations)

---

## UpdateIssueSubjectTool

**Description**: Updates the subject (title) of an issue.

**Class**: `EpicLadder::McpTools::UpdateIssueSubjectTool`

**Overview**:

チケット件名更新MCPツール
チケットのsubjectを更新する

**Examples**:

```
ユーザー: 「Task #9999の件名を変更して」
AI: UpdateIssueSubjectToolを呼び出し
結果: Task #9999の件名が更新される
```

**Parameters**:

- `issue_id` (string, **required**): Issue ID
- `subject` (string, **required**): New subject/title

---

