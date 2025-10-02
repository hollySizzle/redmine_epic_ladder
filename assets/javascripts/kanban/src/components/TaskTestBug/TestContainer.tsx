import React from 'react';
import { TestItem } from './TestItem';
import { AddButton } from '../common/AddButton';

interface TestContainerProps {
  testIds: string[];
}

export const TestContainer: React.FC<TestContainerProps> = ({ testIds }) => {
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
        />
      </div>
    </div>
  );
};
