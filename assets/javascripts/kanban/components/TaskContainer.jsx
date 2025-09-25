import React from 'react';
import { BaseItemCard } from './BaseItemCard';

/**
 * TaskContainer - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const TaskContainer = ({
  tasks,
  userStoryId,
  onTaskAdd,
  onTaskUpdate,
  onTaskDelete
}) => {
  return (
    <div className="task-container">
      <div className="task-header">
        <span>Task</span>
        <button
          className="add-task-btn"
          onClick={() => onTaskAdd(userStoryId)}
        >
          + Task
        </button>
      </div>

      <div className="task-items">
        {tasks.map(task => (
          <BaseItemCard
            key={task.id}
            item={task}
            type="Task"
            onUpdate={onTaskUpdate}
            onDelete={onTaskDelete}
          />
        ))}
      </div>
    </div>
  );
};