import React, { useState } from 'react';
import { UserStory } from './UserStory';
import { AddButton } from '../common/AddButton';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';

/**
 * UserStoryGridForCell
 *
 * EpicVersionGrid（3D Grid）内のセルで使用されるUserStoryグリッド。
 * Epic × Feature × Versionの3次元座標を持つため、epicId/featureId/versionIdが全て必須。
 */
interface UserStoryGridForCellProps {
  epicId: string;
  featureId: string;
  versionId: string;
  storyIds: string[];
}

export const UserStoryGridForCell: React.FC<UserStoryGridForCellProps> = ({
  epicId,
  featureId,
  versionId,
  storyIds
}) => {
  const createUserStory = useStore((state) => state.createUserStory);
  const users = useStore((state) => Object.values(state.entities.users || {}));
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleAddUserStory = () => {
    setIsModalOpen(true);
  };

  const handleSubmit = async (data: IssueFormData) => {
    try {
      await createUserStory(featureId, {
        subject: data.subject,
        description: data.description,
        parent_feature_id: featureId,
        fixed_version_id: versionId !== 'none' ? versionId : undefined, // セル指定バージョンを送信
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
          epicId={epicId}
          featureId={featureId}
          versionId={versionId}
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
        users={users}
      />
    </>
  );
};
