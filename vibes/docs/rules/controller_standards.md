# Controller実装規約

## 責務分離原則

### Controller層の責務
- HTTP要求受付・レスポンス制御
- 権限検証・パラメータ検証
- サービス層呼び出し・結果シリアライゼーション

### 禁止事項
- ビジネスロジック実装
- 直接DB操作
- 複雑データ変換

## 共通処理規約

### Concern活用
```ruby
module KanbanApiConcern
  included do
    before_action :require_login, :find_project, :authorize_kanban_access
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  end

  def serialize_issue(issue)
    { id: issue.id, subject: issue.subject, tracker: issue.tracker.name }
  end
end
```

### エラーハンドリング階層
1. **専用例外**: `StateTransitionService::InvalidTransitionError`
2. **汎用例外**: `ActiveRecord::RecordNotFound`
3. **予期外例外**: `StandardError`

## パフォーマンス要件

### N+1対策必須
```ruby
@issues = query.issues.includes(:tracker, :status, :assigned_to, :fixed_version)
version_ids = issues.pluck(:fixed_version_id).compact.uniq
```

### キャッシュ戦略
```ruby
cache_key = "kanban_task_#{issue.id}_#{issue.updated_on.to_i}"
Rails.cache.fetch(cache_key, expires_in: 30.seconds) { build_data(issue) }
```

## セキュリティ規約

### 権限チェック
```ruby
# 必須: before_action
before_action :authorize_kanban_access

def authorize_kanban_access
  deny_access unless User.current.allowed_to?(:view_kanban, @project)
end
```

### パラメータ検証
```ruby
def filter_params
  params.permit(:version_id, :assignee_id, tracker_ids: [])
end

def validate_filter_values(filter_params)
  valid_tracker_ids = @project.trackers.pluck(:id).map(&:to_s)
  filter_params[:tracker_ids] = filter_params[:tracker_ids]&.select { |id| valid_tracker_ids.include?(id) }
end
```

## API設計規約

### RESTful設計
- `GET /kanban/projects/:id/cards` - データ取得
- `POST /kanban/projects/:id/move_card` - 状態変更
- `POST /kanban/projects/:id/assign_version` - バージョン割当

### レスポンス形式
```ruby
# 成功
{ success: true, data: result, meta: { total_count: count } }

# エラー
{ success: false, error: message, error_code: 'CODE' }
```

## ログ規約

### レベル分け
- `info`: API呼び出し・処理完了
- `debug`: パラメータ詳細・中間結果
- `warn`: 制限到達・非推奨使用
- `error`: 例外・失敗

### パフォーマンス監視
```ruby
start_time = Time.current
# 処理実行
Rails.logger.info "[PERF] #{action_name}: #{(Time.current - start_time) * 1000}ms"
```

## 実装テンプレート

```ruby
class Kanban::ExampleController < ApplicationController
  include KanbanApiConcern

  def action_name
    result = ExampleService.execute(@project, validated_params)

    if result[:success]
      render json: success_response(result)
    else
      render json: error_response(result), status: :unprocessable_entity
    end
  rescue ExampleService::CustomError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def validated_params
    params.permit(:param1, :param2).tap { |p| validate_params(p) }
  end
end
```