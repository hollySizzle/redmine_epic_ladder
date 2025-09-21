// Release Kanban Plugin Entry Point
// Redmine Release Kanban プラグインのメインエントリーポイント
// 7つのコンポーネント統合システムの初期化

import React from 'react';
import ReactDOM from 'react-dom';
import { ReleaseKanbanApp } from './components/ReleaseKanbanApp';

// CSS imports (if using CSS modules or styled-components)
// import './styles/kanban.css';

/**
 * Release Kanban の初期化関数
 * Redmine のページ読み込み時に呼び出される
 */
function initializeReleaseKanban() {
  console.log('Release Kanban Plugin initializing...');

  // DOM要素の検索
  const kanbanContainer = document.getElementById('release-kanban-container');

  if (!kanbanContainer) {
    console.warn('Release Kanban container not found');
    return;
  }

  // データ属性からプロジェクト情報を取得
  const projectId = kanbanContainer.dataset.projectId;
  const currentUserData = kanbanContainer.dataset.currentUser;
  const initialData = kanbanContainer.dataset.initialData;

  if (!projectId) {
    console.error('Project ID not found in container data attributes');
    return;
  }

  // ユーザー情報のパース
  let currentUser = { id: null, name: 'Anonymous' };
  try {
    if (currentUserData) {
      currentUser = JSON.parse(currentUserData);
    }
  } catch (error) {
    console.warn('Failed to parse current user data:', error);
  }

  // 初期データのパース
  let parsedInitialData = null;
  try {
    if (initialData) {
      parsedInitialData = JSON.parse(initialData);
    }
  } catch (error) {
    console.warn('Failed to parse initial data, will fetch from API:', error);
  }

  // React アプリケーションをマウント
  try {
    ReactDOM.render(
      React.createElement(ReleaseKanbanApp, {
        projectId: parseInt(projectId, 10),
        currentUser: currentUser,
        initialData: parsedInitialData
      }),
      kanbanContainer
    );

    console.log('Release Kanban Plugin initialized successfully', {
      projectId,
      user: currentUser.name,
      hasInitialData: !!parsedInitialData
    });
  } catch (error) {
    console.error('Failed to initialize Release Kanban Plugin:', error);

    // フォールバック表示
    kanbanContainer.innerHTML = `
      <div class="release-kanban-error">
        <h3>Release Kanban の読み込みに失敗しました</h3>
        <p>エラー: ${error.message}</p>
        <button onclick="location.reload()">ページを再読み込み</button>
      </div>
    `;
  }
}

/**
 * トラッカー階層制約の検証
 * Issue 作成・編集フォームで使用
 */
function validateTrackerHierarchy(childTrackerId, parentTrackerId) {
  // TrackerHierarchy コンポーネントのクライアント側検証
  const HIERARCHY_RULES = {
    'Epic': { children: ['Feature'], parents: [] },
    'Feature': { children: ['UserStory'], parents: ['Epic'] },
    'UserStory': { children: ['Task', 'Test', 'Bug'], parents: ['Feature'] },
    'Task': { children: [], parents: ['UserStory'] },
    'Test': { children: [], parents: ['UserStory'] },
    'Bug': { children: [], parents: ['UserStory', 'Feature'] }
  };

  // TODO: 実際のトラッカー名を取得する処理を実装
  // 現在はプレースホルダー
  console.log('Validating tracker hierarchy:', { childTrackerId, parentTrackerId });
  return true;
}

/**
 * カンバンカードのドラッグ&ドロップ状態遷移
 * 外部から呼び出し可能な状態遷移API
 */
async function transitionIssueState(issueId, targetColumn, projectId) {
  try {
    const response = await fetch(`/projects/${projectId}/kanban/api/transition_issue`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        issue_id: issueId,
        target_column: targetColumn
      })
    });

    if (!response.ok) {
      throw new Error(`状態遷移失敗: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Issue state transition failed:', error);
    throw error;
  }
}

/**
 * DOM 読み込み完了時の初期化
 */
function onDOMContentLoaded() {
  // 複数のエントリーポイントをサポート
  if (document.getElementById('release-kanban-container')) {
    initializeReleaseKanban();
  }

  // Redmine のフォーム拡張
  enhanceRedmineForms();
}

/**
 * Redmine のフォーム拡張
 * Issue 作成・編集フォームに階層制約検証を追加
 */
function enhanceRedmineForms() {
  const issueForm = document.querySelector('#issue-form, .new_issue, .edit_issue');

  if (issueForm) {
    console.log('Enhancing Redmine issue form with Release Kanban features');

    // 親Issue選択時の階層制約チェック
    const parentSelect = issueForm.querySelector('#issue_parent_issue_id');
    const trackerSelect = issueForm.querySelector('#issue_tracker_id');

    if (parentSelect && trackerSelect) {
      const validateHierarchy = () => {
        const childTrackerId = trackerSelect.value;
        const parentIssueId = parentSelect.value;

        if (childTrackerId && parentIssueId) {
          // TODO: 実際の検証ロジックを実装
          console.log('Validating hierarchy:', { childTrackerId, parentIssueId });
        }
      };

      parentSelect.addEventListener('change', validateHierarchy);
      trackerSelect.addEventListener('change', validateHierarchy);
    }
  }
}

// グローバル関数をエクスポート（Redmine から呼び出し可能）
window.ReleaseKanban = {
  initialize: initializeReleaseKanban,
  validateTrackerHierarchy: validateTrackerHierarchy,
  transitionIssueState: transitionIssueState
};

// DOM 読み込み完了時に初期化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', onDOMContentLoaded);
} else {
  // 既に読み込み完了している場合は即座に実行
  onDOMContentLoaded();
}

console.log('Release Kanban Plugin entry point loaded');

export {
  initializeReleaseKanban,
  validateTrackerHierarchy,
  transitionIssueState
};