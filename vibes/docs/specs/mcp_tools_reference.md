# MCP Tools Reference

This document is **auto-generated** from Ruby source code.
Do not edit manually. Run `rake mcp:generate_docs` to regenerate.

**Total Tools**: 17

---

## AddIssueCommentTool

**Description**: チケットにコメント（ノート）を追加します。

**Class**: `EpicGrid::McpTools::AddIssueCommentTool`

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

- `issue_id` (string, **required**): チケットID
- `comment` (string, **required**): コメント内容

---

## AssignToVersionTool

**Description**: チケット（UserStory推奨）をVersionに割り当てます。UserStoryの場合、配下のTask/Bug/Testも自動的に同じVersionに設定されます。

**Class**: `EpicGrid::McpTools::AssignToVersionTool`

**Overview**:

チケットをVersionに割り当てるMCPツール
UserStoryをVersionに割り当て、配下のTask/Bug/Testも自動的に同じVersionに設定する

**Examples**:

```
ユーザー: 「UserStory #123をVersion 1.2に割り当てて」
AI: AssignToVersionToolを呼び出し
結果: UserStory #123とその配下のTask/Bug/Testが全てVersion 1.2に設定される
```

**Parameters**:

- `issue_id` (string, **required**): チケットID
- `version_id` (string, **required**): Version ID

---

## CreateBugTool

**Description**: Bug（発生した不具合）チケットを作成します。例: '申込フォームのバリデーションが効かない'

**Class**: `EpicGrid::McpTools::CreateBugTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `description` (string, **required**): Bugの説明（自然言語OK）
- `parent_user_story_id` (string, optional): 親UserStory ID（省略可）
- `version_id` (string, optional): Version ID（省略時は親から継承）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateEpicTool

**Description**: Epic（大分類）チケットを作成します。例: 'ユーザー動線'

**Class**: `EpicGrid::McpTools::CreateEpicTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `subject` (string, **required**): Epicの件名
- `description` (string, optional): Epicの説明（省略可）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateFeatureTool

**Description**: Feature（分類を行うための中間層）チケットを作成します。例: 'CTA'

**Class**: `EpicGrid::McpTools::CreateFeatureTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `subject` (string, **required**): Featureの件名
- `parent_epic_id` (string, **required**): 親Epic ID
- `description` (string, optional): Featureの説明（省略可）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateTaskTool

**Description**: 自然言語からTaskチケットを作成します。例: 'カートのリファクタリング'

**Class**: `EpicGrid::McpTools::CreateTaskTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `description` (string, **required**): タスクの説明（自然言語OK）
- `parent_user_story_id` (string, optional): 親UserStory ID（省略可）
- `version_id` (string, optional): Version ID（省略時は親から継承）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateTestTool

**Description**: Test（やるべきテストや検証）チケットを作成します。例: '申込完了までのE2Eテスト'

**Class**: `EpicGrid::McpTools::CreateTestTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `description` (string, **required**): Testの説明（自然言語OK）
- `parent_user_story_id` (string, optional): 親UserStory ID（省略可）
- `version_id` (string, optional): Version ID（省略時は親から継承）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateUserStoryTool

**Description**: UserStory（ユーザの要求など､ざっくりとした目標）チケットを作成します。例: '申込画面を作る'

**Class**: `EpicGrid::McpTools::CreateUserStoryTool`

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

- `project_id` (string, optional): プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）
- `subject` (string, **required**): UserStoryの件名
- `parent_feature_id` (string, **required**): 親Feature ID
- `version_id` (string, optional): Version ID（リリース予定）
- `description` (string, optional): UserStoryの説明（省略可）
- `assigned_to_id` (string, optional): 担当者ID（省略時は現在のユーザー）

---

## CreateVersionTool

**Description**: Version（リリース予定）を作成します。例: 'Sprint 2025-02（2025-02-28まで）'

**Class**: `EpicGrid::McpTools::CreateVersionTool`

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

- `project_id` (string, **required**): プロジェクトID（識別子または数値ID）
- `name` (string, **required**): Version名
- `effective_date` (string, **required**): リリース予定日（YYYY-MM-DD形式）
- `description` (string, optional): Versionの説明（省略可）
- `status` (string, optional): ステータス（open/locked/closed、デフォルト: open）

---

## GetIssueDetailTool

**Description**: チケットの詳細情報、コメント（更新履歴）、子チケットを取得します。

**Class**: `EpicGrid::McpTools::GetIssueDetailTool`

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

- `issue_id` (string, **required**): チケットID

---

## GetProjectStructureTool

**Description**: プロジェクトのEpic階層構造（Epic→Feature→UserStory）を可視化します。PMがプロジェクト全体を把握するのに便利です。

**Class**: `EpicGrid::McpTools::GetProjectStructureTool`

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

- `project_id` (string, **required**): プロジェクトID（識別子または数値ID）
- `version_id` (string, optional): Version IDでフィルタ（省略可）
- `status` (string, optional): ステータスでフィルタ（open/closed、省略可）

---

## ListEpicsTool

**Description**: プロジェクト内のEpic一覧を取得します。担当者、ステータスでフィルタリング可能です。

**Class**: `EpicGrid::McpTools::ListEpicsTool`

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

- `project_id` (string, **required**): プロジェクトID（識別子または数値ID）
- `assigned_to_id` (string, optional): 担当者IDでフィルタ（省略可）
- `status` (string, optional): ステータスでフィルタ（open/closed、省略可）
- `limit` (number, optional): 取得件数上限（デフォルト: 50）

---

## ListUserStoriesTool

**Description**: プロジェクト内のUserStory一覧を取得します。Version、担当者でフィルタリング可能です。

**Class**: `EpicGrid::McpTools::ListUserStoriesTool`

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

- `project_id` (string, **required**): プロジェクトID（識別子または数値ID）
- `version_id` (string, optional): Version IDでフィルタ（省略可）
- `assigned_to_id` (string, optional): 担当者IDでフィルタ（省略可）
- `status` (string, optional): ステータスでフィルタ（open/closed、省略可）
- `limit` (number, optional): 取得件数上限（デフォルト: 50）

---

## MoveToNextVersionTool

**Description**: チケット（UserStory推奨）を次のVersionに移動します（リスケ）。配下のTask/Bug/Testも自動的に移動されます。

**Class**: `EpicGrid::McpTools::MoveToNextVersionTool`

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

- `issue_id` (string, **required**): チケットID
- `confirmed` (boolean, optional): 確認済みフラグ（危険な操作の場合に必要）

---

## UpdateIssueAssigneeTool

**Description**: チケットの担当者を変更します。

**Class**: `EpicGrid::McpTools::UpdateIssueAssigneeTool`

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

- `issue_id` (string, **required**): チケットID
- `assigned_to_id` (string, **required**): 担当者ID（nullで担当者解除）

---

## UpdateIssueProgressTool

**Description**: チケットの進捗率を更新します。0〜100の整数で指定してください。

**Class**: `EpicGrid::McpTools::UpdateIssueProgressTool`

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

- `issue_id` (string, **required**): チケットID
- `progress` (number, **required**): 進捗率（0〜100の整数）

---

## UpdateIssueStatusTool

**Description**: チケットのステータスを更新します。例: 'Open', 'In Progress', 'Closed'

**Class**: `EpicGrid::McpTools::UpdateIssueStatusTool`

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

- `issue_id` (string, **required**): チケットID
- `status_name` (string, **required**): ステータス名（例: 'Open', 'In Progress', 'Closed'）
- `confirmed` (boolean, optional): 確認済みフラグ（危険な操作の場合に必要）

---

