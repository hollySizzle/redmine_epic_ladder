import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';
import { useStore } from '../../store/useStore';

interface TaskTestBugGridProps {
  userStoryId: string;
  taskIds: string[];
  testIds: string[];
  bugIds: string[];
  isLocalCollapsed?: boolean;
}

export const TaskTestBugGrid: React.FC<TaskTestBugGridProps> = ({
  userStoryId,
  taskIds,
  testIds,
  bugIds,
  isLocalCollapsed = false
}) => {
  // 一括折り畳み状態を取得
  const isGlobalCollapsed = useStore(state => state.isUserStoryChildrenCollapsed);

  // 一括折り畳みまたは個別折り畳みが有効な場合は非表示
  if (isGlobalCollapsed || isLocalCollapsed) {
    return null;
  }

  return (
    <div className="task-test-bug-grid">
      <TaskContainer userStoryId={userStoryId} taskIds={taskIds} />
      <TestContainer userStoryId={userStoryId} testIds={testIds} />
      <BugContainer userStoryId={userStoryId} bugIds={bugIds} />
    </div>
  );
};
