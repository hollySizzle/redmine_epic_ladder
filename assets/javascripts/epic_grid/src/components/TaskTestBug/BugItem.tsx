import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { formatDateRange } from '../../utils/dateFormat';

interface BugItemProps {
  bugId: string;
}

export const BugItem: React.FC<BugItemProps> = ({ bugId }) => {
  const bug = useStore(state => state.entities.bugs[bugId]);
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);
  const isDueDateVisible = useStore(state => state.isDueDateVisible);
  const isIssueIdVisible = useStore(state => state.isIssueIdVisible);

  // 担当者情報を取得
  const assignedUser = useStore(state =>
    bug?.assigned_to_id ? state.entities.users[bug.assigned_to_id] : undefined
  );

  if (!bug) return null;

  const className = bug.status === 'closed' ? 'bug-item closed' : 'bug-item';

  const ref = useDraggableAndDropTarget({
    type: 'bug',
    id: bug.id,
    onDrop: (sourceData) => {
      console.log('Bug dropped:', sourceData.id, '→', bug.id);
    }
  });

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!isDetailPaneVisible) {
      toggleDetailPane();
    }
    setSelectedEntity('issue', bug.id);
  };

  return (
    <div ref={ref} className={className} data-bug={bug.id} onClick={handleClick}>
      <div className="main-info-wrapper">
        <StatusIndicator status={bug.status} />
        <span className="title-wrapper">
          {bug.title}
        </span>
        {isIssueIdVisible && (
          <span className="issue-id-wrapper">#{bug.id}</span>
        )}
      </div>
      <div className="essential-info-wrapper">
        {isAssignedToVisible && assignedUser && (
          <span className="assigned_to-name-wrapper">
            {assignedUser.lastname} {assignedUser.firstname}
          </span>
        )}
        {isDueDateVisible && formatDateRange(bug.start_date, bug.due_date) && (
          <span className="date-range-wrapper">
            {formatDateRange(bug.start_date, bug.due_date)}
          </span>
        )}
      </div>
    </div>
  );
};
