import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface TestItemProps {
  testId: string;
}

export const TestItem: React.FC<TestItemProps> = ({ testId }) => {
  const test = useStore(state => state.entities.tests[testId]);

  if (!test) return null;

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
