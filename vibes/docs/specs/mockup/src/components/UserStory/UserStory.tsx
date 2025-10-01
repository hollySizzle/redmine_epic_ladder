import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { TaskTestBugGrid } from '../TaskTestBug/TaskTestBugGrid';
import { TaskItemData } from '../TaskTestBug/TaskItem';
import { TestItemData } from '../TaskTestBug/TestItem';
import { BugItemData } from '../TaskTestBug/BugItem';

export interface UserStoryData {
  id: string;
  title: string;
  status: 'open' | 'closed';
  tasks: TaskItemData[];
  tests: TestItemData[];
  bugs: BugItemData[];
}

interface UserStoryProps {
  story: UserStoryData;
}

export const UserStory: React.FC<UserStoryProps> = ({ story }) => {
  const className = story.status === 'closed' ? 'user-story closed' : 'user-story';

  return (
    <div className={className} data-story={story.id}>
      <div className="user-story-header">
        <StatusIndicator status={story.status} />
        {story.title}
      </div>
      <TaskTestBugGrid
        tasks={story.tasks}
        tests={story.tests}
        bugs={story.bugs}
      />
    </div>
  );
};
