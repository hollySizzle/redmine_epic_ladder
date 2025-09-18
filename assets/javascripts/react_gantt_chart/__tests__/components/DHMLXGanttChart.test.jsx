import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import DHMLXGanttChart from '../../components/DHMLXGanttChart';
import { gantt } from 'dhtmlx-gantt';
import * as dhtmlxDataConverter from '../../utils/dhtmlxDataConverter';
import * as DHMLXCustomBar from '../../templates/DHMLXCustomBar';

// モック設定
jest.mock('dhtmlx-gantt');
jest.mock('../../utils/dhtmlxDataConverter');
jest.mock('../../templates/DHMLXCustomBar');
jest.mock('../../hooks/useZoomConfigDHMLX', () => ({
  useZoomConfigDHMLX: () => ({
    level: 'day',
    setLevel: jest.fn(),
    config: {
      scale_unit: 'day',
      date_scale: '%j',
      subscales: []
    }
  })
}));

describe('DHMLXGanttChart', () => {
  const mockTasks = [
    {
      id: 1,
      text: 'タスク1',
      start: '2024-01-01',
      end: '2024-01-05',
      progress: 0.5,
      parent: 0,
      editable: true,
      is_closed: false,
      priority: '通常',
      status: '新規',
      status_label: '新規',
      priority_label: '通常',
      assignee: 'ユーザー1',
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
      is_closed: false,
      priority: '高',
      status: '進行中',
      status_label: '進行中',
      priority_label: '高',
      assignee: 'ユーザー2',
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

  const mockVisibleColumns = [
    { name: 'text', label: '題名', width: 200 },
    { name: 'start_date', label: '開始日', width: 100 },
    { name: 'duration', label: '期間', width: 80 }
  ];

  const defaultProps = {
    tasks: mockTasks,
    setTasks: jest.fn(),
    links: mockLinks,
    visibleColumns: mockVisibleColumns,
    onColumnSettingsChange: jest.fn(),
    projectId: 'test-project',
    filters: {},
    onFilterChange: jest.fn()
  };

  beforeEach(() => {
    jest.clearAllMocks();
    
    // データ変換モックの設定
    dhtmlxDataConverter.convertSvarToGantt.mockImplementation(tasks => 
      tasks.map(task => ({
        ...task,
        start_date: new Date(task.start),
        end_date: new Date(task.end),
        duration: 5
      }))
    );
    
    dhtmlxDataConverter.convertGanttToSvar.mockImplementation(tasks => tasks);
    
    // Ganttモックの設定
    gantt.init.mockImplementation(() => {});
    gantt.parse.mockImplementation(() => {});
    gantt.clearAll.mockImplementation(() => {});
    gantt.render.mockImplementation(() => {});
    gantt.attachEvent.mockImplementation(() => 1);
    gantt.detachEvent.mockImplementation(() => {});
    gantt.getTask.mockImplementation(id => mockTasks.find(t => t.id === id));
    gantt.getChildren.mockImplementation(() => []);
    gantt.eachTask.mockImplementation(callback => {
      mockTasks.forEach(task => callback(task));
    });
    
    // カスタムテンプレートモックの設定
    DHMLXCustomBar.applyCustomTemplates.mockImplementation(() => {});
    DHMLXCustomBar.addCustomStyles.mockImplementation(() => {});
  });

  describe('F001: 基本表示機能', () => {
    it('ガントチャートを正しく初期化する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      expect(gantt.init).toHaveBeenCalled();
      expect(DHMLXCustomBar.applyCustomTemplates).toHaveBeenCalled();
      expect(DHMLXCustomBar.addCustomStyles).toHaveBeenCalled();
    });

    it('タスクデータを正しく変換して表示する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      expect(dhtmlxDataConverter.convertSvarToGantt).toHaveBeenCalledWith(mockTasks);
      expect(gantt.parse).toHaveBeenCalledWith({
        data: expect.arrayContaining([
          expect.objectContaining({
            id: 1,
            text: 'タスク1',
            start_date: expect.any(Date)
          })
        ]),
        links: mockLinks
      });
    });

    it('階層構造を正しく表示する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // parseに渡されたデータで親子関係が保持されているか確認
      const parseCall = gantt.parse.mock.calls[0][0];
      expect(parseCall.data).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ id: 1, parent: 0 }),
          expect.objectContaining({ id: 2, parent: 1 })
        ])
      );
    });

    it('依存関係リンクを正しく表示する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      const parseCall = gantt.parse.mock.calls[0][0];
      expect(parseCall.links).toEqual(mockLinks);
    });

    it('視覚的状態表示を正しく設定する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // カスタムテンプレートが適用されることを確認
      expect(DHMLXCustomBar.applyCustomTemplates).toHaveBeenCalled();
    });

    it('ズーム機能を正しく初期化する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      // ズーム設定が適用されることを確認
      expect(gantt.config.scale_unit).toBe('day');
      expect(gantt.config.date_scale).toBe('%j');
    });

    it('日本語ロケールを正しく設定する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      expect(gantt.locale).toEqual(
        expect.objectContaining({
          date: expect.objectContaining({
            month_full: expect.arrayContaining(['1月', '2月'])
          }),
          labels: expect.objectContaining({
            dhx_cal_today_button: '今日'
          })
        })
      );
    });

    it('大量データ（100件以上）の場合、仮想スクロールを有効化する', () => {
      const manyTasks = Array.from({ length: 150 }, (_, i) => ({
        ...mockTasks[0],
        id: i + 1
      }));
      
      render(<DHMLXGanttChart {...defaultProps} tasks={manyTasks} />);
      
      expect(gantt.config.virtual_scroll).toBe(true);
      expect(gantt.config.virtual_scroll_sensitivity).toBe(40);
    });

    it('パフォーマンス最適化設定を正しく適用する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      expect(gantt.config.smart_rendering).toBe(true);
      expect(gantt.config.smart_scales).toBe(true);
      expect(gantt.config.static_background).toBe(true);
      expect(gantt.config.branch_loading).toBe(true);
      expect(gantt.config.lazy_rendering).toBe(true);
    });

    it('グリッドカラムを正しく設定する', () => {
      render(<DHMLXGanttChart {...defaultProps} />);
      
      expect(gantt.config.columns).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            name: 'id',
            label: 'ID',
            width: 50
          }),
          expect.objectContaining({
            name: 'text',
            label: 'タスク名',
            width: 200
          }),
          expect.objectContaining({
            name: 'tracker_name',
            label: 'トラッカー',
            width: 100
          }),
          expect.objectContaining({
            name: 'status_name',
            label: 'ステータス',
            width: 100
          }),
          expect.objectContaining({
            name: 'assigned_to_name',
            label: '担当者',
            width: 100
          }),
          expect.objectContaining({
            name: 'start_date',
            label: '開始日',
            width: 100
          }),
          expect.objectContaining({
            name: 'end_date',
            label: '終了日',
            width: 100
          })
        ])
      );
    });

    it('カラムのtemplate関数が正しく動作する', () => {
      const sampleTask = {
        id: 123,
        text: 'テストタスク',
        redmine_data: {
          tracker_name: 'バグ',
          status_name: '新規',
          assigned_to_name: '山田太郎',
          end_date: '2025-01-31'
        }
      };

      render(<DHMLXGanttChart {...defaultProps} />);

      const columns = gantt.config.columns;
      
      // IDカラムのtemplate関数テスト
      const idColumn = columns.find(col => col.name === 'id');
      expect(idColumn.template(sampleTask)).toBe('#123');
      
      // トラッカーカラムのtemplate関数テスト
      const trackerColumn = columns.find(col => col.name === 'tracker_name');
      expect(trackerColumn.template(sampleTask)).toBe('バグ');
      
      // ステータスカラムのtemplate関数テスト
      const statusColumn = columns.find(col => col.name === 'status_name');
      expect(statusColumn.template(sampleTask)).toBe('新規');
      
      // 担当者カラムのtemplate関数テスト
      const assigneeColumn = columns.find(col => col.name === 'assigned_to_name');
      expect(assigneeColumn.template(sampleTask)).toBe('山田太郎');
      
      // 終了日カラムのtemplate関数テスト
      const endDateColumn = columns.find(col => col.name === 'end_date');
      expect(endDateColumn.template(sampleTask)).toBe('2025-01-31');
    });

    it('カラムのtemplate関数がnull値を適切に処理する', () => {
      const sampleTask = {
        id: 123,
        text: 'テストタスク',
        redmine_data: {
          tracker_name: null,
          status_name: undefined,
          assigned_to_name: '',
          end_date: null
        }
      };

      render(<DHMLXGanttChart {...defaultProps} />);

      const columns = gantt.config.columns;
      
      // null値の場合は空文字を返すことを確認
      const trackerColumn = columns.find(col => col.name === 'tracker_name');
      expect(trackerColumn.template(sampleTask)).toBe('');
      
      const statusColumn = columns.find(col => col.name === 'status_name');
      expect(statusColumn.template(sampleTask)).toBe('');
      
      const assigneeColumn = columns.find(col => col.name === 'assigned_to_name');
      expect(assigneeColumn.template(sampleTask)).toBe('');
      
      const endDateColumn = columns.find(col => col.name === 'end_date');
      expect(endDateColumn.template(sampleTask)).toBe('');
    });
  });

  describe('コンポーネントのライフサイクル', () => {
    it('アンマウント時にクリーンアップを実行する', () => {
      const { unmount } = render(<DHMLXGanttChart {...defaultProps} />);
      
      unmount();
      
      expect(gantt.clearAll).toHaveBeenCalled();
      expect(gantt.detachEvent).toHaveBeenCalled();
    });

    it('タスクデータ更新時に再レンダリングする', () => {
      const { rerender } = render(<DHMLXGanttChart {...defaultProps} />);
      
      const newTasks = [...mockTasks, {
        id: 3,
        text: '新規タスク',
        start: '2024-01-10',
        end: '2024-01-15',
        progress: 0,
        parent: 0
      }];
      
      rerender(<DHMLXGanttChart {...defaultProps} tasks={newTasks} />);
      
      expect(gantt.clearAll).toHaveBeenCalled();
      expect(gantt.parse).toHaveBeenCalledTimes(2);
    });
  });
});