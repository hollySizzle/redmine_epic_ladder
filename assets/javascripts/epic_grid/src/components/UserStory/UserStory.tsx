import React from 'react';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { formatDateRange } from '../../utils/dateFormat';
import { StatusIndicator } from '../common/StatusIndicator';
import { TaskTestBugGrid } from '../TaskTestBug/TaskTestBugGrid';

interface UserStoryProps {
  storyId: string;
}

export const UserStory: React.FC<UserStoryProps> = ({ storyId }) => {
  // ストアから直接UserStoryを取得
  const story = useStore(state => state.entities.user_stories[storyId]);
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const isAssignedToVisible = useStore(state => state.isAssignedToVisible);
  const isDueDateVisible = useStore(state => state.isDueDateVisible);

  // 個別折り畳み状態（ストアで管理）
  const isOwnCollapsed = useStore(state => state.userStoryCollapseStates[storyId] ?? false);
  const setUserStoryCollapsed = useStore(state => state.setUserStoryCollapsed);

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
    if (!isDetailPaneVisible) {
      toggleDetailPane();
    }
    setSelectedEntity('issue', story.id);
  };

  const handleToggleCollapse = (e: React.MouseEvent) => {
    e.stopPropagation();
    setUserStoryCollapsed(story.id, !isOwnCollapsed);
  };

  return (
    <div ref={ref} className={className} data-story={story.id}>
      <div className="user-story-header" onClick={handleHeaderClick}>
        <div className="main-info-wrapper">
          <StatusIndicator status={story.status} />
          <span className="title-wrapper">
            {story.title}
          </span>
          <button
            className="user-story-collapse-toggle"
            onClick={handleToggleCollapse}
            title={isOwnCollapsed ? 'Task/Test/Bug配下を展開' : 'Task/Test/Bug配下を折り畳み'}
          >
            {isOwnCollapsed ? '▶' : '▼'}
          </button>
        </div>
        <div className="essential-info-wrapper">
          {isAssignedToVisible && assignedUser && (
            <span className="assigned_to-name-wrapper">
              {assignedUser.lastname} {assignedUser.firstname}
            </span>
          )}
          {isDueDateVisible && formatDateRange(story.start_date, story.due_date) && (
            <span className="date-range-wrapper">
              {formatDateRange(story.start_date, story.due_date)}
            </span>
          )}
        </div>
      </div>
      <TaskTestBugGrid
        userStoryId={story.id}
        taskIds={story.task_ids}
        testIds={story.test_ids}
        bugIds={story.bug_ids}
        isLocalCollapsed={isOwnCollapsed}
      />
    </div>
  );
};
