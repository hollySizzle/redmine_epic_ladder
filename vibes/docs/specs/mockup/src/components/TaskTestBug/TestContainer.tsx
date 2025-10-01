import React from 'react';
import { TestItem, TestItemData } from './TestItem';
import { AddButton } from '../common/AddButton';

interface TestContainerProps {
  tests: TestItemData[];
}

export const TestContainer: React.FC<TestContainerProps> = ({ tests }) => {
  return (
    <div className="test-container">
      <div className="test-container-header">Test</div>
      <div className="test-item-grid">
        {tests.map(test => (
          <TestItem key={test.id} test={test} />
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
