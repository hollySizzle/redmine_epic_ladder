import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';

export interface TaskItemData {
  id: string;
  title: string;
  status: 'open' | 'closed';
}

interface TaskItemProps {
  task: TaskItemData;
}

export const TaskItem: React.FC<TaskItemProps> = ({ task }) => {
  const className = task.status === 'closed' ? 'task-item closed' : 'task-item';

  return (
    <div className={className} data-task={task.id}>
      <StatusIndicator status={task.status} />
      {task.title}
    </div>
  );
};
