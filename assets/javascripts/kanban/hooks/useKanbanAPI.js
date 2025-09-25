import { useState, useCallback, useEffect, useRef } from 'react';
import { KanbanAPI } from '../services/KanbanAPI';

/**
 * Kanban API Hook
 * KanbanAPIとの通信状態を管理するカスタムフック
 *
 * @param {number} projectId - プロジェクトID
 * @param {Object} options - 設定オプション
 */
export function useKanbanAPI(projectId, options = {}) {
  const [api] = useState(() => new KanbanAPI(projectId, options));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // API実行時のローディング状態管理
  const executeWithLoading = useCallback(async (apiCall) => {
    setLoading(true);
    setError(null);

    try {
      const result = await apiCall();
      return result;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // エラークリア
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  return {
    api,
    loading,
    error,
    executeWithLoading,
    clearError
  };
}