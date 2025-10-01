import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface BugItemProps {
  bugId: string;
}

export const BugItem: React.FC<BugItemProps> = ({ bugId }) => {
  const bug = useStore(state => state.entities.bugs[bugId]);

  if (!bug) return null;

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
