// リンク（依存関係）操作のハンドラー

export const createLinkHandlers = (config) => {
  const { 
    gantt,
    markModified, 
    updateParentState 
  } = config;

  // リンク作成バリデーション
  const validateLinkCreation = (link) => {
    // ソースとターゲットが同じ場合は拒否
    if (link.source === link.target) {
      alert('同じタスク間にリンクを作成することはできません');
      return false;
    }

    // 循環参照チェック
    if (wouldCreateCircularDependency(link, gantt)) {
      alert('この依存関係は循環参照を作成するため追加できません');
      return false;
    }

    // 重複チェック
    const existingLinks = gantt.getLinks();
    const duplicate = existingLinks.find(l => 
      l.source === link.source && 
      l.target === link.target && 
      l.type === link.type
    );
    
    if (duplicate) {
      alert('この依存関係は既に存在します');
      return false;
    }

    return true;
  };

  // リンク作成処理
  const handleLinkCreated = (id, link) => {
    console.log('リンク作成:', link);
    
    // リンクタイプの説明
    const linkTypes = {
      '0': 'Finish to Start',
      '1': 'Start to Start',
      '2': 'Finish to Finish',
      '3': 'Start to Finish'
    };
    
    if (!gantt.isTaskExists(link.source) || !gantt.isTaskExists(link.target)) {
      console.warn(`Source task ${link.source} or target task ${link.target} does not exist for link creation`);
      return;
    }
    const sourceTask = gantt.getTask(link.source);
    const targetTask = gantt.getTask(link.target);
    
    console.log(`依存関係作成: "${sourceTask.text}" → "${targetTask.text}" (${linkTypes[link.type]})`);
    
    // 変更状態を記録
    markModified(`link_${id}`);
    updateParentState();
  };

  // リンク削除バリデーション
  const validateLinkDeletion = (link) => {
    // 必須の依存関係かチェック（カスタムロジック）
    if (isRequiredDependency(link, gantt)) {
      alert('この依存関係は削除できません');
      return false;
    }
    
    return confirm('この依存関係を削除してもよろしいですか？');
  };

  // リンク削除処理
  const handleLinkDeleted = (id, link) => {
    console.log('リンク削除:', link);
    
    if (!gantt.isTaskExists(link.source) || !gantt.isTaskExists(link.target)) {
      console.warn(`Source task ${link.source} or target task ${link.target} does not exist for link deletion`);
      markModified(`link_${id}`);
      updateParentState();
      return;
    }
    const sourceTask = gantt.getTask(link.source);
    const targetTask = gantt.getTask(link.target);
    
    console.log(`依存関係削除: "${sourceTask.text}" → "${targetTask.text}"`);
    
    markModified(`link_${id}`);
    updateParentState();
  };

  // リンク更新バリデーション
  const validateLinkUpdate = (link) => {
    return validateLinkCreation(link);
  };

  // リンク更新処理
  const handleLinkUpdated = (id, link) => {
    console.log('リンク更新:', link);
    markModified(`link_${id}`);
    updateParentState();
  };

  // クリティカルパスの計算
  const calculateCriticalPath = () => {
    if (gantt.config.highlight_critical_path) {
      gantt.render();
    }
  };

  // 依存関係に基づくタスク日付の自動調整
  const adjustDependentTasks = (taskId) => {
    const task = gantt.getTask(taskId);
    const links = gantt.getLinks();
    
    // このタスクをソースとするリンクを探す
    const dependentLinks = links.filter(link => link.source === taskId);
    
    dependentLinks.forEach(link => {
      const targetTask = gantt.getTask(link.target);
      
      // Finish to Start の場合
      if (link.type === '0') {
        const sourceEnd = gantt.calculateEndDate(task.start_date, task.duration);
        if (targetTask.start_date < sourceEnd) {
          // ターゲットタスクの開始日を調整
          targetTask.start_date = new Date(sourceEnd);
          gantt.updateTask(targetTask.id);
          markModified(targetTask.id);
          
          // 再帰的に依存タスクを調整
          adjustDependentTasks(targetTask.id);
        }
      }
    });
  };

  return {
    validateLinkCreation,
    handleLinkCreated,
    validateLinkDeletion,
    handleLinkDeleted,
    validateLinkUpdate,
    handleLinkUpdated,
    calculateCriticalPath,
    adjustDependentTasks
  };
};

// ヘルパー関数

// 循環依存のチェック
const wouldCreateCircularDependency = (newLink, gantt) => {
  
  // 一時的にリンクを追加して循環をチェック
  const checkCircular = (taskId, targetId, visited = new Set()) => {
    if (taskId === targetId) return true;
    if (visited.has(taskId)) return false;
    
    visited.add(taskId);
    
    const links = gantt.getLinks();
    const outgoingLinks = links.filter(link => link.source === taskId);
    
    for (const link of outgoingLinks) {
      if (checkCircular(link.target, targetId, visited)) {
        return true;
      }
    }
    
    // 新しいリンクも考慮
    if (newLink.source === taskId && checkCircular(newLink.target, targetId, visited)) {
      return true;
    }
    
    return false;
  };
  
  return checkCircular(newLink.target, newLink.source);
};

// 必須の依存関係かチェック
const isRequiredDependency = (link, gantt) => {
  // カスタムロジック：例えば、マイルストーンへの依存関係は削除不可など
  const targetTask = gantt.getTask(link.target);
  return targetTask && targetTask.type === 'milestone';
};

// リンクタイプの変換
export const getLinkType = (typeString) => {
  const types = {
    'finish_to_start': '0',
    'start_to_start': '1',
    'finish_to_finish': '2',
    'start_to_finish': '3'
  };
  return types[typeString] || '0';
};

// リンクタイプの逆変換
export const getLinkTypeString = (typeCode) => {
  const types = {
    '0': 'finish_to_start',
    '1': 'start_to_start',
    '2': 'finish_to_finish',
    '3': 'start_to_finish'
  };
  return types[typeCode] || 'finish_to_start';
};