# Backend実装規約 (Fat Model, Skinny Controller)

## 0. 設計思想

**Fat Model, Skinny Controller原則**:
- ✅ ビジネスロジックはModelに集約
- ✅ ControllerはHTTP処理のみ
- ✅ Serviceは外部API依存のみ（最小限）

**レイヤー責任分担**:

| レイヤー | 責務 | 禁止事項 |
|---------|------|---------|
| **Model** | ビジネスロジック、バリデーション、データ整合性、統計計算 | HTTP処理、JSON変換 |
| **Controller** | HTTP要求/応答、権限検証、JSON変換、Model呼び出し | ビジネスロジック、DB直接操作 |
| **Service** | 外部API連携のみ（存在不要の場合多い） | ビジスロジック |

---

## 1. Model層 (Fat Model)

### 1.1 責務

**やるべきこと**:
- ✅ ビジネスロジック実装
- ✅ データバリデーション・整合性保証
- ✅ トランザクション制御
- ✅ 統計計算・関連データ取得

**禁止事項**:
- ❌ HTTP要求処理・JSON変換

### 1.2 実装パターン

**ドメインロジック**:
```ruby
class Issue < ApplicationRecord
  # Epic作成
  def self.create_epic(params, project, user)
    transaction do
      epic_tracker = project.trackers.find_by(name: TrackerHierarchy.epic_name)
      raise "Epic tracker not found" unless epic_tracker
      create!(project: project, tracker: epic_tracker, subject: params[:subject], author: user)
    end
  end

  # カード移動
  def move_to_cell(epic_id, version_id, user)
    raise "Permission denied" unless user.allowed_to?(:edit_issues, project)
    transaction do
      update!(parent_issue_id: epic_id, fixed_version_id: version_id)
      propagate_version_to_children(version_id) if tracker.name == 'UserStory'
    end
  end
end
```

**統計計算**:
```ruby
class Project < ApplicationRecord
  def kanban_grid_data(user, filters = {})
    {
      entities: build_normalized_entities(filters),
      grid: build_grid_index,
      metadata: build_metadata(user),
      statistics: kanban_statistics
    }
  end

  def kanban_statistics
    {
      overview: { total_issues: issues.count, completed_issues: issues_closed.count },
      by_version: calculate_version_statistics,
      by_status: calculate_status_distribution
    }
  end
end
```

**N+1対策**:
```ruby
def kanban_grid_data(user, filters)
  epics = issues
    .includes(:tracker, :status, :fixed_version, :assigned_to, :children)
    .where(trackers: { name: 'Epic' })
    .order(:created_on)
  normalize_entities(epics)
end
```

**バリデーション**:
```ruby
class Issue < ApplicationRecord
  validates :subject, presence: true
  validate :validate_tracker_hierarchy, on: :update

  private
  def validate_tracker_hierarchy
    return unless parent_issue_id_changed?
    unless TrackerHierarchy.valid_parent?(tracker, parent.tracker)
      errors.add(:parent_issue_id, "Invalid parent tracker")
    end
  end
end
```

---

## 2. Controller層 (Skinny Controller)

### 2.1 責務

**やるべきこと**:
- ✅ HTTP要求受付・レスポンス制御
- ✅ 権限検証 (`before_action :authorize_kanban_access`)
- ✅ **Modelメソッド呼び出し**（Service呼び出しではない）
- ✅ JSON変換

**禁止事項**:
- ❌ ビジネスロジック実装
- ❌ 直接DB操作

### 2.2 実装パターン

**基本構造**:
```ruby
module Kanban
  class GridController < BaseApiController
    before_action :find_project
    before_action :authorize_kanban_access

    def show
      grid_data = @project.kanban_grid_data(User.current, filter_params)
      render_success(grid_data)
    end

    def move_feature
      feature = Issue.find(params[:feature_id])
      feature.move_to_cell(params[:target_epic_id], params[:target_version_id], User.current)
      render_success(feature)
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.message, :unprocessable_entity)
    end

    def create_epic
      epic = Issue.create_epic(epic_params, @project, User.current)
      render_success(epic, :created)
    end

    private
    def epic_params
      params.require(:epic).permit(:subject, :description, :assigned_to_id)
    end
  end
end
```

**ポイント**: Controllerは**10-30行**程度、ビジネスロジックは全てModelに委譲

**統一レスポンス**:
```ruby
module Kanban
  class BaseApiController < ApplicationController
    def render_success(data, status = :ok)
      render json: {
        success: true,
        data: data,
        meta: { timestamp: Time.current.iso8601, request_id: request.uuid }
      }, status: status
    end

    def render_error(message, status = :bad_request, code: nil)
      render json: {
        success: false,
        error: { message: message, code: code || status.to_s.upcase },
        meta: { timestamp: Time.current.iso8601, request_id: request.uuid }
      }, status: status
    end
  end
end
```

**エラーハンドリング**:
```ruby
class BaseApiController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

  private
  def handle_not_found(exception)
    render_error(exception.message, :not_found, code: 'NOT_FOUND')
  end
end
```

---

## 3. Service層 (最小限)

### 3.1 原則

- ✅ ビジネスロジックは**Model**
- ✅ 外部API連携のみ**Service**
- ❌ Service層の肥大化を避ける

### 3.2 例外: 外部API連携

**許可されるケース**:
```ruby
module Kanban
  class OpenAIIntegrationService
    def generate_test_suggestions(user_story)
      @client.chat(parameters: { model: "gpt-4", messages: [...] })
    end
  end
end

# Modelから呼ぶ
class Issue < ApplicationRecord
  def ai_test_suggestions
    service = Kanban::OpenAIIntegrationService.new(ENV['OPENAI_API_KEY'])
    service.generate_test_suggestions(self)
  end
end
```

### 3.3 削除対象Service例

**以下は全てアンチパターン（Modelに移行）**:
- `CardMoveService` → `Issue#move_to_cell`
- `EpicCreationService` → `Issue.create_epic`
- `StatisticsCalculator` → `Project#kanban_statistics`
- `GridDataBuilder` → `Project#kanban_grid_data`

---

## 4. API設計規約

### 4.1 MSW仕様準拠

**全APIはMSW handlers.tsに定義**:
- フロントエンド: `assets/javascripts/kanban/src/mocks/handlers.ts`
- バックエンド: 同じエンドポイント・レスポンス形式を実装

### 4.2 Normalized API形式

**レスポンス構造**:
```typescript
{
  success: true,
  data: {
    entities: { epics: {}, features: {}, user_stories: {}, tasks: {}, tests: {}, bugs: {}, versions: {} },
    grid: { index: {}, epic_order: [], version_order: [] },
    metadata: { project: {}, user_permissions: {}, api_version: "v1" },
    statistics: { overview: {}, by_version: {}, by_status: {}, by_tracker: {} }
  }
}
```

### 4.3 パフォーマンス要件

- 平均: **200ms以内**
- 95パーセンタイル: **500ms以内**
- N+1クエリ: **0件** (Bulletで検証)

---

## 5. 実装チェックリスト

**Model実装時**:
- [ ] ビジネスロジックをModelに実装
- [ ] バリデーションをModelに定義
- [ ] トランザクション制御を実装
- [ ] N+1対策（includes/pluck）を実施

**Controller実装時**:
- [ ] Controllerは10-30行程度
- [ ] `before_action :authorize_kanban_access` を設定
- [ ] Modelメソッド呼び出し（Serviceではない）
- [ ] `render_success`/`render_error`で統一レスポンス

**Service実装時（例外的に必要な場合のみ）**:
- [ ] 外部API連携のみに限定
- [ ] ビジネスロジックはServiceに書かない
- [ ] Modelから呼び出される設計

---

## 関連ドキュメント

- **技術アーキテクチャ**: @vibes/rules/technical_architecture_quickstart.md
- **API実装ワークフロー**: @vibes/tasks/api_implementation_workflow.md
- **テスト戦略**: @vibes/rules/backend_testing.md
- **MSW API仕様**: assets/javascripts/kanban/src/mocks/handlers.ts
- **TypeScript型定義**: assets/javascripts/kanban/src/types/normalized-api.ts
