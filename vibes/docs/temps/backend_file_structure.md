# Backend File Structure - Epic Ladder Plugin

**作成日**: 2025-10-04
**ステータス**: リファクタリング完了 (Kanban → EpicLadder 名前空間変更済み)

---

## 📁 ディレクトリ構造

```
/usr/src/redmine/plugins/redmine_epic_ladder/
├── config/
│   └── routes.rb                    # ルーティング定義 (MSW準拠)
├── app/
│   ├── controllers/
│   │   ├── concerns/
│   │   │   └── epic_ladder_api_concern.rb  # API共通Concern
│   │   ├── epic_ladder/
│   │   │   ├── base_api_controller.rb    # API基底コントローラー
│   │   │   ├── grid_controller.rb        # グリッドデータAPI
│   │   │   └── cards_controller.rb       # Feature/UserStory CRUD API
│   │   └── epic_ladder_controller.rb        # メインビューコントローラー
│   └── models/
│       └── epic_ladder/
│           └── tracker_hierarchy.rb       # トラッカー階層管理
└── spec/
    └── (テストファイル)
```

---

## 🎯 MSW → Railsエンドポイント対応表

### Grid Data API

| MSW Handler | Rails Route | Controller#Action |
|------------|-------------|-------------------|
| `GET /api/epic_ladder/projects/:projectId/grid` | `GET /api/epic_ladder/projects/:project_id/grid` | `EpicLadder::GridController#show` |
| `POST /api/epic_ladder/projects/:projectId/grid/move_feature` | `POST /api/epic_ladder/projects/:project_id/grid/move_feature` | `EpicLadder::GridController#move_feature` |
| `GET /api/epic_ladder/projects/:projectId/grid/updates` | `GET /api/epic_ladder/projects/:project_id/grid/updates` | `EpicLadder::GridController#updates` |
| `POST /api/epic_ladder/projects/:projectId/grid/reset` | `POST /api/epic_ladder/projects/:project_id/grid/reset` | `EpicLadder::GridController#reset` |

### Epic CRUD API

| MSW Handler | Rails Route | Controller#Action |
|------------|-------------|-------------------|
| `POST /api/epic_ladder/projects/:projectId/epics` | `POST /api/epic_ladder/projects/:project_id/epics` | `EpicLadder::EpicsController#create` |

### Version CRUD API

| MSW Handler | Rails Route | Controller#Action |
|------------|-------------|-------------------|
| `POST /api/epic_ladder/projects/:projectId/versions` | `POST /api/epic_ladder/projects/:project_id/versions` | `EpicLadder::VersionsController#create` |

### Feature Cards API

| MSW Handler | Rails Route | Controller#Action |
|------------|-------------|-------------------|
| `POST /api/epic_ladder/projects/:projectId/cards` | `POST /api/epic_ladder/projects/:project_id/cards` | `EpicLadder::CardsController#create` |
| `POST /api/epic_ladder/projects/:projectId/cards/:featureId/user_stories` | `POST /api/epic_ladder/projects/:project_id/cards/:feature_id/user_stories` | `EpicLadder::CardsController#create_user_story` |

### UserStory子要素 CRUD API

| MSW Handler | Rails Route | Controller#Action |
|------------|-------------|-------------------|
| `POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/tasks` | `POST /api/epic_ladder/projects/:project_id/cards/user_stories/:user_story_id/tasks` | `EpicLadder::CardsController#create_task` |
| `POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/tests` | `POST /api/epic_ladder/projects/:project_id/cards/user_stories/:user_story_id/tests` | `EpicLadder::CardsController#create_test` |
| `POST /api/epic_ladder/projects/:projectId/cards/user_stories/:userStoryId/bugs` | `POST /api/epic_ladder/projects/:project_id/cards/user_stories/:user_story_id/bugs` | `EpicLadder::CardsController#create_bug` |

---

## 📄 ファイル詳細

### 1. `config/routes.rb`
**責務**: MSW準拠のエンドポイント定義
**重要ポイント**:
- 全エンドポイントが `/api/epic_ladder/projects/:project_id/` で統一
- MSW handlers.ts と完全一致
- `defaults: { format: 'json' }` でJSON API専用

---

### 2. `app/controllers/epic_ladder/base_api_controller.rb`
**責務**: API共通基盤機能
**提供機能**:
- 統一レスポンス形式 (`render_success`, `render_error`)
- 例外ハンドリング (`EpicLadder::PermissionDenied`, `EpicLadder::WorkflowViolation`)
- 認証処理 (`api_require_login`, セッション/APIトークン両対応)
- パフォーマンス監視 (`log_performance_metrics`)

**カスタム例外クラス**:
```ruby
module EpicLadder
  class EpicLadderError < StandardError
  class PermissionDenied < EpicLadderError
  class WorkflowViolation < EpicLadderError
end
```

---

### 3. `app/controllers/epic_ladder/grid_controller.rb`
**責務**: グリッドデータ取得・操作API
**アクション一覧**:
- `show`: グリッド全体データ取得 (Normalized API形式)
- `move_feature`: Feature移動 + Version伝播
- `create_epic`: Epic新規作成
- `create_version`: Version新規作成
- `propagate_version`: Version自動伝播
- `move_card`: カード移動 (設計書準拠)
- `real_time_updates`: リアルタイム更新取得 (ポーリング用)

**現在の実装状況**:
- ❌ Service層への依存が残存 (`EpicLadder::FeatureMoveService` など)
- ⚠️ Fat Model原則への移行が必要

---

### 4. `app/controllers/epic_ladder/cards_controller.rb`
**責務**: Feature/UserStory CRUD操作API
**アクション一覧**:
- `index`: Feature Card一覧取得
- `create`: Feature Card作成
- `update`: Feature Card更新
- `show`: Feature Card詳細取得
- `create_user_story`: UserStory作成
- `update_user_story`: UserStory更新
- `destroy_user_story`: UserStory削除
- `create_task`: Task作成
- `create_test`: Test作成
- `create_bug`: Bug作成
- `update_item`: Task/Test/Bug更新（共通）
- `destroy_item`: Task/Test/Bug削除（共通）
- `bulk_update_user_stories`: 複数UserStory一括更新

**現在の実装状況**:
- ❌ Service層への依存が残存 (15個以上のService参照)
- ⚠️ 655行の巨大コントローラー (Fat Controller)
- ⚠️ Fat Model原則への移行が必要

---

### 5. `app/models/epic_ladder/tracker_hierarchy.rb`
**責務**: トラッカー階層制約管理
**提供機能**:
- トラッカー名取得 (`tracker_names`)
- 階層レベル取得 (`level`)
- 親子関係バリデーション (`valid_parent?`)
- 階層ルート取得 (`root_tracker`)

**トラッカー階層定義**:
```
Epic (Level 0)
 └─ Feature (Level 1)
     └─ UserStory (Level 2)
         ├─ Task (Level 3)
         ├─ Test (Level 3)
         └─ Bug (Level 3)
```

---

## 🔧 今後の改善方針 (Fat Model, Skinny Controller)

### Service層削除対象 (Modelに統合)

以下のService層を全て削除し、Issueモデルに統合する:

| Service | 移行先 | 優先度 |
|---------|--------|--------|
| `EpicLadder::FeatureMoveService` | `Issue#move_to_cell` | 🔴 High |
| `EpicLadder::EpicCreationService` | `Issue.create_epic` | 🔴 High |
| `EpicLadder::VersionPropagationService` | `Issue#propagate_version_to_children` | 🔴 High |
| `EpicLadder::CardMoveService` | `Issue#move_card` | 🟡 Medium |
| `EpicLadder::FeatureCreationService` | `Issue.create_feature` | 🟡 Medium |
| `EpicLadder::UserStoryCreationService` | `Issue.create_user_story` | 🟡 Medium |
| `EpicLadder::TaskCreationService` | `Issue.create_task` | 🟡 Medium |
| `EpicLadder::TestCreationService` | `Issue.create_test` | 🟡 Medium |
| `EpicLadder::BugCreationService` | `Issue.create_bug` | 🟡 Medium |
| その他10個以上のService | Issueモデルに統合 | 🟢 Low |

### Controller簡素化目標

**現状**:
- `GridController`: 455行 (Fat Controller)
- `CardsController`: 655行 (超Fat Controller)

**目標**:
- 各アクション: 10-30行以内
- ビジネスロジック: 0行 (全てModelに委譲)
- 総行数: 100-200行程度

**理想的なControllerの例**:
```ruby
module EpicLadder
  class GridController < BaseApiController
    def show
      grid_data = @project.epic_ladder_data(User.current, filter_params)
      render_success(grid_data)
    end

    def move_feature
      feature = Issue.find(params[:feature_id])
      feature.move_to_cell(
        params[:target_epic_id],
        params[:target_version_id],
        User.current
      )
      render_success(feature: feature.as_normalized_json)
    rescue Issue::PermissionError => e
      render_error(e.message, :forbidden)
    end
  end
end
```

---

## ✅ リファクタリング完了項目

- ✅ `module Kanban` → `module EpicLadder` に全変更完了
- ✅ routes.rb を MSW準拠エンドポイントに変更完了
- ✅ カスタム例外クラスを `EpicLadder` 名前空間に統一
- ✅ `app/controllers/concerns/kanban_api_concern.rb` → `epic_ladder_api_concern.rb` にリネーム
- ✅ ディレクトリ構造が既に `epic_ladder/` に統一済み

---

## 🚧 未実装項目

### 必要なController (MSW準拠)

現在、以下のControllerが未実装:

1. **`EpicLadder::EpicsController`**
   - `create`: Epic作成 (現在GridController#create_epicに実装済み)
   - → GridControllerから分離が必要

2. **`EpicLadder::VersionsController`**
   - `create`: Version作成 (現在GridController#create_versionに実装済み)
   - → GridControllerから分離が必要

### 推奨アクション

**Option A: GridControllerから分離**
- `EpicsController`, `VersionsController` を新規作成
- GridControllerの`create_epic`, `create_version`を移動
- routes.rbは既に対応済み

**Option B: Routesを修正してGridControllerに集約**
- routes.rbの `epic_ladder/epics#create` を `epic_ladder/grid#create_epic` に変更
- routes.rbの `epic_ladder/versions#create` を `epic_ladder/grid#create_version` に変更
- Controller構造をシンプルに保つ

**推奨**: Option A (RESTful原則に準拠)

---

## 📚 関連ドキュメント

- **アーキテクチャ規約**: `@vibes/rules/backend_standards.md`
- **協働規約**: `@vibes/rules/ai_collaboration_redmine.md`
- **MSW Handlers**: `kanban/src/mocks/handlers.ts`
- **API型定義 (SSoT)**: `kanban/src/types/normalized-api.ts`

---

## 🔍 検証コマンド

```bash
# エンドポイント一覧確認
bundle exec rake routes | grep epic_ladder

# Controllerファイル確認
find app/controllers -name "*.rb" | xargs grep "module EpicLadder"

# Modelファイル確認
find app/models -name "*.rb" | xargs grep "module EpicLadder"

# Service参照確認 (削除対象)
grep -r "EpicLadder::.*Service" app/controllers/
```

---

**最終更新**: 2025-10-04
**次のステップ**: EpicsController, VersionsController の実装
