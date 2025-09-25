import React, { useCallback, useState } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { SortableContext, rectSortingStrategy } from '@dnd-kit/sortable';
import FeatureCard from './FeatureCard';
import './GridCell.scss';

/**
 * Grid Cell Component
 * ワイヤーフレーム: Epic行 × Column列 の個別セル
 *
 * @param {Object} props
 * @param {Object} props.epic - Epic データ
 * @param {Object} props.column - Column定義
 * @param {Array} props.features - セル内のFeature配列
 * @param {Object} props.permissions - ユーザー権限情報
 * @param {Function} props.onFeatureClick - Feature クリックコールバック
 * @param {Function} props.onFeatureDrop - Feature ドロップコールバック
 */
const GridCell = ({
  epic,
  column,
  features = [],
  permissions = {},
  onFeatureClick,
  onFeatureDrop,
  ...props
}) => {
  const [isHovered, setIsHovered] = useState(false);

  // ドロップ可能エリア設定
  const { setNodeRef, isOver } = useDroppable({
    id: `cell-${epic.issue.id}-${column.id}`,
    data: {
      type: 'cell',
      epic: epic,
      column: column,
      accepts: ['feature', 'user_story'] // 受け入れ可能なアイテムタイプ
    }
  });

  // Feature クリックハンドラー
  const handleFeatureClick = useCallback((feature) => {
    onFeatureClick?.(feature, epic, column);
  }, [epic, column, onFeatureClick]);

  // セルの統計情報計算
  const cellStatistics = React.useMemo(() => {
    const totalUserStories = features.reduce((sum, feature) =>
      sum + (feature.user_stories?.length || 0), 0
    );

    const completedFeatures = features.filter(feature =>
      feature.issue.status?.is_closed
    ).length;

    return {
      featureCount: features.length,
      totalUserStories,
      completedFeatures,
      completionRatio: features.length > 0 ? (completedFeatures / features.length * 100) : 0
    };
  }, [features]);

  // セルが空かどうか
  const isEmpty = features.length === 0;

  // ドラッグオーバー時のスタイル
  const cellClassName = [
    'grid_cell',
    column.id,
    isEmpty ? 'empty' : 'has_features',
    isOver ? 'drag_over' : '',
    isHovered ? 'hovered' : ''
  ].filter(Boolean).join(' ');

  return (
    <div
      ref={setNodeRef}
      className={cellClassName}
      data-epic={epic.issue.id}
      data-column={column.id}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      {...props}
    >
      {/* CELL_HEADER - 統計情報表示 */}
      <div className="cell_header">
        <div className="cell_statistics">
          <span className="feature_count">
            {cellStatistics.featureCount}
          </span>

          {cellStatistics.featureCount > 0 && (
            <>
              <span className="user_story_count">
                {cellStatistics.totalUserStories} US
              </span>

              <div className="completion_indicator">
                <div
                  className="completion_bar"
                  style={{ width: `${cellStatistics.completionRatio}%` }}
                />
              </div>
            </>
          )}
        </div>

        {/* CELL_ACTIONS - ホバー時表示 */}
        {isHovered && permissions.can_edit && (
          <div className="cell_actions">
            <button
              className="cell_action_btn create_feature"
              title="Create Feature"
              onClick={() => {
                // Create feature in this cell
              }}
            >
              <i className="icon-plus" />
            </button>
          </div>
        )}
      </div>

      {/* CELL_CONTENT */}
      <div className="cell_content">
        {isEmpty ? (
          /* EMPTY_STATE */
          <div className="empty_state">
            <div className="empty_message">
              {isOver ? 'Drop here' : 'No features'}
            </div>

            {isOver && (
              <div className="drop_indicator">
                <i className="icon-arrow-down" />
                <span>Drop to move to {column.name}</span>
              </div>
            )}
          </div>
        ) : (
          /* FEATURES_LIST */
          <SortableContext
            items={features.map(f => `feature-${f.issue.id}`)}
            strategy={rectSortingStrategy}
          >
            <div className="features_list">
              {features.map((feature) => (
                <FeatureCard
                  key={feature.issue.id}
                  feature={feature.issue}
                  userStories={feature.user_stories || []}
                  statistics={feature.statistics}
                  permissions={permissions}
                  onClick={() => handleFeatureClick(feature)}
                  onUserStoryToggle={(userStoryId, expanded) => {
                    // Handle user story expansion
                  }}
                  onBulkAction={(actionType, userStoryIds) => {
                    // Handle bulk actions
                  }}
                />
              ))}
            </div>
          </SortableContext>
        )}
      </div>

      {/* DROP_ZONE_OVERLAY - ドラッグオーバー時の視覚的フィードバック */}
      {isOver && (
        <div className="drop_zone_overlay">
          <div className="drop_zone_content">
            <i className="icon-move" />
            <span className="drop_zone_text">
              Move to {column.name}
            </span>
          </div>
        </div>
      )}

      {/* CELL_CONSTRAINTS_INDICATOR - 制約がある場合の表示 */}
      {column.workflow_constraints && (
        <div className="constraints_indicator" title="Workflow constraints apply">
          <i className="icon-lock" />
        </div>
      )}
    </div>
  );
};

export default GridCell;