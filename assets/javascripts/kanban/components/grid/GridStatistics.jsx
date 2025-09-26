import React, { useState, useMemo, useCallback } from 'react';

/**
 * GridStatistics - プロジェクト統計情報表示コンポーネント
 * 設計書準拠: Epic進捗・Version統計・全体サマリーを視覚的に表示
 *
 * @param {Object} statistics - 統計データオブジェクト
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {boolean} showCharts - グラフ表示制御
 * @param {Function} onFilterChange - フィルター変更コールバック
 * @param {Function} onExport - エクスポートコールバック
 */
export const GridStatistics = ({
  statistics = {},
  compactMode = false,
  showCharts = true,
  onFilterChange,
  onExport
}) => {
  // 1. 状態管理
  const [filters, setFilters] = useState({});
  const [selectedTab, setSelectedTab] = useState('overview');
  const [exportLoading, setExportLoading] = useState(false);

  // 2. 統計データ安全性チェック
  const safeStatistics = useMemo(() => ({
    project: statistics.project || {},
    epics: statistics.epics || [],
    versions: statistics.versions || [],
    overview: statistics.overview || {},
    trends: statistics.trends || [],
    lastUpdated: statistics.lastUpdated || new Date().toISOString()
  }), [statistics]);

  // 3. KPI指標計算（メモ化）
  const kpiMetrics = useMemo(() => {
    const { project, epics, versions } = safeStatistics;

    return {
      totalEpics: epics.length,
      totalFeatures: project.totalFeatures || 0,
      totalVersions: versions.length,
      overallCompletion: project.completionRate || 0,
      activeEpics: epics.filter(epic => epic.completionRate < 100).length,
      overdueVersions: versions.filter(version => version.isOverdue).length
    };
  }, [safeStatistics]);

  // 4. フィルター適用統計データ（メモ化）
  const filteredStatistics = useMemo(() => {
    // TODO: フィルター適用ロジック実装
    return safeStatistics;
  }, [safeStatistics, filters]);

  // 5. イベントハンドラー
  const handleFilterChange = useCallback((newFilters) => {
    setFilters(newFilters);
    onFilterChange?.(newFilters);
  }, [onFilterChange]);

  const handleExport = useCallback(async (format) => {
    setExportLoading(true);
    try {
      await onExport?.(format);
    } finally {
      setExportLoading(false);
    }
  }, [onExport]);

  const handleTabChange = useCallback((tab) => {
    setSelectedTab(tab);
  }, []);

  // 6. レンダリング
  return (
    <div className={`grid-statistics ${compactMode ? 'compact' : ''}`}>
      {/* 統計情報ヘッダー */}
      <StatisticsHeader
        filters={filters}
        onFilterChange={handleFilterChange}
        lastUpdated={safeStatistics.lastUpdated}
        compactMode={compactMode}
      />

      {/* 統計情報コンテンツ */}
      <StatisticsContent
        statistics={filteredStatistics}
        kpiMetrics={kpiMetrics}
        selectedTab={selectedTab}
        onTabChange={handleTabChange}
        showCharts={showCharts}
        compactMode={compactMode}
      />

      {/* 統計情報フッター */}
      <StatisticsFooter
        onExport={handleExport}
        exportLoading={exportLoading}
        lastUpdated={safeStatistics.lastUpdated}
      />
    </div>
  );
};

/**
 * StatisticsHeader - 統計情報ヘッダーコンポーネント
 */
const StatisticsHeader = ({ filters, onFilterChange, lastUpdated, compactMode }) => {
  const formatLastUpdated = (timestamp) => {
    try {
      return new Date(timestamp).toLocaleString();
    } catch {
      return 'Unknown';
    }
  };

  return (
    <div className="statistics-header">
      <div className="title-section">
        <h3>📊 Project Statistics</h3>
        {!compactMode && (
          <span className="last-updated">
            Last updated: {formatLastUpdated(lastUpdated)}
          </span>
        )}
      </div>

      {!compactMode && (
        <div className="filter-controls">
          {/* TODO: フィルターコントロール実装 */}
          <button
            className="refresh-button"
            onClick={() => window.location.reload()}
            title="Refresh Statistics"
          >
            🔄
          </button>
        </div>
      )}
    </div>
  );
};

/**
 * StatisticsContent - 統計情報メインコンテンツ
 */
const StatisticsContent = ({
  statistics,
  kpiMetrics,
  selectedTab,
  onTabChange,
  showCharts,
  compactMode
}) => {
  return (
    <div className="statistics-content">
      {/* Overview Panel - KPI Cards */}
      <OverviewPanel kpiMetrics={kpiMetrics} compactMode={compactMode} />

      {/* Detail Panels - Tabbed Interface */}
      {!compactMode && (
        <DetailPanels
          statistics={statistics}
          selectedTab={selectedTab}
          onTabChange={onTabChange}
          showCharts={showCharts}
        />
      )}
    </div>
  );
};

/**
 * OverviewPanel - プロジェクト概要統計表示
 */
const OverviewPanel = ({ kpiMetrics, compactMode }) => {
  const kpiCards = [
    {
      label: 'Total Epics',
      value: kpiMetrics.totalEpics,
      icon: '🗂️',
      color: '#2196F3'
    },
    {
      label: 'Total Features',
      value: kpiMetrics.totalFeatures,
      icon: '⭐',
      color: '#4CAF50'
    },
    {
      label: 'Completion Rate',
      value: `${kpiMetrics.overallCompletion}%`,
      icon: '📈',
      color: '#FF9800'
    },
    {
      label: 'Active Epics',
      value: kpiMetrics.activeEpics,
      icon: '🚧',
      color: '#9C27B0'
    }
  ];

  return (
    <div className="overview-panel">
      <div className={`kpi-cards ${compactMode ? 'compact' : ''}`}>
        {kpiCards.map(card => (
          <KPICard
            key={card.label}
            {...card}
            compactMode={compactMode}
          />
        ))}
      </div>

      {/* Overall Progress Bar */}
      <div className="overall-progress">
        <div className="progress-label">
          Overall Project Completion
        </div>
        <div className="progress-bar">
          <div
            className="progress-fill"
            style={{
              width: `${kpiMetrics.overallCompletion}%`,
              backgroundColor: '#4CAF50'
            }}
          />
        </div>
        <div className="progress-text">
          {kpiMetrics.overallCompletion}% Complete
        </div>
      </div>
    </div>
  );
};

/**
 * KPICard - KPI指標表示カード
 */
const KPICard = ({ label, value, icon, color, compactMode }) => (
  <div className={`kpi-card ${compactMode ? 'compact' : ''}`} style={{ borderColor: color }}>
    <div className="kpi-icon" style={{ color }}>
      {icon}
    </div>
    <div className="kpi-content">
      <div className="kpi-value">{value}</div>
      {!compactMode && <div className="kpi-label">{label}</div>}
    </div>
  </div>
);

/**
 * DetailPanels - 詳細統計情報タブパネル
 */
const DetailPanels = ({ statistics, selectedTab, onTabChange, showCharts }) => {
  const tabs = [
    { id: 'overview', label: 'Overview', icon: '📊' },
    { id: 'epics', label: 'Epic Statistics', icon: '🗂️' },
    { id: 'versions', label: 'Version Statistics', icon: '🏷️' },
    { id: 'distribution', label: 'Distribution', icon: '📈' }
  ];

  return (
    <div className="detail-panels">
      {/* Tab Navigation */}
      <div className="tab-navigation">
        {tabs.map(tab => (
          <button
            key={tab.id}
            className={`tab-button ${selectedTab === tab.id ? 'active' : ''}`}
            onClick={() => onTabChange(tab.id)}
          >
            <span className="tab-icon">{tab.icon}</span>
            <span className="tab-label">{tab.label}</span>
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        {selectedTab === 'overview' && (
          <OverviewTabContent statistics={statistics} />
        )}
        {selectedTab === 'epics' && (
          <EpicStatisticsTabContent epics={statistics.epics} />
        )}
        {selectedTab === 'versions' && (
          <VersionStatisticsTabContent versions={statistics.versions} />
        )}
        {selectedTab === 'distribution' && showCharts && (
          <DistributionTabContent statistics={statistics} />
        )}
      </div>
    </div>
  );
};

/**
 * タブコンテンツコンポーネント群
 */
const OverviewTabContent = ({ statistics }) => (
  <div className="overview-tab">
    <h4>Project Summary</h4>
    <div className="summary-grid">
      <div className="summary-item">
        <strong>Total Issues:</strong> {statistics.project.totalFeatures || 0}
      </div>
      <div className="summary-item">
        <strong>Completion Rate:</strong> {statistics.project.completionRate || 0}%
      </div>
      <div className="summary-item">
        <strong>Active Versions:</strong> {statistics.versions.filter(v => !v.isOverdue).length}
      </div>
    </div>
  </div>
);

const EpicStatisticsTabContent = ({ epics }) => (
  <div className="epic-statistics-tab">
    <h4>Epic Progress</h4>
    {epics.length === 0 ? (
      <p className="no-data">No epic data available</p>
    ) : (
      <div className="epic-list">
        {epics.map(epic => (
          <div key={epic.epicId} className="epic-item">
            <div className="epic-header">
              <strong>{epic.epicName}</strong>
              <span className="completion-badge">
                {epic.completionRate || 0}%
              </span>
            </div>
            <div className="epic-progress-bar">
              <div
                className="epic-progress-fill"
                style={{ width: `${epic.completionRate || 0}%` }}
              />
            </div>
            <div className="epic-details">
              Features: {epic.totalFeatures || 0} |
              Completed: {epic.completedFeatures || 0}
            </div>
          </div>
        ))}
      </div>
    )}
  </div>
);

const VersionStatisticsTabContent = ({ versions }) => (
  <div className="version-statistics-tab">
    <h4>Version Status</h4>
    {versions.length === 0 ? (
      <p className="no-data">No version data available</p>
    ) : (
      <div className="version-list">
        {versions.map(version => (
          <div key={version.versionId} className="version-item">
            <div className="version-header">
              <strong>{version.versionName}</strong>
              <span className={`status-badge ${version.isOverdue ? 'overdue' : 'on-track'}`}>
                {version.isOverdue ? '🚨 Overdue' : '✅ On Track'}
              </span>
            </div>
            <div className="version-details">
              Release: {version.releaseDate} |
              Progress: {version.completionRate || 0}% |
              Issues: {version.completedIssues || 0}/{version.totalIssues || 0}
            </div>
          </div>
        ))}
      </div>
    )}
  </div>
);

const DistributionTabContent = ({ statistics }) => (
  <div className="distribution-tab">
    <h4>Issue Distribution</h4>
    <p className="chart-placeholder">
      📊 Charts will be implemented with Recharts library
    </p>
    <div className="distribution-summary">
      <p>Epic Distribution: {statistics.epics.length} epics</p>
      <p>Version Distribution: {statistics.versions.length} versions</p>
    </div>
  </div>
);

/**
 * StatisticsFooter - 統計情報フッター
 */
const StatisticsFooter = ({ onExport, exportLoading, lastUpdated }) => {
  return (
    <div className="statistics-footer">
      <div className="footer-info">
        <small>Last updated: {new Date(lastUpdated).toLocaleString()}</small>
      </div>

      <div className="export-actions">
        <button
          onClick={() => onExport?.('csv')}
          disabled={exportLoading}
          className="export-button"
        >
          📊 Export CSV
        </button>
        <button
          onClick={() => onExport?.('pdf')}
          disabled={exportLoading}
          className="export-button"
        >
          📄 Export PDF
        </button>
      </div>
    </div>
  );
};

export default GridStatistics;