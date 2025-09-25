import { useState, useCallback, useEffect, useRef } from 'react';
import { useKanbanAPI } from './useKanbanAPI';

/**
 * Kanban Data Hook
 * カンバンデータの取得・更新・キャッシュを管理するカスタムフック
 *
 * @param {number} projectId - プロジェクトID
 * @param {Object} filters - フィルター設定
 * @param {Object} options - 設定オプション
 */
export function useKanbanData(projectId, filters = {}, options = {}) {
  const { api, loading: apiLoading, error: apiError, executeWithLoading } = useKanbanAPI(projectId);

  const [kanbanData, setKanbanData] = useState({
    epics: [],
    versions: [],
    columns: [],
    metadata: {},
    statistics: {}
  });

  const [lastUpdated, setLastUpdated] = useState(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const pollingIntervalRef = useRef(null);

  // 楽観的UI更新用の状態管理
  const [optimisticUpdates, setOptimisticUpdates] = useState([]);
  const [rollbackState, setRollbackState] = useState(null);

  // キャッシング戦略 (規約準拠)
  const [cache, setCache] = useState({
    cards: { data: null, timestamp: null, ttl: 5 * 60 * 1000 }, // 5分
    versions: { data: null, timestamp: null, ttl: 10 * 60 * 1000 }, // 10分
    permissions: { data: null, timestamp: null, ttl: 30 * 60 * 1000 } // 30分 (セッション期間)
  });

  const {
    autoRefresh = true,
    refreshInterval = 30000, // 30秒
    enableRealtime = true,
    enableCache = true // キャッシュ有効化
  } = options;

  // キャッシュヘルパー関数
  const isCacheValid = useCallback((cacheKey) => {
    const cacheItem = cache[cacheKey];
    if (!cacheItem.data || !cacheItem.timestamp) return false;

    const now = Date.now();
    return (now - cacheItem.timestamp) < cacheItem.ttl;
  }, [cache]);

  const setCacheData = useCallback((cacheKey, data) => {
    setCache(prev => ({
      ...prev,
      [cacheKey]: {
        ...prev[cacheKey],
        data: data,
        timestamp: Date.now()
      }
    }));
  }, []);

  const getCacheData = useCallback((cacheKey) => {
    if (!enableCache || !isCacheValid(cacheKey)) return null;
    return cache[cacheKey].data;
  }, [enableCache, isCacheValid, cache]);

  // データ取得 (キャッシング対応)
  const fetchKanbanData = useCallback(async (refresh = false) => {
    try {
      if (refresh) setIsRefreshing(true);

      // キャッシュチェック (リフレッシュ時は無視)
      if (!refresh) {
        const cachedData = getCacheData('cards');
        if (cachedData) {
          setKanbanData(cachedData);
          setLastUpdated(new Date(cache.cards.timestamp));
          return cachedData;
        }
      }

      // APIからデータ取得
      const data = await executeWithLoading(() => api.getKanbanData(filters));
      const resultData = data.data || data;

      // データ更新・キャッシュ保存
      setKanbanData(resultData);
      setLastUpdated(new Date());
      setCacheData('cards', resultData);

      return resultData;
    } catch (error) {
      console.error('Failed to fetch kanban data:', error);
      throw error;
    } finally {
      setIsRefreshing(false);
    }
  }, [api, filters, executeWithLoading, getCacheData, setCacheData, cache.cards.timestamp]);

  // データ更新
  const refreshData = useCallback(() => {
    return fetchKanbanData(true);
  }, [fetchKanbanData]);

  // 楽観的UI更新
  const optimisticUpdate = useCallback(async (updateType, updateData, apiCall) => {
    // 現在の状態をロールバック用に保存
    setRollbackState(JSON.parse(JSON.stringify(kanbanData)));

    try {
      // UI即座更新
      const optimisticData = applyOptimisticUpdate(kanbanData, updateType, updateData);
      setKanbanData(optimisticData);

      // 楽観的更新を記録
      const updateId = Date.now();
      setOptimisticUpdates(prev => [...prev, { id: updateId, type: updateType, data: updateData }]);

      // API呼び出し
      const result = await apiCall();

      // 成功時：楽観的更新を確定
      setOptimisticUpdates(prev => prev.filter(update => update.id !== updateId));
      setRollbackState(null);

      return result;
    } catch (error) {
      // エラー時：ロールバック実行
      rollbackUI();
      throw error;
    }
  }, [kanbanData]);

  // UI更新ロジック
  const applyOptimisticUpdate = useCallback((currentData, updateType, updateData) => {
    const newData = JSON.parse(JSON.stringify(currentData));

    switch (updateType) {
      case 'move_card':
        return applyCardMove(newData, updateData);
      case 'assign_version':
        return applyVersionAssign(newData, updateData);
      case 'bulk_update':
        return applyBulkUpdate(newData, updateData);
      default:
        return newData;
    }
  }, []);

  // カード移動の楽観的更新
  const applyCardMove = useCallback((data, { cardId, sourceCell, targetCell }) => {
    // Epic内のカードを検索・移動
    data.epics.forEach(epic => {
      const sourceColumn = epic.columns?.find(col => col.id === sourceCell.id);
      const targetColumn = epic.columns?.find(col => col.id === targetCell.id);

      if (sourceColumn && targetColumn) {
        const cardIndex = sourceColumn.cards?.findIndex(card => card.id === cardId);
        if (cardIndex !== -1) {
          const [movedCard] = sourceColumn.cards.splice(cardIndex, 1);
          targetColumn.cards = targetColumn.cards || [];
          targetColumn.cards.push(movedCard);
        }
      }
    });
    return data;
  }, []);

  // バージョン割当の楽観的更新
  const applyVersionAssign = useCallback((data, { cardId, versionId }) => {
    data.epics.forEach(epic => {
      epic.columns?.forEach(column => {
        column.cards?.forEach(card => {
          if (card.id === cardId) {
            card.version_id = versionId;
          }
        });
      });
    });
    return data;
  }, []);

  // 一括更新の楽観的更新
  const applyBulkUpdate = useCallback((data, { action, cardIds, params }) => {
    data.epics.forEach(epic => {
      epic.columns?.forEach(column => {
        column.cards?.forEach(card => {
          if (cardIds.includes(card.id)) {
            switch (action) {
              case 'assign_version':
                card.version_id = params.version_id;
                break;
              case 'change_status':
                card.status = params.status;
                break;
              default:
                break;
            }
          }
        });
      });
    });
    return data;
  }, []);

  // ロールバック実行
  const rollbackUI = useCallback(() => {
    if (rollbackState) {
      setKanbanData(rollbackState);
      setRollbackState(null);
      setOptimisticUpdates([]);
    }
  }, [rollbackState]);

  // カード移動 (ドラッグ&ドロップ対応 + 楽観的更新)
  const moveCard = useCallback(async (active, over) => {
    if (over.type === 'column') {
      // 列間移動（ステータス変更）
      return optimisticUpdate(
        'move_card',
        {
          cardId: active.id,
          sourceCell: { type: 'column', id: active.column },
          targetCell: { type: 'column', id: over.id }
        },
        () => api.moveCard(active.id, { type: 'column', id: active.column }, { type: 'column', id: over.id })
      );
    } else if (over.type === 'version') {
      // バージョン割当
      return optimisticUpdate(
        'assign_version',
        { cardId: active.id, versionId: over.id },
        () => api.bulkAssignVersion(over.id, [active.id])
      );
    } else {
      // 同列内順序変更
      return optimisticUpdate(
        'move_card',
        {
          cardId: active.id,
          sourceCell: { type: 'position', id: active.position },
          targetCell: { type: 'position', id: over.position }
        },
        () => api.moveCard(active.id, { type: 'position', id: active.position }, { type: 'position', id: over.position })
      );
    }
  }, [api, optimisticUpdate]);

  // 一括更新 (楽観的更新対応)
  const bulkUpdate = useCallback(async (actionType, issueIds, actionParams = {}) => {
    return optimisticUpdate(
      'bulk_update',
      {
        action: actionType,
        cardIds: issueIds,
        params: actionParams
      },
      () => api.bulkUpdate(actionType, issueIds, actionParams)
    );
  }, [api, optimisticUpdate]);

  // バージョン操作
  const createVersion = useCallback(async (versionData) => {
    try {
      const result = await executeWithLoading(() =>
        api.createVersion(versionData)
      );

      await refreshData();

      return result;
    } catch (error) {
      console.error('Failed to create version:', error);
      throw error;
    }
  }, [api, executeWithLoading, refreshData]);

  // 初回データ取得
  useEffect(() => {
    fetchKanbanData();
  }, [fetchKanbanData]);

  // 自動更新設定
  useEffect(() => {
    if (autoRefresh && refreshInterval > 0) {
      pollingIntervalRef.current = setInterval(() => {
        fetchKanbanData(true);
      }, refreshInterval);

      return () => {
        if (pollingIntervalRef.current) {
          clearInterval(pollingIntervalRef.current);
        }
      };
    }
  }, [autoRefresh, refreshInterval, fetchKanbanData]);

  // フィルター変更時のデータ再取得
  useEffect(() => {
    fetchKanbanData();
  }, [JSON.stringify(filters)]); // eslint-disable-line react-hooks/exhaustive-deps

  return {
    // データ状態
    kanbanData,
    lastUpdated,

    // ローディング状態
    loading: apiLoading,
    isRefreshing,

    // エラー状態
    error: apiError,

    // アクション
    refreshData,
    moveCard,
    bulkUpdate,
    createVersion,

    // 楽観的UI更新関連
    optimisticUpdate,
    rollbackUI,
    optimisticUpdates,
    hasOptimisticUpdates: optimisticUpdates.length > 0,

    // ヘルパー
    isLoaded: !!lastUpdated,
    isEmpty: kanbanData.epics.length === 0
  };
}