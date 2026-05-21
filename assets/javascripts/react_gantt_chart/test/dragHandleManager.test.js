/**
 * ドラッグハンドル管理ユーティリティのテスト
 * 本番環境での動作を確認するための基本テスト
 */

import { 
  initializeDragHandles, 
  refreshDragHandles, 
  createDragHandlesImmediate,
  getDefaultConfig
} from '../components/gantt/utils/dragHandleManager';

// Mock DOM environment for testing
function setupTestDOM() {
  document.body.innerHTML = `
    <div class="gantt_task_line" data-task-id="1">
      <div class="gantt_task_bar">Task 1</div>
    </div>
    <div class="gantt_task_line parent-task-computed" data-task-id="2">
      <div class="gantt_task_bar">Parent Task</div>
    </div>
    <div class="gantt_task_line" data-task-id="3">
      <div class="gantt_task_bar">Task 3</div>
      <div class="gantt_task_drag existing">Existing Handle</div>
    </div>
  `;
}

function cleanupTestDOM() {
  document.body.innerHTML = '';
}

describe('DragHandleManager', () => {
  beforeEach(setupTestDOM);
  afterEach(cleanupTestDOM);

  test('デフォルト設定の取得', () => {
    const config = getDefaultConfig();
    
    expect(config).toHaveProperty('initialDelay', 200);
    expect(config).toHaveProperty('refreshDelay', 100);
    expect(config).toHaveProperty('taskSelector', '.gantt_task_line');
    expect(config).toHaveProperty('enableLogging', false);
  });

  test('権限なしの場合はスキップ', async () => {
    const permissions = { canEdit: false };
    const result = await initializeDragHandles(permissions);
    
    expect(result.skipped).toBe(true);
    expect(result.handlesCreated).toBe(0);
  });

  test('即座にドラッグハンドルを作成', () => {
    const result = createDragHandlesImmediate({
      enableLogging: true,
      logPrefix: '[TEST]'
    });
    
    // 2つのタスク（親タスクは除外）にハンドルが作成される
    expect(result.handlesCreated).toBe(2);
    expect(result.tasksSkipped).toBe(1);
    
    // 実際にDOMにハンドルが追加されているか確認
    const handles = document.querySelectorAll('.gantt_task_drag');
    expect(handles.length).toBe(4); // 2つのタスク × 左右ハンドル
  });

  test('既存ハンドルの削除と再作成', () => {
    // 最初に既存ハンドルがあることを確認
    expect(document.querySelectorAll('.gantt_task_drag').length).toBe(1);
    
    const result = createDragHandlesImmediate();
    
    // 古いハンドルが削除され、新しいハンドルが作成される
    expect(result.handlesCreated).toBe(2);
    expect(document.querySelectorAll('.gantt_task_drag').length).toBe(4);
    expect(document.querySelectorAll('.gantt_task_drag.existing').length).toBe(0);
  });

  test('カスタムクラス名の適用', () => {
    createDragHandlesImmediate({
      leftHandleClass: 'custom_left_handle',
      rightHandleClass: 'custom_right_handle'
    });
    
    expect(document.querySelectorAll('.custom_left_handle').length).toBe(2);
    expect(document.querySelectorAll('.custom_right_handle').length).toBe(2);
  });

  test('親タスクの除外', () => {
    const result = createDragHandlesImmediate();
    
    // 親タスク（parent-task-computed）にはハンドルが作成されない
    const parentTask = document.querySelector('.parent-task-computed');
    expect(parentTask.querySelectorAll('.gantt_task_drag').length).toBe(0);
    
    expect(result.tasksSkipped).toBe(1);
  });

  test('非同期での初期化', async () => {
    const permissions = { canEdit: true };
    const result = await initializeDragHandles(permissions, {
      initialDelay: 10 // テスト用に短く設定
    });
    
    expect(result.handlesCreated).toBe(2);
    expect(result.tasksSkipped).toBe(1);
  });

  test('DOM未準備時のスキップ', async () => {
    cleanupTestDOM(); // DOMをクリア
    
    const permissions = { canEdit: true };
    const result = await refreshDragHandles(permissions, {
      refreshDelay: 10
    });
    
    expect(result.skipped).toBe(true);
    expect(result.handlesCreated).toBe(0);
  });
});

// 実行例（ブラウザコンソール用）
export function runManualTest() {
  console.log('=== ドラッグハンドル管理ユーティリティ テスト ===');
  
  // デフォルト設定確認
  console.log('1. デフォルト設定:', getDefaultConfig());
  
  // 即座に作成テスト
  console.log('2. 即座に作成テスト実行中...');
  const result = createDragHandlesImmediate({
    enableLogging: true,
    logPrefix: '[Manual Test]'
  });
  console.log('結果:', result);
  
  // 非同期テスト
  console.log('3. 非同期初期化テスト実行中...');
  initializeDragHandles({ canEdit: true }, {
    enableLogging: true,
    logPrefix: '[Async Test]'
  }).then(result => {
    console.log('非同期結果:', result);
  });
  
  console.log('=== テスト完了 ===');
}