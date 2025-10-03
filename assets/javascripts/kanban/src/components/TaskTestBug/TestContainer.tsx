import React from 'react';
import { TestItem } from './TestItem';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

interface TestContainerProps {
  userStoryId: string;
  testIds: string[];
}

export const TestContainer: React.FC<TestContainerProps> = ({ userStoryId, testIds }) => {
  const createTest = useStore((state) => state.createTest);

  const handleAddTest = async () => {
    const subject = prompt('Test名を入力してください:');
    if (!subject) return;

    try {
      await createTest(userStoryId, {
        subject,
        description: '',
        parent_user_story_id: userStoryId
      });
    } catch (error) {
      alert(`Test作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
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
  );
};
