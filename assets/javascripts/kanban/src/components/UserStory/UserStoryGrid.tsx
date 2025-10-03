import React from 'react';
import { UserStory } from './UserStory';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

interface UserStoryGridProps {
  featureId: string;
  storyIds: string[];
}

export const UserStoryGrid: React.FC<UserStoryGridProps> = ({ featureId, storyIds }) => {
  const createUserStory = useStore((state) => state.createUserStory);

  const handleAddUserStory = async () => {
    const subject = prompt('User Story名を入力してください:');
    if (!subject) return;

    try {
      await createUserStory(featureId, {
        subject,
        description: '',
        parent_feature_id: featureId
      });
    } catch (error) {
      alert(`User Story作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
    <div className="user-story-grid">
      {storyIds.map(storyId => (
        <UserStory key={storyId} storyId={storyId} />
      ))}
      <AddButton
        type="user-story"
        label="+ Add User Story"
        dataAddButton="user-story"
        onClick={handleAddUserStory}
      />
    </div>
  );
};
