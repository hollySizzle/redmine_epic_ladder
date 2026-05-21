// DHTMLX Gantt カスタムタスクバーテンプレート

/**
 * カスタムタスクバーテンプレート
 * @param {Date} start - タスク開始日
 * @param {Date} end - タスク終了日
 * @param {Object} task - タスクオブジェクト
 * @returns {string} HTML文字列
 */
export const customTaskTemplate = (start, end, task) => {
  const redmineData = task.redmine_data || {};
  const hasChildren = task.type === 'project';
  
  // タスク名の生成
  const taskName = hasChildren ? task.text : `#${task.id} ${task.text}`;
  
  // ステータスの色設定
  const statusColor = getStatusColor(redmineData.status_name);
  
  // 進捗バーの幅計算
  const progressWidth = Math.max(0, Math.min(100, (task.progress || 0) * 100));
  
  return `
    <div class="custom-task-bar" style="position: relative; height: 100%; display: flex; align-items: center;">
      <div class="task-progress-bg" style="
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: ${statusColor.bg};
        border: 1px solid ${statusColor.border};
        border-radius: 3px;
      "></div>
      
      <div class="task-progress-fill" style="
        position: absolute;
        top: 0;
        left: 0;
        width: ${progressWidth}%;
        height: 100%;
        background-color: ${statusColor.progress};
        border-radius: 3px;
        transition: width 0.3s ease;
      "></div>
      
      <div class="task-content" style="
        position: relative;
        z-index: 2;
        display: flex;
        align-items: center;
        width: 100%;
        padding: 0 8px;
        font-size: 12px;
        color: ${statusColor.text};
        white-space: nowrap;
        overflow: hidden;
      ">
        <span class="task-name" style="
          font-weight: ${hasChildren ? 'bold' : 'normal'};
          margin-right: 8px;
          overflow: hidden;
          text-overflow: ellipsis;
        ">${taskName}</span>
        
        <span class="task-status" style="
          background-color: ${statusColor.statusBg};
          color: ${statusColor.statusText};
          padding: 1px 4px;
          border-radius: 2px;
          font-size: 10px;
          margin-right: 4px;
        ">${redmineData.status_name || ''}</span>
        
        <span class="task-assigned" style="
          color: #666;
          font-size: 10px;
        ">${redmineData.assigned_to_name || ''}</span>
      </div>
    </div>
  `;
};

/**
 * カスタムタスクバーの右端テンプレート
 * @param {Object} task - タスクオブジェクト
 * @returns {string} HTML文字列
 */
export const customRightTextTemplate = (task) => {
  const redmineData = task.redmine_data || {};
  const endDate = redmineData.end_date || '';
  const formattedDate = formatDate(endDate);
  
  return `
    <div class="task-right-text" style="
      font-size: 11px;
      color: #666;
      margin-left: 8px;
    ">
      ${formattedDate}
    </div>
  `;
};

/**
 * カスタムタスクバーの左端テンプレート
 * @param {Object} task - タスクオブジェクト
 * @returns {string} HTML文字列
 */
export const customLeftTextTemplate = (task) => {
  const redmineData = task.redmine_data || {};
  const priority = redmineData.priority_name || '';
  
  if (!priority) return '';
  
  const priorityIcon = getPriorityIcon(priority);
  
  return `
    <div class="task-left-text" style="
      font-size: 11px;
      color: #666;
      margin-right: 8px;
    ">
      ${priorityIcon}
    </div>
  `;
};

/**
 * カスタムツールチップテンプレート
 * @param {Date} start - タスク開始日
 * @param {Date} end - タスク終了日
 * @param {Object} task - タスクオブジェクト
 * @returns {string} HTML文字列
 */
export const customTooltipTemplate = (start, end, task) => {
  const redmineData = task.redmine_data || {};
  const customFields = redmineData.custom_fields || {};
  
  // カスタムフィールドの表示
  const customFieldsHtml = Object.entries(customFields)
    .map(([key, value]) => `
      <div class="tooltip-field">
        <span class="field-label">${key}:</span>
        <span class="field-value">${value}</span>
      </div>
    `)
    .join('');
  
  return `
    <div class="gantt-tooltip" style="
      background: white;
      border: 1px solid #ccc;
      border-radius: 4px;
      padding: 12px;
      font-size: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      max-width: 300px;
    ">
      <div class="tooltip-header" style="
        font-weight: bold;
        margin-bottom: 8px;
        padding-bottom: 4px;
        border-bottom: 1px solid #eee;
      ">
        ${task.text}
      </div>
      
      <div class="tooltip-body">
        <div class="tooltip-field">
          <span class="field-label">ID:</span>
          <span class="field-value">#${task.id}</span>
        </div>
        
        <div class="tooltip-field">
          <span class="field-label">期間:</span>
          <span class="field-value">${formatDate(start)} - ${formatDate(end)}</span>
        </div>
        
        <div class="tooltip-field">
          <span class="field-label">ステータス:</span>
          <span class="field-value">${redmineData.status_name || ''}</span>
        </div>
        
        <div class="tooltip-field">
          <span class="field-label">担当者:</span>
          <span class="field-value">${redmineData.assigned_to_name || ''}</span>
        </div>
        
        <div class="tooltip-field">
          <span class="field-label">進捗:</span>
          <span class="field-value">${Math.round((task.progress || 0) * 100)}%</span>
        </div>
        
        ${customFieldsHtml}
      </div>
    </div>
  `;
};

/**
 * マイルストーンテンプレート
 * @param {Object} task - タスクオブジェクト
 * @returns {string} HTML文字列
 */
export const customMilestoneTemplate = (task) => {
  const redmineData = task.redmine_data || {};
  
  return `
    <div class="milestone-marker" style="
      width: 0;
      height: 0;
      border-left: 8px solid transparent;
      border-right: 8px solid transparent;
      border-top: 12px solid #ff6b6b;
      position: relative;
      margin: 0 auto;
    ">
      <div class="milestone-label" style="
        position: absolute;
        top: 15px;
        left: 50%;
        transform: translateX(-50%);
        font-size: 11px;
        font-weight: bold;
        color: #333;
        white-space: nowrap;
      ">
        ${task.text}
      </div>
    </div>
  `;
};

/**
 * ステータスに基づく色設定を取得
 * @param {string} statusName - ステータス名
 * @returns {Object} 色設定オブジェクト
 */
const getStatusColor = (statusName) => {
  const colorMap = {
    'New': {
      bg: '#f0f0f0',
      border: '#d0d0d0',
      progress: '#e0e0e0',
      text: '#333',
      statusBg: '#e3f2fd',
      statusText: '#1976d2'
    },
    '新規': {
      bg: '#f0f0f0',
      border: '#d0d0d0',
      progress: '#e0e0e0',
      text: '#333',
      statusBg: '#e3f2fd',
      statusText: '#1976d2'
    },
    'In Progress': {
      bg: '#e3f2fd',
      border: '#90caf9',
      progress: '#2196f3',
      text: '#333',
      statusBg: '#fff3e0',
      statusText: '#f57c00'
    },
    '進行中': {
      bg: '#e3f2fd',
      border: '#90caf9',
      progress: '#2196f3',
      text: '#333',
      statusBg: '#fff3e0',
      statusText: '#f57c00'
    },
    'Resolved': {
      bg: '#e8f5e8',
      border: '#81c784',
      progress: '#4caf50',
      text: '#333',
      statusBg: '#e8f5e8',
      statusText: '#388e3c'
    },
    '解決': {
      bg: '#e8f5e8',
      border: '#81c784',
      progress: '#4caf50',
      text: '#333',
      statusBg: '#e8f5e8',
      statusText: '#388e3c'
    },
    'Closed': {
      bg: '#f3e5f5',
      border: '#ba68c8',
      progress: '#9c27b0',
      text: '#333',
      statusBg: '#f3e5f5',
      statusText: '#7b1fa2'
    },
    '終了': {
      bg: '#f3e5f5',
      border: '#ba68c8',
      progress: '#9c27b0',
      text: '#333',
      statusBg: '#f3e5f5',
      statusText: '#7b1fa2'
    }
  };
  
  return colorMap[statusName] || colorMap['New'];
};

/**
 * 優先度アイコンを取得
 * @param {string} priority - 優先度名
 * @returns {string} アイコン文字列
 */
const getPriorityIcon = (priority) => {
  const iconMap = {
    'Low': '↓',
    '低': '↓',
    'Normal': '—',
    '通常': '—',
    'High': '↑',
    '高': '↑',
    'Urgent': '↑↑',
    '至急': '↑↑',
    'Immediate': '!!!',
    '即時': '!!!'
  };
  
  return iconMap[priority] || '';
};

/**
 * 日付フォーマット
 * @param {string|Date} date - 日付
 * @returns {string} フォーマット済み日付
 */
const formatDate = (date) => {
  if (!date) return '';
  
  const d = new Date(date);
  if (isNaN(d.getTime())) return '';
  
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  
  return `${year}/${month}/${day}`;
};

/**
 * テンプレートをDHTMLX Ganttに適用
 * @param {Object} gantt - DHTMLX Ganttインスタンス
 */
export const applyCustomTemplates = (gantt) => {
  // タスクバーテンプレート
  gantt.templates.task_text = customTaskTemplate;
  
  // 右端テキストテンプレート
  gantt.templates.rightside_text = customRightTextTemplate;
  
  // 左端テキストテンプレート
  gantt.templates.leftside_text = customLeftTextTemplate;
  
  // ツールチップテンプレート
  gantt.templates.tooltip_text = customTooltipTemplate;
  
  // マイルストーンテンプレート
  gantt.templates.milestone_text = customMilestoneTemplate;
  
  // グリッドの日付フォーマット
  gantt.templates.date_grid = gantt.date.date_to_str('%Y/%m/%d');
  
  // スケールの日付フォーマット
  gantt.templates.date_scale = gantt.date.date_to_str('%m/%d');
};

/**
 * CSSスタイルを追加
 */
export const addCustomStyles = () => {
  const style = document.createElement('style');
  style.textContent = `
    .custom-task-bar {
      font-family: 'Helvetica Neue', Arial, sans-serif;
    }
    
    .tooltip-field {
      display: flex;
      margin-bottom: 4px;
    }
    
    .field-label {
      font-weight: bold;
      margin-right: 8px;
      min-width: 60px;
    }
    
    .field-value {
      color: #666;
    }
    
    .milestone-marker {
      cursor: pointer;
    }
    
    .milestone-marker:hover {
      opacity: 0.8;
    }
    
    .gantt_task_line.gantt_milestone .milestone-marker {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    }
    
    .custom-task-bar:hover {
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    
    .task-progress-fill {
      opacity: 0.7;
    }
    
    .task-content {
      text-shadow: 0 1px 1px rgba(255,255,255,0.5);
    }
  `;
  
  document.head.appendChild(style);
};