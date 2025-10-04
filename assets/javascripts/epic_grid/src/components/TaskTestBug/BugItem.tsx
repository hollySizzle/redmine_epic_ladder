import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface BugItemProps {
  bugId: string;
}

export const BugItem: React.FC<BugItemProps> = ({ bugId }) => {
  const bug = useStore(state => state.entities.bugs[bugId]);
  const setSelectedIssueId = useStore(state => state.setSelectedIssueId);

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
    setSelectedIssueId(bug.id);
  };

  return (
    <div ref={ref} className={className} data-bug={bug.id} onClick={handleClick}>
      <StatusIndicator status={bug.status} />
      {bug.title}
    </div>
  );
};
