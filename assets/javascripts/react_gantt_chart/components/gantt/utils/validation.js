// バリデーション関数

// タスクデータのバリデーション
export const validateTaskData = (task) => {
  const errors = [];
  
  // 必須フィールドチェック
  if (!task.text || task.text.trim() === '') {
    errors.push('タスク名は必須です');
  }
  
  // 日付の妥当性チェック
  if (task.start_date && task.end_date) {
    const start = new Date(task.start_date);
    const end = new Date(task.end_date);
    
    if (isNaN(start.getTime())) {
      errors.push('開始日が無効です');
    }
    if (isNaN(end.getTime())) {
      errors.push('終了日が無効です');
    }
    if (start > end) {
      errors.push('開始日は終了日より前である必要があります');
    }
  }
  
  // 期間のチェック
  if (task.duration !== undefined) {
    if (task.duration < 0) {
      errors.push('期間は0以上である必要があります');
    }
    if (task.duration > 365 * 5) {
      errors.push('期間が長すぎます（5年以内に設定してください）');
    }
  }
  
  // 進捗率のチェック
  if (task.progress !== undefined) {
    if (task.progress < 0 || task.progress > 1) {
      errors.push('進捗率は0から100%の間で設定してください');
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors: errors
  };
};

// リンクデータのバリデーション
export const validateLinkData = (link, gantt) => {
  const errors = [];
  
  // 必須フィールドチェック
  if (!link.source) {
    errors.push('リンクのソースタスクが指定されていません');
  }
  if (!link.target) {
    errors.push('リンクのターゲットタスクが指定されていません');
  }
  
  // 同一タスクへのリンクチェック
  if (link.source === link.target) {
    errors.push('同じタスク間にリンクを作成することはできません');
  }
  
  // タスクの存在チェック
  if (gantt) {
    try {
      gantt.getTask(link.source);
    } catch (e) {
      errors.push('ソースタスクが存在しません');
    }
    
    try {
      gantt.getTask(link.target);
    } catch (e) {
      errors.push('ターゲットタスクが存在しません');
    }
  }
  
  // リンクタイプのチェック
  const validTypes = ['0', '1', '2', '3'];
  if (link.type !== undefined && !validTypes.includes(link.type.toString())) {
    errors.push('無効なリンクタイプです');
  }
  
  return {
    isValid: errors.length === 0,
    errors: errors
  };
};

// 日付範囲のバリデーション
export const validateDateRange = (startDate, endDate) => {
  if (!startDate || !endDate) {
    return {
      isValid: false,
      error: '開始日と終了日の両方を指定してください'
    };
  }
  
  const start = new Date(startDate);
  const end = new Date(endDate);
  
  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    return {
      isValid: false,
      error: '無効な日付形式です'
    };
  }
  
  if (start > end) {
    return {
      isValid: false,
      error: '開始日は終了日より前である必要があります'
    };
  }
  
  // 妥当な範囲かチェック（例：100年以内）
  const maxYears = 100;
  const yearDiff = (end.getFullYear() - start.getFullYear());
  if (yearDiff > maxYears) {
    return {
      isValid: false,
      error: `日付範囲は${maxYears}年以内にしてください`
    };
  }
  
  return { isValid: true };
};

// 親子関係のバリデーション
export const validateParentChild = (taskId, newParentId, gantt) => {
  // 自分自身を親にすることはできない
  if (taskId === newParentId) {
    return {
      isValid: false,
      error: 'タスクを自分自身の子にすることはできません'
    };
  }
  
  // 循環参照チェック
  if (wouldCreateCircularReference(taskId, newParentId, gantt)) {
    return {
      isValid: false,
      error: 'この移動は循環参照を作成するため実行できません'
    };
  }
  
  return { isValid: true };
};

// 循環参照のチェック
const wouldCreateCircularReference = (taskId, newParentId, gantt) => {
  if (!newParentId || !gantt) return false;
  
  let currentId = newParentId;
  const visited = new Set();
  
  while (currentId) {
    // 既に訪問済みの場合は循環を検出
    if (visited.has(currentId)) {
      return true;
    }
    visited.add(currentId);
    
    // 移動するタスクに到達した場合は循環参照
    if (currentId === taskId) {
      return true;
    }
    
    try {
      const parent = gantt.getTask(currentId);
      currentId = parent ? parent.parent : null;
    } catch (e) {
      // タスクが見つからない場合は終了
      break;
    }
  }
  
  return false;
};

// 権限のバリデーション
export const validatePermissions = (action, user, project) => {
  const permissions = {
    create: 'add_issues',
    edit: 'edit_issues',
    delete: 'delete_issues',
    move: 'edit_issues'
  };
  
  const requiredPermission = permissions[action];
  if (!requiredPermission) {
    return { isValid: true }; // 未定義のアクションは許可
  }
  
  // ここでRedmineの権限チェックを行う
  // 実際の実装では、サーバーサイドで権限チェックを行うべき
  return { isValid: true };
};

// データ整合性のチェック
export const validateDataIntegrity = (tasks, links) => {
  const errors = [];
  const taskIds = new Set(tasks.map(t => t.id.toString()));
  
  // リンクの参照整合性チェック
  links.forEach(link => {
    if (!taskIds.has(link.source.toString())) {
      errors.push(`リンク${link.id}のソースタスク(${link.source})が存在しません`);
    }
    if (!taskIds.has(link.target.toString())) {
      errors.push(`リンク${link.id}のターゲットタスク(${link.target})が存在しません`);
    }
  });
  
  // 親子関係の整合性チェック
  tasks.forEach(task => {
    if (task.parent && !taskIds.has(task.parent.toString())) {
      errors.push(`タスク${task.id}の親タスク(${task.parent})が存在しません`);
    }
  });
  
  return {
    isValid: errors.length === 0,
    errors: errors
  };
};