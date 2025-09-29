# Kanban Grid サーバーサイド詳細設計書

## 🔗 関連ドキュメント
- @vibes/docs/logics/wireframe/kanban_ui_grid_layout.drawio
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/kanban_grid/kanban_grid_layout_specification.md

## 1. 設計概要

### 1.1 設計目的・背景
**なぜこのサーバーサイド実装が必要なのか**
- ビジネス要件：2次元グリッド（Epic行×Version列）データの効率的な構築・配信、リアルタイム同期
- ユーザー価値：直感的な D&D操作、バージョン管理統合、複数ユーザー協調作業支援
- システム価値：データ整合性保持、パフォーマンス最適化、拡張可能なグリッド構造

### 1.2 設計方針
**どのようなアプローチで実現するか**
- 主要設計思想：2D マトリクス構造、リアルタイム更新、階層データ整合性重視
- 技術選択理由：Rails MVC + Service層、JSON API設計、WebSocket/ポーリング併用
- 制約・前提条件：Redmine版管理統合、Issue階層準拠、マルチユーザー対応

## 2. 機能要求仕様

### 2.1 主要機能
```mermaid
mindmap
  root((Kanban Grid Server))
    グリッドデータ構築
      Epic行構築
      Version列構築
      セル内データ集約
      フィルタリング対応
    D&D操作処理
      カード移動検証
      ステータス遷移
      バージョン割当
      制約チェック
    バージョン管理統合
      Version CRUD
      Issue一括割当
      依存関係更新
      統計計算
    リアルタイム更新
      変更検出
      差分配信
      衝突解決
      同期保証
```

### 2.2 機能詳細
| 機能ID | 機能名 | 説明 | 優先度 | 受容条件 |
|--------|--------|------|---------|----------|
| GS001 | 2Dグリッド構築 | Epic×Versionマトリクス効率的構築 | High | N+1クエリ回避、3秒以内レスポンス |
| GS002 | カード移動処理 | D&D操作の状態・バージョン更新 | High | 制約検証、ロールバック対応 |
| GS003 | バージョン管理 | Version作成・更新・Issue割当 | High | 依存関係整合性、一括処理対応 |
| GS004 | リアルタイム同期 | マルチユーザー間のグリッド状態同期 | Medium | 衝突検出、差分更新配信 |
| GS005 | フィルタ・検索 | Epic・Version・ステータス・担当者フィルタ | Medium | 動的フィルタ、組み合わせ対応 |

## 3. UI/UX設計仕様

### 3.1 サーバーサイド処理フロー
```mermaid
graph TD
    A[クライアント要求] --> B[GridController]
    B --> C[権限・パラメータ検証]
    C --> D[GridDataBuilder]
    D --> E[Epic階層データ取得]
    E --> F[Version列データ構築]
    F --> G[セル内Feature集約]
    G --> H[統計・メタデータ計算]
    H --> I[JSON構造化]
    I --> J[レスポンス配信]

    style A fill:#e1f5fe
    style D fill:#f3e5f5
    style G fill:#f3e5f5
```

### 3.2 状態遷移設計
```mermaid
stateDiagram-v2
    [*] --> グリッド要求
    グリッド要求 --> データ構築: パラメータ解析
    データ構築 --> Epic取得: フィルタ適用
    Epic取得 --> Version取得: Epic階層ロード
    Version取得 --> セル構築: Version配列生成
    セル構築 --> 統計計算: Feature配置計算
    統計計算 --> レスポンス生成: メタデータ付加
    レスポンス生成 --> [*]

    グリッド要求 --> エラー応答: バリデーション失敗
    エラー応答 --> [*]
```

### 3.3 D&D操作シーケンス設計
```mermaid
sequenceDiagram
    participant C as Client
    participant GC as GridController
    participant CMS as CardMoveService
    participant DB as Database
    participant WS as WebSocket/Polling

    C->>GC: POST /grid/move_card
    GC->>GC: 権限・制約チェック
    GC->>CMS: execute(card_id, source, target)
    CMS->>DB: Issue更新処理
    CMS->>CMS: 関連Issue更新
    CMS->>GC: MoveResult
    GC->>C: 更新結果JSON

    Note over CMS,WS: リアルタイム同期
    CMS->>WS: 変更通知
    WS->>C: 他ユーザーへ変更配信
```

## 4. データ設計

### 4.1 データ構造
```mermaid
erDiagram
    ISSUES {
        id integer PK
        subject string
        tracker_id integer FK
        status_id integer FK
        parent_id integer FK
        fixed_version_id integer FK
        assigned_to_id integer FK
        updated_on datetime
    }

    VERSIONS {
        id integer PK
        project_id integer FK
        name string
        description text
        effective_date date
        status string
    }

    KANBAN_COLUMN_CONFIGS {
        id integer PK
        project_id integer FK
        column_name string
        column_position integer
        status_ids text
    }

    WORKFLOW_TRANSITIONS {
        id integer PK
        tracker_id integer FK
        old_status_id integer FK
        new_status_id integer FK
        role_id integer FK
    }

    ISSUES ||--o{ ISSUES : "parent-child"
    ISSUES }|--|| VERSIONS : "fixed_version"
    KANBAN_COLUMN_CONFIGS }|--|| PROJECTS : "project"
    WORKFLOW_TRANSITIONS }|--|| TRACKERS : "tracker"
```

### 4.2 データフロー
```mermaid
flowchart LR
    A[Project Issues] --> B[Epic フィルタリング]
    B --> C[Version 取得]
    C --> D[2D マトリクス構築]
    D --> E[Feature 配置計算]
    E --> F[統計・メタデータ生成]
    F --> G[JSON レスポンス]

    G --> H[クライアント表示]
    H --> I[D&D操作]
    I --> J[移動要求]
    J --> K[制約検証・更新]
    K --> L[関連Issue更新]
    L --> M[リアルタイム配信]
    M --> A
```

## 5. アーキテクチャ設計

### 5.1 システム構成
```mermaid
C4Context
    Person(user, "ユーザー", "複数ユーザー協調作業")
    System(grid, "Kanban Grid System", "2Dグリッドマトリクス管理")

    System_Ext(redmine, "Redmine Core", "Issue・Version管理基盤")
    SystemDb(db, "Database", "PostgreSQL/MySQL")
    SystemDb(cache, "Redis Cache", "グリッドデータキャッシュ")
    System_Ext(ws, "WebSocket/SSE", "リアルタイム通信")

    Rel(user, grid, "グリッド操作・D&D")
    Rel(grid, redmine, "Issue・Version API")
    Rel(grid, db, "グリッドデータ永続化")
    Rel(grid, cache, "構築済みグリッドキャッシュ")
    Rel(grid, ws, "リアルタイム変更配信")
```

### 5.2 コンポーネント構成
```mermaid
C4Component
    Component(grid_ctrl, "GridController", "Rails Controller", "グリッドAPI エンドポイント")
    Component(version_ctrl, "VersionsController", "Rails Controller", "Version管理API")
    Component(grid_builder, "GridDataBuilder", "Ruby Service", "2Dグリッド構築")
    Component(move_service, "CardMoveService", "Ruby Service", "D&D移動処理")
    Component(update_service, "GridUpdateService", "Ruby Service", "リアルタイム更新")

    Rel(grid_ctrl, grid_builder, "グリッド構築依頼")
    Rel(grid_ctrl, move_service, "カード移動実行")
    Rel(grid_ctrl, update_service, "差分更新取得")
    Rel(version_ctrl, grid_builder, "バージョン変更通知")
```

## 6. インターフェース設計

### 6.1 Grid Controller インターフェース
```ruby
# Grid API エンドポイント設計（疑似コード）
class GridController
  # GET /kanban/projects/:project_id/grid
  def index
    response_format: {
      grid: {
        rows: Array<EpicRow>,
        columns: Array<ColumnConfig>,
        versions: Array<Version>
      },
      metadata: {
        project: ProjectInfo,
        user_permissions: Hash,
        grid_configuration: GridConfig
      },
      statistics: {
        overview: ProjectStats,
        by_version: VersionStats,
        by_status: StatusDistribution
      }
    }
  end

  # POST /grid/move_card
  def move_card
    params: {
      card_id: Integer,
      source_cell: { epic_id, version_id, column_id },
      target_cell: { epic_id, version_id, column_id }
    }
    response_format: {
      updated_card: Issue,
      affected_cells: Array<CellUpdate>,
      statistics_update: StatsDelta
    }
  end

  # GET /grid/updates?since=timestamp
  def real_time_updates
    response_format: {
      updates: Array<IssueUpdate>,
      deleted_issues: Array<Integer>,
      grid_structure_changes: Array<GridChange>
    }
  end
end
```

### 6.2 Grid構築インターフェース
```mermaid
sequenceDiagram
    participant GC as GridController
    participant GB as GridDataBuilder
    participant DB as Database
    participant Cache as Redis

    GC->>GB: build(project, user, filters)
    GB->>Cache: check_grid_cache(cache_key)
    alt Cache Hit
        Cache->>GB: cached_grid_data
    else Cache Miss
        GB->>DB: load_filtered_epics
        GB->>DB: load_project_versions
        GB->>GB: build_2d_matrix
        GB->>Cache: store_grid_cache
    end
    GB->>GC: grid_response_data
```

## 7. 非機能要求

### 7.1 パフォーマンス要求
| 項目 | 要求値 | 測定方法 |
|------|---------|----------|
| グリッド初期表示 | 3秒以内 | Epic×Version マトリクス構築時間 |
| D&D移動処理 | 1秒以内 | カード移動〜UI更新完了時間 |
| リアルタイム更新 | 5秒以内 | 変更検出〜配信完了時間 |
| 大規模グリッド | 100 Epic × 20 Version対応 | メモリ使用量・クエリ性能 |

### 7.2 品質要求
- **可用性**: マルチユーザー同時操作99.9%成功率
- **保守性**: Service層テストカバレッジ90%以上、Controller層85%以上
- **拡張性**: 新Tracker・カスタムフィールド対応可能な抽象化

## 8. 実装指針

### 8.1 技術スタック
- **バックエンド**: Ruby on Rails 6.1+ (Redmine準拠)
- **データベース**: PostgreSQL/MySQL (複雑クエリ最適化)
- **キャッシュ**: Redis (グリッドデータ・統計キャッシュ)
- **リアルタイム**: ActionCable/Server-Sent Events
- **テスト**: RSpec + FactoryBot + JSON Schema検証

### 8.2 実装パターン
```ruby
# GridDataBuilder実装パターン（疑似コード）
class GridDataBuilder
  # 1. キャッシュ戦略
  def build
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      build_grid_structure
    end
  end

  # 2. N+1クエリ回避 + トラッカー判定システム
  def load_filtered_epics
    # ⚠️ 重要: 設定ベースのトラッカー判定
    epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]

    @project.issues
            .includes(:tracker, :status, :fixed_version,
                     children: [:tracker, :status, :fixed_version])
            .joins(:tracker)
            .where(trackers: { name: epic_tracker_name })
            # ← 'Epic'ハードコーディングではなく設定値使用
  end

  # トラッカー階層設定取得（TrackerHierarchy.rb）
  # settings = Setting.plugin_redmine_release_kanban || {}
  # {
  #   epic: settings['epic_tracker'] || 'Epic',
  #   feature: settings['feature_tracker'] || 'Feature',
  #   user_story: settings['user_story_tracker'] || 'UserStory'
  # }

  # 3. 2Dマトリクス効率構築
  def build_epic_row(epic, versions, columns)
    versions.map { |version| build_grid_cell(epic, version) }
  end
end
```

### 8.3 エラーハンドリング戦略
```mermaid
flowchart TD
    A[D&D移動要求] --> B{移動種別判定}
    B -->|列移動| C[ステータス遷移検証]
    B -->|バージョン移動| D[Version割当検証]
    B -->|Epic変更| E[階層変更検証]

    C --> F{Workflow制約}
    D --> G{Version制約}
    E --> H{階層制約}

    F -->|OK| I[移動実行]
    F -->|NG| J[制約エラー]
    G -->|OK| I
    G -->|NG| J
    H -->|OK| I
    H -->|NG| J

    I --> K[関連Issue更新]
    J --> L[エラー詳細返却]
```

## 9. テスト設計

テスト戦略・ケース設計・実装については以下を参照：
- @vibes/rules/testing/server_side_testing_strategy.md
- @vibes/rules/testing/kanban_grid_server_test_specification.md

## 10. 運用・保守設計

### 10.1 監視・ログ設計
- **パフォーマンス監視**: グリッド構築時間、D&D処理時間、メモリ使用量
- **エラートラッキング**: 移動制約違反、データ不整合、同時更新衝突
- **利用状況分析**: グリッドサイズ分布、操作頻度、リアルタイム同期負荷

### 10.2 スケーラビリティ対応
- **水平分割**: プロジェクト単位でのデータ分散
- **キャッシュ戦略**: Redis Cluster、グリッドデータ段階的キャッシュ
- **非同期処理**: 大規模一括操作のジョブキュー化

---

*Kanban Grid サーバーサイド実装は、Epic×Versionの2次元マトリクス構造を効率的に構築・配信し、リアルタイムなD&D操作とマルチユーザー協調作業を支援する基盤設計です。スケーラブルなアーキテクチャにより大規模プロジェクトでも高いパフォーマンスを実現します。*