import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';

interface TaskTestBugGridProps {
  taskIds: string[];
  testIds: string[];
  bugIds: string[];
}

export const TaskTestBugGrid: React.FC<TaskTestBugGridProps> = ({
  taskIds,
  testIds,
  bugIds
}) => {
  return (
    <div className="task-test-bug-grid">
      <TaskContainer taskIds={taskIds} />
      <TestContainer testIds={testIds} />
      <BugContainer bugIds={bugIds} />
    </div>
  );
};
