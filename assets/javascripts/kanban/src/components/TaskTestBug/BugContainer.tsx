import React from 'react';
import { BugItem } from './BugItem';
import { AddButton } from '../common/AddButton';

interface BugContainerProps {
  bugIds: string[];
}

export const BugContainer: React.FC<BugContainerProps> = ({ bugIds }) => {
  return (
    <div className="bug-container">
      <div className="bug-container-header">Bug</div>
      <div className="bug-item-grid">
        {bugIds.map(bugId => (
          <BugItem key={bugId} bugId={bugId} />
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
