import React, { useState, useCallback, useEffect } from 'react';
import { FeatureHeader } from './FeatureHeader';
import { UserStoryList } from './UserStoryList';
import { useDraggable } from '@dnd-kit/core';
import { ExpansionStateStorageFactory } from '../utils/ExpansionStateStorage';
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
  onUserStoryDelete,
  projectId,
  userId
}) => {
  const [userStoriesExpanded, setUserStoriesExpanded] = useState(new Map());
  const [expansionStorage, setExpansionStorage] = useState(null);

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

  // LocalStorage初期化とデータ復元
  useEffect(() => {
    if (projectId && userId) {
      const storage = ExpansionStateStorageFactory.getInstance(projectId, userId);
      setExpansionStorage(storage);

      // 保存されている展開状態を復元
      const savedStates = storage.getExpansionStates();
      if (savedStates.size > 0) {
        setUserStoriesExpanded(savedStates);
      }
    }
  }, [projectId, userId]);

  const handleUserStoryToggle = useCallback((userStoryId) => {
    const newState = expansionStorage
      ? expansionStorage.toggleExpansionState(userStoryId)
      : !userStoriesExpanded.get(userStoryId);

    setUserStoriesExpanded(prev => {
      const newMap = new Map(prev);
      newMap.set(userStoryId, newState);
      return newMap;
    });
  }, [expansionStorage, userStoriesExpanded]);

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