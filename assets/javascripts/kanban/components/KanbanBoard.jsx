// assets/javascripts/kanban/components/KanbanBoard.jsx
import React from 'react';

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
          <div key={column.id} className="column-header">
            {column.name}
          </div>
        ))}
      </div>

      <div className="kanban-body">
        {/* スタブ：Epic Swimlane */}
        <div className="epic-swimlane">
          <div className="epic-row-header">
            <div className="issue-card epic">
              <div className="card-subject">サンプルEpic</div>
            </div>
          </div>
          {columns.map(column => (
            <div key={column.id} className="kanban-column">
              <div className="column-cards">
                {/* スタブカード */}
                <div className="issue-card user-story">
                  <div className="card-subject">サンプルUserStory</div>
                  <div className="card-meta">
                    <span className="version-chip version-direct">v1.0</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};