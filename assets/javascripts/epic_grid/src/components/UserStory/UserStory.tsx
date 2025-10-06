import React from 'react';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { StatusIndicator } from '../common/StatusIndicator';
import { TaskTestBugGrid } from '../TaskTestBug/TaskTestBugGrid';

interface UserStoryProps {
  storyId: string;
  isLocalCollapsed?: boolean;
}

export const UserStory: React.FC<UserStoryProps> = ({ storyId, isLocalCollapsed = false }) => {
  // ストアから直接UserStoryを取得
  const story = useStore(state => state.entities.user_stories[storyId]);
  const setSelectedIssueId = useStore(state => state.setSelectedIssueId);
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);

  // 担当者情報を取得
  const assignedUser = useStore(state =>
    story?.assigned_to_id ? state.entities.users[story.assigned_to_id] : undefined
  );

  if (!story) return null;

  const className = story.status === 'closed' ? 'user-story closed' : 'user-story';

  const ref = useDraggableAndDropTarget({
    type: 'user-story',
    id: story.id,
    onDrop: (sourceData) => {
      console.log('UserStory dropped:', sourceData.id, '→', story.id);
    }
  });

  const handleHeaderClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIssueId(story.id);
  };

  return (
    <div ref={ref} className={className} data-story={story.id}>
      <div className="user-story-header" onClick={handleHeaderClick}>
        <StatusIndicator status={story.status} />
        <span className="title-wrapper">
          {story.title}
        </span>
        {isAssignedToVisible && assignedUser && (
          <span className="assigned_to-name-wrapper">
            {assignedUser.lastname} {assignedUser.firstname}
          </span>
        )}
      </div>
      <TaskTestBugGrid
        userStoryId={story.id}
        taskIds={story.task_ids}
        testIds={story.test_ids}
        bugIds={story.bug_ids}
        isLocalCollapsed={isLocalCollapsed}
      />
    </div>
  );
};
