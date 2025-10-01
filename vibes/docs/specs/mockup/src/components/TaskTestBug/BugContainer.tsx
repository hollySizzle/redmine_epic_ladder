import React from 'react';
import { BugItem, BugItemData } from './BugItem';
import { AddButton } from '../common/AddButton';

interface BugContainerProps {
  bugs: BugItemData[];
}

export const BugContainer: React.FC<BugContainerProps> = ({ bugs }) => {
  return (
    <div className="bug-container">
      <div className="bug-container-header">Bug</div>
      <div className="bug-item-grid">
        {bugs.map(bug => (
          <BugItem key={bug.id} bug={bug} />
        ))}
        <AddButton
          type="bug"
          label="+ Add Bug"
          dataAddButton="bug"
          className="bug-item"
        />
      </div>
    </div>
  );
};
