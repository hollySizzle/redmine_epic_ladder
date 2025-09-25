import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';
import './UserStoryItem.scss';

/**
 * UserStoryItem - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const UserStoryItem = ({
  userStory,
  expanded,
  onToggle,
  onUpdate,
  onDelete
}) => {
  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#f0f0f0',
      '完了': '#e0e0e0',
      '未着手': '#f5f5f5'
    };
    return colors[status] || '#f5f5f5';
  };

  const handleDeleteClick = (e) => {
    e.stopPropagation();
    if (window.confirm(`UserStory "${userStory.issue.subject}" を削除しますか？`)) {
      onDelete(userStory.issue.id);
    }
  };

  return (
    <div className={`user-story ${expanded ? 'expanded' : 'collapsed'}`}>
      <div className="user-story-header" onClick={onToggle}>
        <button className="collapse-btn">
          {expanded ? '▼' : '▶'}
        </button>

        <span
          className={`user-story-title ${expanded ? '' : 'collapsed-title'}`}
        >
          {userStory.issue.subject}
        </span>

        <span
          className="user-story-status"
          style={{ backgroundColor: getStatusColor(userStory.issue.status) }}
        >
          {userStory.issue.status}
        </span>

        <button
          className="user-story-delete-btn"
          onClick={handleDeleteClick}
          title="UserStoryを削除"
        >
          Delete
        </button>
      </div>

      {expanded && (
        <>
          <TaskContainer
            tasks={userStory.tasks}
            userStoryId={userStory.issue.id}
            onTaskAdd={() => console.log('Task追加')}
            onTaskUpdate={() => console.log('Task更新')}
            onTaskDelete={() => console.log('Task削除')}
          />

          <TestContainer
            tests={userStory.tests}
            userStoryId={userStory.issue.id}
            onTestAdd={() => console.log('Test追加')}
            onTestUpdate={() => console.log('Test更新')}
            onTestDelete={() => console.log('Test削除')}
          />

          <BugContainer
            bugs={userStory.bugs}
            userStoryId={userStory.issue.id}
            onBugAdd={() => console.log('Bug追加')}
            onBugUpdate={() => console.log('Bug更新')}
            onBugDelete={() => console.log('Bug削除')}
          />
        </>
      )}
    </div>
  );
};