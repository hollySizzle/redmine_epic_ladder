import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';

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

  const ref = useDraggableAndDropTarget({
    type: 'task',
    id: task.id,
    onDrop: (sourceData) => {
      console.log('Task dropped:', sourceData.id, '→', task.id);
    }
  });

  return (
    <div ref={ref} className={className} data-task={task.id}>
      <StatusIndicator status={task.status} />
      {task.title}
    </div>
  );
};
