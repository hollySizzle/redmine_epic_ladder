import React from 'react';
import { TaskItem } from './TaskItem';
import { AddButton } from '../common/AddButton';

interface TaskContainerProps {
  taskIds: string[];
}

export const TaskContainer: React.FC<TaskContainerProps> = ({ taskIds }) => {
  return (
    <div className="task-container">
      <div className="task-container-header">Task</div>
      <div className="task-item-grid">
        {taskIds.map(taskId => (
          <TaskItem key={taskId} taskId={taskId} />
        ))}
        <AddButton
          type="task"
          label="+ Add Task"
          dataAddButton="task"
          className="task-item"
        />
      </div>
    </div>
  );
};
