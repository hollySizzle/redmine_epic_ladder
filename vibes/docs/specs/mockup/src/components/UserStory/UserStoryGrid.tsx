import React from 'react';
import { UserStory } from './UserStory';

interface UserStoryGridProps {
  storyIds: string[];
}

export const UserStoryGrid: React.FC<UserStoryGridProps> = ({ storyIds }) => {
  return (
    <div className="user-story-grid">
      {storyIds.map(storyId => (
        <UserStory key={storyId} storyId={storyId} />
      ))}
    </div>
  );
};
