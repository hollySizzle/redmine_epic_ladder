import React, { useState } from 'react';
import { TaskItem } from './TaskItem';
import { AddButton } from '../common/AddButton';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';

interface TaskContainerProps {
  userStoryId: string;
  taskIds: string[];
}

export const TaskContainer: React.FC<TaskContainerProps> = ({ userStoryId, taskIds }) => {
  const createTask = useStore((state) => state.createTask);
  const users = useStore((state) => state.entities.users || {});
  const userStory = useStore((state) => state.entities.user_stories[userStoryId]);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const usersList = Object.values(users);

  const handleAddTask = () => {
    setIsModalOpen(true);
  };

  const handleSubmit = async (data: IssueFormData) => {
    try {
      await createTask(userStoryId, {
        subject: data.subject,
        description: data.description,
        parent_user_story_id: userStoryId,
        assigned_to_id: data.assigned_to_id
      });
    } catch (error) {
      alert(`Task作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  return (
    <>
      <div className="task-container">
        <div className="task-container-header">Task</div>
        <div className="task-item-grid">
          {taskIds.map(taskId => (
            <TaskItem key={taskId} taskId={taskId} />
          ))}
          <AddButton
            type="task"
            label="+ Add Task"
            dataAddButton="task"
            className="task-item"
            onClick={handleAddTask}
          />
        </div>
      </div>

      <IssueFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleSubmit}
        title="新しいTaskを追加"
        subjectLabel="Task名"
        subjectPlaceholder="例: データベース設計"
        showAssignee={true}
        users={usersList}
        defaultAssigneeId={userStory?.assigned_to_id}
      />
    </>
  );
};
