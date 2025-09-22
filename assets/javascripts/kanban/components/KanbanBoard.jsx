// assets/javascripts/kanban/components/KanbanBoard.jsx
import React, { useState, useEffect } from 'react';
import { DndContext, DragOverlay, closestCorners } from '@dnd-kit/core';
import { ApiClient } from '../utils/ApiClient';

export const KanbanBoard = ({ projectId, kanbanData, selectedCards, onCardSelect, currentUser }) => {
  const [columns, setColumns] = useState([]);
  const [issues, setIssues] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [apiClient] = useState(() => new ApiClient(projectId));

  // 初期データの読み込み
  useEffect(() => {
    loadKanbanData();
  }, [projectId]);

  const loadKanbanData = async () => {
    try {
      setLoading(true);

      // 実際のAPIまたはモックデータを使用
      let data;
      if (kanbanData) {
        data = kanbanData;
      } else {
        try {
          data = await apiClient.getKanbanData();
        } catch (error) {
          console.warn('API未実装、モックデータを使用:', error);
          data = getMockData();
        }
      }

      setColumns(data.columns || getMockColumns());
      setIssues(data.issues || []);
    } catch (error) {
      console.error('カンバンデータ読み込みエラー:', error);
      // フォールバック: モックデータを使用
      setColumns(getMockColumns());
      setIssues(getMockIssues());
    } finally {
      setLoading(false);
    }
  };

  // モックデータの生成（技術仕様書準拠）
  const getMockColumns = () => [
    { id: 'todo', name: 'ToDo', color: '#f1f1f1' },
    { id: 'in_progress', name: 'In Progress', color: '#fff3cd' },
    { id: 'ready_for_test', name: 'Ready for Test', color: '#d1ecf1' },
    { id: 'released', name: 'Released', color: '#d4edda' }
  ];

  const getMockIssues = () => [
    {
      id: 1,
      subject: 'サンプルUserStory',
      tracker: 'UserStory',
      status: 'New',
      assigned_to: 'ユーザー1',
      epic: 'Epic例',
      column: 'todo',
      hierarchy_level: 3
    },
    {
      id: 2,
      subject: 'サンプルTask',
      tracker: 'Task',
      status: 'In Progress',
      assigned_to: 'ユーザー2',
      epic: 'Epic例',
      column: 'in_progress',
      hierarchy_level: 4,
      parent_id: 1
    }
  ];

  const getMockData = () => ({
    columns: getMockColumns(),
    issues: getMockIssues()
  });

  // ドラッグ開始時の処理
  const handleDragStart = (event) => {
    setActiveId(event.active.id);
  };

  // ドラッグ終了時の処理
  const handleDragEnd = async (event) => {
    const { active, over } = event;
    setActiveId(null);

    if (!over) return;

    const activeIssue = issues.find(issue => issue.id === active.id);
    const overColumn = over.id;

    if (activeIssue && activeIssue.column !== overColumn) {
      try {
        // 楽観的UI更新
        setIssues(prevIssues =>
          prevIssues.map(issue =>
            issue.id === activeIssue.id
              ? { ...issue, column: overColumn }
              : issue
          )
        );

        // API呼び出し（実装されていない場合はスキップ）
        try {
          await apiClient.transitionIssue(activeIssue.id, overColumn);
        } catch (apiError) {
          console.warn('API未実装、UI更新のみ:', apiError);
        }
      } catch (error) {
        console.error('カード移動エラー:', error);
        // エラー時は元の状態に戻す
        loadKanbanData();
      }
    }
  };

  // カラム内のイシューを取得
  const getIssuesForColumn = (columnId) => {
    return issues.filter(issue => issue.column === columnId);
  };

  // Epic別にイシューをグループ化
  const getEpicGroups = () => {
    const epics = [...new Set(issues.map(issue => issue.epic).filter(Boolean))];
    if (epics.length === 0) return [{ name: 'その他', issues: issues }];

    return epics.map(epicName => ({
      name: epicName,
      issues: issues.filter(issue => issue.epic === epicName)
    }));
  };

  if (loading) {
    return <div className="kanban-loading">読み込み中...</div>;
  }

  return (
    <div className="kanban-board">
      <DndContext
        collisionDetection={closestCorners}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="kanban-header">
          <div className="epic-header">Epic</div>
          {columns.map(column => (
            <div key={column.id} className="column-header" style={{ backgroundColor: column.color }}>
              <span>{column.name}</span>
              <span className="issue-count">({getIssuesForColumn(column.id).length})</span>
            </div>
          ))}
        </div>

        <div className="kanban-body">
          {getEpicGroups().map(epicGroup => (
            <EpicSwimlane
              key={epicGroup.name}
              epicName={epicGroup.name}
              columns={columns}
              issues={epicGroup.issues}
              onCardSelect={onCardSelect}
              selectedCards={selectedCards}
            />
          ))}
        </div>

        <DragOverlay>
          {activeId ? (
            <IssueCard
              issue={issues.find(issue => issue.id === activeId)}
              isDragging={true}
            />
          ) : null}
        </DragOverlay>
      </DndContext>
    </div>
  );
};

// Epic Swimlane コンポーネント
const EpicSwimlane = ({ epicName, columns, issues, onCardSelect, selectedCards }) => {
  const getIssuesForColumn = (columnId) => {
    return issues.filter(issue => issue.column === columnId);
  };

  return (
    <div className="epic-swimlane">
      <div className="epic-row-header">
        <div className="epic-info">
          <h3>{epicName}</h3>
          <span className="epic-issue-count">{issues.length}件</span>
        </div>
      </div>

      {columns.map(column => (
        <KanbanColumn
          key={`${epicName}-${column.id}`}
          column={column}
          issues={getIssuesForColumn(column.id)}
          onCardSelect={onCardSelect}
          selectedCards={selectedCards}
        />
      ))}
    </div>
  );
};

// カンバンカラムコンポーネント
const KanbanColumn = ({ column, issues, onCardSelect, selectedCards }) => {
  return (
    <div className="kanban-column" data-column-id={column.id}>
      <div className="column-content">
        {issues.map(issue => (
          <IssueCard
            key={issue.id}
            issue={issue}
            onSelect={onCardSelect}
            isSelected={selectedCards?.includes(issue.id)}
          />
        ))}
      </div>
    </div>
  );
};

// イシューカードコンポーネント
const IssueCard = ({ issue, isDragging = false, onSelect, isSelected }) => {
  const handleClick = () => {
    onSelect?.(issue.id);
  };

  return (
    <div
      className={`issue-card ${issue.tracker.toLowerCase().replace(/\s+/g, '-')} ${isDragging ? 'dragging' : ''} ${isSelected ? 'selected' : ''}`}
      onClick={handleClick}
      draggable
    >
      <div className="card-header">
        <span className="tracker-badge">{issue.tracker}</span>
        <span className="issue-id">#{issue.id}</span>
      </div>

      <div className="card-body">
        <h4 className="issue-subject">{issue.subject}</h4>
      </div>

      <div className="card-footer">
        <span className="assigned-to">{issue.assigned_to || '未割当'}</span>
        <span className="status">{issue.status}</span>
      </div>
    </div>
  );
};