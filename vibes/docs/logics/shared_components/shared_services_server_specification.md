# 共通サービス サーバーサイド詳細設計書

## 🔗 関連ドキュメント
- @vibes/specs/ui/shared_services_wireframe.drawio
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/shared_components/shared_components_specification.md

## 1. 設計概要

### 1.1 設計目的・背景
**なぜこの共通サービス実装が必要なのか**
- ビジネス要件：Kanbanコンポーネント間で共有される横断的機能の統一実装
- ユーザー価値：一貫したセキュリティ、パフォーマンス、ユーザビリティの提供
- システム価値：コード重複排除、保守性向上、品質標準化、運用効率化

### 1.2 設計方針
**どのようなアプローチで実現するか**
- 主要設計思想：関心の分離、単一責任原則、依存性注入、設定駆動
- 技術選択理由：Rails Service Object パターン、Redis キャッシング、非同期処理
- 制約・前提条件：Redmine Core統合、プラグイン間互換性、パフォーマンス要求

## 2. 機能要求仕様

### 2.1 主要機能
```mermaid
mindmap
  root((共通サービス))
    認証・認可サービス
      権限チェック
      セッション管理
      ワークフロー制約
      階層制約管理
    キャッシングサービス
      データキャッシュ
      キャッシュ無効化
      ウォームアップ
      分散キャッシュ
    通知サービス
      リアルタイム通知
      メール通知
      アクティビティログ
      ブロードキャスト
    バリデーションサービス
      移動制約チェック
      階層整合性
      ワークフロールール
      一括操作検証
    エラーハンドリング
      例外分類
      構造化エラー応答
      ログ管理
      監査証跡
    ユーティリティサービス
      データシリアライズ
      メタデータ生成
      設定管理
      監視メトリクス
```

### 2.2 機能詳細
| 機能ID | 機能名 | 説明 | 優先度 | 受容条件 |
|--------|--------|------|---------|----------|
| SS001 | 統一認証・認可 | Redmine権限モデル統合、階層制約チェック | High | 権限チェック100%、セキュリティ保証 |
| SS002 | 高性能キャッシング | Redis分散キャッシュ、自動無効化 | High | 90%キャッシュヒット率、5倍高速化 |
| SS003 | リアルタイム通知 | WebSocket/メール通知、アクティビティログ | Medium | 3秒以内配信、通知漏れゼロ |
| SS004 | 包括的バリデーション | 移動・階層・ワークフロー制約の統合検証 | High | ルール違反100%検出、詳細エラー |
| SS005 | 統一エラーハンドリング | 構造化例外処理、監査ログ、復旧支援 | Medium | 全例外捕捉、トレーサビリティ |

## 3. UI/UX設計仕様

### 3.1 サービス連携フロー
```mermaid
graph TD
    A[Controller層] --> B[認証・認可サービス]
    B --> C[バリデーションサービス]
    C --> D[ビジネスロジック実行]
    D --> E[キャッシングサービス]
    E --> F[通知サービス]
    F --> G[レスポンス生成]

    H[エラー発生] --> I[エラーハンドリングサービス]
    I --> J[ログ記録]
    J --> K[構造化エラー応答]

    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style I fill:#ffebee
```

### 3.2 権限チェック状態遷移
```mermaid
stateDiagram-v2
    [*] --> 権限要求
    権限要求 --> ユーザー認証: 認証情報確認
    ユーザー認証 --> プロジェクト権限: 認証成功
    ユーザー認証 --> 認証失敗: 認証情報不正
    プロジェクト権限 --> 操作権限: プロジェクトアクセス可
    プロジェクト権限 --> 権限不足: プロジェクト権限なし
    操作権限 --> 階層制約: 基本権限OK
    操作権限 --> 権限不足: 基本権限不足
    階層制約 --> 権限承認: 制約チェック通過
    階層制約 --> 制約違反: 階層ルール違反
    権限承認 --> [*]
    認証失敗 --> [*]
    権限不足 --> [*]
    制約違反 --> [*]
```

### 3.3 キャッシング戦略シーケンス
```mermaid
sequenceDiagram
    participant C as Controller
    participant CS as CacheService
    participant Redis as Redis Cache
    participant DB as Database
    participant NS as NotificationService

    C->>CS: get_kanban_data(project, user, filters)
    CS->>Redis: check_cache(cache_key)
    alt Cache Hit
        Redis->>CS: cached_data
        CS->>C: cached_data
    else Cache Miss
        CS->>DB: load_fresh_data
        DB->>CS: fresh_data
        CS->>Redis: store_cache(fresh_data)
        CS->>C: fresh_data
    end

    Note over C,NS: データ更新時のキャッシュ無効化
    C->>CS: invalidate_cache(affected_keys)
    CS->>Redis: delete_cache_keys
    CS->>NS: notify_cache_invalidation
```

## 4. データ設計

### 4.1 サービス共通データ構造
```mermaid
erDiagram
    KANBAN_USER_PREFERENCES {
        id integer PK
        user_id integer FK
        project_id integer FK
        default_expanded boolean
        auto_refresh boolean
        column_widths json
        filter_settings json
        created_at datetime
        updated_at datetime
    }

    KANBAN_PERMISSIONS_CACHE {
        cache_key string PK
        user_id integer FK
        project_id integer FK
        permissions json
        expires_at datetime
    }

    KANBAN_ACTIVITY_LOGS {
        id integer PK
        user_id integer FK
        project_id integer FK
        target_type string
        target_id integer
        action string
        details json
        request_id string
        created_at datetime
    }

    KANBAN_ERROR_LOGS {
        id integer PK
        error_class string
        error_message text
        context json
        request_id string
        user_id integer FK
        project_id integer FK
        created_at datetime
    }

    KANBAN_USER_PREFERENCES }|--|| USERS : "user"
    KANBAN_USER_PREFERENCES }|--|| PROJECTS : "project"
    KANBAN_PERMISSIONS_CACHE }|--|| USERS : "user"
    KANBAN_ACTIVITY_LOGS }|--|| USERS : "user"
    KANBAN_ERROR_LOGS }|--|| USERS : "user"
```

### 4.2 サービス間データフロー
```mermaid
flowchart LR
    A[ユーザー要求] --> B[認証サービス]
    B --> C[権限キャッシュ確認]
    C --> D[バリデーションサービス]
    D --> E[ビジネスロジック]
    E --> F[データキャッシュ更新]
    F --> G[通知配信]
    G --> H[アクティビティログ]

    I[エラー発生] --> J[エラー分類]
    J --> K[エラーログ記録]
    K --> L[通知送信]
    L --> M[復旧処理]

    N[定期処理] --> O[キャッシュクリーンアップ]
    O --> P[統計収集]
    P --> Q[監視メトリクス更新]
```

## 5. アーキテクチャ設計

### 5.1 システム構成
```mermaid
C4Context
    Person(user, "ユーザー", "システム利用者")
    System(services, "共通サービス層", "横断的機能提供")

    System_Ext(redmine, "Redmine Core", "認証・権限・データ基盤")
    SystemDb(db, "Database", "永続化・トランザクション")
    SystemDb(redis, "Redis Cluster", "キャッシュ・セッション・通知")
    System_Ext(mail, "Mail System", "メール通知配信")
    System_Ext(monitor, "Monitoring", "ログ・メトリクス・アラート")

    Rel(user, services, "機能利用")
    Rel(services, redmine, "認証・権限・データ連携")
    Rel(services, db, "設定・ログ永続化")
    Rel(services, redis, "高速キャッシュ・リアルタイム通信")
    Rel(services, mail, "メール通知")
    Rel(services, monitor, "監視データ送信")
```

### 5.2 サービス層構成
```mermaid
C4Component
    Component(auth, "PermissionService", "Ruby Service", "認証・認可・権限管理")
    Component(cache, "CacheService", "Ruby Service", "分散キャッシング・無効化")
    Component(notify, "NotificationService", "Ruby Service", "リアルタイム・メール通知")
    Component(valid, "ValidationService", "Ruby Service", "ルール・制約バリデーション")
    Component(error, "ErrorHandlingService", "Ruby Service", "例外処理・ログ管理")
    Component(util, "SerializerService", "Ruby Service", "データ変換・メタデータ")

    Rel(auth, cache, "権限情報キャッシュ")
    Rel(valid, auth, "権限確認依頼")
    Rel(notify, cache, "通知データキャッシュ")
    Rel(error, notify, "エラー通知送信")
    Rel(util, cache, "シリアライズ結果キャッシュ")
```

## 6. インターフェース設計

### 6.1 共通サービス インターフェース
```ruby
# 共通サービス統一インターフェース（疑似コード）
module Kanban
  class ServiceBase
    # 共通初期化
    def initialize(context = {})
      @project = context[:project]
      @user = context[:user]
      @request_id = context[:request_id] || SecureRandom.uuid
    end

    # 結果オブジェクト標準化
    class ServiceResult
      attr_reader :success, :data, :errors, :metadata

      def initialize(success:, data: nil, errors: [], metadata: {})
        @success = success
        @data = data
        @errors = errors
        @metadata = metadata.merge(
          timestamp: Time.zone.now.iso8601,
          service: self.class.name
        )
      end

      def success?
        @success
      end

      def failed?
        !@success
      end
    end
  end

  # 権限サービス
  class PermissionService < ServiceBase
    def check_kanban_access(user, project, operation)
      ServiceResult.new(
        success: permission_granted?,
        data: { allowed_operations: calculate_permissions },
        errors: permission_granted? ? [] : ['Access denied'],
        metadata: { operation: operation, checked_at: Time.zone.now }
      )
    end
  end

  # キャッシングサービス
  class CacheService < ServiceBase
    def get_or_set(key, expires_in: 15.minutes, &block)
      ServiceResult.new(
        success: true,
        data: Rails.cache.fetch(key, expires_in: expires_in, &block),
        metadata: { cache_key: key, expires_in: expires_in }
      )
    end
  end
end
```

### 6.2 通知システム インターフェース
```mermaid
sequenceDiagram
    participant BS as BusinessService
    participant NS as NotificationService
    participant WS as WebSocket
    participant MS as MailService
    participant AL as ActivityLogger

    BS->>NS: notify_issue_update(issue, user, action)
    NS->>NS: build_notification_data

    par リアルタイム通知
        NS->>WS: broadcast_to_project(data)
        WS->>Users: WebSocket配信
    and メール通知
        NS->>MS: send_email_notification
        MS->>Users: メール送信
    and アクティビティログ
        NS->>AL: log_activity(action, details)
        AL->>Database: ログ永続化
    end

    NS->>BS: NotificationResult
```

## 7. 非機能要求

### 7.1 パフォーマンス要求
| 項目 | 要求値 | 測定方法 |
|------|---------|----------|
| 権限チェック処理 | 50ms以内 | キャッシュヒット率90%以上 |
| キャッシュアクセス | 10ms以内 | Redis レスポンス時間 |
| 通知配信時間 | 3秒以内 | WebSocket配信完了時間 |
| バリデーション処理 | 100ms以内 | 複数ルール同時チェック |

### 7.2 可用性・信頼性要求
- **可用性**: Redis Cluster冗長化、99.9%稼働率
- **整合性**: キャッシュ-DB間データ整合性保証、楽観的ロック
- **耐障害性**: サービス障害時のフォールバック処理、サーキットブレーカー

## 8. 実装指針

### 8.1 技術スタック
- **フレームワーク**: Ruby on Rails Service Object パターン
- **キャッシュ**: Redis Cluster (分散キャッシング・高可用性)
- **非同期処理**: Sidekiq/ActiveJob (バックグラウンドジョブ)
- **監視**: Prometheus/Grafana (メトリクス・アラート)
- **ログ**: Elasticsearch/Kibana (構造化ログ・検索)

### 8.2 実装パターン
```ruby
# 共通サービス実装パターン（疑似コード）
module Kanban
  class ValidationService < ServiceBase
    # 1. メイン処理メソッド
    def validate_issue_move(issue, target_column, target_version = nil)
      return early_validation_failure unless basic_checks_pass?

      errors = []
      errors.concat(validate_status_transition(issue, target_column))
      errors.concat(validate_hierarchy_constraints(issue, target_column))
      errors.concat(validate_version_assignment(issue, target_version)) if target_version

      ServiceResult.new(
        success: errors.empty?,
        data: { validated_issue: issue, target_column: target_column },
        errors: errors,
        metadata: build_validation_metadata
      )
    end

    # 2. プライベートメソッド（単一責任）
    private

    def validate_status_transition(issue, target_column)
      # 具体的なバリデーションロジック
    end

    # 3. 結果メタデータ構築
    def build_validation_metadata
      {
        validation_time: Time.zone.now,
        rules_checked: @checked_rules,
        performance_metrics: @metrics
      }
    end
  end
end
```

### 8.3 エラーハンドリング戦略
```mermaid
flowchart TD
    A[サービス実行] --> B{例外発生}
    B -->|なし| C[正常結果返却]
    B -->|あり| D[例外種別判定]

    D -->|ValidationError| E[バリデーションエラー処理]
    D -->|PermissionError| F[権限エラー処理]
    D -->|SystemError| G[システムエラー処理]
    D -->|UnknownError| H[未知エラー処理]

    E --> I[構造化エラー応答]
    F --> I
    G --> J[エラーログ記録]
    H --> J

    J --> K[管理者通知]
    K --> I
    I --> L[クライアント応答]
```

## 9. テスト設計

テスト戦略・ケース設計・実装については以下を参照：
- @vibes/rules/testing/server_side_testing_strategy.md
- @vibes/rules/testing/shared_services_server_test_specification.md

## 10. 運用・保守設計

### 10.1 監視・メトリクス設計
- **パフォーマンス監視**: サービス応答時間・スループット・エラー率
- **リソース監視**: Redis メモリ使用量・接続数・キュー長
- **ビジネス監視**: 権限チェック頻度・キャッシュヒット率・通知配信成功率

### 10.2 運用自動化
- **ヘルスチェック**: 各サービス生存監視・依存システム接続確認
- **自動復旧**: Redis再接続・キャッシュ再構築・通知リトライ
- **キャパシティ管理**: Redis クラスター自動スケーリング・ログローテーション

---

*共通サービス サーバーサイド実装は、Kanban システム全体の品質・パフォーマンス・セキュリティを支える横断的基盤です。統一されたアーキテクチャパターンにより、保守性と拡張性を重視した設計を実現します。*