import { useState, useCallback, useMemo } from 'react';

/**
 * GridHeader - 設計書準拠のグリッドヘッダーコンポーネント
 * 設計書仕様: ProjectTitle + VersionHeaders + NewVersionButton
 *
 * @param {string} projectTitle - プロジェクトタイトル
 * @param {Array} versionColumns - Version列配列
 * @param {Function} onNewVersion - 新Version作成コールバック
 * @param {boolean} showStatistics - 統計情報表示フラグ
 * @param {boolean} enableFiltering - フィルタリング有効フラグ
 * @param {Function} onFiltersChange - フィルター変更コールバック
 * @param {boolean} compactMode - コンパクト表示モード
 */
export const GridHeader = ({
  projectTitle,
  versionColumns = [],
  onNewVersion,
  showStatistics = true,
  enableFiltering = true,
  onFiltersChange,
  compactMode = false
}) => {
  // フィルター状態管理
  const [filterState, setFilterState] = useState({
    keyword: '',
    statusFilter: 'all',
    assignedToMe: false,
    completedOnly: false
  });

  // 新Version作成状態
  const [isCreatingVersion, setIsCreatingVersion] = useState(false);
  const [newVersionData, setNewVersionData] = useState({
    name: '',
    description: '',
    effective_date: ''
  });

  // フィルター変更処理
  const handleFilterChange = useCallback((newFilters) => {
    const updatedFilters = { ...filterState, ...newFilters };
    setFilterState(updatedFilters);
    onFiltersChange?.(updatedFilters);
  }, [filterState, onFiltersChange]);

  // 新Version作成処理
  const handleCreateVersion = useCallback(async () => {
    if (!newVersionData.name.trim()) {
      alert('Version名を入力してください');
      return;
    }

    try {
      setIsCreatingVersion(true);
      const createdVersion = await onNewVersion(newVersionData);

      if (createdVersion) {
        // 作成成功時の処理
        setNewVersionData({ name: '', description: '', effective_date: '' });
        setIsCreatingVersion(false);
      }
    } catch (error) {
      console.error('Version作成エラー:', error);
      alert(`Version作成に失敗しました: ${error.message}`);
    } finally {
      setIsCreatingVersion(false);
    }
  }, [newVersionData, onNewVersion]);

  // Version統計計算
  const versionStatistics = useMemo(() => {
    if (!showStatistics) return null;

    return versionColumns.reduce((stats, version) => {
      const issueCount = version.issue_count || 0;
      stats.totalIssues += issueCount;
      stats.totalVersions += 1;

      if (version.status === 'open') {
        stats.activeVersions += 1;
      }

      return stats;
    }, {
      totalIssues: 0,
      totalVersions: 0,
      activeVersions: 0
    });
  }, [versionColumns, showStatistics]);

  return (
    <div className={`kanban-grid-header ${compactMode ? 'compact' : ''}`}>
      {/* プロジェクトタイトル部 */}
      <div className="grid-header-title-section">
        <div className="project-title-cell">
          <h2 className="project-title">{projectTitle}</h2>

          {showStatistics && versionStatistics && (
            <div className="project-statistics">
              <span className="stat-item">
                <span className="stat-label">Versions:</span>
                <span className="stat-value">{versionStatistics.totalVersions}</span>
              </span>
              <span className="stat-item">
                <span className="stat-label">Issues:</span>
                <span className="stat-value">{versionStatistics.totalIssues}</span>
              </span>
              <span className="stat-item">
                <span className="stat-label">Active:</span>
                <span className="stat-value">{versionStatistics.activeVersions}</span>
              </span>
            </div>
          )}
        </div>

        {/* フィルター部（設計書67-71行目準拠） */}
        {enableFiltering && (
          <div className="grid-header-filters">
            <div className="filter-group">
              <input
                type="text"
                placeholder="キーワード検索..."
                value={filterState.keyword}
                onChange={(e) => handleFilterChange({ keyword: e.target.value })}
                className="filter-input filter-keyword"
              />

              <select
                value={filterState.statusFilter}
                onChange={(e) => handleFilterChange({ statusFilter: e.target.value })}
                className="filter-select filter-status"
              >
                <option value="all">全ステータス</option>
                <option value="open">進行中</option>
                <option value="resolved">解決済み</option>
                <option value="closed">完了</option>
              </select>

              <label className="filter-checkbox">
                <input
                  type="checkbox"
                  checked={filterState.assignedToMe}
                  onChange={(e) => handleFilterChange({ assignedToMe: e.target.checked })}
                />
                自分の担当のみ
              </label>

              <label className="filter-checkbox">
                <input
                  type="checkbox"
                  checked={filterState.completedOnly}
                  onChange={(e) => handleFilterChange({ completedOnly: e.target.checked })}
                />
                完了済みのみ
              </label>
            </div>
          </div>
        )}
      </div>

      {/* Version列ヘッダー部（設計書67-85行目準拠） */}
      <div className="grid-header-columns">
        {versionColumns.map((version) => (
          <div
            key={version.id}
            className={`version-column-header ${version.type === 'no-version' ? 'no-version' : ''}`}
          >
            <div className="version-header-content">
              <h3 className="version-name" title={version.description}>
                {version.name}
              </h3>

              {version.effective_date && (
                <div className="version-date">
                  {new Date(version.effective_date).toLocaleDateString()}
                </div>
              )}

              {showStatistics && version.issue_count !== undefined && (
                <div className="version-statistics">
                  <span className="issue-count">{version.issue_count} issues</span>
                  {version.status && (
                    <span className={`version-status ${version.status}`}>
                      {version.status}
                    </span>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}

        {/* 新Version作成ボタン（設計書71行目準拠） */}
        <div className="new-version-column">
          {!isCreatingVersion ? (
            <button
              className="new-version-button"
              onClick={() => setIsCreatingVersion(true)}
              title="新しいVersionを作成"
            >
              <span className="plus-icon">+</span>
              <span className="button-text">New Version</span>
            </button>
          ) : (
            <div className="new-version-form">
              <div className="form-group">
                <input
                  type="text"
                  placeholder="Version名"
                  value={newVersionData.name}
                  onChange={(e) => setNewVersionData({
                    ...newVersionData,
                    name: e.target.value
                  })}
                  className="version-name-input"
                  autoFocus
                />
              </div>

              <div className="form-group">
                <input
                  type="date"
                  placeholder="リリース予定日"
                  value={newVersionData.effective_date}
                  onChange={(e) => setNewVersionData({
                    ...newVersionData,
                    effective_date: e.target.value
                  })}
                  className="version-date-input"
                />
              </div>

              <div className="form-group">
                <textarea
                  placeholder="説明（任意）"
                  value={newVersionData.description}
                  onChange={(e) => setNewVersionData({
                    ...newVersionData,
                    description: e.target.value
                  })}
                  className="version-description-input"
                  rows="2"
                />
              </div>

              <div className="form-actions">
                <button
                  onClick={handleCreateVersion}
                  disabled={!newVersionData.name.trim()}
                  className="create-button"
                >
                  作成
                </button>
                <button
                  onClick={() => {
                    setIsCreatingVersion(false);
                    setNewVersionData({ name: '', description: '', effective_date: '' });
                  }}
                  className="cancel-button"
                >
                  キャンセル
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default GridHeader;