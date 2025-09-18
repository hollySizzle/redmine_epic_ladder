// ガントチャートのヘルパー関数

// 変更されたタスクの取得
export const getModifiedTasks = (gantt, modifiedIds) => {
  const tasks = [];
  
  modifiedIds.forEach(id => {
    if (id.startsWith('link_')) {
      // リンクの場合は別処理
      return;
    }
    
    try {
      const task = gantt.getTask(id);
      if (task) {
        tasks.push({
          id: task.id,
          text: task.text,
          start_date: task.start_date,
          duration: task.duration,
          progress: task.progress,
          parent: task.parent,
          redmine_data: task.redmine_data
        });
      }
    } catch (e) {
      console.warn(`Task ${id} not found`);
    }
  });
  
  return tasks;
};

// 変更されたリンクの取得
export const getModifiedLinks = (gantt, modifiedIds) => {
  const links = [];
  
  modifiedIds.forEach(id => {
    if (id.startsWith('link_')) {
      const linkId = id.replace('link_', '');
      try {
        const link = gantt.getLink(linkId);
        if (link) {
          links.push(link);
        }
      } catch (e) {
        console.warn(`Link ${linkId} not found`);
      }
    }
  });
  
  return links;
};

// 親階層を展開
export const expandParentHierarchy = (gantt, taskId) => {
  let currentId = taskId;
  while (currentId) {
    gantt.open(currentId);
    const currentTask = gantt.getTask(currentId);
    currentId = currentTask ? currentTask.parent : null;
  }
};

// 全タスクを展開
export const expandAllTasks = (gantt) => {
  console.log('expandAllTasks 実行開始');
  
  // 親タスクのみを対象にする
  const parentTasks = [];
  gantt.eachTask(function(task) {
    if (gantt.hasChild(task.id)) {
      parentTasks.push(task.id);
    }
  });
  
  console.log(`展開対象の親タスク: ${parentTasks.length}件`);
  
  // DHMLXの公式APIを使用して展開
  parentTasks.forEach(taskId => {
    try {
      gantt.open(taskId);
      console.log(`タスク ${taskId} を展開`);
    } catch (error) {
      console.warn(`タスク ${taskId} の展開に失敗:`, error);
    }
  });
  
  // レンダリングを実行
  gantt.render();
  console.log('expandAllTasks 完了');
};

// 全タスクを折りたたむ
export const collapseAllTasks = (gantt) => {
  console.log('collapseAllTasks 実行開始');
  
  // 親タスクのみを対象にする
  const parentTasks = [];
  gantt.eachTask(function(task) {
    if (gantt.hasChild(task.id)) {
      parentTasks.push(task.id);
    }
  });
  
  console.log(`折りたたみ対象の親タスク: ${parentTasks.length}件`);
  
  // DHMLXの公式APIを使用して折りたたみ
  parentTasks.forEach(taskId => {
    try {
      gantt.close(taskId);
      console.log(`タスク ${taskId} を折りたたみ`);
    } catch (error) {
      console.warn(`タスク ${taskId} の折りたたみに失敗:`, error);
    }
  });
  
  // レンダリングを実行
  gantt.render();
  console.log('collapseAllTasks 完了');
};

// タスクをハイライト表示
export const highlightTask = (taskId, duration = 2000) => {
  setTimeout(() => {
    const taskElement = document.querySelector(`[task_id="${taskId}"]`);
    if (taskElement) {
      taskElement.style.boxShadow = '0 0 10px rgba(59, 130, 246, 0.5)';
      taskElement.style.transition = 'box-shadow 0.3s ease';
      
      setTimeout(() => {
        taskElement.style.boxShadow = '';
      }, duration);
    }
  }, 100);
};

// 日付範囲の取得
export const getDateRange = (gantt) => {
  let minDate = null;
  let maxDate = null;
  
  gantt.eachTask(function(task) {
    const taskStart = task.start_date;
    const taskEnd = gantt.calculateEndDate(task.start_date, task.duration);
    
    if (!minDate || taskStart < minDate) {
      minDate = taskStart;
    }
    if (!maxDate || taskEnd > maxDate) {
      maxDate = taskEnd;
    }
  });
  
  return { minDate, maxDate };
};

// タスクのフィルタリング
export const filterTasks = (gantt, filterFunc) => {
  gantt.attachEvent('onBeforeTaskDisplay', filterFunc);
  gantt.render();
};

// フィルターのクリア
export const clearTaskFilter = (gantt) => {
  gantt.detachAllEvents('onBeforeTaskDisplay');
  gantt.render();
};

// タスクの検索
export const searchTasks = (gantt, searchText) => {
  const results = [];
  const lowerSearchText = searchText.toLowerCase();
  
  gantt.eachTask(function(task) {
    if (task.text.toLowerCase().includes(lowerSearchText) ||
        (task.redmine_data?.description && 
         task.redmine_data.description.toLowerCase().includes(lowerSearchText))) {
      results.push({
        id: task.id,
        text: task.text,
        path: getTaskPath(gantt, task.id)
      });
    }
  });
  
  return results;
};

// タスクのパスを取得
export const getTaskPath = (gantt, taskId) => {
  const path = [];
  let currentId = taskId;
  
  while (currentId) {
    const task = gantt.getTask(currentId);
    if (task) {
      path.unshift(task.text);
      currentId = task.parent;
    } else {
      break;
    }
  }
  
  return path.join(' > ');
};

// 進捗率の計算
export const calculateProgress = (gantt, taskId) => {
  const task = gantt.getTask(taskId);
  
  if (!gantt.hasChild(taskId)) {
    // 子タスクがない場合はそのまま返す
    return task.progress || 0;
  }
  
  // 子タスクがある場合は加重平均を計算
  let totalDuration = 0;
  let weightedProgress = 0;
  
  gantt.eachTask(function(child) {
    totalDuration += child.duration || 1;
    weightedProgress += (child.progress || 0) * (child.duration || 1);
  }, taskId);
  
  return totalDuration > 0 ? weightedProgress / totalDuration : 0;
};

// タスクの統計情報
export const getTaskStatistics = (gantt) => {
  const stats = {
    total: 0,
    completed: 0,
    inProgress: 0,
    notStarted: 0,
    overdue: 0,
    critical: 0
  };
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  gantt.eachTask(function(task) {
    stats.total++;
    
    if (task.progress >= 1) {
      stats.completed++;
    } else if (task.progress > 0) {
      stats.inProgress++;
    } else {
      stats.notStarted++;
    }
    
    const taskEnd = gantt.calculateEndDate(task.start_date, task.duration);
    if (taskEnd < today && task.progress < 1) {
      stats.overdue++;
    }
    
    if (task.critical_task) {
      stats.critical++;
    }
  });
  
  return stats;
};

// CSVエクスポート用のデータ整形
export const formatTasksForExport = (gantt) => {
  const tasks = [];
  
  gantt.eachTask(function(task) {
    tasks.push({
      id: task.id,
      text: task.text,
      start_date: gantt.templates.date_grid(task.start_date),
      end_date: gantt.templates.date_grid(gantt.calculateEndDate(task.start_date, task.duration)),
      duration: task.duration,
      progress: Math.round((task.progress || 0) * 100) + '%',
      assigned_to: task.redmine_data?.assigned_to_name || '',
      status: task.redmine_data?.status_name || '',
      tracker: task.redmine_data?.tracker_name || '',
      parent_id: task.parent || '',
      level: task.$level
    });
  });
  
  return tasks;
};