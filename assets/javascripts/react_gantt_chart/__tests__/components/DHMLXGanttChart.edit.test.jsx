import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import DHMLXGanttChart from '../../components/DHMLXGanttChart';
import { gantt } from 'dhtmlx-gantt';
import * as dhtmlxDataConverter from '../../utils/dhtmlxDataConverter';

// モック設定
jest.mock('dhtmlx-gantt');
jest.mock('../../utils/dhtmlxDataConverter');
jest.mock('../../templates/DHMLXCustomBar');
jest.mock('../../hooks/useZoomConfigDHMLX', () => ({
  useZoomConfigDHMLX: () => ({
    level: 'day',
    setLevel: jest.fn(),
    config: { scale_unit: 'day' }
  })
}));

// fetchモック
global.fetch = jest.fn();

describe('DHMLXGanttChart - 編集機能', () => {
  const mockTasks = [
    {
      id: 1,
      text: 'タスク1',
      start: '2024-01-01',
      end: '2024-01-05',
      progress: 0.5,
      parent: 0,
      editable: true,
      issue_id: '123'
    },
    {
      id: 2,
      text: 'タスク2',
      start: '2024-01-03',
      end: '2024-01-08',
      progress: 0.3,
      parent: 1,
      editable: true,
      issue_id: '124'
    }
  ];

  const mockLinks = [
    {
      id: 1,
      source: 1,
      target: 2,
      type: '0'
    }
  ];

  const defaultProps = {
    tasks: mockTasks,
    setTasks: jest.fn(),
    links: mockLinks,
    visibleColumns: [],
    onColumnSettingsChange: jest.fn(),
    projectId: 'test-project',
    filters: {},
    onFilterChange: jest.fn()
  };

  beforeEach(() => {
    jest.clearAllMocks();
    
    // データ変換モック設定
    dhtmlxDataConverter.convertSvarToGantt.mockImplementation(tasks => 
      tasks.map(task => ({
        ...task,
        start_date: new Date(task.start),
        end_date: new Date(task.end)
      }))
    );
    
    dhtmlxDataConverter.convertGanttToSvar.mockImplementation(tasks => tasks);
    dhtmlxDataConverter.convertForBulkUpdate.mockImplementation((ids, getTask) => 
      ids.map(id => ({ id, ...getTask(id) }))
    );
    
    // Ganttモック設定
    gantt.init = jest.fn();
    gantt.parse = jest.fn();
    gantt.clearAll = jest.fn();
    gantt.attachEvent = jest.fn(() => 1);
    gantt.getTask = jest.fn(id => mockTasks.find(t => t.id === id));
    gantt.getChildren = jest.fn(() => []);
    gantt.getLinks = jest.fn(() => mockLinks);
    gantt.showLightbox = jest.fn();
    gantt.uid = jest.fn(() => 999);
    gantt.addTask = jest.fn();
    gantt.config = { lightbox: { sections: [] } };
    gantt.locale = { labels: {} };
    gantt.form_blocks = {};
    gantt.templates = {};
    gantt.refreshData = jest.fn();
    gantt.detachAllEvents = jest.fn();
    gantt.clearCache = jest.fn();
    gantt.clearTimer = jest.fn();
    gantt.eachTask = jest.fn();
    gantt.calculateDuration = jest.fn(() => 5);
    gantt.calculateEndDate = jest.fn(() => new Date('2024-01-05'));
    gantt.date = {
      date_to_str: jest.fn(() => jest.fn(date => date.toISOString().split('T')[0]))
    };
    gantt.getState = jest.fn(() => ({ lightbox: 1 }));
    gantt.silent = jest.fn(fn => fn());
    gantt.batchUpdate = jest.fn(fn => fn());
    
    // fetchモック設定
    fetch.mockResolvedValue({
      ok: true,
      json: async () => ({ success: true })
    });
    
    // DOMモック設定
    document.querySelector = jest.fn().mockReturnValue({
      content: 'mock-csrf-token'
    });
    
    // メタタグモック
    document.querySelector.mockReturnValue({
      content: 'mock-csrf-token'
    });
  });

  describe('F003: 編集・保存機能', () => {
    it('インライン編集イベントハンドラーを正しく登録する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // インライン編集用イベントハンドラーが登録される
      expect(gantt.attachEvent).toHaveBeenCalledWith('onBeforeTaskUpdate', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterTaskUpdate', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onBeforeTaskMove', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterTaskMove', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onTaskDrag', expect.any(Function));
    });

    it('ライトボックス編集イベントハンドラーを正しく登録する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // ライトボックス編集用イベントハンドラーが登録される
      expect(gantt.attachEvent).toHaveBeenCalledWith('onBeforeLightbox', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onLightboxSave', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onTaskDblClick', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterLightbox', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onLightbox', expect.any(Function));
    });

    it('カスタムform_blockが正しく定義される', () => {
      // gantt.form_blocksのモック設定
      gantt.form_blocks = {};
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // カスタムform_blockが定義される
      expect(gantt.form_blocks.redmine_template).toBeDefined();
      expect(gantt.form_blocks.redmine_template.render).toBeDefined();
      expect(gantt.form_blocks.redmine_template.set_value).toBeDefined();
      expect(gantt.form_blocks.redmine_template.get_value).toBeDefined();
      expect(gantt.form_blocks.redmine_template.focus).toBeDefined();
    });

    it('カスタムform_blockのrender関数が正しく動作する', () => {
      gantt.form_blocks = {};
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      const renderFunc = gantt.form_blocks.redmine_template.render;
      const result = renderFunc({ name: 'test_section' });
      
      expect(result).toBe('<div class="redmine_form_container" id="test_section"></div>');
    });

    it('カスタムform_blockのset_value関数が正しく動作する', () => {
      gantt.form_blocks = {};
      
      const mockNode = {
        innerHTML: ''
      };
      
      const mockTask = {
        redmine_data: {
          assigned_to_name: 'テストユーザー',
          status_name: '進行中',
          priority_name: '高'
        },
        progress: 0.75
      };
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      const setValueFunc = gantt.form_blocks.redmine_template.set_value;
      setValueFunc(mockNode, {}, mockTask, {});
      
      // HTMLが正しく設定される
      expect(mockNode.innerHTML).toContain('redmine-details-form');
      expect(mockNode.innerHTML).toContain('value="テストユーザー"');
      expect(mockNode.innerHTML).toContain('selected="">進行中');
      expect(mockNode.innerHTML).toContain('value="75"');
    });

    it('カスタムform_blockのget_value関数が正しく動作する', () => {
      gantt.form_blocks = {};
      
      const mockTask = {
        redmine_data: {
          assigned_to_name: 'テストユーザー'
        }
      };
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      const getValueFunc = gantt.form_blocks.redmine_template.get_value;
      const result = getValueFunc({}, mockTask, {});
      
      expect(result).toEqual({
        assigned_to_name: 'テストユーザー'
      });
    });

    it('カスタムform_blockのfocus関数が正しく動作する', () => {
      gantt.form_blocks = {};
      
      const mockInput = {
        focus: jest.fn()
      };
      
      const mockNode = {
        querySelector: jest.fn().mockReturnValue(mockInput)
      };
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      const focusFunc = gantt.form_blocks.redmine_template.focus;
      focusFunc(mockNode);
      
      expect(mockNode.querySelector).toHaveBeenCalledWith('input, select');
      expect(mockInput.focus).toHaveBeenCalled();
    });

    it('リンク編集イベントハンドラーを正しく登録する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // リンク編集用イベントハンドラーが登録される
      expect(gantt.attachEvent).toHaveBeenCalledWith('onBeforeLinkAdd', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterLinkAdd', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onBeforeLinkDelete', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterLinkDelete', expect.any(Function));
    });

    it('タスク更新バリデーションが正しく機能する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onBeforeTaskUpdateイベントハンドラーを取得
      const updateHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onBeforeTaskUpdate'
      )[1];
      
      // 有効なデータは通す
      expect(updateHandler(1, {
        id: 1,
        text: '有効なタスク',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        progress: 0.5,
        duration: 4
      })).toBe(true);
      
      // タスク名が空の場合はエラー
      expect(updateHandler(1, {
        id: 1,
        text: '',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        progress: 0.5,
        duration: 4
      })).toBe(false);
      
      // 開始日が終了日より後の場合はエラー
      expect(updateHandler(1, {
        id: 1,
        text: 'タスク',
        start_date: new Date('2024-01-05'),
        end_date: new Date('2024-01-01'),
        progress: 0.5,
        duration: 4
      })).toBe(false);
    });

    it('タスク移動の循環参照チェックが正しく機能する', () => {
      // 親子関係のモック設定
      gantt.getTask.mockImplementation(id => {
        const tasks = {
          1: { id: 1, text: '親タスク', parent: 0 },
          2: { id: 2, text: '子タスク', parent: 1 }
        };
        return tasks[id];
      });
      
      gantt.getChildren.mockImplementation(id => {
        if (id === 1) return [2];
        return [];
      });
      
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onBeforeTaskMoveイベントハンドラーを取得
      const moveHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onBeforeTaskMove'
      )[1];
      
      // 正常な移動は許可
      expect(moveHandler(1, 0, 0)).toBe(true);
      
      // 循環参照を作成する移動は拒否
      expect(moveHandler(1, 2, 0)).toBe(false);
    });

    it('リンク作成のバリデーションが正しく機能する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onBeforeLinkAddイベントハンドラーを取得
      const linkAddHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onBeforeLinkAdd'
      )[1];
      
      // 有効なリンクは許可
      expect(linkAddHandler(999, {
        source: 1,
        target: 2,
        type: '0'
      })).toBe(true);
      
      // 自己リンクは拒否
      expect(linkAddHandler(999, {
        source: 1,
        target: 1,
        type: '0'
      })).toBe(false);
      
      // 重複リンクは拒否
      expect(linkAddHandler(999, {
        source: 1,
        target: 2,
        type: '0'
      })).toBe(false);
    });

    it('一括保存機能が正しく機能する', async () => {
      const { container } = render(<DHMLXGanttChart {...defaultProps} />);
      
      // 変更をシミュレートするためにonAfterTaskUpdateイベントを呼び出し
      const updateHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onAfterTaskUpdate'
      )[1];
      
      // タスク更新をシミュレート
      updateHandler(1, { id: 1, text: '更新されたタスク' });
      
      // 一括保存APIを呼び出し
      await waitFor(() => {
        // window.ganttApi経由で一括保存を呼び出し
        if (window.ganttApi && window.ganttApi.bulkSave) {
          window.ganttApi.bulkSave();
        }
      });
      
      // fetchが適切なパラメータで呼び出されているか確認
      expect(fetch).toHaveBeenCalledWith(
        '/projects/test-project/react_gantt_chart/bulk_update',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'X-CSRF-Token': 'mock-csrf-token'
          }),
          body: expect.any(String)
        })
      );
    });

    it('ダブルクリックでライトボックスを開く', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onTaskDblClickイベントハンドラーを取得
      const dblClickHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onTaskDblClick'
      )[1];
      
      // ダブルクリックをシミュレート
      const result = dblClickHandler(1, {});
      
      // ライトボックスが開かれる
      expect(gantt.showLightbox).toHaveBeenCalledWith(1);
      
      // デフォルト動作を無効化
      expect(result).toBe(false);
    });

    it('サブタスク作成機能が正しく機能する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onGanttRenderイベントハンドラーを取得
      const renderHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onGanttRender'
      )[1];
      
      // サブタスク作成ボタンのモック設定
      const mockButton = {
        setAttribute: jest.fn(),
        getAttribute: jest.fn().mockReturnValue('1'),
        onclick: null
      };
      
      document.querySelectorAll = jest.fn().mockReturnValue([mockButton]);
      
      // レンダーイベントをシミュレート
      renderHandler();
      
      // ボタンのクリックハンドラーが設定される
      expect(mockButton.onclick).toBeDefined();
      
      // クリックイベントをシミュレート
      mockButton.onclick({ stopPropagation: jest.fn() });
      
      // 新規タスクが追加される
      expect(gantt.addTask).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 999,
          text: '新規タスク',
          parent: '1'
        }),
        '1'
      );
      
      // ライトボックスが開かれる
      expect(gantt.showLightbox).toHaveBeenCalledWith(999);
    });

    it('フォーム値の収集が正しく機能する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // onLightboxSaveイベントハンドラーを取得
      const saveHandler = gantt.attachEvent.mock.calls.find(
        call => call[0] === 'onLightboxSave'
      )[1];
      
      // フォームエレメントのモック設定
      const mockElements = {
        assigned_to_input: { value: 'ユーザー1' },
        status_select: { value: '進行中' },
        progress_input: { value: '75' },
        priority_select: { value: '高' }
      };
      
      document.getElementById = jest.fn().mockImplementation(id => mockElements[id]);
      
      // タスクデータをシミュレート
      const taskItem = {
        id: 1,
        text: 'テストタスク',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        progress: 0.5,
        duration: 4,
        redmine_data: {
          custom_fields: {}
        }
      };
      
      // 保存イベントをシミュレート
      const result = saveHandler(1, taskItem, false);
      
      // フォーム値がタスクデータに反映される
      expect(taskItem.redmine_data.assigned_to_name).toBe('ユーザー1');
      expect(taskItem.redmine_data.status_name).toBe('進行中');
      expect(taskItem.progress).toBe(0.75);
      expect(taskItem.redmine_data.priority_name).toBe('高');
      
      // 正常に保存される
      expect(result).toBe(true);
    });
  });
});