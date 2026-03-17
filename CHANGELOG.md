# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2026-03-17

### create_inquiry_tool — 問合せ起票MCPツール新規実装
leaderがPMO相談時にチケットがなくagent_spawn_guardでブロックされる問題が発生していた。create_user_storyは親Feature IDの事前把握が前提だが、問合せフローでは「どのFeatureに起票すべきか」を呼び出し側が知らない。プロジェクトごとに「問合せ」Featureを常設し、そのFeatureを自動検出して配下にUserStoryを起票するMCPツールを新設。IssueCreationServiceに委譲することでcreate_user_storyとDRYを維持し、新ツール固有のコードはFeature自動検出ロジック（約10行）のみ。
- create_inquiry_tool: 問合せ起票MCPツール新規実装（Feature自動検出+US作成） (issue_8278)
- Feature検出ロジック: subjectに「問合せ」「問い合わせ」を含むFeatureを自動検出（ID昇順で最初の1件）
- parent_feature_id不要: 呼び出し側がFeature IDを知らなくても起票可能
- ticket-tasuki側のfeature_id外部ファイル管理が不要に（epic-ladder側で自動解決）

## [1.4.0] - 2026-03-17

### MCP Tools Expansion Phase 1 & 2 — AIエージェントのコンテキスト効率化と操作バッチ化

MCPツール利用状況の定量分析（get_issue_detail 3,103回/1位、update_issue_status 794回/3位）から、コンテキスト浪費とAPI呼び出し過多がagentの性能ボトルネックであると判明。Phase 1でコンテキスト効率化、Phase 2で操作バッチ化とワークフロー自動化に取り組んだ。

### get_issue_detail_tool includeパラメータ+relations対応
get_issue_detail_toolは毎回全セクション（children/journals含む）を返却しており、AIのコンテキストウィンドウを浪費していた。includeパラメータで必要なセクションのみ選択取得可能にした。また、relationsが取得できなかったためlist_related_issues_toolの新設が検討されていたが、既存ツールの拡張で解決。
- includeパラメータ追加（children/journals/relations選択取得、デフォルト全取得で後方互換） (issue_7587)
- relationsセクション新設 (issue_7587)

### list_recently_updated_issues_tool 新規実装
agent並列実行時に「直前のタスクを忘れる」問題が発生していた。セッション中断・再開時やagent間引き継ぎ時に、最近の作業コンテキストを素早く回復する手段がなかった。
- 新規MCPツール実装（project_id/limit対応、更新日時降順） (issue_7588)

### bulk_update_issue_status_tool 新規実装
QA完了時の一括クローズ等で、update_issue_statusを1チケットずつ繰り返し呼び出す非効率なパターンが常態化していた（1セッション最大147回）。1回のAPI呼び出しで最大50件を処理可能にし、部分失敗時はロールバックせず成功/失敗を個別報告する設計とした（全件ロールバックは成功分まで巻き戻すため不適切）。
- 新規MCPツール実装（最大50件一括、部分失敗報告） (issue_7589)

### promote_to_us_tool + IssuePromoter共通モデル + クイックアクション改修
Bug→US化は5ステップの手動操作で、人間・agent双方にとって頻出だった。v1.1.0で導入した既存PromotionController（トラッカー変換型）は元のBug/Test/Taskのトラッカー・履歴が失われるため、「バグの経緯を残したまま新USの子として管理したい」というQAワークフローに不適合だった。「新US作成+子付け替え型」に作り直し、元チケットを保持しつつ昇格可能にした。VersionDateManagerと同じアーキテクチャ（共通モデル → MCP/クイックアクション/React各層から利用）でIssuePromoterを新設。
- IssuePromoter共通モデル新設（validate_promotable/promote_to_user_story） (issue_7590, issue_7591)
- promote_to_us_tool MCPツール新規実装 (issue_7590)
- PromotionControllerをIssuePromoter委譲型にリファクタ (issue_7591)

## [1.3.0] - 2026-03-07

### add_related_issue_tool / remove_related_issue_tool — チケット間関連付けのMCP対応
QAワークフローで「旧US↔新USのrelates関連付け」が規約化されているが、MCPから関連付けを設定/解除する手段がなかった。agentはチケットの親子関係は操作できても、relates/blocks/precedes等の関連は手動に頼っていた。addがあるなら誤操作取り消しのremoveも必須であるため、対で実装。
- add_related_issue_tool: チケット間関連付け設定（relates/blocks/precedes等、重複チェック付き） (issue_7586)
- remove_related_issue_tool: チケット間関連付け解除（双方向検索対応） (issue_7586)

## [1.2.0] - 2026-02-19

### CopyIssueTool — チケット複製のMCP対応
agentがチケットをテンプレート的に使い回す際、毎回create系ツールで全フィールドを指定し直す必要があった。既存チケットを元に属性をコピーし、必要な部分だけ上書きできる複製ツールを追加。クロスプロジェクトコピー時のセキュリティ（ソースチケットのview_issues権限チェック）も考慮。
- copy_issue_tool: チケット複製MCPツール新規実装（属性コピー+上書きパラメータ対応） (issue_6306)
- ソースチケット閲覧権限チェック追加（クロスプロジェクト情報漏洩防止） (issue_6306)
- IssueStatus.default明示設定（IssueCreationServiceとの一貫性） (issue_6307)

## [1.1.0] - 2026-02-18

### USに昇格クイックアクション — Task/Bug/TestからUserStoryへの変換
Task/Bug/Testのスコープが当初想定より大きいと判明した際、手動でトラッカーを変更し親チケットを付け替える必要があった。チケット詳細画面のクイックアクションからワンクリックで昇格可能にした。VersionControllerと同じパターン（ApplicationController継承+find_issue+authorize_update）に倣い、既存アーキテクチャとの一貫性を維持。
- PromotionController新規実装（トラッカー変更+親をFeature直下に付け替え、トランザクション制御） (issue_6295)
- チケット詳細画面に「USに昇格」ボタン追加（JavaScript confirm付き） (issue_6295)

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
