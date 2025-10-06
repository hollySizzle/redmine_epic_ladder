import React, { useState } from 'react';
import { BugItem } from './BugItem';
import { AddButton } from '../common/AddButton';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';

interface BugContainerProps {
  userStoryId: string;
  bugIds: string[];
}

export const BugContainer: React.FC<BugContainerProps> = ({ userStoryId, bugIds }) => {
  const createBug = useStore((state) => state.createBug);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleAddBug = () => {
    setIsModalOpen(true);
  };

  const handleSubmit = async (data: IssueFormData) => {
    try {
      await createBug(userStoryId, {
        subject: data.subject,
        description: data.description,
        parent_user_story_id: userStoryId
      });
    } catch (error) {
      alert(`Bug作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  return (
    <>
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

      <IssueFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleSubmit}
        title="新しいBugを追加"
        subjectLabel="Bug名"
        subjectPlaceholder="例: ログインできない不具合"
      />
    </>
  );
};
