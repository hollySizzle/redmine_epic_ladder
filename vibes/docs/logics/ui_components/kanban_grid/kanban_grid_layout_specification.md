# Kanban Grid Layout コンポーネント設計仕様書

## 🔗 関連ドキュメント
- @vibes/specs/ui/kanban_ui_grid_layout.drawio
- @vibes/specs/ui/kanban_ui_feature_card_component.drawio
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md

## 1. 概要

2次元グリッドレイアウト（EPIC行 × Version列）でFeature Cardを配置するカンバン表示システム。ワイヤーフレーム準拠のバージョン管理とEpicスイムレーン統合。

## 2. グリッド構造設計

### 2.1 レイアウト構成
```
┌─────────────────────────────────────────────────────────────┐
│ Header: Epic Kanban Board                                   │
├─────────────┬──────────────┬──────────────┬──────────────────┤
│ EPIC        │ Version-1    │ Version-2    │ Version-3 │ No Version │
├─────────────┼──────────────┼──────────────┼──────────────────┤
│施設・ユーザー│ [FeatureCard]│ [FeatureCard]│              │            │
│管理          │              │              │              │ [未割当]   │
├─────────────┼──────────────┼──────────────┼──────────────────┤
│開診         │              │ [FeatureCard]│ [FeatureCard]│            │
│スケジュール  │              │              │              │            │
├─────────────┼──────────────┼──────────────┼──────────────────┤
│運用監視体制  │              │              │ [FeatureCard]│            │
├─────────────┼──────────────┼──────────────┼──────────────────┤
│No EPIC      │ [FeatureCard]│              │              │            │
├─────────────┼──────────────┼──────────────┼──────────────────┤
│+ New Epic   │              │              │              │            │
└─────────────┴──────────────┴──────────────┴──────────────────┘
```

### 2.2 コンポーネント階層
```
KanbanGridLayout
├── GridHeader
│   ├── ProjectTitle
│   └── VersionHeaders[]
│       ├── VersionColumn
│       ├── NewVersionButton
│       └── NoVersionColumn
├── EpicRows[]
│   ├── EpicHeaderCell
│   └── VersionCells[]
│       └── FeatureCard[] (from feature_card_component)
├── NoEpicRow
│   ├── NoEpicHeaderCell
│   └── VersionCells[]
└── NewEpicRow
    └── NewEpicButton
```

## 3. React コンポーネント実装

### 3.1 KanbanGridLayout (メインコンポーネント)

```javascript
// assets/javascripts/kanban/components/KanbanGridLayout.jsx
import React, { useState, useEffect, useMemo } from 'react';
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core';
import { GridHeader } from './GridHeader';
import { EpicRow } from './EpicRow';
import { NoEpicRow } from './NoEpicRow';
import { NewEpicRow } from './NewEpicRow';
import { FeatureCard } from '../feature_card/FeatureCard';
import { KanbanAPI } from '../../utils/KanbanAPI';

export const KanbanGridLayout = ({
  projectId,
  currentUser,
  initialData,
  onDataUpdate
}) => {
  const [gridData, setGridData] = useState(initialData || { epics: [], versions: [] });
  const [activeCard, setActiveCard] = useState(null);
  const [draggedOverCell, setDraggedOverCell] = useState(null);
  const [loading, setLoading] = useState(!initialData);

  // バージョン列の定義（固定 + 動的）
  const versionColumns = useMemo(() => {
    const dynamicVersions = gridData.versions.map(version => ({
      id: version.id,
      name: version.name,
      type: 'version'
    }));

    return [
      ...dynamicVersions,
      { id: 'no-version', name: 'No Version', type: 'no-version' }
    ];
  }, [gridData.versions]);

  // Epic行の定義
  const epicRows = useMemo(() => {
    const epics = gridData.epics.map(epic => ({
      id: epic.issue.id,
      name: epic.issue.subject,
      type: 'epic',
      data: epic
    }));

    return [
      ...epics,
      { id: 'no-epic', name: 'No EPIC', type: 'no-epic', data: null }
    ];
  }, [gridData.epics]);

  useEffect(() => {
    if (!initialData) {
      loadGridData();
    }
  }, [projectId]);

  const loadGridData = async () => {
    try {
      setLoading(true);
      const data = await KanbanAPI.getGridData(projectId);
      setGridData(data);
    } catch (error) {
      console.error('グリッドデータ読み込みエラー:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDragStart = (event) => {
    const { active } = event;
    setActiveCard(active.data.current);
  };

  const handleDragOver = (event) => {
    const { over } = event;
    if (over && over.data.current?.type === 'grid-cell') {
      setDraggedOverCell(over.data.current);
    } else {
      setDraggedOverCell(null);
    }
  };

  const handleDragEnd = async (event) => {
    const { active, over } = event;

    if (!over || !over.data.current) return;

    const draggedCard = active.data.current;
    const dropTarget = over.data.current;

    try {
      if (dropTarget.type === 'grid-cell') {
        await handleFeatureCardMove(draggedCard, dropTarget);
      } else if (dropTarget.type === 'version-assignment') {
        await handleVersionAssignment(draggedCard, dropTarget);
      }
    } catch (error) {
      console.error('ドラッグ操作エラー:', error);
    } finally {
      setActiveCard(null);
      setDraggedOverCell(null);
      await loadGridData(); // データ再読み込み
    }
  };

  const handleFeatureCardMove = async (card, target) => {
    const { epicId, versionId } = target;

    const result = await KanbanAPI.moveFeatureCard(projectId, {
      feature_id: card.feature.issue.id,
      target_epic_id: epicId === 'no-epic' ? null : epicId,
      target_version_id: versionId === 'no-version' ? null : versionId
    });

    if (result.success) {
      onDataUpdate?.(result.updated_data);
    }
  };

  const handleVersionAssignment = async (card, target) => {
    await KanbanAPI.assignVersion(projectId, {
      issue_id: card.feature.issue.id,
      version_id: target.versionId
    });
  };

  const getCellFeatures = (epicId, versionId) => {
    if (epicId === 'no-epic') {
      // No Epic行の場合：親が存在しないFeatureを取得
      return gridData.orphan_features?.filter(feature => {
        const featureVersionId = feature.issue.fixed_version?.id;
        if (versionId === 'no-version') {
          return !featureVersionId;
        }
        return featureVersionId === versionId;
      }) || [];
    }

    // 通常Epic行の場合
    const epic = gridData.epics.find(e => e.issue.id === epicId);
    if (!epic) return [];

    return epic.features.filter(feature => {
      const featureVersionId = feature.issue.fixed_version?.id;
      if (versionId === 'no-version') {
        return !featureVersionId;
      }
      return featureVersionId === versionId;
    });
  };

  if (loading) {
    return <div className="kanban-grid-loading">グリッドデータを読み込み中...</div>;
  }

  return (
    <div className="kanban-grid-layout">
      <DndContext
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragOver={handleDragOver}
        onDragEnd={handleDragEnd}
      >
        <GridHeader
          projectTitle={`Epic Kanban Board - ${gridData.project?.name || ''}`}
          versionColumns={versionColumns}
          onNewVersion={() => handleNewVersion()}
        />

        <div className="grid-body">
          {epicRows.map(epicRow => (
            epicRow.type === 'no-epic' ? (
              <NoEpicRow
                key={epicRow.id}
                versionColumns={versionColumns}
                getCellFeatures={(versionId) => getCellFeatures(epicRow.id, versionId)}
                draggedOverCell={draggedOverCell}
              />
            ) : (
              <EpicRow
                key={epicRow.id}
                epic={epicRow.data}
                versionColumns={versionColumns}
                getCellFeatures={(versionId) => getCellFeatures(epicRow.id, versionId)}
                draggedOverCell={draggedOverCell}
              />
            )
          ))}

          <NewEpicRow
            onNewEpic={() => handleNewEpic()}
          />
        </div>

        <DragOverlay>
          {activeCard && (
            <FeatureCard
              feature={activeCard.feature}
              expanded={false}
              isDragging={true}
            />
          )}
        </DragOverlay>
      </DndContext>
    </div>
  );

  async function handleNewVersion() {
    const versionName = prompt('新しいVersionの名前を入力してください:');
    if (versionName) {
      try {
        await KanbanAPI.createVersion(projectId, { name: versionName });
        await loadGridData();
      } catch (error) {
        alert('Version作成に失敗しました: ' + error.message);
      }
    }
  }

  async function handleNewEpic() {
    const epicSubject = prompt('新しいEpicの件名を入力してください:');
    if (epicSubject) {
      try {
        await KanbanAPI.createEpic(projectId, { subject: epicSubject });
        await loadGridData();
      } catch (error) {
        alert('Epic作成に失敗しました: ' + error.message);
      }
    }
  }
};
```

### 3.2 GridHeader

```javascript
// assets/javascripts/kanban/components/GridHeader.jsx
import React from 'react';

export const GridHeader = ({
  projectTitle,
  versionColumns,
  onNewVersion
}) => {
  return (
    <div className="grid-header">
      <div className="project-title-header">
        {projectTitle}
      </div>

      <div className="version-headers">
        <div className="epic-column-header">EPIC</div>

        {versionColumns.map(column => (
          <div
            key={column.id}
            className={`version-column-header ${column.type}`}
          >
            <span className="version-name">{column.name}</span>

            {column.type === 'version' && (
              <button
                className="version-actions-btn"
                onClick={() => handleVersionActions(column)}
                title="Version操作"
              >
                ⋮
              </button>
            )}
          </div>
        ))}

        <button
          className="new-version-btn"
          onClick={onNewVersion}
          title="新しいVersionを作成"
        >
          + New Version
        </button>
      </div>
    </div>
  );

  function handleVersionActions(version) {
    // Version編集・削除などのアクションメニュー
    const action = prompt(`Version "${version.name}" の操作を選択:\n1. 編集\n2. 削除\n数字を入力:`);

    if (action === '1') {
      const newName = prompt('新しいVersion名:', version.name);
      if (newName && newName !== version.name) {
        // バージョン名更新処理
        console.log('Version名更新:', { id: version.id, newName });
      }
    } else if (action === '2') {
      if (confirm(`Version "${version.name}" を削除しますか？`)) {
        // バージョン削除処理
        console.log('Version削除:', version.id);
      }
    }
  }
};
```

### 3.3 EpicRow

```javascript
// assets/javascripts/kanban/components/EpicRow.jsx
import React from 'react';
import { GridCell } from './GridCell';

export const EpicRow = ({
  epic,
  versionColumns,
  getCellFeatures,
  draggedOverCell
}) => {
  return (
    <div className="epic-row">
      <div className="epic-header-cell">
        <span className="epic-name">{epic.issue.subject}</span>

        <div className="epic-stats">
          <span className="feature-count">
            {epic.features?.length || 0} Features
          </span>
        </div>

        <button
          className="epic-actions-btn"
          onClick={() => handleEpicActions(epic)}
          title="Epic操作"
        >
          ⋮
        </button>
      </div>

      {versionColumns.map(versionColumn => {
        const cellFeatures = getCellFeatures(versionColumn.id);
        const isDropTarget = draggedOverCell?.epicId === epic.issue.id &&
                           draggedOverCell?.versionId === versionColumn.id;

        return (
          <GridCell
            key={`${epic.issue.id}-${versionColumn.id}`}
            epicId={epic.issue.id}
            versionId={versionColumn.id}
            features={cellFeatures}
            isDropTarget={isDropTarget}
            cellType={versionColumn.type}
          />
        );
      })}
    </div>
  );

  function handleEpicActions(epic) {
    const action = prompt(`Epic "${epic.issue.subject}" の操作を選択:\n1. 編集\n2. 新しいFeature追加\n3. 削除\n数字を入力:`);

    if (action === '1') {
      // Epic編集画面を開く
      window.open(`/issues/${epic.issue.id}/edit`, '_blank');
    } else if (action === '2') {
      // 新しいFeature作成
      const featureSubject = prompt('新しいFeatureの件名:');
      if (featureSubject) {
        console.log('新Feature作成:', { parent: epic.issue.id, subject: featureSubject });
      }
    } else if (action === '3') {
      if (confirm(`Epic "${epic.issue.subject}" を削除しますか？`)) {
        console.log('Epic削除:', epic.issue.id);
      }
    }
  }
};
```

### 3.4 GridCell (ドロップゾーン)

```javascript
// assets/javascripts/kanban/components/GridCell.jsx
import React from 'react';
import { useDroppable } from '@dnd-kit/core';
import { FeatureCard } from '../feature_card/FeatureCard';

export const GridCell = ({
  epicId,
  versionId,
  features = [],
  isDropTarget,
  cellType
}) => {
  const { setNodeRef, isOver } = useDroppable({
    id: `cell-${epicId}-${versionId}`,
    data: {
      type: 'grid-cell',
      epicId: epicId,
      versionId: versionId
    }
  });

  const getCellStyle = () => {
    if (cellType === 'no-version') {
      return 'grid-cell no-version-cell';
    }
    return 'grid-cell version-cell';
  };

  const getCellBackgroundColor = () => {
    if (isOver || isDropTarget) {
      return cellType === 'no-version' ? '#f0f0f0' : '#f0ebf7';
    }
    return cellType === 'no-version' ? '#f9f9f9' : '#ffffff';
  };

  return (
    <div
      ref={setNodeRef}
      className={getCellStyle()}
      style={{
        backgroundColor: getCellBackgroundColor(),
        border: isOver ? '2px dashed #9673a6' : '1px solid #9673a6',
        minHeight: '120px'
      }}
    >
      <div className="cell-features">
        {features.map(feature => (
          <FeatureCard
            key={feature.issue.id}
            feature={feature}
            expanded={false} // グリッド内では常に折り畳み
            onToggle={() => handleFeatureExpand(feature)}
            compact={true} // コンパクト表示モード
          />
        ))}
      </div>

      {isOver && (
        <div className="drop-indicator">
          ここにFeatureをドロップ
        </div>
      )}

      {features.length === 0 && !isOver && (
        <div className="empty-cell-message">
          Feature未割当
        </div>
      )}
    </div>
  );

  function handleFeatureExpand(feature) {
    // Featureの詳細表示または編集画面を開く
    window.open(`/issues/${feature.issue.id}`, '_blank');
  }
};
```

### 3.5 NoEpicRow

```javascript
// assets/javascripts/kanban/components/NoEpicRow.jsx
import React from 'react';
import { GridCell } from './GridCell';

export const NoEpicRow = ({
  versionColumns,
  getCellFeatures,
  draggedOverCell
}) => {
  return (
    <div className="no-epic-row">
      <div className="no-epic-header-cell">
        <span className="no-epic-name">No EPIC</span>
        <div className="no-epic-description">
          親Epicが未設定のFeature
        </div>
      </div>

      {versionColumns.map(versionColumn => {
        const cellFeatures = getCellFeatures(versionColumn.id);
        const isDropTarget = draggedOverCell?.epicId === 'no-epic' &&
                           draggedOverCell?.versionId === versionColumn.id;

        return (
          <GridCell
            key={`no-epic-${versionColumn.id}`}
            epicId="no-epic"
            versionId={versionColumn.id}
            features={cellFeatures}
            isDropTarget={isDropTarget}
            cellType={versionColumn.type}
          />
        );
      })}
    </div>
  );
};
```

## 4. Ruby-React データ統合

### 4.1 Grid Data Builder Service

```ruby
# app/services/kanban/grid_data_builder.rb
class Kanban::GridDataBuilder
  def initialize(project, current_user, filters = {})
    @project = project
    @current_user = current_user
    @filters = filters
  end

  def build
    {
      project: project_metadata,
      versions: build_versions,
      epics: build_epics_with_features,
      orphan_features: build_orphan_features,
      metadata: build_metadata
    }
  end

  private

  def project_metadata
    {
      id: @project.id,
      name: @project.name,
      identifier: @project.identifier
    }
  end

  def build_versions
    @project.versions
           .includes(:issues)
           .order(:effective_date, :name)
           .map { |version| serialize_version(version) }
  end

  def build_epics_with_features
    epic_issues = @project.issues
                         .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                         .where(trackers: { name: 'Epic' })
                         .order(:created_on)

    epic_issues.map do |epic|
      {
        issue: serialize_issue(epic),
        features: build_epic_features(epic)
      }
    end
  end

  def build_epic_features(epic)
    epic.children
        .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
        .where(trackers: { name: 'Feature' })
        .order(:created_on)
        .map do |feature|
          Kanban::FeatureCardDataBuilder.new(feature).build
        end
  end

  def build_orphan_features
    # 親Epicが存在しないFeatureを取得
    orphan_features = @project.issues
                             .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
                             .where(
                               trackers: { name: 'Feature' },
                               parent_id: nil
                             )
                             .order(:created_on)

    orphan_features.map do |feature|
      Kanban::FeatureCardDataBuilder.new(feature).build
    end
  end

  def serialize_version(version)
    {
      id: version.id,
      name: version.name,
      description: version.description,
      effective_date: version.effective_date&.iso8601,
      status: version.status,
      sharing: version.sharing,
      issue_count: version.issues.count
    }
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      description: issue.description,
      status: issue.status.name,
      priority: issue.priority&.name,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version ? serialize_version(issue.fixed_version) : nil,
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601,
      tracker: issue.tracker.name
    }
  end

  def build_metadata
    {
      total_epics: @project.issues.where(trackers: { name: 'Epic' }).count,
      total_features: @project.issues.where(trackers: { name: 'Feature' }).count,
      total_versions: @project.versions.count,
      last_updated: Time.current.iso8601,
      user_permissions: build_user_permissions
    }
  end

  def build_user_permissions
    {
      view_issues: @current_user.allowed_to?(:view_issues, @project),
      edit_issues: @current_user.allowed_to?(:edit_issues, @project),
      add_issues: @current_user.allowed_to?(:add_issues, @project),
      delete_issues: @current_user.allowed_to?(:delete_issues, @project),
      manage_versions: @current_user.allowed_to?(:manage_versions, @project)
    }
  end
end
```

### 4.2 Grid API Controller

```ruby
# app/controllers/kanban/grid_controller.rb
class Kanban::GridController < ApplicationController
  include KanbanApiConcern

  # GET /kanban/projects/:project_id/grid
  def show
    @grid_data = Kanban::GridDataBuilder.new(@project, current_user, filter_params).build

    render json: @grid_data
  end

  # POST /kanban/projects/:project_id/grid/move_feature
  def move_feature
    feature = @project.issues.find(params[:feature_id])
    target_epic = params[:target_epic_id] ? @project.issues.find(params[:target_epic_id]) : nil
    target_version = params[:target_version_id] ? @project.versions.find(params[:target_version_id]) : nil

    begin
      ActiveRecord::Base.transaction do
        # Epic変更
        if target_epic
          feature.parent = target_epic
        else
          feature.parent = nil
        end

        # Version変更
        feature.fixed_version = target_version

        feature.save!

        # 自動化処理：子要素のVersion伝播
        if target_version
          propagate_version_to_children(feature, target_version)
        end
      end

      render json: {
        success: true,
        message: 'Feature移動成功',
        updated_data: Kanban::GridDataBuilder.new(@project, current_user).build
      }

    rescue => e
      render json: {
        success: false,
        message: 'Feature移動失敗',
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # POST /kanban/projects/:project_id/grid/create_version
  def create_version
    version = @project.versions.build(version_params)
    version.sharing = 'none' # プロジェクト内のみ

    if version.save
      render json: {
        success: true,
        version: serialize_version(version),
        message: 'Version作成成功'
      }
    else
      render json: {
        success: false,
        errors: version.errors,
        message: 'Version作成失敗'
      }, status: :unprocessable_entity
    end
  end

  # POST /kanban/projects/:project_id/grid/create_epic
  def create_epic
    epic = Issue.new(epic_params)
    epic.project = @project
    epic.tracker = Tracker.find_by(name: 'Epic')
    epic.author = User.current
    epic.status = IssueStatus.default

    if epic.save
      render json: {
        success: true,
        epic: serialize_issue(epic),
        message: 'Epic作成成功'
      }
    else
      render json: {
        success: false,
        errors: epic.errors,
        message: 'Epic作成失敗'
      }, status: :unprocessable_entity
    end
  end

  private

  def filter_params
    params.permit(:version_id, :assignee_id, :status_id, :tracker_id)
  end

  def version_params
    params.require(:version).permit(:name, :description, :effective_date)
  end

  def epic_params
    params.require(:epic).permit(:subject, :description, :assigned_to_id, :priority_id)
  end

  def propagate_version_to_children(parent_issue, version)
    Kanban::VersionPropagationService.new(parent_issue, version).execute
  end

  def serialize_version(version)
    {
      id: version.id,
      name: version.name,
      description: version.description,
      effective_date: version.effective_date&.iso8601,
      status: version.status
    }
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      status: issue.status.name,
      tracker: issue.tracker.name,
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601
    }
  end
end
```

## 5. CSS スタイリング

### 5.1 Grid Layout スタイル

```scss
// assets/stylesheets/kanban/grid_layout.scss
.kanban-grid-layout {
  width: 100%;
  overflow-x: auto;
  background: #ffffff;

  .grid-header {
    position: sticky;
    top: 0;
    background: #ffffff;
    border-bottom: 2px solid #dee2e6;
    z-index: 100;

    .project-title-header {
      background: #f5f5f5;
      color: #666666;
      font-size: 16px;
      font-weight: bold;
      text-align: center;
      padding: 10px;
      border: 1px solid #666666;
    }

    .version-headers {
      display: flex;

      .epic-column-header {
        width: 200px;
        background: #dae8fc;
        color: #6c8ebf;
        font-size: 14px;
        font-weight: bold;
        text-align: center;
        padding: 10px;
        border: 1px solid #6c8ebf;
      }

      .version-column-header {
        width: 280px;
        background: #e1d5e7;
        color: #9673a6;
        font-size: 12px;
        font-weight: bold;
        text-align: center;
        padding: 10px;
        border: 1px solid #9673a6;
        position: relative;

        &.no-version {
          width: 240px;
          background: #f5f5f5;
          color: #666666;
          border-color: #666666;
        }

        .version-name {
          display: block;
        }

        .version-actions-btn {
          position: absolute;
          top: 5px;
          right: 5px;
          background: transparent;
          border: none;
          color: #9673a6;
          font-size: 14px;
          cursor: pointer;

          &:hover {
            background: rgba(150, 115, 166, 0.1);
            border-radius: 2px;
          }
        }
      }

      .new-version-btn {
        background: #e8f5e8;
        color: #82b366;
        border: 1px solid #82b366;
        font-weight: bold;
        font-size: 10px;
        padding: 10px 20px;
        cursor: pointer;

        &:hover {
          background: #d4edda;
        }
      }
    }
  }

  .grid-body {
    .epic-row, .no-epic-row {
      display: flex;
      border-bottom: 1px solid #dee2e6;

      .epic-header-cell, .no-epic-header-cell {
        width: 200px;
        background: #dae8fc;
        border: 1px solid #6c8ebf;
        padding: 10px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        position: relative;

        .epic-name, .no-epic-name {
          font-size: 14px;
          font-weight: bold;
          color: #6c8ebf;
          text-align: center;
        }

        .epic-stats {
          margin-top: 5px;
          text-align: center;

          .feature-count {
            font-size: 10px;
            color: #666666;
          }
        }

        .no-epic-description {
          font-size: 10px;
          color: #666666;
          text-align: center;
          margin-top: 5px;
        }

        .epic-actions-btn {
          position: absolute;
          top: 5px;
          right: 5px;
          background: transparent;
          border: none;
          color: #6c8ebf;
          font-size: 14px;
          cursor: pointer;

          &:hover {
            background: rgba(108, 142, 191, 0.1);
            border-radius: 2px;
          }
        }
      }

      .no-epic-header-cell {
        background: #f5f5f5;
        border-color: #666666;

        .no-epic-name {
          color: #666666;
        }
      }
    }

    .new-epic-row {
      display: flex;
      height: 40px;

      .new-epic-btn {
        width: 100%;
        background: #e8f5e8;
        color: #82b366;
        border: 1px dashed #82b366;
        font-weight: bold;
        font-size: 12px;
        text-align: center;
        cursor: pointer;

        &:hover {
          background: #d4edda;
        }
      }
    }
  }
}

.grid-cell {
  width: 280px;
  min-height: 120px;
  border: 1px solid #9673a6;
  padding: 5px;
  position: relative;
  overflow-y: auto;
  max-height: 200px;

  &.no-version-cell {
    width: 240px;
    background: #f9f9f9;
    border-color: #666666;
  }

  &.version-cell {
    background: #ffffff;
  }

  .cell-features {
    .feature-card {
      margin-bottom: 8px;

      &:last-child {
        margin-bottom: 0;
      }
    }
  }

  .drop-indicator {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(150, 115, 166, 0.1);
    border: 2px dashed #9673a6;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    color: #9673a6;
    font-weight: bold;
  }

  .empty-cell-message {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 10px;
    color: #999999;
    text-align: center;
  }
}
```

## 6. 機能拡張設計

### 6.1 フィルタリング機能

```javascript
// assets/javascripts/kanban/components/GridFilters.jsx
export const GridFilters = ({
  versions,
  assignees,
  statuses,
  activeFilters,
  onFilterChange
}) => {
  return (
    <div className="grid-filters">
      <select
        value={activeFilters.version_id || ''}
        onChange={(e) => onFilterChange('version_id', e.target.value)}
      >
        <option value="">全Version</option>
        {versions.map(version => (
          <option key={version.id} value={version.id}>
            {version.name}
          </option>
        ))}
      </select>

      <select
        value={activeFilters.assignee_id || ''}
        onChange={(e) => onFilterChange('assignee_id', e.target.value)}
      >
        <option value="">全担当者</option>
        {assignees.map(assignee => (
          <option key={assignee.id} value={assignee.id}>
            {assignee.name}
          </option>
        ))}
      </select>

      <button onClick={() => onFilterChange('reset')}>
        フィルタクリア
      </button>
    </div>
  );
};
```

### 6.2 検索機能

```javascript
// assets/javascripts/kanban/components/GridSearch.jsx
export const GridSearch = ({ onSearch, placeholder = "Feature検索..." }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch] = useDebounce(searchTerm, 300);

  useEffect(() => {
    onSearch(debouncedSearch);
  }, [debouncedSearch, onSearch]);

  return (
    <div className="grid-search">
      <input
        type="text"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        placeholder={placeholder}
        className="search-input"
      />
      <button
        onClick={() => setSearchTerm('')}
        className="search-clear"
      >
        ✕
      </button>
    </div>
  );
};
```

---

*2次元グリッドレイアウトでEpicとVersionを軸とするFeature Card配置システム。ワイヤーフレーム準拠のD&Dとデータ統合を実現*