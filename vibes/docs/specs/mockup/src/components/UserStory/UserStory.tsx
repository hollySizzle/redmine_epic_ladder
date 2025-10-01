import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { TaskTestBugGrid } from '../TaskTestBug/TaskTestBugGrid';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface UserStoryProps {
  storyId: string;
}

export const UserStory: React.FC<UserStoryProps> = ({ storyId }) => {
  // ストアから直接UserStoryを取得
  const story = useStore(state => state.entities.user_stories[storyId]);

  if (!story) return null;

  const className = story.status === 'closed' ? 'user-story closed' : 'user-story';

  const ref = useDraggableAndDropTarget({
    type: 'user-story',
    id: story.id,
    onDrop: (sourceData) => {
      console.log('UserStory dropped:', sourceData.id, '→', story.id);
    }
  });

  return (
    <div ref={ref} className={className} data-story={story.id}>
      <div className="user-story-header">
        <StatusIndicator status={story.status} />
        {story.title}
      </div>
      <TaskTestBugGrid
        taskIds={story.task_ids}
        testIds={story.test_ids}
        bugIds={story.bug_ids}
      />
    </div>
  );
};
