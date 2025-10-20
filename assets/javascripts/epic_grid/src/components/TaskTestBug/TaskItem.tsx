import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { formatDateRange } from '../../utils/dateFormat';

interface TaskItemProps {
  taskId: string;
}

export const TaskItem: React.FC<TaskItemProps> = ({ taskId }) => {
  const task = useStore(state => state.entities.tasks[taskId]);
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);
  const isDueDateVisible = useStore(state => state.isDueDateVisible);
  const isIssueIdVisible = useStore(state => state.isIssueIdVisible);
  const isUnassignedHighlightVisible = useStore(state => state.isUnassignedHighlightVisible);

  // 担当者情報を取得
  const assignedUser = useStore(state =>
    task?.assigned_to_id ? state.entities.users[task.assigned_to_id] : undefined
  );

  if (!task) return null;

  // 担当者不在チェック
  const isUnassigned = !task.assigned_to_id;

  // 完了済みチケットは、担当者未設定に関わらず完了済みの色を優先
  const isClosed = task.status === 'closed';
  const className = [
    'task-item',
    isClosed && 'closed',
    !isClosed && isUnassigned && isUnassignedHighlightVisible && 'unassigned'
  ].filter(Boolean).join(' ');

  const ref = useDraggableAndDropTarget({
    type: 'task',
    id: task.id,
    onDrop: (sourceData) => {
      console.log('Task dropped:', sourceData.id, '→', task.id);
    }
  });

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!isDetailPaneVisible) {
      toggleDetailPane();
    }
    setSelectedEntity('issue', task.id);
  };

  return (
    <div ref={ref} className={className} data-task={task.id} onClick={handleClick}>
      <div className="main-info-wrapper">
        <StatusIndicator status={task.status} />
        <span className="title-wrapper">
          {task.title}
        </span>
        {isIssueIdVisible && (
          <span className="issue-id-wrapper">#{task.id}</span>
        )}
      </div>
      <div className="essential-info-wrapper">
        {isAssignedToVisible && assignedUser && (
          <span className="assigned_to-name-wrapper">
            {assignedUser.lastname} {assignedUser.firstname}
          </span>
        )}
        {isDueDateVisible && formatDateRange(task.start_date, task.due_date) && (
          <span className="date-range-wrapper">
            {formatDateRange(task.start_date, task.due_date)}
          </span>
        )}
      </div>
    </div>
  );
};
