import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';

export interface BugItemData {
  id: string;
  title: string;
  status: 'open' | 'closed';
}

interface BugItemProps {
  bug: BugItemData;
}

export const BugItem: React.FC<BugItemProps> = ({ bug }) => {
  const className = bug.status === 'closed' ? 'bug-item closed' : 'bug-item';

  const ref = useDraggableAndDropTarget({
    type: 'bug',
    id: bug.id,
    onDrop: (sourceData) => {
      console.log('Bug dropped:', sourceData.id, '→', bug.id);
    }
  });

  return (
    <div ref={ref} className={className} data-bug={bug.id}>
      <StatusIndicator status={bug.status} />
      {bug.title}
    </div>
  );
};
