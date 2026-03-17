# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### MCP Tools Expansion Phase 1 & 2 — AIエージェントのコンテキスト効率化と操作バッチ化

### get_issue_detail_tool includeパラメータ+relations対応
get_issue_detail_toolは呼び出し回数3,103回（1位）だが、毎回全セクション返却でAIのコンテキストを浪費していた。includeパラメータで取得セクションを選択可能にし、relationsセクションも新設。list_related_issues_toolの新設を回避しつつ関連チケット情報を取得可能に。
- includeパラメータ追加（children/journals/relations選択取得、デフォルト全取得で後方互換） (issue_7587)
- relationsセクション新設 (issue_7587)

### list_recently_updated_issues_tool 新規実装
agent並列実行時に直前のタスクを忘れる問題への対策。更新日時降順でチケット一覧を取得し、agentが最近の作業コンテキストを回復できるようにする。
- 新規MCPツール実装（project_id/limit対応、更新日時降順） (issue_7588)

### bulk_update_issue_status_tool 新規実装
update_issue_statusが794回（3位）、1セッション最大147回。QA完了時の一括クローズ等でバッチ操作が頻発しており、1回のAPI呼び出しで最大50件を一括更新可能にする。部分失敗時はロールバックせず成功/失敗リストを返却。
- 新規MCPツール実装（最大50件一括、部分失敗報告） (issue_7589)

### promote_to_us_tool + IssuePromoter共通モデル + クイックアクション改修
Bug→US化は5ステップの手動操作だった。既存PromotionController（トラッカー変換型）は元のBug/Test/Taskの履歴・trackerが失われるためQAワークフローに不適合。「新US作成+子付け替え型」に作り直し、元チケットの経緯を保持したまま昇格可能にした。VersionDateManagerと同じアーキテクチャでIssuePromoter共通モデルを新設し、MCP/クイックアクション双方で共通利用。
- IssuePromoter共通モデル新設（validate_promotable/promote_to_user_story） (issue_7590, issue_7591)
- promote_to_us_tool MCPツール新規実装 (issue_7590)
- PromotionControllerをIssuePromoter委譲型にリファクタ (issue_7591)

## [1.0.0] - 2026-02-18

### Added

- Epic Ladder view: kanban-style React/TypeScript UI for visualizing Epic/Feature/UserStory hierarchy across versions
- Tracker hierarchy enforcement (Epic > Feature > UserStory > Task/Bug/Test) with configurable tracker mapping
- VersionDateManager: automatic start/due date calculation when assigning issues to versions
- Drag-and-drop support for moving issues between versions and reordering within the board
- Side panel with search, list, and about tabs for issue navigation
- Detail pane for inline issue viewing within the Epic Ladder board
- Filter panel for narrowing displayed issues by various criteria
- MCP (Model Context Protocol) server integration for AI agent collaboration
  - Issue CRUD tools: create/update Epic, Feature, UserStory, Task, Bug, Test
  - Version management tools: create version, assign to version, move to next version
  - Query tools: list epics, list user stories, list versions, list project members, list statuses
  - Issue detail and project structure visualization tools
  - Issue field update tools: status, assignee, description, subject, parent, progress, custom fields
  - Per-tool hint configuration for guiding AI agent behavior
- Issue detail view hooks: quick actions for version changes, hierarchy navigation, and child issue creation
- Project-level settings for enabling/disabling plugin features per project
- Plugin-level settings for global tracker name mapping and MCP API toggle
- Automatic asset deployment (npm-free environment support)
- Internationalization support (English and Japanese locales)
- RSpec test suite for controllers, models, MCP tools, and hooks
- Vitest test suite for React frontend components
- MSW (Mock Service Worker) integration for frontend API mocking and contract testing
