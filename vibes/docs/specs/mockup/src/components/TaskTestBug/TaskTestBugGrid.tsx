import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';
import { TaskItemData } from './TaskItem';
import { TestItemData } from './TestItem';
import { BugItemData } from './BugItem';

interface TaskTestBugGridProps {
  tasks: TaskItemData[];
  tests: TestItemData[];
  bugs: BugItemData[];
}

export const TaskTestBugGrid: React.FC<TaskTestBugGridProps> = ({
  tasks,
  tests,
  bugs
}) => {
  return (
    <div className="task-test-bug-grid">
      <TaskContainer tasks={tasks} />
      <TestContainer tests={tests} />
      <BugContainer bugs={bugs} />
    </div>
  );
};
