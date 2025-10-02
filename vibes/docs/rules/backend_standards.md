# Backend実装規約 (Controller + Service)

## 📋 目次
- [Backend実装規約 (Controller + Service)](#backend実装規約-controller-service) (L1-29)
  - [1. Controller層の原則](#1-controller層の原則) (L10-29)
    - [1.1 責務](#11-責務) (L12-24)
    - [1.2 必須パターン](#12-必須パターン) (L26-29)
- [app/controllers/concerns/kanban_api_concern.rb に共通処理を集約](#appcontrollersconcernskanban_api_concernrb-に共通処理を集約) (L30-62)
    - [1.3 パフォーマンス要件](#13-パフォーマンス要件) (L39-48)
    - [1.4 セキュリティ必須項目](#14-セキュリティ必須項目) (L50-62)
- [Strong Parameters必須](#strong-parameters必須) (L63-64)
- [プロジェクト配下のリソース検証必須](#プロジェクト配下のリソース検証必須) (L66-221)
    - [1.5 レスポンス形式統一](#15-レスポンス形式統一) (L70-80)
    - [1.6 参照実装](#16-参照実装) (L82-86)
  - [2. Service層の原則](#2-service層の原則) (L88-192)
    - [2.1 責務](#21-責務) (L90-101)
    - [2.2 単一責任の原則](#22-単一責任の原則) (L103-122)
    - [2.3 戻り値統一規約](#23-戻り値統一規約) (L124-136)
    - [2.4 カスタム例外定義](#24-カスタム例外定義) (L138-148)
    - [2.5 トランザクション制御](#25-トランザクション制御) (L150-163)
    - [2.6 N+1対策パターン](#26-n1対策パターン) (L165-172)
    - [2.7 冪等性保証](#27-冪等性保証) (L174-186)
    - [2.8 参照実装](#28-参照実装) (L188-192)
  - [3. 実装チェックリスト](#3-実装チェックリスト) (L194-214)
    - [Controller実装時](#controller実装時) (L196-203)
    - [Service実装時](#service実装時) (L205-214)
  - [🔗 関連ドキュメント](#-関連ドキュメント) (L216-221)
## 1. Controller層の原則

### 1.1 責務

**やるべきこと**:
- HTTP要求受付・レスポンス制御
- 権限検証 (`before_action :authorize_kanban_access`)
- パラメータ検証 (Strong Parameters)
- Service層呼び出し
- 結果のシリアライゼーション (JSON化)

**やってはいけないこと**:
- ❌ ビジネスロジック実装
- ❌ 直接DB操作 (`Issue.find.update!`など)
- ❌ 複雑なデータ変換

### 1.2 必須パターン

**Concern活用**:
```ruby
# app/controllers/concerns/kanban_api_concern.rb に共通処理を集約
include KanbanApiConcern
```

**エラーハンドリング階層**:
1. **専用例外** - `KanbanService::InvalidTransitionError` → 400 Bad Request
2. **汎用例外** - `ActiveRecord::RecordNotFound` → 404 Not Found
3. **予期外** - `StandardError` → 500 Internal Server Error

### 1.3 パフォーマンス要件

**N+1対策必須**:
- `includes(:tracker, :status, :assigned_to, :fixed_version)` で事前読み込み
- Bulletツールで検出・修正

**API応答時間基準**:
- 平均: **200ms以内**
- 95パーセンタイル: **500ms以内**
- クエリ数: **3クエリ以下**

### 1.4 セキュリティ必須項目

**権限チェック**:
```ruby
before_action :authorize_kanban_access

def authorize_kanban_access
  deny_access unless User.current.allowed_to?(:view_kanban, @project)
end
```

**パラメータ検証**:
```ruby
# Strong Parameters必須
params.permit(:version_id, :assignee_id, tracker_ids: [])

# プロジェクト配下のリソース検証必須
@project.trackers.pluck(:id).include?(params[:tracker_id])
```

### 1.5 レスポンス形式統一

**成功**:
```ruby
{ success: true, data: result, meta: { total_count: count } }
```

**エラー**:
```ruby
{ success: false, error: message, error_code: 'VALIDATION_ERROR' }
```

### 1.6 参照実装

**実装済みController**: `app/controllers/kanban/`配下のファイルを参照してください。

---

## 2. Service層の原則

### 2.1 責務

**やるべきこと**:
- ビジネスロジック実装
- データ変換・加工
- 複雑な計算・判定
- 非同期Job呼び出し

**やってはいけないこと**:
- ❌ HTTP要求処理 (Controller責務)
- ❌ View描画処理
- ❌ 直接権限チェック (Controller責務)

### 2.2 単一責任の原則

**Good**: 1つのServiceは1つの責務のみ
```ruby
class Kanban::VersionPropagationService
  # バージョン伝播のみに特化
end

class Kanban::TestGenerationService
  # Test自動生成のみに特化
end
```

**Bad**: 複数責務混在
```ruby
class BadKanbanService
  def do_everything  # バージョン・状態・検証すべて ❌
  end
end
```

### 2.3 戻り値統一規約

**必須**: 全Serviceは以下の形式で戻り値を統一

**成功時**:
```ruby
{ success: true, data: result_data, meta: additional_info }
```

**失敗時**:
```ruby
{ success: false, error: error_message, error_code: 'CODE', details: {...} }
```

### 2.4 カスタム例外定義

**業務固有エラーは専用例外を定義**:
```ruby
module Kanban
  class StateTransitionService
    class InvalidTransitionError < StandardError; end
    class TransitionBlockedError < StandardError; end
  end
end
```

### 2.5 トランザクション制御

**複数更新は必ずトランザクション内で実行**:
```ruby
def execute
  ActiveRecord::Base.transaction do
    step1_result = execute_step1
    step2_result = execute_step2(step1_result)
    { success: true, data: step2_result }
  end
rescue CustomError => e
  { success: false, error: e.message, error_code: 'CUSTOM_ERROR' }
end
```

### 2.6 N+1対策パターン

**必須**:
- `includes` - 関連データ事前読み込み
- `pluck` - 必要カラムのみ取得
- `find_each(batch_size: 100)` - 大量データ処理

**実装例は実装済みServiceを参照**してください。

### 2.7 冪等性保証

**非同期Job・API呼び出しは冪等性を確保**:
```ruby
def idempotent_operation(user_story)
  # 既存レコード確認
  existing = find_existing_test(user_story)
  return existing if existing && !options[:force_recreate]

  # 作成処理
  create_new_test(user_story)
end
```

### 2.8 参照実装

**実装済みService**: `app/services/kanban/`配下のファイルを参照してください。

---

## 3. 実装チェックリスト

### Controller実装時

- [ ] `KanbanApiConcern` をincludeしている
- [ ] `before_action :authorize_kanban_access` を設定
- [ ] Strong Parametersでパラメータ検証
- [ ] Service呼び出し結果を統一形式でレスポンス
- [ ] エラーハンドリング3階層を実装
- [ ] N+1問題がないことをBulletで確認

### Service実装時

- [ ] 単一責任を守っている (1 Service = 1 責務)
- [ ] 戻り値が統一形式 (`{success: true/false, ...}`)
- [ ] カスタム例外を定義している
- [ ] トランザクション内で複数更新を実行
- [ ] N+1対策 (includes/pluck/find_each) を実施
- [ ] 冪等性を確保 (非同期Job・API呼び出し)

---

## 🔗 関連ドキュメント

- **技術アーキテクチャ**: @vibes/rules/technical_architecture_quickstart.md
- **テスト戦略**: @vibes/rules/testing_strategy.md
- **実装済みController**: `app/controllers/kanban/`
- **実装済みService**: `app/services/kanban/`
