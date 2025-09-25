import React from 'react';
import { BaseItemCard } from './BaseItemCard';

/**
 * BugContainer - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const BugContainer = ({
  bugs,
  userStoryId,
  onBugAdd,
  onBugUpdate,
  onBugDelete
}) => {
  return (
    <div className="bug-container">
      <div className="bug-header">
        <span>Bug</span>
        <button
          className="add-bug-btn"
          onClick={() => onBugAdd(userStoryId)}
        >
          + Bug
        </button>
      </div>

      <div className="bug-items">
        {bugs.map(bug => (
          <BaseItemCard
            key={bug.id}
            item={bug}
            type="Bug"
            onUpdate={onBugUpdate}
            onDelete={onBugDelete}
          />
        ))}
      </div>
    </div>
  );
};