import React from 'react';
import { TaskItem } from './TaskItem';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

interface TaskContainerProps {
  userStoryId: string;
  taskIds: string[];
}

export const TaskContainer: React.FC<TaskContainerProps> = ({ userStoryId, taskIds }) => {
  const createTask = useStore((state) => state.createTask);

  const handleAddTask = async () => {
    const subject = prompt('Task名を入力してください:');
    if (!subject) return;

    try {
      await createTask(userStoryId, {
        subject,
        description: '',
        parent_user_story_id: userStoryId
      });
    } catch (error) {
      alert(`Task作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
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
  );
};
