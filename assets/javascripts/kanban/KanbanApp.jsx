// assets/javascripts/kanban/KanbanApp.jsx
import React, { useState, useEffect } from 'react';
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core';
import { VersionBar } from './components/VersionBar';
import { KanbanBoard } from './components/KanbanBoard';
import { BatchActionPanel } from './components/BatchActionPanel';
import { KanbanAPIService } from './services/KanbanAPIService';

export const KanbanApp = ({ projectId, currentUser, apiBaseUrl }) => {
  const [kanbanData, setKanbanData] = useState({ epics: [], columns: [] });
  const [selectedCards, setSelectedCards] = useState(new Set());
  const [activeCard, setActiveCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const apiService = new KanbanAPIService(projectId, apiBaseUrl);

  useEffect(() => {
    loadKanbanData();
  }, [projectId]);

  const loadKanbanData = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await apiService.getKanbanData();
      setKanbanData(data);
    } catch (error) {
      console.error('カンバンデータ読み込みエラー:', error);
      setError('カンバンデータの読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleDragStart = (event) => {
    const { active } = event;
    setActiveCard(active.data.current);
  };

  const handleDragEnd = async (event) => {
    const { active, over } = event;
    if (!over) return;

    const draggedCard = active.data.current;
    const dropTarget = over.data.current;

    try {
      if (dropTarget.type === 'column') {
        await handleColumnMove(draggedCard, dropTarget);
      } else if (dropTarget.type === 'version') {
        await handleVersionAssignment(draggedCard, dropTarget);
      }
    } catch (error) {
      console.error('ドラッグ操作エラー:', error);
      setError(`操作に失敗しました: ${error.message}`);
    } finally {
      setActiveCard(null);
      loadKanbanData(); // データを再読み込み
    }
  };

  const handleColumnMove = async (card, column) => {
    const result = await apiService.moveCard(card.issue.id, column.id);
    if (result.triggered_actions?.length > 0) {
      console.log('自動化アクション実行:', result.triggered_actions);
    }
  };

  const handleVersionAssignment = async (card, versionTarget) => {
    await apiService.assignVersion(card.issue.id, versionTarget.version.id);
  };

  if (loading) {
    return (
      <div className="kanban-loading">
        <div className="spinner"></div>
        <p>カンバンを読み込み中...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="kanban-error">
        <h3>エラーが発生しました</h3>
        <p>{error}</p>
        <button onClick={loadKanbanData}>再読み込み</button>
      </div>
    );
  }

  return (
    <div className="kanban-app">
      <DndContext
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <VersionBar
          projectId={projectId}
          onVersionChange={loadKanbanData}
        />

        <KanbanBoard
          kanbanData={kanbanData}
          selectedCards={selectedCards}
          onCardSelect={setSelectedCards}
          currentUser={currentUser}
        />

        <BatchActionPanel
          selectedCards={selectedCards}
          projectId={projectId}
          apiService={apiService}
          onBatchAction={loadKanbanData}
          onClearSelection={() => setSelectedCards(new Set())}
        />

        <DragOverlay>
          {activeCard && <CardPreview card={activeCard} />}
        </DragOverlay>
      </DndContext>
    </div>
  );
};

// ドラッグ中のカードプレビュー
const CardPreview = ({ card }) => (
  <div className="card-preview">
    <h4>{card.issue.subject}</h4>
    <span className="tracker">{card.issue.tracker}</span>
  </div>
);