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

  const {
    autoRefresh = true,
    refreshInterval = 30000, // 30秒
    enableRealtime = true
  } = options;

  // データ取得
  const fetchKanbanData = useCallback(async (refresh = false) => {
    try {
      if (refresh) setIsRefreshing(true);

      const data = await executeWithLoading(() => api.getKanbanData(filters));

      setKanbanData(data.data || data);
      setLastUpdated(new Date());

      return data;
    } catch (error) {
      console.error('Failed to fetch kanban data:', error);
      throw error;
    } finally {
      setIsRefreshing(false);
    }
  }, [api, filters, executeWithLoading]);

  // データ更新
  const refreshData = useCallback(() => {
    return fetchKanbanData(true);
  }, [fetchKanbanData]);

  // カード移動
  const moveCard = useCallback(async (cardId, sourceCell, targetCell) => {
    try {
      const result = await executeWithLoading(() =>
        api.moveCard(cardId, sourceCell, targetCell)
      );

      // 楽観的UI更新またはデータ再取得
      await refreshData();

      return result;
    } catch (error) {
      console.error('Failed to move card:', error);
      throw error;
    }
  }, [api, executeWithLoading, refreshData]);

  // 一括更新
  const bulkUpdate = useCallback(async (actionType, issueIds, actionParams = {}) => {
    try {
      const result = await executeWithLoading(() =>
        api.bulkUpdate(actionType, issueIds, actionParams)
      );

      await refreshData();

      return result;
    } catch (error) {
      console.error('Failed to bulk update:', error);
      throw error;
    }
  }, [api, executeWithLoading, refreshData]);

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

    // ヘルパー
    isLoaded: !!lastUpdated,
    isEmpty: kanbanData.epics.length === 0
  };
}