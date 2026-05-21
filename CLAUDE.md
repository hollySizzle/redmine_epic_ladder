# Claude Code Router

Claude Code セッションの tool-specific 入口。Claude Code は本ファイルを native に読む。共通の central preset rules は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` を正本とし、router 本文には複製しない。AGENTS.md (Codex tool-specific) を import しない。

## セッション開始

1. 現在の working directory がこの project root またはその配下であることを確認する。
2. mozyo-bridge の central preset rules を読む:
   - `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md`
3. 非自明な作業を始める前に active な `Redmine issue / journal と Rails project docs` を確認する。

`.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` が存在しない場合は、読んだふりをせず停止し、operator に `mozyo-bridge rules install` を依頼する。

## ClaudeCode 起動時の最小 reminder

- 迎合せず事実に基づいて結論を述べる。意見の不一致は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` が指定する durable record に残す。
- implementation done / implementation_done は completion ではない。review / audit / close 条件は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` に従う。
- pane 通知は通知でしかない。判断の正本は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` と active な `Redmine issue / journal と Rails project docs` を読む。
- handoff を送る場合は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` の handoff startup decision / receive-method rule に従い、受領方法を durable record に残す。
- `mozyo-bridge status` / `mozyo-bridge doctor` / pane scrollback は operator/debug 用。durable anchor が利用可能なときに、それらから receiver state や ticket state を推測しない。
- handoff chat は state + durable anchor の最小ポインタにとどめる。受領方法・retry 計画・試行コマンドは durable record 側に置き、chat に貼り直さない。
- 詳細・例外・gate templates は `.mozyo-bridge/rules/presets/redmine-rails-governed/agent-workflow.md` を読む。router に重複させない。

## Project-Local Additions

<!-- mozyo-bridge:project-local-additions:begin -->
- 対象は Redmine plugin `redmine_epic_ladder`。Redmine core の変更は禁止。
- DB schema 変更は禁止。migration を追加しない。
- TypeScript の型定義は `assets/javascripts/epic_ladder/src/types/` を SSoT として扱う。
- 主要機能:
  - REACT: Epic Ladder view。主要 path は `assets/javascripts/epic_ladder/`。
  - MCP: AI agent 連携 tool。主要 path は `lib/epic_ladder/mcp_tools/`。
  - ISSUE_DETAIL: issue detail quick actions。主要 path は `lib/epic_ladder/hooks/`。
- 共通ロジック:
  - `app/models/epic_ladder/version_date_manager.rb`: version 変更時の日付計算。React grid controller、issue detail version controller、MCP assign tool から使う。
  - `app/models/epic_ladder/tracker_hierarchy.rb`: Epic -> Feature -> UserStory -> Task/Bug/Test の tracker 階層 rule。
- テスト:
  - 全体: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/`
  - MCP tools: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/lib/epic_ladder/mcp_tools/`
  - controllers: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/controllers/`
  - frontend: `cd assets/javascripts/epic_ladder && npm test`
- docs catalog / generated file conventions は `.mozyo-bridge/docs/catalog.yaml` を正本とし、生成物を手編集しない。
<!-- mozyo-bridge:project-local-additions:end -->
