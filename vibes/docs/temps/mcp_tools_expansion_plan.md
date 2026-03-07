# MCPツール拡張計画

作成日: 2026-03-07

## 背景（なぜやるか）

179セッション分の実利用データ分析から、既存MCPツールでカバーできない操作ギャップを特定した。

### 主要な課題

1. **関連チケット操作の欠如**: QAワークフローで「旧US↔新USの関連付け」が規約化されているが、MCPから実行する手段がない
2. **get_issue_detailの非効率**: 3,103回呼び出し（1位）。毎回全データ返却でコンテキスト浪費。relationsも取得不可
3. **バッチ操作の非効率**: update_issue_statusが794回（3位）、1セッション最大147回。一括操作手段なし
4. **直近作業の把握困難**: agent並列実行時に直前のタスクを忘れる問題
5. **Bug/Test/Task→US昇格の手間**: 人間・agent共に5-6ステップの手動操作が必要

### 設計根拠

Anthropic公式ガイド「[Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents)」に基づく:

- **タスク指向の粒度**: APIラッパーではなく、人間がタスクを認識する粒度に合わせる
- **曖昧さの排除**: 「どのツールを使うべきか人間が迷う状態」が最悪の設計
- **コンテキスト効率**: 必要な情報だけ返す（search_contacts vs list_contacts の原則）
- **タスク指向の複合操作は正当**: schedule_event（可用性確認+予約）のように、人間が1つのタスクとして認識する操作は束ねてよい

## 何をやるか

### Phase 1: 基盤ツール（独立・依存関係なし）

#### 1-1. add_related_issue_tool【新規】

チケット間の関連を設定する。

- **パラメータ**: `issue_id`, `related_issue_id`, `relation_type`（デフォルト"relates"）
- **内部実装**: `IssueRelation.new(issue_from:, issue_to:, relation_type:)`
- **権限**: 両チケットの`view_issues` + `manage_issue_relations`
- **重複チェック**: 既に同じ関連が存在する場合はエラー

#### 1-2. remove_related_issue_tool【新規】

関連チケットの紐付けを解除する。add があるなら remove は必須（誤操作の取り消し手段）。

- **パラメータ**: `issue_id`, `related_issue_id`
- **内部実装**: `IssueRelation` を検索して `destroy`
- **権限**: `manage_issue_relations`

#### 1-3. get_issue_detail_tool 改善【既存拡張】

includeパラメータ追加 + relations対応。

- **追加パラメータ**: `include`（配列、enum: `["children", "journals", "relations"]`、デフォルト: 全取得で後方互換）
- **relationsセクション追加**: `issue.relations.map { |r| { id:, relation_type:, issue_id:, issue_to_id: } }`
- **効果**: コンテキスト節約 + 別途 list_related_issues_tool が不要に

#### 1-4. list_recently_updated_issues_tool【新規】

プロジェクト内のチケットを更新日時降順で取得。

- **パラメータ**: `project_id`（省略時はデフォルトプロジェクト）, `limit`（デフォルト20、最大50）
- **内部実装**: `Issue.where(project:).order(updated_on: :desc).limit(limit)`
- **レスポンス**: `[{ id, subject, tracker, status, updated_on, assigned_to }]`（軽量）
- **用途**: agent並列実行時の「直前に何をやっていたか」把握

### Phase 2: 効率化・構造操作

#### 2-1. bulk_update_issue_status_tool【新規】

複数チケットのステータスを一括更新。

- **パラメータ**: `issue_ids[]`（最大50件）, `status_name`, `comment`（任意）
- **エラーハンドリング**: 部分失敗時は成功/失敗リストを返却（ロールバックしない）
- **レスポンス**: `{ succeeded: N, failed: M, results: [{ issue_id, success, error? }] }`
- **closable?チェック**: 各issueに対して個別実行

#### 2-2. promote_to_us_tool【新規】+ IssuePromoter 共通モデル

Bug/Test/TaskをUserStoryに昇格させる構造操作。

**共通モデル `app/models/epic_ladder/issue_promoter.rb`:**
- `promote_to_user_story(issue, target_feature, us_subject:)`
- `validate_promotable?(issue)` — 対象がBug/Test/Taskであること、親USが存在すること等
- 内部ステップ:
  1. target_feature配下に新US作成
  2. 対象issueの親を新USに付け替え
  3. 元の親USと新USを関連付け（`relates`）
- VersionDateManagerと同じアーキテクチャパターン: ロジックを共有モデルに置き、MCP/クイックアクション/Reactから共通利用

**MCPツール `promote_to_us_tool.rb`:**
- パラメータ: `issue_id`, `target_feature_id`（省略時は元の親USの親Feature）, `us_subject`（省略時は元チケットの件名）
- IssuePromoterに委譲

**クイックアクション（ISSUE_DETAIL）:**
- Bug/Test/Taskの詳細画面に「USに昇格」ボタン表示
- 確認ダイアログ → APIエンドポイント → IssuePromoterに委譲
- 人間運用での4画面遷移を1クリックに短縮

```
┌─────────────────────────────────────────────────────┐
│            IssuePromoter (共通ロジック)               │
│  - promote_to_user_story()                          │
│  - validate_promotable?()                           │
└─────────────────────────────────────────────────────┘
         ▲              ▲              ▲
         │              │              │
    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
    │  REACT  │    │ ISSUE   │    │   MCP   │
    │  (将来) │    │ DETAIL  │    │promote_ │
    │         │    │quick    │    │to_us_   │
    │         │    │action   │    │tool     │
    └─────────┘    └─────────┘    └─────────┘
```

## やらないこと（と理由）

| 提案 | 判断 | 理由 |
|------|------|------|
| get_issue_detail キャッシュ | 不採用 | MCPサーバーはステートレスであるべき。更新直後のキャッシュヒットが危険 |
| list_related_issues_tool | 不要 | get_issue_detail の include=relations で代替 |
| list_child_issues_tool | 不要 | get_issue_detail の children で十分 |
| list_issues_by_version_tool | 保留 | list_user_stories のトラッカーフィルタオプション化で対応可能（別途検討） |

## 実装パターン

全ツールは既存パターンに従う:
- `MCP::Tool` 継承、`extend BaseHelper`
- `*_tool.rb` 命名で Registry が自動検出
- `success_response` / `error_response` ヘルパー使用
- 権限チェック: `server_context[:user]` から取得
- テスト: `spec/lib/epic_ladder/mcp_tools/*_tool_spec.rb`

## 現在のツール数と今後

- 現在: 20ツール（Registry自動検出）
- Phase 1-2完了後: 24ツール
- Registry の `categorize_tool` によるグルーピングは維持
- 25+を超える場合は Anthropic推奨の Tool Search パターン導入を検討
