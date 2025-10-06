import React, { useState } from 'react';
import { TestItem } from './TestItem';
import { AddButton } from '../common/AddButton';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';

interface TestContainerProps {
  userStoryId: string;
  testIds: string[];
}

export const TestContainer: React.FC<TestContainerProps> = ({ userStoryId, testIds }) => {
  const createTest = useStore((state) => state.createTest);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleAddTest = () => {
    setIsModalOpen(true);
  };

  const handleSubmit = async (data: IssueFormData) => {
    try {
      await createTest(userStoryId, {
        subject: data.subject,
        description: data.description,
        parent_user_story_id: userStoryId
      });
    } catch (error) {
      alert(`Test作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  return (
    <>
      <div className="test-container">
        <div className="test-container-header">Test</div>
        <div className="test-item-grid">
          {testIds.map(testId => (
            <TestItem key={testId} testId={testId} />
          ))}
          <AddButton
            type="test"
            label="+ Add Test"
            dataAddButton="test"
            className="test-item"
            onClick={handleAddTest}
          />
        </div>
      </div>

      <IssueFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleSubmit}
        title="新しいTestを追加"
        subjectLabel="Test名"
        subjectPlaceholder="例: ログイン機能のテスト"
      />
    </>
  );
};
