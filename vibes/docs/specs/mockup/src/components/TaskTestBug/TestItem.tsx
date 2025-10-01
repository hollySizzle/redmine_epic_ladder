import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';

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

  const ref = useDraggableAndDropTarget({
    type: 'test',
    id: test.id,
    onDrop: (sourceData) => {
      console.log('Test dropped:', sourceData.id, '→', test.id);
    }
  });

  return (
    <div ref={ref} className={className} data-test={test.id}>
      <StatusIndicator status={test.status} />
      {test.title}
    </div>
  );
};
