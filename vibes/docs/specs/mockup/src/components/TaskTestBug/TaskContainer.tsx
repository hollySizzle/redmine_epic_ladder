import React from 'react';
import { TaskItem, TaskItemData } from './TaskItem';
import { AddButton } from '../common/AddButton';

interface TaskContainerProps {
  tasks: TaskItemData[];
}

export const TaskContainer: React.FC<TaskContainerProps> = ({ tasks }) => {
  return (
    <div className="task-container">
      <div className="task-container-header">Task</div>
      <div className="task-item-grid">
        {tasks.map(task => (
          <TaskItem key={task.id} task={task} />
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
