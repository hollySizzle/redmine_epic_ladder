import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';

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

  return (
    <div className={className} data-bug={bug.id}>
      <StatusIndicator status={bug.status} />
      {bug.title}
    </div>
  );
};
