import React, { useState, useCallback } from 'react';
import { FeatureHeader } from './FeatureHeader';
import { UserStoryList } from './UserStoryList';
import { useDraggable } from '@dnd-kit/core';
import './FeatureCard.scss';

/**
 * FeatureCard - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const FeatureCard = ({
  feature,
  expanded = true,
  onToggle,
  onUserStoryAdd,
  onUserStoryUpdate,
  onUserStoryDelete
}) => {
  const [userStoriesExpanded, setUserStoriesExpanded] = useState(new Map());

  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `feature-${feature.issue.id}`,
    data: {
      type: 'Feature',
      issue: feature.issue
    }
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    opacity: isDragging ? 0.5 : 1,
  } : undefined;

  const handleUserStoryToggle = useCallback((userStoryId) => {
    setUserStoriesExpanded(prev => {
      const newMap = new Map(prev);
      newMap.set(userStoryId, !prev.get(userStoryId));
      return newMap;
    });
  }, []);

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className="feature-card"
      data-feature-id={feature.issue.id}
    >
      <FeatureHeader
        feature={feature}
        expanded={expanded}
        onToggle={onToggle}
      />

      {expanded && (
        <UserStoryList
          userStories={feature.user_stories}
          userStoriesExpanded={userStoriesExpanded}
          onUserStoryToggle={handleUserStoryToggle}
          onUserStoryAdd={onUserStoryAdd}
          onUserStoryUpdate={onUserStoryUpdate}
          onUserStoryDelete={onUserStoryDelete}
        />
      )}
    </div>
  );
};