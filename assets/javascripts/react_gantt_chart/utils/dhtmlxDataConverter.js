// DHTMLX Gantt用データ変換ユーティリティ

/**
 * SVAR形式のタスクデータをDHTMLX形式に変換
 * @param {Array} svarTasks - SVAR形式のタスクデータ
 * @returns {Array} DHTMLX形式のタスクデータ
 */
export const convertSvarToGantt = (svarTasks) => {
  if (!Array.isArray(svarTasks)) return [];
  
  return svarTasks.map(task => ({
    id: task.id,
    text: task.text || task.subject || '',
    start_date: parseDate(task.start),
    duration: calculateDuration(task.start, task.end),
    parent: task.parent || 0,
    progress: calculateProgress(task.status_name, task.done_ratio),
    type: determineTaskType(task),
    open: true,  // デフォルトで展開
    // 元のRedmineデータを保持
    redmine_data: {
      assigned_to_name: task.assigned_to_name || '',
      status_name: task.status_name || '',
      end_date: task.end,
      custom_fields: task.custom_fields || {},
      subject: task.subject || '',
      tracker_name: task.tracker_name || '',
      priority_name: task.priority_name || '',
      done_ratio: task.done_ratio || 0,
      project_id: task.project_id,
      created_on: task.created_on,
      updated_on: task.updated_on
    }
  }));
};

/**
 * DHTMLX形式のタスクデータをSVAR形式に変換
 * @param {Array} ganttTasks - DHTMLX形式のタスクデータ
 * @returns {Array} SVAR形式のタスクデータ
 */
export const convertGanttToSvar = (ganttTasks) => {
  if (!Array.isArray(ganttTasks)) return [];
  
  return ganttTasks.map(task => ({
    id: task.id,
    text: task.text,
    start: formatDate(task.start_date),
    end: formatDate(calculateEndDate(task)),
    parent: task.parent || 0,
    assigned_to_name: task.redmine_data?.assigned_to_name || '',
    status_name: task.redmine_data?.status_name || '',
    custom_fields: task.redmine_data?.custom_fields || {},
    subject: task.redmine_data?.subject || task.text,
    tracker_name: task.redmine_data?.tracker_name || '',
    priority_name: task.redmine_data?.priority_name || '',
    done_ratio: task.redmine_data?.done_ratio || 0,
    project_id: task.redmine_data?.project_id,
    created_on: task.redmine_data?.created_on,
    updated_on: task.redmine_data?.updated_on
  }));
};

/**
 * 日付文字列をDateオブジェクトに変換
 * @param {string} dateString - 日付文字列 (YYYY-MM-DD)
 * @returns {Date} Dateオブジェクト
 */
export const parseDate = (dateString) => {
  if (!dateString) return new Date();
  
  const date = new Date(dateString);
  return isNaN(date.getTime()) ? new Date() : date;
};

/**
 * Dateオブジェクトを日付文字列に変換
 * @param {Date} date - Dateオブジェクト
 * @returns {string} 日付文字列 (YYYY-MM-DD)
 */
export const formatDate = (date) => {
  if (!date || !(date instanceof Date)) return '';
  
  return date.toISOString().split('T')[0];
};

/**
 * 開始日と終了日から期間を計算
 * @param {string} startDate - 開始日 (YYYY-MM-DD)
 * @param {string} endDate - 終了日 (YYYY-MM-DD)
 * @returns {number} 期間（日数）
 */
export const calculateDuration = (startDate, endDate) => {
  if (!startDate || !endDate) return 1;
  
  const start = parseDate(startDate);
  const end = parseDate(endDate);
  
  const diffTime = end.getTime() - start.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  return diffDays > 0 ? diffDays : 1;
};

/**
 * 開始日と期間から終了日を計算
 * @param {Date} startDate - 開始日
 * @param {number} duration - 期間（日数）
 * @returns {Date} 終了日
 */
export const calculateEndDate = (task) => {
  if (!task.start_date || !task.duration) return new Date();
  
  const endDate = new Date(task.start_date);
  endDate.setDate(endDate.getDate() + task.duration);
  
  return endDate;
};

/**
 * ステータスと進捗率から進捗を計算
 * @param {string} statusName - ステータス名
 * @param {number} doneRatio - 完了率
 * @returns {number} 進捗率 (0-1)
 */
export const calculateProgress = (statusName, doneRatio) => {
  // 完了率が設定されている場合はそれを使用
  if (typeof doneRatio === 'number' && doneRatio >= 0 && doneRatio <= 100) {
    return doneRatio / 100;
  }
  
  // ステータスから進捗を推定
  const statusProgressMap = {
    'New': 0,
    '新規': 0,
    'In Progress': 0.3,
    '進行中': 0.3,
    'Resolved': 0.8,
    '解決': 0.8,
    'Closed': 1.0,
    '終了': 1.0,
    'Rejected': 0,
    '却下': 0
  };
  
  return statusProgressMap[statusName] || 0;
};

/**
 * タスクタイプを判定
 * @param {Object} task - タスクデータ
 * @returns {string} タスクタイプ
 */
export const determineTaskType = (task) => {
  // 子タスクがある場合はproject（親タスク）
  if (task.children && task.children.length > 0) {
    return 'project';
  }
  
  // マイルストーンの判定
  if (task.tracker_name === 'マイルストーン' || task.tracker_name === 'Milestone') {
    return 'milestone';
  }
  
  // 通常のタスク
  return 'task';
};

/**
 * リンクデータをDHTMLX形式に変換
 * @param {Array} svarLinks - SVAR形式のリンクデータ
 * @returns {Array} DHTMLX形式のリンクデータ
 */
export const convertLinksToGantt = (svarLinks) => {
  if (!Array.isArray(svarLinks)) return [];
  
  return svarLinks.map(link => ({
    id: link.id,
    source: link.source,
    target: link.target,
    type: link.type || '0' // 0: finish_to_start, 1: start_to_start, 2: finish_to_finish, 3: start_to_finish
  }));
};

/**
 * DHTMLX形式のリンクデータをSVAR形式に変換
 * @param {Array} ganttLinks - DHTMLX形式のリンクデータ
 * @returns {Array} SVAR形式のリンクデータ
 */
export const convertLinksToSvar = (ganttLinks) => {
  if (!Array.isArray(ganttLinks)) return [];
  
  return ganttLinks.map(link => ({
    id: link.id,
    source: link.source,
    target: link.target,
    type: link.type
  }));
};

/**
 * 一括更新用のデータ変換
 * @param {Array} modifiedTaskIds - 変更されたタスクID一覧
 * @param {Function} getTask - タスク取得関数
 * @param {Map} pendingOrder - 保留中の順序変更
 * @returns {Array} 一括更新用データ
 */
export const convertForBulkUpdate = (modifiedTaskIds, getTask, pendingOrder) => {
  return modifiedTaskIds.map(id => {
    const task = getTask(id);
    const orderInfo = pendingOrder.get(id) || {};
    
    return {
      id: parseInt(id),
      start: formatDate(task.start_date),
      end: formatDate(calculateEndDate(task)),
      parent: task.parent || null,
      ...orderInfo
    };
  });
};

/**
 * カスタムフィールドの値を取得
 * @param {Object} customFields - カスタムフィールドオブジェクト
 * @param {string} fieldName - フィールド名
 * @returns {string} フィールド値
 */
export const getCustomFieldValue = (customFields, fieldName) => {
  if (!customFields || typeof customFields !== 'object') return '';
  
  return customFields[fieldName] || '';
};

/**
 * タスクの表示名を生成
 * @param {Object} task - タスクデータ
 * @returns {string} 表示名
 */
export const generateTaskDisplayName = (task) => {
  if (!task) return '';
  
  const hasChildren = task.children && task.children.length > 0;
  const prefix = hasChildren ? '' : `#${task.id} `;
  
  return prefix + (task.text || task.subject || '');
};

/**
 * 日付範囲の妥当性チェック
 * @param {Date} startDate - 開始日
 * @param {Date} endDate - 終了日
 * @returns {boolean} 妥当性
 */
export const isValidDateRange = (startDate, endDate) => {
  if (!startDate || !endDate) return false;
  if (!(startDate instanceof Date) || !(endDate instanceof Date)) return false;
  
  return startDate <= endDate;
};

/**
 * ズームレベルに応じたスケール設定を生成
 * @param {string} level - ズームレベル
 * @returns {Object} スケール設定
 */
export const generateScaleConfig = (level) => {
  const scaleConfigs = {
    year: {
      unit: 'year',
      step: 1,
      format: '%Y年'
    },
    quarter: {
      unit: 'quarter',
      step: 1,
      format: '%Y年Q%q'
    },
    month: {
      unit: 'month',
      step: 1,
      format: '%Y年%m月'
    },
    week: {
      unit: 'week',
      step: 1,
      format: '%Y年%W週'
    },
    day: {
      unit: 'day',
      step: 1,
      format: '%m/%d'
    }
  };
  
  return scaleConfigs[level] || scaleConfigs.day;
};