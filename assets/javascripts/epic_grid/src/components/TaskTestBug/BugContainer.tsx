import React from 'react';
import { BugItem } from './BugItem';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

interface BugContainerProps {
  userStoryId: string;
  bugIds: string[];
}

export const BugContainer: React.FC<BugContainerProps> = ({ userStoryId, bugIds }) => {
  const createBug = useStore((state) => state.createBug);

  const handleAddBug = async () => {
    const subject = prompt('Bug名を入力してください:');
    if (!subject) return;

    try {
      await createBug(userStoryId, {
        subject,
        description: '',
        parent_user_story_id: userStoryId
      });
    } catch (error) {
      alert(`Bug作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

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
          onClick={handleAddBug}
        />
      </div>
    </div>
  );
};
