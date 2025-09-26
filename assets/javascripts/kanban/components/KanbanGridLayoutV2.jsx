import { useState, useEffect, useMemo, useReducer, useCallback } from 'react';
import {
  DndContext,
  DragOverlay,
  closestCenter,
  PointerSensor,
  KeyboardSensor,
  useSensors,
  useSensor
} from '@dnd-kit/core';
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable';

// 設計書準拠のコンポーネントインポート
import { GridHeader } from './grid/GridHeader';
import { GridBody } from './grid/GridBody';
import { EpicRow } from './grid/EpicRow';
import { NoEpicRow } from './grid/NoEpicRow';
import { NewEpicRow } from './grid/NewEpicRow';
import { GridCell } from './grid/GridCell';
import { FeatureCard } from './grid/FeatureCard';
import { DragIndicator } from './grid/DragIndicator';
import { GridV2API } from '../services/GridV2API';
import { GridWebSocketService } from '../services/GridWebSocketService.js';
import {
  applyRemoteGridUpdate,
  applyRemoteFeatureMove,
  addRemoteEpic,
  addRemoteVersion,
  applyPollingUpdate,
  rollbackOptimisticUpdate,
  applyRealTimeUpdate
} from '../utils/realTimeUpdateHelpers.js';
import { getOptimisticUpdateService } from '../services/OptimisticUpdateService.js';

// 設計書準拠のグリッド状態管理
const gridReducer = (state, action) => {
  switch (action.type) {
    case 'SET_INITIAL_DATA':
      return {
        ...state,
        data: action.payload,
        loading: false,
        error: null
      };

    case 'SET_LOADING':
      return {
        ...state,
        loading: action.payload
      };

    case 'SET_ERROR':
      return {
        ...state,
        error: action.payload,
        loading: false
      };

    case 'START_DRAG':
      return {
        ...state,
        ui: {
          ...state.ui,
          draggedCard: action.payload,
          hoveredCell: null
        }
      };

    case 'HOVER_CELL':
      return {
        ...state,
        ui: {
          ...state.ui,
          hoveredCell: action.payload
        }
      };

    case 'END_DRAG':
      return {
        ...state,
        ui: {
          ...state.ui,
          draggedCard: null,
          hoveredCell: null
        }
      };

    case 'OPTIMISTIC_UPDATE':
      return {
        ...state,
        data: action.payload.updatedData,
        optimisticUpdates: [
          ...state.optimisticUpdates,
          action.payload.update
        ]
      };

    case 'MOVE_SUCCESS':
      return {
        ...state,
        data: action.payload.updatedData,
        optimisticUpdates: state.optimisticUpdates.filter(
          update => update.id !== action.payload.updateId
        )
      };

    case 'MOVE_ROLLBACK':
      return {
        ...state,
        data: rollbackOptimisticUpdate(state.data, action.payload.updateId),
        optimisticUpdates: state.optimisticUpdates.filter(
          update => update.id !== action.payload.updateId
        ),
        error: action.payload.error
      };

    case 'REAL_TIME_UPDATE':
      return {
        ...state,
        data: applyRealTimeUpdate(state.data, action.payload)
      };

    case 'REMOTE_GRID_UPDATE':
      return {
        ...state,
        data: applyRemoteGridUpdate(state.data, action.payload),
        lastUpdateTimestamp: action.payload.timestamp
      };

    case 'REMOTE_FEATURE_MOVE':
      return {
        ...state,
        data: applyRemoteFeatureMove(state.data, action.payload),
        lastUpdateTimestamp: action.payload.timestamp
      };

    case 'REMOTE_EPIC_CREATED':
      return {
        ...state,
        data: addRemoteEpic(state.data, action.payload.epic),
        lastUpdateTimestamp: action.payload.timestamp
      };

    case 'REMOTE_VERSION_CREATED':
      return {
        ...state,
        data: addRemoteVersion(state.data, action.payload.version),
        lastUpdateTimestamp: action.payload.timestamp
      };

    case 'USER_JOINED':
      return {
        ...state,
        ui: {
          ...state.ui,
          onlineUsers: [...(state.ui.onlineUsers || []), action.payload]
        }
      };

    case 'USER_LEFT':
      return {
        ...state,
        ui: {
          ...state.ui,
          onlineUsers: (state.ui.onlineUsers || []).filter(
            user => user.id !== action.payload.id
          )
        }
      };

    case 'CONNECTION_STATUS':
      return {
        ...state,
        ui: {
          ...state.ui,
          connectionStatus: action.payload
        }
      };

    case 'WEBSOCKET_ERROR':
      return {
        ...state,
        ui: {
          ...state.ui,
          websocketError: action.payload
        }
      };

    case 'POLLING_UPDATE':
      return {
        ...state,
        data: applyPollingUpdate(state.data, action.payload),
        lastUpdateTimestamp: action.payload.last_update_timestamp
      };

    default:
      return state;
  }
};

// 初期状態
const initialGridState = {
  data: null,
  ui: {
    draggedCard: null,
    hoveredCell: null
  },
  loading: true,
  error: null,
  optimisticUpdates: [],
  lastUpdateTimestamp: null
};

/**
 * KanbanGridLayoutV2 - 設計書準拠の完全新規実装
 * 設計書仕様: Epic×Version 2次元マトリクス、パフォーマンス最適化、リアルタイム同期
 *
 * @param {number} projectId - プロジェクトID
 * @param {Object} currentUser - 現在のユーザー情報
 * @param {Object} initialData - 初期データ（オプション）
 * @param {Function} onDataUpdate - データ更新コールバック
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {boolean} showStatistics - 統計情報表示
 * @param {boolean} enableFiltering - フィルタリング有効
 * @param {boolean} dragEnabled - ドラッグ&ドロップ有効
 * @param {Object} dropConstraints - ドロップ制約設定
 */
export const KanbanGridLayoutV2 = ({
  projectId,
  currentUser,
  initialData = null,
  onDataUpdate,
  compactMode = false,
  showStatistics = true,
  enableFiltering = true,
  dragEnabled = true,
  dropConstraints = {}
}) => {
  // 設計書準拠の状態管理
  const [gridState, gridDispatch] = useReducer(gridReducer, {
    ...initialGridState,
    data: initialData,
    loading: !initialData
  });

  // グリッド構造計算（メモ化）
  const gridMatrix = useMemo(() => {
    if (!gridState.data) return null;
    return buildGridMatrix(gridState.data);
  }, [gridState.data]);

  // Version列計算（メモ化）
  const versionColumns = useMemo(() => {
    if (!gridMatrix) return [];

    const versions = gridMatrix.versions.map(version => ({
      id: version.id,
      name: version.name,
      description: version.description,
      effective_date: version.effective_date,
      status: version.status,
      issue_count: version.issue_count,
      type: 'version'
    }));

    return [
      ...versions,
      {
        id: 'no-version',
        name: 'No Version',
        type: 'no-version',
        issue_count: countNoVersionIssues(gridMatrix)
      }
    ];
  }, [gridMatrix]);

  // Epic行計算（メモ化）
  const epicRows = useMemo(() => {
    if (!gridMatrix) return [];

    const epics = gridMatrix.grid.rows.map(epicData => ({
      id: epicData.issue.id,
      name: epicData.issue.subject,
      type: 'epic',
      data: epicData,
      statistics: epicData.statistics
    }));

    return [
      ...epics,
      {
        id: 'no-epic',
        name: 'No EPIC',
        type: 'no-epic',
        data: null,
        statistics: calculateNoEpicStatistics(gridMatrix)
      }
    ];
  }, [gridMatrix]);

  // D&Dセンサー設定（設計書準拠）
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 }
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates
    })
  );

  // 初期データ読み込み
  useEffect(() => {
    if (!initialData) {
      loadGridData();
    }
  }, [projectId]);

  // WebSocketリアルタイム同期
  useEffect(() => {
    if (!gridState.data || !userId) return;

    // WebSocket接続初期化
    const wsService = GridWebSocketService.getInstance(projectId, userId, {
      autoReconnect: true,
      reconnectDelay: 1000,
      maxReconnectAttempts: 3
    });

    // イベントハンドラー設定
    wsService
      .on('grid_update', (data) => {
        if (data.isRemoteUpdate) {
          console.log('[KanbanGrid] Received remote grid update:', data);
          gridDispatch({ type: 'REMOTE_GRID_UPDATE', payload: data });
        }
      })
      .on('feature_moved', (data) => {
        if (data.isRemoteUpdate) {
          console.log('[KanbanGrid] Received remote feature move:', data);
          gridDispatch({ type: 'REMOTE_FEATURE_MOVE', payload: data });
        }
      })
      .on('epic_created', (data) => {
        console.log('[KanbanGrid] New epic created:', data);
        gridDispatch({ type: 'REMOTE_EPIC_CREATED', payload: data });
      })
      .on('version_created', (data) => {
        console.log('[KanbanGrid] New version created:', data);
        gridDispatch({ type: 'REMOTE_VERSION_CREATED', payload: data });
      })
      .on('user_joined', (user) => {
        console.log('[KanbanGrid] User joined:', user);
        gridDispatch({ type: 'USER_JOINED', payload: user });
      })
      .on('user_left', (user) => {
        console.log('[KanbanGrid] User left:', user);
        gridDispatch({ type: 'USER_LEFT', payload: user });
      })
      .on('connection_status', (status) => {
        console.log('[KanbanGrid] Connection status:', status);
        gridDispatch({ type: 'CONNECTION_STATUS', payload: status });
      })
      .on('error', (error) => {
        console.error('[KanbanGrid] WebSocket error:', error);
        if (error.requiresRefresh) {
          // データリフレッシュが必要な場合
          loadGridData();
        }
        gridDispatch({ type: 'WEBSOCKET_ERROR', payload: error });
      });

    // WebSocket接続開始
    wsService.connect().catch(error => {
      console.error('[KanbanGrid] WebSocket connection failed:', error);
      // WebSocket接続失敗時はポーリングにフォールバック
      startPollingUpdates();
    });

    return () => {
      wsService.disconnect();
      GridWebSocketService.removeInstance(projectId, userId);
    };
  }, [projectId, userId, gridState.data]);

  // ポーリングフォールバック（WebSocket接続失敗時）
  const startPollingUpdates = useCallback(() => {
    const interval = setInterval(async () => {
      try {
        const updates = await GridV2API.getUpdates(projectId, gridState.lastUpdateTimestamp);
        if (updates.success && updates.updates.length > 0) {
          gridDispatch({ type: 'POLLING_UPDATE', payload: updates });
        }
      } catch (error) {
        console.warn('Polling updates failed:', error);
      }
    }, 10000); // 10秒間隔（WebSocketより長めに設定）

    return () => clearInterval(interval);
  }, [projectId, gridState.lastUpdateTimestamp]);

  // グリッドデータ読み込み
  const loadGridData = useCallback(async (filters = {}) => {
    try {
      gridDispatch({ type: 'SET_LOADING', payload: true });

      const response = await GridV2API.getGridData(projectId, filters);

      if (response.success) {
        gridDispatch({
          type: 'SET_INITIAL_DATA',
          payload: response.data
        });
      } else {
        throw new Error(response.error);
      }
    } catch (error) {
      console.error('Grid data loading error:', error);
      gridDispatch({
        type: 'SET_ERROR',
        payload: error.message
      });
    }
  }, [projectId]);

  // ドラッグ開始処理
  const handleDragStart = useCallback((event) => {
    const { active } = event;
    gridDispatch({
      type: 'START_DRAG',
      payload: active.data.current
    });
  }, []);

  // ドラッグオーバー処理
  const handleDragOver = useCallback((event) => {
    const { over } = event;

    if (over && over.data.current?.type === 'grid-cell') {
      gridDispatch({
        type: 'HOVER_CELL',
        payload: over.data.current
      });
    } else {
      gridDispatch({
        type: 'HOVER_CELL',
        payload: null
      });
    }
  }, []);

  // ドラッグ終了処理（楽観的更新 + ロールバック対応）
  const handleDragEnd = useCallback(async (event) => {
    const { active, over } = event;

    if (!over || !over.data.current) {
      gridDispatch({ type: 'END_DRAG' });
      return;
    }

    const draggedCard = active.data.current;
    const dropTarget = over.data.current;

    // ドロップ制約検証
    if (!validateDropTarget(draggedCard, dropTarget, dropConstraints)) {
      gridDispatch({ type: 'END_DRAG' });
      return;
    }

    // 楽観的更新サービス使用
    const optimisticService = getOptimisticUpdateService();

    try {
      const moveData = {
        project_id: projectId,
        user_id: userId,
        feature_id: draggedCard.feature.issue.id,
        source_cell: buildCellCoordinates(draggedCard.currentCell),
        target_cell: buildCellCoordinates(dropTarget),
        lock_version: draggedCard.feature.issue.lock_version,
        currentGridData: gridState.data,
        userAction: 'drag_and_drop'
      };

      await optimisticService.executeOptimisticUpdate(
        'move_feature',
        moveData,
        gridDispatch
      );

      onDataUpdate?.(gridState.data);

    } catch (error) {
      console.error('Optimistic feature move failed:', error);

      // 追加のエラーハンドリング（必要に応じてリフレッシュ）
      if (error.requiresRollback) {
        console.warn('Rollback required - refreshing grid data');
        loadGridData();
      }
    } finally {
      gridDispatch({ type: 'END_DRAG' });
    }
  }, [projectId, userId, gridState.data, dropConstraints, loadGridData, onDataUpdate]);

  // セル内Feature取得
  const getCellFeatures = useCallback((epicId, versionId) => {
    if (!gridMatrix) return [];

    if (epicId === 'no-epic') {
      // No Epic行の処理
      const orphanFeatures = gridMatrix.orphan_features || [];
      return orphanFeatures.filter(feature => {
        const featureVersionId = feature.issue.fixed_version_id;
        if (versionId === 'no-version') {
          return !featureVersionId;
        }
        return featureVersionId === versionId;
      });
    }

    // 通常Epic行の処理
    const epicData = gridMatrix.grid.rows.find(row => row.issue.id === epicId);
    if (!epicData) return [];

    return epicData.features.filter(feature => {
      const featureVersionId = feature.issue.fixed_version_id;
      if (versionId === 'no-version') {
        return !featureVersionId;
      }
      return featureVersionId === versionId;
    });
  }, [gridMatrix]);

  // セル統計計算
  const getCellStatistics = useCallback((epicId, versionId) => {
    const features = getCellFeatures(epicId, versionId);
    const completedFeatures = features.filter(feature =>
      ['Resolved', 'Closed'].includes(feature.issue.status)
    );

    return {
      total_features: features.length,
      completed_features: completedFeatures.length,
      completion_rate: features.length > 0 ?
        Math.round((completedFeatures.length / features.length) * 100) : 0
    };
  }, [getCellFeatures]);

  // Epic作成処理
  const handleNewEpic = useCallback(async (epicData) => {
    try {
      const result = await GridV2API.createEpic(projectId, epicData);

      if (result.success) {
        await loadGridData();
        return result.created_epic;
      } else {
        throw new Error(result.error);
      }
    } catch (error) {
      console.error('Epic creation error:', error);
      throw error;
    }
  }, [projectId, loadGridData]);

  // Version作成処理
  const handleNewVersion = useCallback(async (versionData) => {
    try {
      const result = await GridV2API.createVersion(projectId, versionData);

      if (result.success) {
        await loadGridData();
        return result.created_version;
      } else {
        throw new Error(result.error);
      }
    } catch (error) {
      console.error('Version creation error:', error);
      throw error;
    }
  }, [projectId, loadGridData]);

  // ローディング状態
  if (gridState.loading) {
    return (
      <div className="kanban-grid-loading">
        <div className="loading-spinner" />
        <p>グリッドデータを読み込み中...</p>
      </div>
    );
  }

  // エラー状態
  if (gridState.error) {
    return (
      <div className="kanban-grid-error">
        <h3>エラーが発生しました</h3>
        <p>{gridState.error}</p>
        <button onClick={() => loadGridData()}>再試行</button>
      </div>
    );
  }

  // メインレンダリング
  return (
    <div className={`kanban-grid-layout-v2 ${compactMode ? 'compact' : ''}`}>
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragOver={handleDragOver}
        onDragEnd={handleDragEnd}
      >
        <GridHeader
          projectTitle={gridMatrix?.metadata?.project?.name}
          versionColumns={versionColumns}
          onNewVersion={handleNewVersion}
          showStatistics={showStatistics}
          enableFiltering={enableFiltering}
          onFiltersChange={loadGridData}
          compactMode={compactMode}
        />

        <GridBody
          epicRows={epicRows}
          versionColumns={versionColumns}
          getCellFeatures={getCellFeatures}
          getCellStatistics={getCellStatistics}
          draggedCard={gridState.ui.draggedCard}
          hoveredCell={gridState.ui.hoveredCell}
          compactMode={compactMode}
          onNewEpic={handleNewEpic}
        />

        <DragOverlay>
          {gridState.ui.draggedCard && (
            <FeatureCard
              feature={gridState.ui.draggedCard.feature}
              expanded={false}
              isDragging={true}
              compactMode={compactMode}
            />
          )}
        </DragOverlay>
      </DndContext>

      {/* 統計情報パネル */}
      {showStatistics && gridMatrix && (
        <div className="grid-statistics-panel">
          <GridStatistics statistics={gridMatrix.statistics} />
        </div>
      )}
    </div>
  );
};

// ヘルパー関数群（設計書準拠）

function buildGridMatrix(data) {
  return {
    grid: data.grid,
    versions: data.grid.versions,
    orphan_features: data.orphan_features,
    metadata: data.metadata,
    statistics: data.statistics
  };
}

function countNoVersionIssues(gridMatrix) {
  return (gridMatrix.orphan_features || []).filter(
    feature => !feature.issue.fixed_version_id
  ).length;
}

function calculateNoEpicStatistics(gridMatrix) {
  const orphanFeatures = gridMatrix.orphan_features || [];
  const completedFeatures = orphanFeatures.filter(feature =>
    ['Resolved', 'Closed'].includes(feature.issue.status)
  );

  return {
    total_features: orphanFeatures.length,
    completed_features: completedFeatures.length,
    completion_rate: orphanFeatures.length > 0 ?
      Math.round((completedFeatures.length / orphanFeatures.length) * 100) : 0
  };
}

function validateDropTarget(draggedCard, dropTarget, constraints) {
  // 基本制約チェック
  if (dropTarget.type !== 'grid-cell') return false;

  // カスタム制約チェック
  if (constraints.epic_change_allowed === false &&
      draggedCard.currentCell.epicId !== dropTarget.epicId) {
    return false;
  }

  if (constraints.version_change_allowed === false &&
      draggedCard.currentCell.versionId !== dropTarget.versionId) {
    return false;
  }

  return true;
}

function applyOptimisticMove(draggedCard, dropTarget) {
  const updateId = `move_${Date.now()}_${Math.random()}`;

  return {
    id: updateId,
    type: 'feature_move',
    card: draggedCard,
    target: dropTarget,
    timestamp: new Date().toISOString(),
    updatedData: null // 実装簡略化のため省略
  };
}

function buildCellCoordinates(cellData) {
  return {
    epic_id: cellData.epicId === 'no-epic' ? null : cellData.epicId,
    version_id: cellData.versionId === 'no-version' ? null : cellData.versionId,
    column_id: cellData.columnId
  };
}

function rollbackOptimisticUpdate(data, updateId) {
  // 楽観的更新のロールバック処理
  // 実装簡略化のため現在のデータを返す
  return data;
}

function applyRealTimeUpdate(currentData, updatePayload) {
  // リアルタイム更新の適用処理
  // 実装簡略化のため現在のデータを返す
  return currentData;
}

export default KanbanGridLayoutV2;