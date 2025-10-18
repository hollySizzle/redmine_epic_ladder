import React from 'react';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';
import { formatDateRange, isOverdue } from '../../utils/dateFormat';
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
  const isIssueIdVisible = useStore(state => state.isIssueIdVisible);

  // 個別折り畳み状態（ストアで管理）
  const isOwnCollapsed = useStore(state => state.userStoryCollapseStates[storyId] ?? false);
  const setUserStoryCollapsed = useStore(state => state.setUserStoryCollapsed);

  // 担当者情報を取得
  const assignedUser = useStore(state =>
    story?.assigned_to_id ? state.entities.users[story.assigned_to_id] : undefined
  );

  // 全エンティティを取得（期日超過チェック用）
  const entities = useStore(state => state.entities);

  if (!story) return null;

  // 自身または子チケットに期日超過があるかチェック
  const isSelfOverdue = isOverdue(story.due_date);

  const hasOverdueChildren =
    story.task_ids.some(id => entities.tasks[id] && isOverdue(entities.tasks[id].due_date)) ||
    story.test_ids.some(id => entities.tests[id] && isOverdue(entities.tests[id].due_date)) ||
    story.bug_ids.some(id => entities.bugs[id] && isOverdue(entities.bugs[id].due_date));

  const shouldHighlight = isSelfOverdue || hasOverdueChildren;

  const className = [
    'user-story',
    story.status === 'closed' && 'closed',
    shouldHighlight && 'overdue'
  ].filter(Boolean).join(' ');

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
          {isIssueIdVisible && (
            <span className="issue-id-wrapper">#{story.id}</span>
          )}
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
