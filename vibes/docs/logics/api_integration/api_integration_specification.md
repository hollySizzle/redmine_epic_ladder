# API統合 詳細設計書

## 🔗 関連ドキュメント
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
- @vibes/logics/ui_components/kanban_grid/kanban_grid_layout_specification.md
- @vibes/logics/data_structures/data_structures_specification.md
- @vibes/rules/technical_architecture_standards.md

## 1. 設計概要

### 1.1 設計目的・背景
**なぜこのAPI統合システムが必要なのか**
- ビジネス要件：React Frontend と Ruby Rails Backend の完全分離・独立開発可能性
- ユーザー価値：リアルタイム操作・即座フィードバック・オフライン耐性・楽観的更新
- システム価値：Redmine標準API活用・プラグイン互換性・拡張性・セキュリティ保証

### 1.2 設計方針
**どのようなアプローチで実現するか**
- 主要設計思想：RESTful API設計、レイヤード アーキテクチャ、API First開発
- 技術選択理由：JSON API（軽量）、CSRF保護（セキュリティ）、楽観的更新（UX）
- 制約・前提条件：Redmine標準API準拠、既存プラグイン互換性、認証・権限継承

## 2. 機能要求仕様

### 2.1 主要機能
```mermaid
mindmap
  root((API統合システム))
    データ取得API
      Grid Layout データ
      Feature Card 一覧
      階層構造データ
      統計・集計情報
    操作API
      Feature移動・配置
      Epic・Version作成
      Issue CRUD操作
      一括更新処理
    リアルタイム同期
      楽観的更新
      競合検出・解決
      差分更新配信
      エラー回復処理
    認証・権限
      Redmine認証統合
      権限ベース操作制限
      CSRF攻撃保護
      API利用監査
```

### 2.2 機能詳細
| 機能ID | API名 | 説明 | 優先度 | 受容条件 |
|--------|-------|------|---------|----------|
| API001 | Grid Data取得 | Epic×Version マトリクスデータ取得 | High | 3秒以内で完全データ取得 |
| API002 | Feature移動 | D&D操作によるFeature配置変更 | High | 1秒以内で楽観的更新完了 |
| API003 | 階層作成・編集 | Epic・Version・UserStory作成 | High | 作成後即座にUI反映 |
| API004 | Version自動伝播 | 親要素Version変更時の子要素更新 | High | 階層全体で一貫性保証 |
| API005 | 一括操作 | 複数Issue同時更新・割り当て | Medium | 100件以内2秒で処理完了 |
| API006 | リアルタイム同期 | 他ユーザー操作の即座反映 | Medium | WebSocket・ポーリング対応 |
| API007 | エラー回復 | 通信失敗・競合時の自動回復 | Low | ユーザー操作継続可能性確保 |

## 3. API設計仕様

### 3.1 API階層アーキテクチャ
```mermaid
graph TD
    A[React Frontend] --> B[KanbanAPI Client]
    B --> C[HTTP/HTTPS]
    C --> D[Rails Router]
    D --> E[Kanban Controllers]
    E --> F[Service Layer]
    E --> G[Redmine Standard API]
    F --> H[ActiveRecord Models]
    G --> H

    I[CSRF Protection] --> C
    J[Authentication] --> E
    K[Authorization] --> F

    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style E fill:#fff3e0
    style F fill:#e8f5e8
    style H fill:#ffebee
```

### 3.2 エンドポイント設計
```mermaid
graph LR
    subgraph "Data Retrieval APIs"
        A[GET /kanban/projects/:id/grid]
        B[GET /kanban/projects/:id/feature_cards]
        C[GET /kanban/projects/:id/statistics]
    end

    subgraph "Manipulation APIs"
        D[POST /kanban/projects/:id/grid/move_feature]
        E[POST /kanban/projects/:id/grid/create_epic]
        F[POST /kanban/projects/:id/feature_cards/:id/user_stories]
    end

    subgraph "Batch Operation APIs"
        G[POST /kanban/projects/:id/batch_update]
        H[POST /kanban/projects/:id/assign_version]
        I[POST /kanban/projects/:id/generate_tests]
    end

    style A fill:#e8f5e8
    style D fill:#fff3e0
    style G fill:#f3e5f5
```

### 3.3 API通信フロー設計
```mermaid
sequenceDiagram
    participant UI as React UI
    participant Client as KanbanAPI Client
    participant Router as Rails Router
    participant Controller as Kanban Controller
    participant Service as Service Layer
    participant DB as Database

    Note over UI,DB: データ取得フロー
    UI->>Client: getGridData(projectId)
    Client->>Router: GET /kanban/projects/:id/grid
    Router->>Controller: GridController#show
    Controller->>Service: GridDataBuilder.build()
    Service->>DB: Issue階層クエリ
    DB->>Service: 階層データ
    Service->>Controller: 構造化グリッドデータ
    Controller->>Client: JSON Response
    Client->>UI: 型安全データ

    Note over UI,DB: Feature移動フロー（楽観的更新）
    UI->>UI: 即座UI更新（楽観的）
    UI->>Client: moveFeature(featureId, targetCell)
    Client->>Router: POST /kanban/projects/:id/grid/move_feature
    Router->>Controller: GridController#move_feature
    Controller->>Service: FeatureMoveService.execute()
    Service->>DB: Issue更新・Version伝播
    DB->>Service: 更新完了
    Service->>Controller: 成功結果
    Controller->>Client: Success Response
    Client->>UI: 確定・エラー回復

    Note over UI,DB: エラー処理フロー
    UI->>Client: API操作実行
    Client-->>Router: 通信失敗
    Client->>Client: エラー検出・分類
    Client->>UI: 楽観的更新ロールバック
    UI->>UI: エラー通知・再試行UI
```

## 4. クライアントサイドAPI設計

### 4.1 API Client アーキテクチャ
```mermaid
classDiagram
    class KanbanAPIClient {
        +BASE_URL: string
        +projectId: number
        +getGridData(): Promise~GridData~
        +moveFeature(params): Promise~MoveResult~
        +createEpic(params): Promise~Epic~
        +batchUpdate(params): Promise~BatchResult~
    }

    class APIError {
        +status: number
        +message: string
        +details: object
        +isNetworkError(): boolean
        +isValidationError(): boolean
    }

    class RequestManager {
        +sendRequest(config): Promise
        +handleResponse(response): object
        +handleError(error): APIError
        +retryRequest(config): Promise
    }

    class OptimisticUpdater {
        +applyOptimistic(operation): void
        +rollbackOptimistic(operation): void
        +confirmOptimistic(result): void
    }

    KanbanAPIClient --> RequestManager
    KanbanAPIClient --> OptimisticUpdater
    RequestManager --> APIError
```

### 4.2 エラーハンドリング戦略
```mermaid
stateDiagram-v2
    [*] --> API_Call
    API_Call --> Success: 通信成功
    API_Call --> Network_Error: 通信失敗
    API_Call --> Server_Error: サーバーエラー
    API_Call --> Validation_Error: バリデーションエラー

    Success --> [*]: 処理完了

    Network_Error --> Retry_Logic: 自動リトライ
    Server_Error --> Error_Analysis: エラー分析
    Validation_Error --> User_Notification: ユーザー通知

    Retry_Logic --> Success: リトライ成功
    Retry_Logic --> Give_Up: 最大回数超過

    Error_Analysis --> Recoverable: 回復可能
    Error_Analysis --> Fatal_Error: 致命的エラー

    Recoverable --> User_Action: ユーザー操作要求
    Fatal_Error --> System_Fallback: システム代替処理
    Give_Up --> User_Notification
    User_Action --> API_Call
    User_Notification --> [*]
    System_Fallback --> [*]

    note right of Retry_Logic: 指数バックオフ\n最大3回リトライ
    note right of Error_Analysis: HTTP Status・エラーコード分析
```

## 5. サーバーサイドAPI設計

### 5.1 Controller層設計
```mermaid
graph TD
    A[Kanban Controllers] --> B[GridController]
    A --> C[FeatureCardsController]
    A --> D[BatchOperationsController]

    B --> E[show: Grid Data取得]
    B --> F[move_feature: Feature移動]
    B --> G[create_epic: Epic作成]

    C --> H[index: Feature一覧]
    C --> I[create: Feature作成]
    C --> J[update: Feature更新]

    D --> K[update: 一括更新]
    D --> L[assign_version: Version割当]
    D --> M[generate_tests: Test生成]

    style B fill:#e1f5fe
    style C fill:#f3e5f5
    style D fill:#fff3e0
```

### 5.2 Service層統合設計
```mermaid
sequenceDiagram
    participant Controller as Kanban Controller
    participant DataBuilder as GridDataBuilder
    participant MoveService as FeatureMoveService
    participant VersionService as VersionPropagationService
    participant TestService as TestGenerationService
    participant Validator as DataValidator

    Note over Controller,Validator: 複合操作フロー例
    Controller->>DataBuilder: 現在データ取得
    DataBuilder->>Controller: Grid構造データ

    Controller->>Validator: 操作可能性検証
    Validator->>Controller: 検証結果

    Controller->>MoveService: Feature移動実行
    MoveService->>VersionService: Version自動伝播
    VersionService->>TestService: 必要に応じてTest生成
    TestService->>MoveService: 生成結果
    MoveService->>Controller: 移動完了・副作用結果

    Controller->>DataBuilder: 更新後データ構築
    DataBuilder->>Controller: 最新Grid構造
```

## 6. データ変換・シリアライゼーション

### 6.1 データ変換フロー
```mermaid
flowchart TD
    A[Redmine ActiveRecord] --> B[Hash変換]
    B --> C[データ正規化]
    C --> D[統計計算]
    D --> E[権限フィルタ]
    E --> F[JSON シリアライズ]
    F --> G[HTTP レスポンス]

    G --> H[HTTP リクエスト]
    H --> I[JSON パース]
    I --> J[型検証・変換]
    J --> K[React Props]
    K --> L[Component State]

    M[バリデーション エラー] --> N[エラー レスポンス]
    N --> O[クライアント エラー処理]
    O --> P[ユーザー フィードバック]

    style A fill:#ffebee
    style F fill:#fff3e0
    style K fill:#e8f5e8
    style M fill:#f44336,color:#ffffff
```

### 6.2 型安全性保証
```typescript
// API型定義インターフェース（疑似コード）
interface APIEndpoint<TRequest, TResponse> {
  method: HTTPMethod;
  path: string;
  requestSchema: Schema<TRequest>;
  responseSchema: Schema<TResponse>;
  authRequired: boolean;
  permissions: Permission[];
}

// Grid Data API例
interface GridDataAPI extends APIEndpoint<GridDataRequest, GridDataResponse> {
  method: 'GET';
  path: '/kanban/projects/:id/grid';
  requestSchema: GridDataRequestSchema;
  responseSchema: GridDataResponseSchema;
  authRequired: true;
  permissions: ['view_issues'];
}

// Feature移動API例
interface MoveFeatureAPI extends APIEndpoint<MoveFeatureRequest, MoveFeatureResponse> {
  method: 'POST';
  path: '/kanban/projects/:id/grid/move_feature';
  requestSchema: MoveFeatureRequestSchema;
  responseSchema: MoveFeatureResponseSchema;
  authRequired: true;
  permissions: ['edit_issues'];
}
```

## 7. 非機能要求

### 7.1 パフォーマンス要求
| 項目 | 要求値 | 測定方法 | 備考 |
|------|---------|----------|------|
| Grid Data初期取得 | 3秒以内 | Time to First Response | 100Epic×10Version想定 |
| Feature移動レスポンス | 500ms以内 | API Response Time | 楽観的更新適用時 |
| 一括操作処理 | 100件2秒以内 | Batch Processing Time | Version伝播含む |
| API同時接続 | 50ユーザー対応 | Concurrent Users | Rails標準制限内 |
| データ転送量 | 1MB以内/リクエスト | Payload Size | gzip圧縮適用時 |

### 7.2 可用性・信頼性要求
- **API可用性**: 99.9%以上（Redmine本体稼働時）
- **エラー回復**: 一時的障害から30秒以内自動回復
- **データ整合性**: 競合操作時の適切な競合解決
- **セキュリティ**: CSRF・XSS・SQLインジェクション対策完備

### 7.3 運用性要求
- **監査ログ**: 全API操作のログ記録・追跡可能性
- **API監視**: レスポンス時間・エラー率・使用状況監視
- **バージョニング**: API仕様変更時の後方互換性保証
- **ドキュメント**: OpenAPI/Swagger仕様書自動生成

## 8. セキュリティ設計

### 8.1 認証・認可フロー
```mermaid
sequenceDiagram
    participant User as ユーザー
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Redmine as Redmine Core
    participant DB as Database

    Note over User,DB: 認証フロー
    User->>Browser: ログイン操作
    Browser->>Rails: ログイン要求
    Rails->>Redmine: Redmine認証処理
    Redmine->>DB: ユーザー認証情報確認
    DB->>Redmine: 認証結果
    Redmine->>Rails: セッション確立
    Rails->>Browser: セッションCookie設定

    Note over User,DB: API認可フロー
    Browser->>Rails: API要求（Cookie付き）
    Rails->>Redmine: セッション検証
    Redmine->>Rails: ユーザー情報・権限
    Rails->>Rails: プロジェクト権限チェック
    Rails->>Rails: 操作権限チェック
    Rails->>Browser: API実行 or 権限エラー
```

### 8.2 セキュリティ対策
```mermaid
graph TD
    A[API Security Layers] --> B[CSRF Protection]
    A --> C[XSS Prevention]
    A --> D[SQL Injection Protection]
    A --> E[Authorization Check]

    B --> F[CSRF Token検証]
    B --> G[SameSite Cookie]

    C --> H[Content Security Policy]
    C --> I[Input Sanitization]

    D --> J[ActiveRecord ORM]
    D --> K[Prepared Statements]

    E --> L[Redmine Permission System]
    E --> M[Project-based Access Control]

    style A fill:#f44336,color:#ffffff
    style B fill:#ff9800
    style C fill:#ff9800
    style D fill:#ff9800
    style E fill:#ff9800
```

## 9. テスト設計

### 9.1 API テスト戦略
```mermaid
pyramid
    title API統合 テストピラミッド

    "E2E API テスト（Postman/Newman）" : 10
    "統合テスト（Controller + Service）" : 30
    "単体テスト（Service・Utils）" : 60
```

### 9.2 テストケース設計
| テストレベル | 対象 | 主要テストケース | カバレッジ目標 |
|-------------|------|------------------|----------------|
| 単体テスト | Service・Utils | データ変換・バリデーション・計算ロジック | 95%以上 |
| 統合テスト | Controller + DB | API動作・権限・エラー処理 | 90%以上 |
| E2Eテスト | フルスタック | ユーザーシナリオ・実環境動作 | 主要API100% |

### 9.3 API契約テスト
```typescript
// API契約テスト例（疑似コード）
describe('Grid Data API Contract', () => {
  it('should return valid grid data structure', async () => {
    const response = await request(app)
      .get('/kanban/projects/1/grid')
      .set('X-CSRF-Token', csrfToken)
      .expect(200);

    // レスポンススキーマ検証
    expect(response.body).toMatchSchema(GridDataResponseSchema);

    // 必須フィールド存在確認
    expect(response.body).toHaveProperty('project');
    expect(response.body).toHaveProperty('epics');
    expect(response.body).toHaveProperty('versions');

    // 統計情報精度確認
    const statistics = response.body.metadata.statistics;
    expect(statistics.total_features).toBeGreaterThan(0);
  });

  it('should handle feature move with version propagation', async () => {
    const moveRequest = {
      feature_id: 123,
      target_epic_id: 456,
      target_version_id: 789
    };

    const response = await request(app)
      .post('/kanban/projects/1/grid/move_feature')
      .send(moveRequest)
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.propagation_results).toBeDefined();
  });
});
```

## 10. 運用・保守設計

### 10.1 API監視・ログ設計
- **アクセスログ**: 全API要求の記録（時刻・ユーザー・エンドポイント・レスポンス時間）
- **エラーログ**: API障害・バリデーションエラー・権限違反の詳細記録
- **パフォーマンス監視**: 応答時間・スループット・リソース使用率測定
- **ビジネスログ**: Feature移動・Epic作成等の業務操作監査証跡

### 10.2 API進化・バージョン管理
```mermaid
stateDiagram-v2
    [*] --> v1_0_stable
    v1_0_stable --> v1_1_development: 新機能開発
    v1_1_development --> v1_1_beta: 機能完成・テスト
    v1_1_beta --> v1_1_stable: 品質確認完了
    v1_1_stable --> v1_2_development: 次期機能開発

    v1_0_stable --> v1_0_deprecated: v1.1リリース後
    v1_0_deprecated --> v1_0_removed: 移行期間終了後

    note right of v1_1_beta: 後方互換性確認\nクライアント適応テスト
    note right of v1_0_deprecated: 6ヶ月移行期間\n非推奨警告表示
```

### 10.3 スケーラビリティ・パフォーマンス監視
- **スケールアウト対応**: ロードバランサー・複数Rails インスタンス対応
- **キャッシング戦略**: Redis活用の統計情報・頻繁アクセスデータキャッシング
- **データベース最適化**: クエリ最適化・インデックス設計・接続プール管理
- **CDN活用**: 静的アセット・APIレスポンス（適切な場合）のCDN配信

---

*API統合設計は、React Frontend と Rails Backend を結ぶ重要な架け橋です。この設計書は実装コードではなく、RESTful API設計・セキュリティ・パフォーマンス・運用の思想を明確化し、フロントエンド・バックエンド開発チーム間の効率的な協働を実現します。*