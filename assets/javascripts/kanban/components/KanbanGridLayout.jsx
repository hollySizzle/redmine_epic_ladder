import React, { useState, useEffect, useMemo } from 'react';
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core';
import { GridHeader } from './GridHeader';
import { EpicRow } from './EpicRow';
import { NoEpicRow } from './NoEpicRow';
import { NewEpicRow } from './NewEpicRow';
import { FeatureCard } from './FeatureCard';
import { KanbanAPI } from '../services/KanbanAPI';

/**
 * KanbanGridLayout (メインコンポーネント)
 * ワイヤーフレーム準拠: 2次元グリッドレイアウト（EPIC行 × Version列）
 *
 * @param {number} projectId - プロジェクトID
 * @param {Object} currentUser - 現在のユーザー情報
 * @param {Object} initialData - 初期データ
 * @param {Function} onDataUpdate - データ更新コールバック
 */
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

  const handleNewVersion = async () => {
    const versionName = prompt('新しいVersionの名前を入力してください:');
    if (versionName) {
      try {
        await KanbanAPI.createVersion(projectId, { name: versionName });
        await loadGridData();
      } catch (error) {
        alert('Version作成に失敗しました: ' + error.message);
      }
    }
  };

  const handleNewEpic = async () => {
    const epicSubject = prompt('新しいEpicの件名を入力してください:');
    if (epicSubject) {
      try {
        await KanbanAPI.createEpic(projectId, { subject: epicSubject });
        await loadGridData();
      } catch (error) {
        alert('Epic作成に失敗しました: ' + error.message);
      }
    }
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
          onNewVersion={handleNewVersion}
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
            onNewEpic={handleNewEpic}
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
};