import React, { useState, useCallback, useMemo } from 'react';
import {
  DndContext,
  DragOverlay,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  rectSortingStrategy,
} from '@dnd-kit/sortable';
import GridCell from './GridCell';
import FeatureCard from './FeatureCard';
import VersionBar from './VersionBar';
import './KanbanGridLayout.scss';

/**
 * Kanban Grid Layout Component
 * ワイヤーフレーム: GROUP_KANBAN_GRID準拠 (Epic行 × Version列)
 *
 * @param {Object} props
 * @param {Array} props.epics - Epic データ配列
 * @param {Array} props.versions - Version データ配列
 * @param {Array} props.columns - カラム定義配列
 * @param {Object} props.metadata - メタデータ
 * @param {Function} props.onCardMove - カード移動コールバック
 * @param {Function} props.onVersionAssign - バージョン割り当てコールバック
 * @param {Function} props.onBulkAction - 一括操作コールバック
 * @param {Object} props.permissions - ユーザー権限情報
 */
const KanbanGridLayout = ({
  epics = [],
  versions = [],
  columns = [],
  metadata = {},
  onCardMove,
  onVersionAssign,
  onBulkAction,
  permissions = {},
  ...props
}) => {
  const [activeCard, setActiveCard] = useState(null);
  const [selectedVersions, setSelectedVersions] = useState(new Set());
  const [gridFilters, setGridFilters] = useState({
    showOnlyAssigned: false,
    hideCompleted: false,
    versionFilter: null
  });

  // DnD センサー設定
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // グリッドデータの構築とフィルタリング
  const gridData = useMemo(() => {
    const filteredEpics = epics.filter(epic => {
      if (gridFilters.hideCompleted && epic.issue.status?.is_closed) return false;
      return true;
    });

    const filteredVersions = versions.filter(version => {
      if (gridFilters.versionFilter && version.id !== gridFilters.versionFilter) return false;
      return true;
    });

    return {
      epics: filteredEpics,
      versions: filteredVersions
    };
  }, [epics, versions, gridFilters]);

  // ドラッグ開始ハンドラー
  const handleDragStart = useCallback((event) => {
    const { active } = event;
    setActiveCard(active.data.current);
  }, []);

  // ドラッグ終了ハンドラー
  const handleDragEnd = useCallback((event) => {
    const { active, over } = event;

    setActiveCard(null);

    if (!over) return;

    const draggedItem = active.data.current;
    const dropTarget = over.data.current;

    // 移動処理を実行
    if (draggedItem && dropTarget) {
      onCardMove?.(draggedItem, dropTarget);
    }
  }, [onCardMove]);

  // バージョン選択ハンドラー
  const handleVersionSelect = useCallback((versionId, selected) => {
    setSelectedVersions(prev => {
      const newSet = new Set(prev);
      if (selected) {
        newSet.add(versionId);
      } else {
        newSet.delete(versionId);
      }
      return newSet;
    });
  }, []);

  // フィルター変更ハンドラー
  const handleFilterChange = useCallback((filterType, value) => {
    setGridFilters(prev => ({
      ...prev,
      [filterType]: value
    }));
  }, []);

  // セル内のFeatureを検索
  const getFeaturesForCell = useCallback((epic, version, column) => {
    if (!epic.features) return [];

    return epic.features.filter(feature => {
      // バージョンマッチング
      if (version) {
        const featureMatches = feature.issue.fixed_version?.id === version.id;
        const userStoryMatches = feature.user_stories?.some(us =>
          us.issue.fixed_version?.id === version.id
        );
        if (!featureMatches && !userStoryMatches) return false;
      }

      // カラムマッチング（ステータスベース）
      if (column) {
        const statusMatches = column.statuses?.includes(feature.issue.status?.name);
        return statusMatches;
      }

      return true;
    });
  }, []);

  return (
    <div className="group_kanban_grid" {...props}>
      {/* GRID_HEADER */}
      <div className="grid_header">
        {/* VERSION_BAR */}
        <VersionBar
          versions={gridData.versions}
          selectedVersions={selectedVersions}
          onVersionSelect={handleVersionSelect}
          onVersionCreate={permissions.can_manage_versions ? onVersionAssign : null}
          permissions={permissions}
        />

        {/* GRID_FILTERS */}
        <div className="grid_filters">
          <label className="filter_option">
            <input
              type="checkbox"
              checked={gridFilters.showOnlyAssigned}
              onChange={(e) => handleFilterChange('showOnlyAssigned', e.target.checked)}
            />
            Show only assigned
          </label>

          <label className="filter_option">
            <input
              type="checkbox"
              checked={gridFilters.hideCompleted}
              onChange={(e) => handleFilterChange('hideCompleted', e.target.checked)}
            />
            Hide completed
          </label>

          <select
            value={gridFilters.versionFilter || ''}
            onChange={(e) => handleFilterChange('versionFilter', e.target.value || null)}
            className="version_filter"
          >
            <option value="">All versions</option>
            {versions.map(version => (
              <option key={version.id} value={version.id}>
                {version.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* GRID_MAIN */}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="grid_main">
          {/* COLUMN_HEADERS */}
          <div className="column_headers">
            <div className="epic_column_header">Epics</div>
            {columns.map(column => (
              <div key={column.id} className="grid_column_header" data-column={column.id}>
                <span className="column_name">{column.name}</span>
                <span className="column_count">
                  {/* TODO: Calculate count per column */}
                </span>
              </div>
            ))}
          </div>

          {/* GRID_BODY */}
          <div className="grid_body">
            {gridData.epics.map((epic, rowIndex) => (
              <div key={epic.issue.id} className="grid_row" data-epic={epic.issue.id}>
                {/* EPIC_CELL */}
                <div className="epic_cell">
                  <div className="epic_info">
                    <span className="epic_id">#{epic.issue.id}</span>
                    <span className="epic_title">{epic.issue.subject}</span>
                    <span className="epic_status">{epic.issue.status?.name}</span>
                  </div>
                  <div className="epic_statistics">
                    <span className="feature_count">
                      {epic.features?.length || 0} Features
                    </span>
                    <div className="epic_progress">
                      <div
                        className="progress_bar"
                        style={{
                          width: `${epic.completion_ratio || 0}%`
                        }}
                      />
                    </div>
                  </div>
                </div>

                {/* GRID_CELLS */}
                {columns.map(column => {
                  const cellFeatures = getFeaturesForCell(epic, null, column);

                  return (
                    <GridCell
                      key={`${epic.issue.id}-${column.id}`}
                      epic={epic}
                      column={column}
                      features={cellFeatures}
                      permissions={permissions}
                      onFeatureClick={(feature) => {
                        // Handle feature click
                      }}
                    />
                  );
                })}
              </div>
            ))}
          </div>

          {/* VERSION_GRID_OVERLAY - バージョン割り当て時に表示 */}
          {selectedVersions.size > 0 && (
            <div className="version_grid_overlay">
              {gridData.epics.map(epic => (
                <div key={epic.issue.id} className="version_row">
                  <div className="epic_cell_overlay">
                    <span className="epic_title">{epic.issue.subject}</span>
                  </div>
                  {gridData.versions.map(version => {
                    const versionFeatures = getFeaturesForCell(epic, version, null);

                    return (
                      <div
                        key={`${epic.issue.id}-${version.id}`}
                        className={`version_cell ${selectedVersions.has(version.id) ? 'selected' : ''}`}
                      >
                        {versionFeatures.map(feature => (
                          <FeatureCard
                            key={feature.issue.id}
                            feature={feature.issue}
                            userStories={feature.user_stories || []}
                            statistics={feature.statistics}
                            permissions={permissions}
                            isDragDisabled={false}
                          />
                        ))}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* DRAG_OVERLAY */}
        <DragOverlay>
          {activeCard ? (
            <div className="drag_overlay_item">
              {activeCard.type === 'feature' && (
                <FeatureCard
                  feature={activeCard.feature}
                  userStories={activeCard.feature.user_stories || []}
                  isDragDisabled={true}
                />
              )}
              {['task', 'test', 'bug'].includes(activeCard.type) && (
                <div className={`base_item_drag_overlay ${activeCard.type}`}>
                  #{activeCard.item.id} {activeCard.item.subject}
                </div>
              )}
            </div>
          ) : null}
        </DragOverlay>
      </DndContext>

      {/* GRID_FOOTER */}
      <div className="grid_footer">
        <div className="grid_statistics">
          <span className="total_epics">{gridData.epics.length} Epics</span>
          <span className="total_features">
            {gridData.epics.reduce((sum, epic) => sum + (epic.features?.length || 0), 0)} Features
          </span>
          <span className="completion_ratio">
            {/* TODO: Calculate overall completion */}
            Overall completion: 0%
          </span>
        </div>
      </div>
    </div>
  );
};

export default KanbanGridLayout;