# Kanban Grid Layout コンポーネント詳細設計書

## 🔗 関連ドキュメント
- @vibes/docs/logics/ui_components/wireframe/kanban_ui_grid_layout.drawio
- @vibes/docs/logics/ui_components/wireframe/kanban_ui_feature_card_component.drawio
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md

## 1. 設計概要

### 1.1 設計目的・背景
**なぜこのコンポーネントが必要なのか**
- ビジネス要件：Epic（スイムレーン）× Version（時間軸）の2次元マトリクスでプロジェクト全体を俯瞰
- ユーザー価値：複雑なプロジェクト構造を直感的に理解・操作可能な鳥瞰図表示
- システム価値：Feature配置最適化、リソース配分可視化、リリース計画管理の統合

### 1.2 設計方針
**どのようなアプローチで実現するか**
- 主要設計思想：2次元マトリクス表示、ドラッグ&ドロップ直感操作、階層データの平面展開
- 技術選択理由：React（宣言的UI）、@dnd-kit（高性能D&D）、CSS Grid（レスポンシブ）
- 制約・前提条件：Redmine Issue階層準拠、大量データ表示対応、リアルタイム同期

## 2. 機能要求仕様

### 2.1 主要機能
```mermaid
mindmap
  root((Kanban Grid Layout))
    マトリクス表示機能
      Epic × Version グリッド構成
      Feature Card 配置表示
      空セル・孤立Feature管理
      動的行列追加・削除
    ドラッグ&ドロップ機能
      Feature Epic間移動
      Feature Version間移動
      リアルタイムドロップ予告
      移動制約・権限チェック
    データ管理機能
      階層データ平面展開
      Version自動伝播処理
      統計情報リアルタイム更新
      権限ベース操作制御
```

### 2.2 機能詳細
| 機能ID | 機能名 | 説明 | 優先度 | 受容条件 |
|--------|--------|------|---------|----------|
| G001 | 2次元マトリクス表示 | Epic行×Version列の格子状レイアウト | High | 全Epic・Versionが正確に表示 |
| G002 | Feature D&D移動 | Feature CardのEpic・Version間自由移動 | High | ドロップ時に即座にデータ更新 |
| G003 | 動的グリッド管理 | Epic・Version行列の追加・削除・編集 | High | 操作後グリッド構造即座更新 |
| G004 | 孤立Feature管理 | 親Epic未設定FeatureのNo Epic行表示 | High | 孤立状態Feature適切管理 |
| G005 | Version自動伝播 | Feature移動時の子要素Version継承 | Medium | 階層全体Version一貫性保持 |
| G006 | セル統計表示 | 各セルのFeature数・進捗率表示 | Medium | リアルタイム統計情報更新 |
| G007 | グリッドフィルタ | 条件絞り込み・キーワード検索機能 | Low | 大量データ快適操作対応 |

## 3. UI/UX設計仕様

### 3.1 コンポーネント階層構造
```mermaid
graph TD
    A[KanbanGridLayout] --> B[DndContext]
    B --> C[GridHeader]
    B --> D[GridBody]
    B --> E[DragOverlay]

    C --> F[ProjectTitle]
    C --> G[VersionHeaders]
    G --> H[VersionColumn]
    G --> I[NoVersionColumn]
    G --> J[NewVersionButton]

    D --> K[EpicRows]
    D --> L[NoEpicRow]
    D --> M[NewEpicRow]

    K --> N[EpicHeaderCell]
    K --> O[VersionCells]
    L --> P[NoEpicHeaderCell]
    L --> O

    O --> Q[GridCell]
    Q --> R[FeatureCard]
    Q --> S[DropIndicator]
    Q --> T[EmptyCellMessage]

    E --> U[DraggingFeatureCard]

    style A fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    style B fill:#f3e5f5,stroke:#9c27b0
    style C fill:#fff3e0,stroke:#ff9800
    style D fill:#e8f5e8,stroke:#4caf50
    style Q fill:#ffebee,stroke:#f44336
```

### 3.2 グリッド構造設計
```mermaid
graph LR
    subgraph "Grid Matrix Structure"
        direction TB
        A[Header: Epic Kanban Board]

        subgraph "Column Headers"
            B[EPIC]
            C[Version-1]
            D[Version-2]
            E[Version-3]
            F[No Version]
        end

        subgraph "Row Data"
            G[Epic1: 施設・ユーザー管理]
            H[Epic2: 開診スケジュール]
            I[Epic3: 運用監視体制]
            J[No EPIC]
            K[+ New Epic]
        end

        subgraph "Cell Content"
            L[FeatureCard A]
            M[FeatureCard B]
            N[FeatureCard C]
            O[未割当Features]
        end
    end

    B --> G
    C --> L
    D --> M
    E --> N
    F --> O

    style A fill:#e3f2fd
    style G fill:#f3e5f5
    style L fill:#fff3e0
```

### 3.3 状態遷移設計
```mermaid
stateDiagram-v2
    [*] --> 初期化中
    初期化中 --> グリッド表示中: データ取得成功
    初期化中 --> エラー状態: データ取得失敗

    グリッド表示中 --> ドラッグ準備中: Feature mousedown
    グリッド表示中 --> Epic管理中: Epic作成・編集
    グリッド表示中 --> Version管理中: Version作成・編集
    グリッド表示中 --> フィルタ中: 検索・フィルタ

    ドラッグ準備中 --> ドラッグ中: drag start
    ドラッグ中 --> ドロップ処理中: valid drop
    ドラッグ中 --> グリッド表示中: invalid drop / cancel

    ドロップ処理中 --> API通信中: 移動API呼び出し
    Epic管理中 --> API通信中: Epic CRUD
    Version管理中 --> API通信中: Version CRUD

    API通信中 --> データ更新中: 操作成功
    API通信中 --> エラー状態: 操作失敗

    データ更新中 --> グリッド表示中: UI反映完了
    フィルタ中 --> グリッド表示中: フィルタ結果表示

    エラー状態 --> 初期化中: 再試行
    エラー状態 --> グリッド表示中: エラー回復

    note right of ドラッグ中: DragOverlay表示\nドロップターゲット強調
    note right of API通信中: 楽観的更新\n+ ロールバック対応
```

### 3.4 ユーザーインタラクション設計
```mermaid
sequenceDiagram
    participant U as ユーザー
    participant GL as GridLayout
    participant GC as GridCell
    participant DO as DragOverlay
    participant API as API
    participant VP as VersionPropagation

    Note over U,VP: Feature D&D移動フロー
    U->>GL: Feature Card ドラッグ開始
    GL->>DO: DragOverlay表示開始
    GL->>GC: 全セルにドロップ可能性通知
    GC->>GC: ドロップターゲット強調表示

    U->>GC: 目標セルにホバー
    GC->>GL: ドロップ予告イベント
    GL->>GC: ドロップ可能性フィードバック

    U->>GC: 目標セルにドロップ
    GC->>GL: ドロップ完了イベント
    GL->>API: Feature移動API呼び出し
    API->>VP: Version自動伝播開始
    VP->>API: 子要素Version更新完了
    API->>GL: 移動成功レスポンス
    GL->>GL: グリッドデータ再読み込み
    GL->>U: UI更新・操作完了通知

    Note over U,VP: Epic・Version管理フロー
    U->>GL: + New Epic クリック
    GL->>U: Epic作成モーダル表示
    U->>GL: Epic情報入力・送信
    GL->>API: Epic作成API呼び出し
    API->>GL: 作成完了レスポンス
    GL->>GL: グリッド行追加・再描画
    GL->>U: 作成完了フィードバック
```

## 4. データ設計

### 4.1 データ構造
```mermaid
erDiagram
    GRID_DATA {
        project object "プロジェクト基本情報"
        versions array "Version配列"
        epics array "Epic配列（Feature含む）"
        orphan_features array "孤立Feature配列"
        metadata object "グリッドメタデータ"
    }

    EPIC_ROW {
        issue object "Epic Issue情報"
        features array "配下Feature配列"
        statistics object "Epic統計情報"
        ui_state object "UI状態（展開等）"
    }

    VERSION_COLUMN {
        id integer "Version ID"
        name string "Version名"
        description text "説明"
        effective_date date "リリース予定日"
        status string "Version状態"
        issue_count integer "関連Issue総数"
    }

    GRID_CELL {
        epic_id integer "Epic ID（null=No Epic）"
        version_id integer "Version ID（null=No Version）"
        features array "配置Feature配列"
        statistics object "セル統計情報"
        drop_constraints object "ドロップ制約情報"
    }

    GRID_METADATA {
        total_epics integer "Epic総数"
        total_features integer "Feature総数"
        total_versions integer "Version総数"
        matrix_dimensions object "マトリクス次元情報"
        user_permissions object "ユーザー操作権限"
        last_updated datetime "最終更新日時"
    }

    GRID_DATA ||--o{ EPIC_ROW : contains
    GRID_DATA ||--o{ VERSION_COLUMN : includes
    EPIC_ROW ||--o{ GRID_CELL : intersects
    VERSION_COLUMN ||--o{ GRID_CELL : intersects
    GRID_DATA ||--|| GRID_METADATA : provides
```

### 4.2 データフロー
```mermaid
flowchart TD
    A[Redmine Issues DB] --> B[Issue階層クエリ]
    C[Redmine Versions DB] --> D[Version情報クエリ]

    B --> E[GridDataBuilder]
    D --> E

    E --> F[Epic配列構築]
    E --> G[Version配列構築]
    E --> H[Feature配置計算]
    E --> I[統計情報集計]

    F --> J[マトリクス構造生成]
    G --> J
    H --> J
    I --> J

    J --> K[権限情報付加]
    K --> L[React Grid Props]

    L --> M[Grid UI 表示]
    M --> N[ユーザー操作]

    N --> O{操作種別}
    O -->|D&D移動| P[Feature移動処理]
    O -->|Epic管理| Q[Epic CRUD処理]
    O -->|Version管理| R[Version CRUD処理]

    P --> S[Version自動伝播]
    Q --> T[グリッド構造更新]
    R --> T
    S --> T

    T --> U[DB更新コミット]
    U --> V[更新イベント発火]
    V --> W[Grid Data 再構築]
    W --> M

    style A fill:#ffebee
    style L fill:#e8f5e8
    style M fill:#e1f5fe
    style U fill:#fff3e0
```

## 5. アーキテクチャ設計

### 5.1 システム構成
```mermaid
C4Context
    Person(pm, "プロジェクトマネージャー", "Epic・Feature配置管理")
    Person(po, "プロダクトオーナー", "Version・リリース計画")
    Person(dev, "開発者", "Feature進捗・配置確認")
    Person(qa, "QA担当", "品質・テスト計画管理")

    System(grid_system, "Kanban Grid System", "2次元マトリクス・D&D操作")
    System_Ext(redmine_core, "Redmine Core", "Issue・Version管理基盤")
    System_Ext(browser, "Web Browser", "D&D・レスポンシブUI")
    SystemDb(database, "Database", "Issue階層・Version永続化")

    Rel(pm, grid_system, "Epic・Feature配置管理")
    Rel(po, grid_system, "Version・リリース計画管理")
    Rel(dev, grid_system, "Feature進捗確認・移動")
    Rel(qa, grid_system, "テスト・品質計画確認")

    Rel(grid_system, redmine_core, "Issue CRUD・関連操作")
    Rel(grid_system, browser, "D&D UI・レスポンシブ表示")
    Rel(grid_system, database, "階層データ永続化")
```

### 5.2 コンポーネント構成
```mermaid
C4Component
    Component(grid_ui, "Grid UI Layer", "React + @dnd-kit", "マトリクス表示・D&D操作")
    Component(grid_controller, "Grid Controller", "React Hooks + Context", "状態管理・イベント制御")
    Component(grid_service, "Grid Service", "GridDataBuilder", "マトリクス構造構築・変換")
    Component(dnd_service, "D&D Service", "@dnd-kit integration", "ドラッグ&ドロップ制御")
    Component(grid_api, "Grid API", "Rails GridController", "CRUD操作・データ配信")
    Component(version_service, "Version Service", "VersionPropagationService", "Version自動伝播処理")
    Component(issue_repository, "Issue Repository", "Redmine Issue + ActiveRecord", "Issue階層永続化")

    Rel(grid_ui, grid_controller, "状態参照・イベント発火")
    Rel(grid_ui, dnd_service, "D&D操作統合")
    Rel(grid_controller, grid_service, "データ変換要求")
    Rel(grid_controller, grid_api, "HTTP通信")
    Rel(grid_api, version_service, "Version伝播処理")
    Rel(grid_api, issue_repository, "Issue CRUD操作")

    style grid_ui fill:#e1f5fe
    style grid_controller fill:#f3e5f5
    style grid_service fill:#fff3e0
    style grid_api fill:#e8f5e8
```

## 6. インターフェース設計

### 6.1 Props インターフェース
```typescript
interface KanbanGridLayoutProps {
  // 基本プロパティ
  projectId: number;
  currentUser: UserData;

  // データ制御
  initialData?: GridData;
  onDataUpdate?: (updatedData: GridData) => void;
  onError?: (error: GridError) => void;

  // 表示制御
  compactMode?: boolean;
  showStatistics?: boolean;
  enableFiltering?: boolean;

  // D&D制御
  dragEnabled?: boolean;
  dropConstraints?: DropConstraintConfig;
}

interface GridData {
  project: ProjectMetadata;
  versions: VersionColumn[];
  epics: EpicRow[];
  orphan_features: FeatureCard[];
  matrix_dimensions: MatrixDimensions;
  metadata: GridMetadata;
}

interface GridCellData {
  coordinates: CellCoordinate;
  features: FeatureCard[];
  statistics: CellStatistics;
  drop_allowed: boolean;
  cell_type: 'epic-version' | 'epic-no-version' | 'no-epic-version' | 'no-epic-no-version';
}

interface DropConstraintConfig {
  epic_change_allowed: boolean;
  version_change_allowed: boolean;
  required_permissions: string[];
  max_features_per_cell?: number;
}
```

### 6.2 API インターフェース
```mermaid
sequenceDiagram
    participant C as Client
    participant GC as GridController
    participant GDB as GridDataBuilder
    participant VPS as VersionPropagationService
    participant IR as IssueRepository

    Note over C,IR: グリッドデータ初期取得
    C->>GC: GET /kanban/projects/:id/grid
    GC->>GDB: GridDataBuilder.new(project, user, filters)
    GDB->>IR: Epic・Feature・Version階層クエリ
    IR->>GDB: 階層構造データ
    GDB->>GC: マトリクス構造JSON
    GC->>C: GridData レスポンス

    Note over C,IR: Feature D&D移動操作
    C->>GC: POST /kanban/projects/:id/grid/move_feature
    GC->>IR: Feature.update(parent_id, fixed_version_id)
    GC->>VPS: propagate_version_to_children(feature, version)
    VPS->>IR: 子要素Version一括更新
    IR->>GC: 更新完了通知
    GC->>GDB: 更新後データ再構築
    GDB->>GC: 最新GridData
    GC->>C: 移動成功 + 更新データ

    Note over C,IR: Epic・Version管理操作
    C->>GC: POST /kanban/projects/:id/grid/create_epic
    GC->>IR: Issue.create(tracker: 'Epic', ...)
    IR->>GC: Epic作成完了
    GC->>GDB: グリッド構造再計算
    GDB->>GC: 更新GridData
    GC->>C: Epic作成完了 + GridData
```

## 7. 非機能要求

### 7.1 パフォーマンス要求
| 項目 | 要求値 | 測定方法 | 想定条件 |
|------|---------|----------|----------|
| グリッド初期表示 | 5秒以内 | Time to Interactive | 100Epic×20Version |
| D&D操作レスポンス | 0.3秒以内 | Drag→Drop→UI更新 | 楽観的更新適用時 |
| セル追加・削除 | 2秒以内 | API→グリッド再描画 | 差分更新活用時 |
| 大量スクロール | 60FPS維持 | Chrome Performance | 仮想スクロール対応 |
| メモリ使用量 | セル当たり1.5MB以内 | DevTools Memory | React.memo最適化 |

### 7.2 品質要求
- **可用性**: 99.9%以上（Redmine本体稼働時）
- **保守性**: コンポーネント粒度テスト、循環複雑度8以下
- **拡張性**: 新トラッカー・カスタムフィールド追加対応
- **互換性**: Redmine 5.0-6.0、既存プラグイン共存

### 7.3 ユーザビリティ要求
- **学習性**: 初回利用時5分以内でD&D操作習得
- **効率性**: 従来画面遷移の70%時間短縮
- **満足度**: SUS（System Usability Scale）スコア80以上
- **アクセシビリティ**: WCAG 2.1 AA準拠

## 8. 実装指針

### 8.1 技術スタック
- **UI Framework**: React 18 + TypeScript 4.8+
- **D&D System**: @dnd-kit/core + @dnd-kit/sortable
- **レイアウト**: CSS Grid + Flexbox
- **状態管理**: useState + useContext（React Query併用）
- **API通信**: Fetch API + SWR（キャッシング・同期）

### 8.2 実装パターン
```typescript
// Grid Layout実装基本パターン（疑似コード）
export const KanbanGridLayout: FC<KanbanGridLayoutProps> = ({
  projectId,
  initialData,
  onDataUpdate
}) => {
  // 1. 状態管理（階層化）
  const [gridState, gridDispatch] = useReducer(gridReducer, {
    data: initialData,
    ui: { draggedCard: null, hoveredCell: null },
    loading: false,
    error: null
  });

  // 2. グリッド構造計算（メモ化）
  const gridMatrix = useMemo(() =>
    buildGridMatrix(gridState.data), [gridState.data]);

  // 3. D&D統合
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 8 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  // 4. 操作ハンドラー（最適化）
  const handleDragEnd = useCallback(async (event: DragEndEvent) => {
    const { active, over } = event;

    if (!over || !validateDropTarget(active.data, over.data)) {
      return;
    }

    // 楽観的更新
    const optimisticUpdate = applyOptimisticMove(active.data, over.data);
    gridDispatch({ type: 'OPTIMISTIC_UPDATE', payload: optimisticUpdate });

    try {
      const result = await moveFeature(active.data.feature, over.data.cell);
      gridDispatch({ type: 'MOVE_SUCCESS', payload: result });
      onDataUpdate?.(result.updatedData);
    } catch (error) {
      gridDispatch({ type: 'MOVE_ROLLBACK', payload: { error } });
    }
  }, [onDataUpdate]);

  // 5. レンダリング（条件分岐最小化）
  return (
    <div className="kanban-grid-layout">
      <DndContext sensors={sensors} onDragEnd={handleDragEnd}>
        <GridHeader matrix={gridMatrix} />
        <GridBody
          matrix={gridMatrix}
          dragState={gridState.ui}
          onCellInteraction={handleCellInteraction}
        />
        <DragOverlay>
          {gridState.ui.draggedCard &&
            <FeatureCard {...gridState.ui.draggedCard} isDragging />}
        </DragOverlay>
      </DndContext>
    </div>
  );
};
```

### 8.3 パフォーマンス最適化戦略
```mermaid
flowchart TD
    A[大量データ対応] --> B[React.memo + 比較最適化]
    A --> C[仮想スクロール（react-window）]
    A --> D[遅延ローディング（Intersection Observer）]

    E[D&D最適化] --> F[ドラッグ中レンダリング制限]
    E --> G[ドロップターゲット事前計算]
    E --> H[楽観的更新 + ロールバック]

    I[状態管理最適化] --> J[useReducer状態階層化]
    I --> K[useCallback・useMemo活用]
    I --> L[Context分離（UI・Data）]

    M[API最適化] --> N[SWR キャッシング]
    M --> O[差分更新（Delta Sync）]
    M --> P[リクエストバッチング]

    style A fill:#ffebee
    style E fill:#f3e5f5
    style I fill:#e8f5e8
    style M fill:#fff3e0
```

## 9. テスト設計

### 9.1 テスト戦略
```mermaid
pyramid
    title Grid Layout テストピラミッド

    "E2E（Playwright）" : 5
    "統合テスト（MSW + RTL）" : 25
    "コンポーネントテスト（RTL）" : 70
```

### 9.2 テストケース設計
| テストレベル | 対象コンポーネント | 主要テストケース | カバレッジ目標 |
|-------------|-------------------|------------------|----------------|
| 単体テスト | GridLayout・GridCell・D&D | 表示・移動・作成・削除・エラー処理 | 90%以上 |
| 統合テスト | API連携・状態管理 | データ取得・移動・伝播・整合性 | 85%以上 |
| E2Eテスト | ユーザーシナリオ | Epic追加→Feature移動→Version伝播 | 主要フロー100% |

### 9.3 テスト実装例
```typescript
// Grid Layout統合テスト例（疑似コード）
describe('KanbanGridLayout', () => {
  const mockGridData = createMockGridData({
    epics: 3,
    versions: 4,
    featuresPerEpic: 2
  });

  it('should display complete grid matrix', async () => {
    render(<KanbanGridLayout projectId={1} initialData={mockGridData} />);

    // Epic行表示確認
    expect(screen.getAllByTestId('epic-row')).toHaveLength(4); // 3 + No Epic

    // Version列表示確認
    expect(screen.getAllByTestId('version-column')).toHaveLength(5); // 4 + No Version

    // Feature Card配置確認
    expect(screen.getAllByTestId('feature-card')).toHaveLength(6); // 3×2
  });

  it('should perform drag and drop movement', async () => {
    const onDataUpdate = jest.fn();
    render(
      <KanbanGridLayout
        projectId={1}
        initialData={mockGridData}
        onDataUpdate={onDataUpdate}
      />
    );

    const featureCard = screen.getByText('Feature A');
    const targetCell = screen.getByTestId('cell-epic2-version3');

    // D&D操作実行
    await dragAndDrop(featureCard, targetCell);

    // API呼び出し確認
    expect(mockApi.moveFeature).toHaveBeenCalledWith({
      featureId: 1,
      targetEpicId: 2,
      targetVersionId: 3
    });

    // データ更新コールバック確認
    expect(onDataUpdate).toHaveBeenCalled();
  });
});
```

## 10. 運用・保守設計

### 10.1 監視・ログ設計
- **パフォーマンス監視**: Web Vitals測定（LCP, FID, CLS）
- **操作ログ**: D&D操作・Epic/Version作成をRedmine Journal記録
- **エラートラッキング**: クライアントサイドエラー→サーバーログ連携
- **使用状況分析**: グリッド操作パターン・頻度分析

### 10.2 更新・デプロイ戦略
- **段階的リリース**: 機能フラグによる段階的展開
- **A/Bテスト**: 新UI・旧UI並行運用による効果測定
- **ロールバック**: webpack chunk単位の部分ロールバック
- **データ移行**: Issue階層変更時の自動マイグレーション

### 10.3 スケーラビリティ対応
```mermaid
graph TD
    A[現在: 50Epic×10Version] --> B[短期: 200Epic×20Version]
    B --> C[中期: 500Epic×50Version]
    C --> D[長期: 1000Epic×100Version]

    E[対応策レベル1] --> F[仮想スクロール導入]
    E --> G[React.memo最適化]

    H[対応策レベル2] --> I[遅延ローディング]
    H --> J[データページング]

    K[対応策レベル3] --> L[サーバーサイド集約]
    K --> M[WebSocket リアルタイム更新]

    style A fill:#e8f5e8
    style B fill:#fff3e0
    style C fill:#ffebee
    style D fill:#f44336,color:#ffffff
```

---

*Kanban Grid Layoutは、Epic×Versionの2次元マトリクスでプロジェクト全体を俯瞰し、直感的なD&D操作でFeature配置を最適化する中核システムです。この設計書は実装コードではなく、設計思想・要求仕様・アーキテクチャ構造を体系化し、開発・運用チーム全体での共通理解を促進します。*