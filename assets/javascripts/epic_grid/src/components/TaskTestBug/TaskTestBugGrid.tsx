import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';

interface TaskTestBugGridProps {
  userStoryId: string;
  taskIds: string[];
  testIds: string[];
  bugIds: string[];
}

export const TaskTestBugGrid: React.FC<TaskTestBugGridProps> = ({
  userStoryId,
  taskIds,
  testIds,
  bugIds
}) => {
  return (
    <div className="task-test-bug-grid">
      <TaskContainer userStoryId={userStoryId} taskIds={taskIds} />
      <TestContainer userStoryId={userStoryId} testIds={testIds} />
      <BugContainer userStoryId={userStoryId} bugIds={bugIds} />
    </div>
  );
};
