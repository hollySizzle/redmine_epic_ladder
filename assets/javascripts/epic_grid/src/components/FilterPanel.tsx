import React, { useState, useMemo } from 'react';
import { useStore } from '../store/useStore';
import type { RansackFilterParams } from '../types/normalized-api';

/**
 * FilterPanel Component
 *
 * Epic Gridのフィルタリング機能を提供するUIコンポーネント
 * - バージョン絞込（複数選択可能）
 * - 担当者絞込（複数選択可能）
 * - トラッカー絞込（複数選択可能）
 */
export const FilterPanel: React.FC = () => {
  const entities = useStore(state => state.entities);
  const filters = useStore(state => state.filters);
  const setFilters = useStore(state => state.setFilters);
  const clearFilters = useStore(state => state.clearFilters);

  const [isExpanded, setIsExpanded] = useState(false);

  // ローカル状態（Apply前の一時的なフィルタ）
  const [localFilters, setLocalFilters] = useState<RansackFilterParams>(filters);

  // バージョンリストを取得（ID順）
  const versions = useMemo(() => {
    return Object.values(entities.versions).sort((a, b) =>
      parseInt(a.id) - parseInt(b.id)
    );
  }, [entities.versions]);

  // ユーザーリストを取得（ID順）
  const users = useMemo(() => {
    return Object.values(entities.users).sort((a, b) => a.id - b.id);
  }, [entities.users]);

  // トラッカーリスト（静的）
  // 実際のトラッカーIDはRedmineのデータベースに依存するため、
  // 動的に取得する方が望ましいが、ここでは基本的なトラッカーを想定
  const trackers = useMemo(() => [
    { id: 1, name: 'Epic' },
    { id: 2, name: 'Feature' },
    { id: 3, name: 'UserStory' },
    { id: 4, name: 'Task' },
    { id: 5, name: 'Test' },
    { id: 6, name: 'Bug' }
  ], []);

  // バージョン選択ハンドラー
  const handleVersionChange = (versionId: string, checked: boolean) => {
    setLocalFilters(prev => {
      const currentVersions = prev.fixed_version_id_in || [];
      const newVersions = checked
        ? [...currentVersions, versionId]
        : currentVersions.filter(id => id !== versionId);

      return {
        ...prev,
        fixed_version_id_in: newVersions.length > 0 ? newVersions : undefined
      };
    });
  };

  // 担当者選択ハンドラー
  const handleUserChange = (userId: number, checked: boolean) => {
    setLocalFilters(prev => {
      const currentUsers = prev.assigned_to_id_in || [];
      const newUsers = checked
        ? [...currentUsers, userId]
        : currentUsers.filter(id => id !== userId);

      return {
        ...prev,
        assigned_to_id_in: newUsers.length > 0 ? newUsers : undefined
      };
    });
  };

  // トラッカー選択ハンドラー
  const handleTrackerChange = (trackerId: number, checked: boolean) => {
    setLocalFilters(prev => {
      const currentTrackers = prev.tracker_id_in || [];
      const newTrackers = checked
        ? [...currentTrackers, trackerId]
        : currentTrackers.filter(id => id !== trackerId);

      return {
        ...prev,
        tracker_id_in: newTrackers.length > 0 ? newTrackers : undefined
      };
    });
  };

  // フィルタ適用
  const handleApply = () => {
    setFilters(localFilters);
    setIsExpanded(false);
  };

  // フィルタクリア
  const handleClear = () => {
    setLocalFilters({});
    clearFilters();
    setIsExpanded(false);
  };

  // アクティブフィルタ数をカウント
  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.fixed_version_id_in && filters.fixed_version_id_in.length > 0) count++;
    if (filters.assigned_to_id_in && filters.assigned_to_id_in.length > 0) count++;
    if (filters.tracker_id_in && filters.tracker_id_in.length > 0) count++;
    return count;
  }, [filters]);

  return (
    <div className="filter-panel">
      <button
        className="filter-toggle-btn"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        🔍 フィルタ {activeFilterCount > 0 && `(${activeFilterCount})`}
      </button>

      {isExpanded && (
        <div className="filter-dropdown">
          <div className="filter-section">
            <h4>バージョン</h4>
            <div className="filter-options">
              {versions.length > 0 ? (
                versions.map(version => (
                  <label key={version.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.fixed_version_id_in?.includes(version.id) || false}
                      onChange={(e) => handleVersionChange(version.id, e.target.checked)}
                    />
                    <span>{version.name}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">バージョンがありません</p>
              )}
            </div>
          </div>

          <div className="filter-section">
            <h4>担当者</h4>
            <div className="filter-options">
              {users.length > 0 ? (
                users.map(user => (
                  <label key={user.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.assigned_to_id_in?.includes(user.id) || false}
                      onChange={(e) => handleUserChange(user.id, e.target.checked)}
                    />
                    <span>{user.firstname} {user.lastname}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">担当者がいません</p>
              )}
            </div>
          </div>

          <div className="filter-section">
            <h4>トラッカー</h4>
            <div className="filter-options">
              {trackers.map(tracker => (
                <label key={tracker.id} className="filter-checkbox">
                  <input
                    type="checkbox"
                    checked={localFilters.tracker_id_in?.includes(tracker.id) || false}
                    onChange={(e) => handleTrackerChange(tracker.id, e.target.checked)}
                  />
                  <span>{tracker.name}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="filter-actions">
            <button className="filter-apply-btn" onClick={handleApply}>
              適用
            </button>
            <button className="filter-clear-btn" onClick={handleClear}>
              クリア
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
