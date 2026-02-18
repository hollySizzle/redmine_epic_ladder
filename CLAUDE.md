# Epic Ladder Plugin

## 提供機能

| 機能 | 概要 | 主要ディレクトリ |
|------|------|-----------------|
| REACT | Epic Ladderビュー（カンバン風UI） | `assets/javascripts/epic_ladder/` |
| MCP | AIエージェント連携ツール群 | `lib/epic_ladder/mcp_tools/` |
| ISSUE_DETAIL | チケット詳細画面のクイックアクション | `lib/epic_ladder/hooks/` |

## ディレクトリ構造

```
app/
  controllers/epic_ladder/  # API endpoints
  models/epic_ladder/       # VersionDateManager等
  views/hooks/              # 詳細画面拡張パーシャル
lib/epic_ladder/
  mcp_tools/                # MCPツール実装
  hooks/                    # Redmine Hooks
assets/javascripts/epic_ladder/
  src/                      # React/TypeScript
spec/                       # RSpec テスト
```

## 共通ロジック

### VersionDateManager
バージョン変更時の日付計算ロジック。全機能で共通使用。
- 場所: `app/models/epic_ladder/version_date_manager.rb`
- 使用箇所: React(grid_controller), ISSUE_DETAIL(version_controller), MCP(assign_to_version_tool)

### TrackerHierarchy
トラッカー階層ルール（Epic→Feature→UserStory→Task/Bug/Test）
- 場所: `app/models/epic_ladder/tracker_hierarchy.rb`

## テスト

```bash
# 全テスト
RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/

# MCPツール
RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/lib/epic_ladder/mcp_tools/

# コントローラー
RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/controllers/

# フロントエンド
cd assets/javascripts/epic_ladder && npm test
```

## 機能間の関係

```
┌─────────────────────────────────────────────────────┐
│              VersionDateManager (SSoT)              │
│  - update_dates_for_version_change()                │
│  - change_version_with_dates()                      │
└─────────────────────────────────────────────────────┘
         ▲              ▲              ▲
         │              │              │
    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
    │  REACT  │    │ ISSUE   │    │   MCP   │
    │  grid_  │    │ DETAIL  │    │  tools  │
    │controller│   │version_ │    │         │
    │         │    │controller│   │         │
    └─────────┘    └─────────┘    └─────────┘
```

## 注意事項

- Redmineコア機能の変更禁止
- DBスキーマ変更禁止（マイグレーション不可）
- 型定義(TypeScript)がSSoT: `assets/javascripts/epic_ladder/src/types/`
