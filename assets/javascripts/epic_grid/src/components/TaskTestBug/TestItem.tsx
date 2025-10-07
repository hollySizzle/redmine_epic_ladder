import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { formatDateRange } from '../../utils/dateFormat';

interface TestItemProps {
  testId: string;
}

export const TestItem: React.FC<TestItemProps> = ({ testId }) => {
  const test = useStore(state => state.entities.tests[testId]);
  const setSelectedIssueId = useStore(state => state.setSelectedIssueId);
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);
  const isDueDateVisible = useStore(state => state.isDueDateVisible);

  // 担当者情報を取得
  const assignedUser = useStore(state =>
    test?.assigned_to_id ? state.entities.users[test.assigned_to_id] : undefined
  );

  if (!test) return null;

  const className = test.status === 'closed' ? 'test-item closed' : 'test-item';

  const ref = useDraggableAndDropTarget({
    type: 'test',
    id: test.id,
    onDrop: (sourceData) => {
      console.log('Test dropped:', sourceData.id, '→', test.id);
    }
  });

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIssueId(test.id);
  };

  return (
    <div ref={ref} className={className} data-test={test.id} onClick={handleClick}>
      <div className="main-info-wrapper">
        <StatusIndicator status={test.status} />
        <span className="title-wrapper">
          {test.title}
        </span>
      </div>
      <div className="essential-info-wrapper">
        {isAssignedToVisible && assignedUser && (
          <span className="assigned_to-name-wrapper">
            {assignedUser.lastname} {assignedUser.firstname}
          </span>
        )}
        {isDueDateVisible && formatDateRange(test.start_date, test.due_date) && (
          <span className="date-range-wrapper">
            {formatDateRange(test.start_date, test.due_date)}
          </span>
        )}
      </div>
    </div>
  );
};
