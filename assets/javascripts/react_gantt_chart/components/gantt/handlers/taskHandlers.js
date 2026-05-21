// タスク操作のハンドラー

export const createTaskHandlers = (config) => {
  const { 
    projectId, 
    gantt,
    markModified, 
    updateParentState,
    pendingOrder,
    modifiedTasks 
  } = config;

  // サブタスク作成処理
  const handleCreateSubtask = async (parentTaskId) => {
    if (!gantt.isTaskExists(parentTaskId)) {
      console.warn(`Parent task ${parentTaskId} does not exist for subtask creation`);
      return;
    }
    const parentTask = gantt.getTask(parentTaskId);
    if (!parentTask) return;

    // 新規チケット作成ダイアログを表示
    const subject = prompt('新規サブタスク名を入力してください:', '新規サブタスク');
    if (!subject) return;

    try {
      // プラグインのコントローラー経由でサブタスクを作成
      const response = await fetch(`/projects/${projectId}/react_gantt_chart/create_subtask`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        credentials: 'same-origin',
        body: JSON.stringify({
          issue: {
            subject: subject,
            parent_issue_id: parentTaskId,
            start_date: new Date().toISOString().split('T')[0],
            due_date: null
          }
        })
      });

      if (response.ok) {
        const result = await response.json();
        console.log('Create subtask response:', result); // デバッグログ
        
        if (result.issue) {
          // 作成されたタスクをGanttに追加
          const newTask = result.issue;
          console.log('New task data:', newTask); // デバッグログ
          console.log('New task redmine_data:', newTask.redmine_data); // デバッグログ
          
          // タスクをGanttチャートに追加
          gantt.addTask(newTask, newTask.parent);
          
          // 追加されたタスクのデータを確認
          const addedTask = gantt.getTask(newTask.id);
          console.log('Added task data:', addedTask); // デバッグログ
          
          // 親タスクとその親階層を全て展開
          expandParentHierarchy(gantt, parentTaskId);
          
          // Ganttチャートを更新
          gantt.refreshData();
          gantt.render();
          
          // 新しく作成されたサブタスクをDHTMLX Ganttで選択
          setTimeout(() => {
            if (gantt.isTaskExists(newTask.id)) {
              gantt.selectTask(newTask.id);
              console.log('DHTMLX Ganttで新しいサブタスクを選択:', newTask.id);
              
              // 2ペインモードの場合、右側の詳細画面を新しいサブタスクで更新
              if (config.onTaskSelected) {
                console.log('サブタスク作成後、右側詳細画面を更新:', newTask.id);
                config.onTaskSelected(newTask.id);
              }
            } else {
              console.warn('新しいサブタスクがGanttに存在しません:', newTask.id);
            }
          }, 200);
          
          // TaskDetailPane の iframe を強制リロード（親チケット画面も更新）
          if (config.onTaskDetailRefresh) {
            console.log('親チケット詳細画面をリフレッシュ:', parentTaskId);
            config.onTaskDetailRefresh(parentTaskId);
          }
          
          // 成功メッセージを表示
          alert('サブタスクが正常に作成されました');
          
          // 変更されたタスクとしてマーク
          markModified(newTask.id);
          updateParentState();
        }
      } else {
        let errorMessage = 'サブタスクの作成に失敗しました';
        try {
          const errorData = await response.json();
          errorMessage = errorData.errors?.join(', ') || errorMessage;
        } catch (e) {
          // JSONパースエラーの場合はデフォルトメッセージを使用
        }
        throw new Error(errorMessage);
      }
    } catch (error) {
      console.error('Create subtask error:', error);
      alert('サブタスクの作成に失敗しました: ' + error.message);
    }
  };

  // 新規ルートタスク作成処理
  const handleCreateRootTask = async () => {
    const subject = prompt('新規チケット名を入力してください:', '新規チケット');
    if (!subject) return;

    try {
      const response = await fetch(`/projects/${projectId}/issues.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          issue: {
            subject: subject,
            start_date: new Date().toISOString().split('T')[0],
            due_date: null
          }
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.issue) {
          alert('チケットが正常に作成されました');
          // データを再取得する必要がある場合は、親コンポーネントに通知
          if (config.onFilterChange) {
            config.onFilterChange(config.filters);
          }
        }
      } else {
        const errorData = await response.json();
        throw new Error(errorData.errors?.join(', ') || 'チケットの作成に失敗しました');
      }
    } catch (error) {
      console.error('Create issue error:', error);
      alert('チケットの作成に失敗しました: ' + error.message);
    }
  };

  // タスク移動前のバリデーション
  const validateTaskMove = (id, parent, tindex) => {
    if (!gantt.isTaskExists(id)) {
      console.warn(`Task ${id} does not exist for move validation`);
      return false;
    }
    const task = gantt.getTask(id);
    
    // 自分自身を親にすることはできない
    if (id == parent) {
      alert('タスクを自分自身の子にすることはできません');
      return false;
    }
    
    // 循環参照チェック
    if (isCircularReference(id, parent)) {
      alert('この移動は循環参照を作成するため実行できません');
      return false;
    }
    
    return true;
  };

  // タスク移動処理
  const handleMoveTask = (id, parent, tindex) => {
    try {
      if (!validateTaskMove(id, parent, tindex)) {
        return false;
      }
      
      const task = gantt.getTask(id);
      if (!task) {
        console.error(`Task with id ${id} not found`);
        return false;
      }
      
      const oldParent = task.parent;
      
      // 行ドラッグ&ドロップの場合の追加ログ
      console.log("Task reorder:", {
        task: task.text,
        from: oldParent,
        to: parent,
        index: tindex,
        operation: oldParent !== parent ? 'parent_change' : 'reorder'
      });
      
      // 順序情報を保存
      pendingOrder.set(id, {
        prevSibling: getPrevSibling(id, parent, tindex),
        nextSibling: getNextSibling(id, parent, tindex),
        operation: oldParent !== parent ? 'parent_change' : 'reorder'
      });
      
      markModified(id);
      
      // 親タスクも変更対象としてマーク
      if (oldParent && oldParent !== parent) {
        markModified(oldParent);
        if (parent) {
          markModified(parent);
        }
      }
      
      return true;
    } catch (error) {
      console.error('Task move error:', error);
      alert('タスクの移動中にエラーが発生しました: ' + error.message);
      return false;
    }
  };

  // タスクデータのバリデーション
  const validateTaskData = (id, item) => {
    // 必須フィールドチェック
    if (!item.text || item.text.trim() === '') {
      alert('タスク名は必須です');
      return false;
    }
    
    // 日付の妥当性チェック
    if (item.start_date && item.end_date) {
      const start = new Date(item.start_date);
      const end = new Date(item.end_date);
      if (start > end) {
        console.log('taskHandlers.validateTaskData警告: 開始日が終了日より後になっています', {
          id: id,
          start_date: item.start_date,
          end_date: item.end_date,
          start: start,
          end: end,
          item: item
        });
        // alert('開始日は終了日より前である必要があります');
        // return false;
      }
    }
    
    return true;
  };

  // タスク削除処理
  const handleDeleteTask = async (id) => {
    if (!confirm('本当にこのタスクを削除しますか？')) {
      return;
    }
    
    try {
      // Redmine APIを使用してタスクを削除
      const response = await fetch(`/issues/${id}.json`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        }
      });
      
      if (response.ok) {
        gantt.deleteTask(id);
        alert('タスクが削除されました');
      } else {
        throw new Error('タスクの削除に失敗しました');
      }
    } catch (error) {
      console.error('Delete task error:', error);
      alert('タスクの削除に失敗しました: ' + error.message);
    }
  };

  return {
    handleCreateSubtask,
    handleCreateRootTask,
    handleMoveTask,
    validateTaskData,
    handleDeleteTask
  };
};

// ヘルパー関数

// 親階層を展開
const expandParentHierarchy = (gantt, taskId) => {
  let currentId = taskId;
  while (currentId) {
    gantt.open(currentId);
    if (!gantt.isTaskExists(currentId)) {
      console.warn(`Task ${currentId} does not exist during parent expansion`);
      break;
    }
    const currentTask = gantt.getTask(currentId);
    currentId = currentTask ? currentTask.parent : null;
  }
};

// 循環参照チェック
const isCircularReference = (taskId, newParentId) => {
  if (!newParentId) return false;
  
  let currentId = newParentId;
  while (currentId) {
    if (currentId == taskId) return true;
    if (!gantt.isTaskExists(currentId)) {
      console.warn(`Task ${currentId} does not exist during ancestor check`);
      break;
    }
    const parent = gantt.getTask(currentId);
    currentId = parent ? parent.parent : null;
  }
  return false;
};

// 前の兄弟タスクを取得
const getPrevSibling = (taskId, parentId, index) => {
  const siblings = gantt.getChildren(parentId);
  if (index > 0 && siblings[index - 1]) {
    return siblings[index - 1];
  }
  return null;
};

// 次の兄弟タスクを取得
const getNextSibling = (taskId, parentId, index) => {
  const siblings = gantt.getChildren(parentId);
  if (index < siblings.length - 1 && siblings[index + 1]) {
    return siblings[index + 1];
  }
  return null;
};