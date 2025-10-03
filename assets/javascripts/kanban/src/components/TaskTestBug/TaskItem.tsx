import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface TaskItemProps {
  taskId: string;
}

export const TaskItem: React.FC<TaskItemProps> = ({ taskId }) => {
  const task = useStore(state => state.entities.tasks[taskId]);
  const setSelectedIssueId = useStore(state => state.setSelectedIssueId);

  if (!task) return null;

  const className = task.status === 'closed' ? 'task-item closed' : 'task-item';

  const ref = useDraggableAndDropTarget({
    type: 'task',
    id: task.id,
    onDrop: (sourceData) => {
      console.log('Task dropped:', sourceData.id, '→', task.id);
    }
  });

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIssueId(task.id);
  };

  return (
    <div ref={ref} className={className} data-task={task.id} onClick={handleClick}>
      <StatusIndicator status={task.status} />
      {task.title}
    </div>
  );
};
