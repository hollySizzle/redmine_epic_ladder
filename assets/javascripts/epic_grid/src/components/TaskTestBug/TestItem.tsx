import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

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
      <StatusIndicator status={test.status} />
      <span className="title-wrapper">
        {test.title}
      </span>
      {isAssignedToVisible && assignedUser && (
        <span className="assigned_to-name-wrapper">
          {assignedUser.lastname} {assignedUser.firstname}
        </span>
      )}
      {isDueDateVisible && test.due_date && (
        <span className="due-date-wrapper">
          📅 {test.due_date}
        </span>
      )}
    </div>
  );
};
