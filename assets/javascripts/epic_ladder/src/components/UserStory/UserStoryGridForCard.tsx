import React, { useState } from 'react';
import { UserStory } from './UserStory';
import { AddButton } from '../common/AddButton';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';

/**
 * UserStoryGridForCard
 *
 * FeatureCard内で使用されるUserStoryグリッド。
 * FeatureCardは単独のFeatureコンポーネントであり、
 * Epic/Versionのコンテキストを持たないため、featureIdのみで動作する。
 */
interface UserStoryGridForCardProps {
  featureId: string;
  storyIds: string[];
}

export const UserStoryGridForCard: React.FC<UserStoryGridForCardProps> = ({
  featureId,
  storyIds
}) => {
  const createUserStory = useStore((state) => state.createUserStory);
  const users = useStore((state) => state.entities.users || {});
  const [isModalOpen, setIsModalOpen] = useState(false);

  const usersList = Object.values(users);

  const handleAddUserStory = () => {
    setIsModalOpen(true);
  };

  const handleSubmit = async (data: IssueFormData) => {
    try {
      await createUserStory(featureId, {
        subject: data.subject,
        description: data.description,
        parent_feature_id: featureId,
        assigned_to_id: data.assigned_to_id
      });
    } catch (error) {
      alert(`User Story作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  return (
    <>
      <div className="user-story-grid">
        {storyIds.map(storyId => (
          <UserStory key={storyId} storyId={storyId} />
        ))}
        <AddButton
          type="user-story"
          label="+ Add User Story"
          dataAddButton="user-story"
          featureId={featureId}
          onClick={handleAddUserStory}
        />
      </div>

      <IssueFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleSubmit}
        title="新しいUser Storyを追加"
        subjectLabel="User Story名"
        subjectPlaceholder="例: ユーザーがログインできる"
        showAssignee={true}
        users={usersList}
      />
    </>
  );
};
