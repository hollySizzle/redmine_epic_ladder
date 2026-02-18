import React, { useState, useMemo } from 'react';
import { useStore } from '../store/useStore';
import type { RansackFilterParams } from '../types/normalized-api';
import { naturalSortKey, compareNaturalSort } from '../utils/naturalSort';

/**
 * FilterPanel Component
 *
 * Epic Ladderのフィルタリング機能を提供するUIコンポーネント
 * - バージョン絞込（複数選択可能）
 * - 担当者絞込（複数選択可能）
 * - トラッカー絞込（複数選択可能）
 */
export const FilterPanel: React.FC = () => {
  const entities = useStore(state => state.entities);
  const metadata = useStore(state => state.metadata);
  const filters = useStore(state => state.filters);
  const setFilters = useStore(state => state.setFilters);
  const clearFilters = useStore(state => state.clearFilters);
  const excludeClosedVersions = useStore(state => state.excludeClosedVersions);
  const toggleExcludeClosedVersions = useStore(state => state.toggleExcludeClosedVersions);
  const hideEmptyEpicsVersions = useStore(state => state.hideEmptyEpicsVersions);
  const toggleHideEmptyEpicsVersions = useStore(state => state.toggleHideEmptyEpicsVersions);

  const [isExpanded, setIsExpanded] = useState(false);

  // ローカル状態（Apply前の一時的なフィルタ）
  const [localFilters, setLocalFilters] = useState<RansackFilterParams>(filters);

  // バージョン期日フィルタのローカル状態
  const [effectiveDateFrom, setEffectiveDateFrom] = useState<string>(filters.fixed_version_effective_date_gteq || '');
  const [effectiveDateTo, setEffectiveDateTo] = useState<string>(filters.fixed_version_effective_date_lteq || '');

  // バージョンリストを取得（自然順ソート）
  const versions = useMemo(() => {
    return Object.values(entities.versions).sort((a, b) =>
      compareNaturalSort(naturalSortKey(a.name), naturalSortKey(b.name))
    );
  }, [entities.versions]);

  // ユーザーリストを取得（ID順）
  const users = useMemo(() => {
    return Object.values(entities.users).sort((a, b) => a.id - b.id);
  }, [entities.users]);

  // ステータスリスト（環境依存、metadataから取得）
  const statuses = useMemo(() => {
    return metadata?.available_statuses || [];
  }, [metadata?.available_statuses]);

  // トラッカーリスト（環境依存、metadataから取得）
  const trackers = useMemo(() => {
    return metadata?.available_trackers || [];
  }, [metadata?.available_trackers]);

  // Epicリストを取得（フィルタ用・自然順ソート）
  const epics = useMemo(() => {
    return Object.values(entities.epics).sort((a, b) =>
      compareNaturalSort(naturalSortKey(a.subject), naturalSortKey(b.subject))
    );
  }, [entities.epics]);

  // Featureリストを取得（フィルタ用・自然順ソート）
  const features = useMemo(() => {
    return Object.values(entities.features).sort((a, b) =>
      compareNaturalSort(naturalSortKey(a.title), naturalSortKey(b.title))
    );
  }, [entities.features]);

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

  // ステータス選択ハンドラー
  const handleStatusChange = (statusId: number, checked: boolean) => {
    setLocalFilters(prev => {
      const currentStatuses = prev.status_id_in || [];
      const newStatuses = checked
        ? [...currentStatuses, statusId]
        : currentStatuses.filter(id => id !== statusId);

      return {
        ...prev,
        status_id_in: newStatuses.length > 0 ? newStatuses : undefined
      };
    });
  };

  // Epic選択ハンドラー
  const handleEpicChange = (epicId: string, checked: boolean) => {
    setLocalFilters(prev => {
      const currentEpics = prev.parent_id_in || [];
      const newEpics = checked
        ? [...currentEpics, epicId]
        : currentEpics.filter(id => id !== epicId);

      return {
        ...prev,
        parent_id_in: newEpics.length > 0 ? newEpics : undefined
      };
    });
  };

  // Feature選択ハンドラー
  const handleFeatureChange = (featureId: string, checked: boolean) => {
    setLocalFilters(prev => {
      const currentFeatures = prev.parent_id_in || [];
      const newFeatures = checked
        ? [...currentFeatures, featureId]
        : currentFeatures.filter(id => id !== featureId);

      return {
        ...prev,
        parent_id_in: newFeatures.length > 0 ? newFeatures : undefined
      };
    });
  };

  // バージョン期日フィルタハンドラー
  const handleEffectiveDateFromChange = (value: string) => {
    setEffectiveDateFrom(value);
    setLocalFilters(prev => ({
      ...prev,
      fixed_version_effective_date_gteq: value || undefined
    }));
  };

  const handleEffectiveDateToChange = (value: string) => {
    setEffectiveDateTo(value);
    setLocalFilters(prev => ({
      ...prev,
      fixed_version_effective_date_lteq: value || undefined
    }));
  };

  // フィルタ適用
  const handleApply = () => {
    setFilters(localFilters);
    setIsExpanded(false);
  };

  // フィルタクリア
  const handleClear = () => {
    setLocalFilters({});
    setEffectiveDateFrom('');
    setEffectiveDateTo('');
    clearFilters();
    setIsExpanded(false);
  };

  // アクティブフィルタ数をカウント
  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.fixed_version_id_in && filters.fixed_version_id_in.length > 0) count++;
    if (filters.assigned_to_id_in && filters.assigned_to_id_in.length > 0) count++;
    if (filters.tracker_id_in && filters.tracker_id_in.length > 0) count++;
    if (filters.status_id_in && filters.status_id_in.length > 0) count++;
    if (filters.parent_id_in && filters.parent_id_in.length > 0) count++;
    if (filters.fixed_version_effective_date_gteq || filters.fixed_version_effective_date_lteq) count++;
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
          {/* クローズ済みバージョン非表示トグル */}
          <div className="filter-section">
            <label className="filter-checkbox">
              <input
                type="checkbox"
                checked={excludeClosedVersions}
                onChange={() => toggleExcludeClosedVersions()}
              />
              <span>クローズ済みバージョンを非表示</span>
            </label>
          </div>

          {/* フィルタでヒットしなかったEpic/Version非表示トグル */}
          <div className="filter-section">
            <label className="filter-checkbox">
              <input
                type="checkbox"
                checked={hideEmptyEpicsVersions}
                onChange={() => toggleHideEmptyEpicsVersions()}
              />
              <span>ヒットしなかったEpic/Versionを非表示</span>
            </label>
          </div>

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
            <h4>バージョン期日</h4>
            <div className="filter-date-range">
              <div className="filter-date-input">
                <label htmlFor="effective-date-from">開始日</label>
                <input
                  id="effective-date-from"
                  type="date"
                  value={effectiveDateFrom}
                  onChange={(e) => handleEffectiveDateFromChange(e.target.value)}
                  placeholder="YYYY-MM-DD"
                />
              </div>
              <span className="filter-date-separator">〜</span>
              <div className="filter-date-input">
                <label htmlFor="effective-date-to">終了日</label>
                <input
                  id="effective-date-to"
                  type="date"
                  value={effectiveDateTo}
                  onChange={(e) => handleEffectiveDateToChange(e.target.value)}
                  placeholder="YYYY-MM-DD"
                />
              </div>
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
              {trackers.length > 0 ? (
                trackers.map(tracker => (
                  <label key={tracker.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.tracker_id_in?.includes(tracker.id) || false}
                      onChange={(e) => handleTrackerChange(tracker.id, e.target.checked)}
                    />
                    <span>{tracker.name}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">トラッカーがありません</p>
              )}
            </div>
          </div>

          <div className="filter-section">
            <h4>ステータス</h4>
            <div className="filter-options">
              {statuses.length > 0 ? (
                statuses.map(status => (
                  <label key={status.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.status_id_in?.includes(status.id) || false}
                      onChange={(e) => handleStatusChange(status.id, e.target.checked)}
                    />
                    <span>{status.name}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">ステータスがありません</p>
              )}
            </div>
          </div>

          <div className="filter-section">
            <h4>Epic</h4>
            <div className="filter-options">
              {epics.length > 0 ? (
                epics.map(epic => (
                  <label key={epic.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.parent_id_in?.includes(epic.id) || false}
                      onChange={(e) => handleEpicChange(epic.id, e.target.checked)}
                    />
                    <span>{epic.subject}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">Epicがありません</p>
              )}
            </div>
          </div>

          <div className="filter-section">
            <h4>Feature</h4>
            <div className="filter-options">
              {features.length > 0 ? (
                features.map(feature => (
                  <label key={feature.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={localFilters.parent_id_in?.includes(feature.id) || false}
                      onChange={(e) => handleFeatureChange(feature.id, e.target.checked)}
                    />
                    <span>{feature.title}</span>
                  </label>
                ))
              ) : (
                <p className="no-options">Featureがありません</p>
              )}
            </div>
          </div>

          <div className="filter-actions">
            <button className="eg-button eg-button--primary" onClick={handleApply}>
              適用
            </button>
            <button className="eg-button eg-button--ghost" onClick={handleClear}>
              クリア
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
