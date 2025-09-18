import React from 'react';
import { render, waitFor, act } from '@testing-library/react';
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

// タイマーモック
jest.useFakeTimers();

describe('DHMLXGanttChart - パフォーマンス最適化', () => {
  const createMockTasks = (count) => {
    return Array.from({ length: count }, (_, index) => ({
      id: index + 1,
      text: `タスク${index + 1}`,
      start: '2024-01-01',
      end: '2024-01-05',
      progress: 0.5,
      parent: 0,
      editable: true,
      issue_id: `${index + 1}`
    }));
  };

  const defaultProps = {
    setTasks: jest.fn(),
    links: [],
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
    
    // Ganttモック設定
    gantt.init.mockImplementation(() => {});
    gantt.parse.mockImplementation(() => {});
    gantt.clearAll.mockImplementation(() => {});
    gantt.attachEvent.mockImplementation(() => 1);
    gantt.silent.mockImplementation((callback) => callback());
    gantt.batchUpdate.mockImplementation((callback) => callback());
    gantt.clearCache.mockImplementation(() => {});
    gantt.clearTimer.mockImplementation(() => {});
    gantt.detachAllEvents.mockImplementation(() => {});
    gantt.eachTask.mockImplementation((callback) => {
      // タスクをモックしてコールバックを呼び出し
      defaultProps.tasks?.forEach(task => callback(task));
    });
  });

  afterEach(() => {
    jest.clearAllTimers();
  });

  describe('F006: パフォーマンス最適化', () => {
    it('100件未満のデータで通常処理を使用する', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // 通常処理のパフォーマンス設定が適用される
      expect(gantt.config.virtual_scroll).toBeUndefined();
      expect(gantt.config.smart_rendering).toBe(true);
      expect(gantt.config.smart_scales).toBe(true);
      expect(gantt.config.static_background).toBe(true);
    });

    it('100件以上のデータで仮想スクロールを有効化する', () => {
      const tasks = createMockTasks(150);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // 仮想スクロールが有効化される
      expect(gantt.config.virtual_scroll).toBe(true);
      expect(gantt.config.virtual_scroll_sensitivity).toBe(40);
    });

    it('100-500件のデータでバッチ更新を使用する', () => {
      const tasks = createMockTasks(300);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // タスク更新時にバッチ更新が使用される
      expect(gantt.batchUpdate).toHaveBeenCalled();
    });

    it('500-1000件のデータでサイレント処理を使用する', () => {
      const tasks = createMockTasks(750);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // タスク更新時にサイレント処理が使用される
      expect(gantt.silent).toHaveBeenCalled();
    });

    it('1000件以上のデータでチャンク処理を使用する', async () => {
      const tasks = createMockTasks(1500);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // チャンク処理のためのsetTimeoutが使用される
      expect(setTimeout).toHaveBeenCalled();
      
      // タイマーを進めてチャンク処理を実行
      act(() => {
        jest.advanceTimersByTime(100);
      });
      
      // チャンク処理で複数回のparseが呼び出される
      await waitFor(() => {
        expect(gantt.parse).toHaveBeenCalledTimes(2); // 初期化 + チャンク処理
      });
    });

    it('パフォーマンス最適化設定が正しく適用される', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // パフォーマンス最適化設定が適用される
      expect(gantt.config.smart_rendering).toBe(true);
      expect(gantt.config.smart_scales).toBe(true);
      expect(gantt.config.static_background).toBe(true);
      expect(gantt.config.branch_loading).toBe(true);
      expect(gantt.config.lazy_rendering).toBe(true);
      expect(gantt.config.dynamic_loading).toBe(true);
      expect(gantt.config.optimize_render).toBe('auto');
    });

    it('メモリ最適化設定が正しく適用される', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリ最適化設定が適用される
      expect(gantt.config.cascade_delete).toBe(false);
      expect(gantt.config.auto_types).toBe(true);
      expect(gantt.config.prevent_default_scroll).toBe(true);
      expect(gantt.config.scale_offset_minimal).toBe(false);
    });

    it('パフォーマンス最適化をwindow.ganttApi経由でアクセスできる', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // パフォーマンス最適化機能がAPIで公開されている
      expect(window.ganttApi).toHaveProperty('optimizedDataUpdate');
      
      // 最適化されたデータ更新を実行
      const newTasks = createMockTasks(200);
      window.ganttApi.optimizedDataUpdate(newTasks);
      
      // バッチ更新が使用される
      expect(gantt.batchUpdate).toHaveBeenCalled();
    });
  });

  describe('F007: メモリ管理', () => {
    it('コンポーネントアンマウント時にメモリクリーンアップを実行する', () => {
      const tasks = createMockTasks(50);
      const { unmount } = render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // アンマウントを実行
      unmount();
      
      // メモリクリーンアップが実行される
      expect(gantt.detachAllEvents).toHaveBeenCalled();
      expect(gantt.clearAll).toHaveBeenCalled();
      expect(gantt.clearCache).toHaveBeenCalled();
      expect(gantt.clearTimer).toHaveBeenCalled();
    });

    it('メモリクリーンアップ機能をwindow.ganttApi経由でアクセスできる', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリクリーンアップ機能がAPIで公開されている
      expect(window.ganttApi).toHaveProperty('cleanupMemory');
      
      // メモリクリーンアップを実行
      window.ganttApi.cleanupMemory();
      
      // クリーンアップが実行される
      expect(gantt.detachAllEvents).toHaveBeenCalled();
      expect(gantt.clearAll).toHaveBeenCalled();
      expect(gantt.clearCache).toHaveBeenCalled();
      expect(gantt.clearTimer).toHaveBeenCalled();
    });

    it('メモリクリーンアップ時に状態をリセットする', () => {
      const tasks = createMockTasks(50);
      const { unmount } = render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // アンマウントを実行
      unmount();
      
      // 状態がリセットされることを確認
      // ここでは内部状態のリセットを間接的に確認
      expect(gantt.clearAll).toHaveBeenCalled();
    });

    it('メモリクリーンアップ時にキャッシュをクリアする', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリクリーンアップを実行
      window.ganttApi.cleanupMemory();
      
      // キャッシュクリアが実行される
      expect(gantt.clearCache).toHaveBeenCalled();
      expect(gantt.clearTimer).toHaveBeenCalled();
    });

    it('メモリリークを防ぐためのイベントリスナークリーンアップ', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリクリーンアップを実行
      window.ganttApi.cleanupMemory();
      
      // イベントリスナーがクリアされる
      expect(gantt.detachAllEvents).toHaveBeenCalled();
    });

    it('メモリクリーンアップ時にタイマーをクリアする', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリクリーンアップを実行
      window.ganttApi.cleanupMemory();
      
      // タイマーがクリアされる
      expect(gantt.clearTimer).toHaveBeenCalled();
    });

    it('メモリクリーンアップ時にコンポーネント状態をリセットする', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メモリクリーンアップを実行
      window.ganttApi.cleanupMemory();
      
      // コンポーネント状態がリセットされる
      expect(gantt.clearAll).toHaveBeenCalled();
    });

    it('メモリクリーンアップが無効なganttオブジェクトでもエラーにならない', () => {
      const tasks = createMockTasks(50);
      render(<DHMLXGanttChart {...defaultProps} tasks={tasks} />);
      
      // メソッドが存在しない場合をシミュレート
      gantt.clearCache = undefined;
      gantt.clearTimer = undefined;
      
      // エラーが発生しないことを確認
      expect(() => {
        window.ganttApi.cleanupMemory();
      }).not.toThrow();
    });
  });
});