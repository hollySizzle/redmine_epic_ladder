import React from 'react';
import { UserStory, UserStoryData } from './UserStory';

interface UserStoryGridProps {
  stories: UserStoryData[];
}

export const UserStoryGrid: React.FC<UserStoryGridProps> = ({ stories }) => {
  return (
    <div className="user-story-grid">
      {stories.map(story => (
        <UserStory key={story.id} story={story} />
      ))}
    </div>
  );
};
