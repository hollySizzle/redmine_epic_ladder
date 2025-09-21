# KanbanUI技術実装仕様

## 概要
React+@dnd-kit活用のカンバンボード。Epic Swimlane、Version Bar、D&D操作による自動化トリガー統合。

## メインアプリケーション

### カンバンアプリ構成
```javascript
// assets/javascripts/kanban/KanbanApp.jsx
import React, { useState, useEffect } from 'react';
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core';
import { VersionBar } from './components/VersionBar';
import { KanbanBoard } from './components/KanbanBoard';
import { BatchActionPanel } from './components/BatchActionPanel';
import { KanbanAPI } from './utils/KanbanAPI';

export const KanbanApp = ({ projectId, currentUser }) => {
  const [kanbanData, setKanbanData] = useState({ epics: [], columns: [] });
  const [selectedCards, setSelectedCards] = useState(new Set());
  const [activeCard, setActiveCard] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadKanbanData();
  }, [projectId]);

  const loadKanbanData = async () => {
    try {
      const data = await KanbanAPI.getKanbanData(projectId);
      setKanbanData(data);
    } catch (error) {
      console.error('カンバンデータ読み込みエラー:', error);
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
    } finally {
      setActiveCard(null);
      loadKanbanData(); // データを再読み込み
    }
  };

  const handleColumnMove = async (card, column) => {
    const result = await KanbanAPI.moveCard(projectId, card.issue.id, column.id);
    if (result.triggered_actions?.length > 0) {
      console.log('自動化アクション実行:', result.triggered_actions);
    }
  };

  const handleVersionAssignment = async (card, versionTarget) => {
    await KanbanAPI.assignVersion(projectId, card.issue.id, versionTarget.version.id);
  };

  if (loading) return <div className="kanban-loading">読み込み中...</div>;

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
```

## コンポーネント実装

### カンバンボード
```javascript
// assets/javascripts/kanban/components/KanbanBoard.jsx
import React from 'react';
import { EpicSwimlane } from './EpicSwimlane';
import { ColumnHeader } from './ColumnHeader';

export const KanbanBoard = ({ kanbanData, selectedCards, onCardSelect, currentUser }) => {
  const columns = [
    { id: 'todo', name: 'ToDo', color: '#f1f1f1' },
    { id: 'in_progress', name: 'In Progress', color: '#fff3cd' },
    { id: 'ready_for_test', name: 'Ready for Test', color: '#d1ecf1' },
    { id: 'released', name: 'Released', color: '#d4edda' }
  ];

  return (
    <div className="kanban-board">
      <div className="kanban-header">
        <div className="epic-header">Epic</div>
        {columns.map(column => (
          <ColumnHeader key={column.id} column={column} />
        ))}
      </div>

      <div className="kanban-body">
        {kanbanData.epics.map(epic => (
          <EpicSwimlane
            key={epic.issue.id}
            epic={epic}
            columns={columns}
            selectedCards={selectedCards}
            onCardSelect={onCardSelect}
            currentUser={currentUser}
          />
        ))}
      </div>
    </div>
  );
};
```

### Epic Swimlane
```javascript
// assets/javascripts/kanban/components/EpicSwimlane.jsx
import React, { useState } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { IssueCard } from './IssueCard';

export const EpicSwimlane = ({ epic, columns, selectedCards, onCardSelect, currentUser }) => {
  const [expanded, setExpanded] = useState(true);

  const getCardsForColumn = (columnId) => {
    const allCards = [];

    // Feature配下のUserStory/Task/Testを収集
    epic.features.forEach(feature => {
      feature.user_stories.forEach(userStory => {
        if (userStory.issue.status_column === columnId) {
          allCards.push({ ...userStory.issue, type: 'UserStory' });
        }

        userStory.tasks.forEach(task => {
          if (task.status_column === columnId) {
            allCards.push({ ...task, type: 'Task' });
          }
        });

        userStory.tests.forEach(test => {
          if (test.status_column === columnId) {
            allCards.push({ ...test, type: 'Test' });
          }
        });

        userStory.bugs.forEach(bug => {
          if (bug.status_column === columnId) {
            allCards.push({ ...bug, type: 'Bug' });
          }
        });
      });

      // Feature自体がカラムに該当する場合
      if (feature.issue.status_column === columnId) {
        allCards.push({ ...feature.issue, type: 'Feature' });
      }
    });

    // Epic自体がカラムに該当する場合
    if (epic.issue.status_column === columnId) {
      allCards.push({ ...epic.issue, type: 'Epic' });
    }

    return allCards;
  };

  return (
    <div className="epic-swimlane">
      <div className="epic-row-header">
        <IssueCard
          issue={epic.issue}
          type="Epic"
          selected={selectedCards.has(epic.issue.id)}
          onSelect={() => handleCardSelect(epic.issue.id)}
          onToggle={() => setExpanded(!expanded)}
          expanded={expanded}
        />
      </div>

      {expanded && columns.map(column => (
        <KanbanColumn
          key={`${epic.issue.id}-${column.id}`}
          column={column}
          cards={getCardsForColumn(column.id)}
          epic={epic}
          selectedCards={selectedCards}
          onCardSelect={onCardSelect}
        />
      ))}
    </div>
  );

  function handleCardSelect(cardId) {
    const newSelection = new Set(selectedCards);
    if (newSelection.has(cardId)) {
      newSelection.delete(cardId);
    } else {
      newSelection.add(cardId);
    }
    onCardSelect(newSelection);
  }
};
```

### カンバンカラム
```javascript
// assets/javascripts/kanban/components/KanbanColumn.jsx
import React from 'react';
import { useDroppable } from '@dnd-kit/core';
import { IssueCard } from './IssueCard';

export const KanbanColumn = ({ column, cards, epic, selectedCards, onCardSelect }) => {
  const { setNodeRef, isOver } = useDroppable({
    id: `${epic.issue.id}-${column.id}`,
    data: {
      type: 'column',
      id: column.id,
      epic_id: epic.issue.id
    }
  });

  const handleCardSelect = (cardId) => {
    const newSelection = new Set(selectedCards);
    if (newSelection.has(cardId)) {
      newSelection.delete(cardId);
    } else {
      newSelection.add(cardId);
    }
    onCardSelect(newSelection);
  };

  return (
    <div
      ref={setNodeRef}
      className={`kanban-column ${isOver ? 'drop-hover' : ''}`}
      style={{ backgroundColor: isOver ? column.color : 'transparent' }}
    >
      <div className="column-cards">
        {cards.map(card => (
          <IssueCard
            key={card.id}
            issue={card}
            type={card.type}
            selected={selectedCards.has(card.id)}
            onSelect={() => handleCardSelect(card.id)}
          />
        ))}
      </div>
    </div>
  );
};
```

### Issue カード
```javascript
// assets/javascripts/kanban/components/IssueCard.jsx
import React, { useState } from 'react';
import { useDraggable } from '@dnd-kit/core';
import { TestGenerationButton } from './TestGenerationButton';
import { VersionChip } from './VersionChip';

export const IssueCard = ({ issue, type, selected, onSelect, onToggle, expanded }) => {
  const [showDetails, setShowDetails] = useState(false);

  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: issue.id,
    data: { issue, type }
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    opacity: isDragging ? 0.5 : 1,
  } : undefined;

  const getCardColor = () => {
    const colors = {
      'Epic': '#007bff',
      'Feature': '#28a745',
      'UserStory': '#ffc107',
      'Task': '#6c757d',
      'Test': '#dc3545',
      'Bug': '#fd7e14'
    };
    return colors[type] || '#6c757d';
  };

  const getBadges = () => {
    const badges = [];

    // BLOCKEDバッジ
    if (issue.blocked_by_relations?.length > 0) {
      badges.push({ type: 'blocked', text: 'BLOCKED', color: '#dc3545' });
    }

    // バージョン未設定警告
    if (type === 'UserStory' && !issue.fixed_version) {
      badges.push({ type: 'version-warning', text: '要設定', color: '#6c757d' });
    }

    return badges;
  };

  const handleCardClick = (e) => {
    if (e.detail === 2) { // ダブルクリック
      window.open(`/issues/${issue.id}`, '_blank');
    } else {
      setShowDetails(!showDetails);
    }
  };

  const handleContextMenu = (e) => {
    e.preventDefault();
    // コンテキストメニュー表示
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className={`issue-card ${type.toLowerCase()} ${selected ? 'selected' : ''}`}
      onClick={handleCardClick}
      onContextMenu={handleContextMenu}
    >
      <div className="card-header" style={{ borderLeftColor: getCardColor() }}>
        <div className="card-select">
          <input
            type="checkbox"
            checked={selected}
            onChange={onSelect}
            onClick={(e) => e.stopPropagation()}
          />
        </div>

        <div className="card-info">
          <span className="card-id">#{issue.id}</span>
          <span className="card-tracker">{type}</span>
          {onToggle && (
            <button
              className="expand-toggle"
              onClick={(e) => { e.stopPropagation(); onToggle(); }}
            >
              {expanded ? '▼' : '▶'}
            </button>
          )}
        </div>
      </div>

      <div className="card-content">
        <h4 className="card-subject">{issue.subject}</h4>

        <div className="card-meta">
          {issue.assigned_to && (
            <span className="assignee">{issue.assigned_to}</span>
          )}
          {issue.fixed_version && (
            <VersionChip version={issue.fixed_version} source={issue.version_source} />
          )}
        </div>

        <div className="card-badges">
          {getBadges().map((badge, index) => (
            <span
              key={index}
              className={`badge badge-${badge.type}`}
              style={{ backgroundColor: badge.color }}
            >
              {badge.text}
            </span>
          ))}
        </div>

        {type === 'UserStory' && (
          <div className="card-actions">
            <TestGenerationButton
              userStory={issue}
              onTestGenerated={() => {/* リロード処理 */}}
            />
          </div>
        )}
      </div>

      {showDetails && (
        <div className="card-details">
          <p>{issue.description}</p>
          <div className="detail-links">
            <a href={`/issues/${issue.id}`} target="_blank">詳細</a>
            <a href={`/issues/${issue.id}/edit`} target="_blank">編集</a>
          </div>
        </div>
      )}
    </div>
  );
};
```

### バージョンチップ
```javascript
// assets/javascripts/kanban/components/VersionChip.jsx
import React from 'react';

export const VersionChip = ({ version, source }) => {
  const getChipStyle = () => {
    const styles = {
      direct: { backgroundColor: '#007bff', color: 'white' },
      inherited: { backgroundColor: '#6c757d', color: 'white' },
      none: { backgroundColor: '#f8f9fa', color: '#6c757d', border: '1px dashed #dee2e6' }
    };
    return styles[source] || styles.none;
  };

  const getTooltipText = () => {
    const tooltips = {
      direct: '直接設定されたバージョン',
      inherited: '親から継承されたバージョン',
      none: 'バージョン未設定'
    };
    return tooltips[source] || 'バージョン情報なし';
  };

  return (
    <span
      className={`version-chip version-${source}`}
      style={getChipStyle()}
      title={getTooltipText()}
    >
      {version || '未設定'}
    </span>
  );
};
```

## ユーティリティ実装

### カンバンAPI
```javascript
// assets/javascripts/kanban/utils/KanbanAPI.js
export class KanbanAPI {
  static async getKanbanData(projectId) {
    const response = await fetch(`/kanban/projects/${projectId}/cards`);
    if (!response.ok) throw new Error('カンバンデータ取得失敗');
    return await response.json();
  }

  static async moveCard(projectId, cardId, columnId) {
    const response = await fetch(`/kanban/projects/${projectId}/move_card`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        card_id: cardId,
        column_id: columnId
      })
    });

    if (!response.ok) throw new Error('カード移動失敗');
    return await response.json();
  }

  static async assignVersion(projectId, issueId, versionId) {
    const response = await fetch(`/kanban/projects/${projectId}/assign_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_id: issueId,
        version_id: versionId
      })
    });

    if (!response.ok) throw new Error('バージョン割当失敗');
    return await response.json();
  }

  static async batchUpdate(projectId, issueIds, updates) {
    const response = await fetch(`/kanban/projects/${projectId}/batch_update`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_ids: issueIds,
        updates: updates
      })
    });

    if (!response.ok) throw new Error('一括更新失敗');
    return await response.json();
  }
}
```

## ショートカット実装

### キーボードショートカット
```javascript
// assets/javascripts/kanban/utils/KeyboardShortcuts.js
export class KeyboardShortcuts {
  constructor(kanbanApp) {
    this.app = kanbanApp;
    this.setupEventListeners();
  }

  setupEventListeners() {
    document.addEventListener('keydown', this.handleKeyDown.bind(this));
  }

  handleKeyDown(event) {
    // モーダルやフォームが開いている時は無効
    if (this.isInputActive()) return;

    const { key, shiftKey, ctrlKey, metaKey } = event;

    switch (key.toLowerCase()) {
      case 'n':
        this.triggerNewIssue();
        break;
      case 'u':
        this.triggerNewUserStory();
        break;
      case 't':
        this.triggerNewTask();
        break;
      case 'v':
        if (shiftKey) {
          this.triggerNewVersion();
        } else {
          this.triggerVersionAssignment();
        }
        break;
      case 'escape':
        this.clearSelection();
        break;
      case 'a':
        if (ctrlKey || metaKey) {
          event.preventDefault();
          this.selectAll();
        }
        break;
    }
  }

  isInputActive() {
    const activeElement = document.activeElement;
    return ['INPUT', 'TEXTAREA', 'SELECT'].includes(activeElement.tagName) ||
           activeElement.contentEditable === 'true';
  }

  triggerNewIssue() {
    console.log('新規Issue作成ショートカット');
    // モーダル表示処理
  }

  triggerNewUserStory() {
    console.log('新規UserStory作成ショートカット');
  }

  triggerNewTask() {
    console.log('新規Task作成ショートカット');
  }

  triggerVersionAssignment() {
    console.log('バージョン設定ショートカット');
  }

  triggerNewVersion() {
    console.log('新規バージョン作成ショートカット');
  }

  clearSelection() {
    this.app.clearSelection();
  }

  selectAll() {
    this.app.selectAllVisibleCards();
  }
}
```

## テスト実装

### React コンポーネントテスト
```javascript
// spec/javascript/kanban/components/KanbanBoard.test.jsx
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { KanbanBoard } from '../../../assets/javascripts/kanban/components/KanbanBoard';

describe('KanbanBoard', () => {
  const mockKanbanData = {
    epics: [{
      issue: { id: 1, subject: 'Test Epic', tracker: 'Epic' },
      features: [{
        issue: { id: 2, subject: 'Test Feature', tracker: 'Feature' },
        user_stories: [{
          issue: { id: 3, subject: 'Test UserStory', tracker: 'UserStory', status_column: 'todo' },
          tasks: [],
          tests: [],
          bugs: []
        }]
      }]
    }]
  };

  it 'Epicとカラムヘッダーが表示される' do
    render(
      <KanbanBoard
        kanbanData={mockKanbanData}
        selectedCards={new Set()}
        onCardSelect={() => {}}
        currentUser={{ id: 1 }}
      />
    );

    expect(screen.getByText('Test Epic')).toBeInTheDocument();
    expect(screen.getByText('ToDo')).toBeInTheDocument();
    expect(screen.getByText('In Progress')).toBeInTheDocument();
  });

  it 'カードをクリックで選択' do
    const mockOnCardSelect = jest.fn();
    render(
      <KanbanBoard
        kanbanData={mockKanbanData}
        selectedCards={new Set()}
        onCardSelect={mockOnCardSelect}
        currentUser={{ id: 1 }}
      />
    );

    const checkbox = screen.getByRole('checkbox');
    fireEvent.click(checkbox);

    expect(mockOnCardSelect).toHaveBeenCalled();
  });
});
```

---

*React+@dnd-kit活用のカンバンUI。Epic Swimlane、D&D自動化、ショートカット統合*