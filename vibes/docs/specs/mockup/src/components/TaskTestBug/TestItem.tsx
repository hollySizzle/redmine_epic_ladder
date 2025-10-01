import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';

export interface TestItemData {
  id: string;
  title: string;
  status: 'open' | 'closed';
}

interface TestItemProps {
  test: TestItemData;
}

export const TestItem: React.FC<TestItemProps> = ({ test }) => {
  const className = test.status === 'closed' ? 'test-item closed' : 'test-item';

  return (
    <div className={className} data-test={test.id}>
      <StatusIndicator status={test.status} />
      {test.title}
    </div>
  );
};
