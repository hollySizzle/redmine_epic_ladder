import React from 'react';
import { UserStoryItem } from './UserStoryItem';

/**
 * UserStoryList - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const UserStoryList = ({
  userStories,
  userStoriesExpanded,
  onUserStoryToggle,
  onUserStoryAdd,
  onUserStoryUpdate,
  onUserStoryDelete
}) => {
  return (
    <div className="user-story-list">
      {userStories.map(userStory => (
        <UserStoryItem
          key={userStory.issue.id}
          userStory={userStory}
          expanded={userStoriesExpanded.get(userStory.issue.id) || false}
          onToggle={() => onUserStoryToggle(userStory.issue.id)}
          onUpdate={onUserStoryUpdate}
          onDelete={onUserStoryDelete}
        />
      ))}

      <button
        className="add-user-story-btn"
        onClick={onUserStoryAdd}
      >
        + UserStory
      </button>
    </div>
  );
};