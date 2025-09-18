import React from 'react';
import { render, waitFor } from '@testing-library/react';
import DHMLXGanttWrapper from '../../components/DHMLXGanttWrapper';
import { gantt } from 'dhtmlx-gantt';

// モックのganttオブジェクトを使用
jest.mock('dhtmlx-gantt');

describe('DHMLXGanttWrapper', () => {
  const mockData = {
    tasks: [
      {
        id: 1,
        text: 'タスク1',
        start: '2025-01-15',
        end: '2025-01-20',
        progress: 0.5
      },
      {
        id: 2,
        text: 'タスク2',
        start: '2025-01-16',
        end: '2025-01-18',
        parent: 1,
        progress: 0.8
      }
    ],
    links: [
      { id: 1, source: 1, target: 2, type: '0' }
    ]
  };

  const mockConfig = {
    date_format: '%Y-%m-%d',
    scale_mode: 'Week',
    readonly: false
  };

  const mockOnUpdate = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('コンポーネントが正しくレンダリングされること', () => {
    const { container } = render(
      <DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />
    );

    const ganttContainer = container.querySelector('.dhtmlx-gantt-container');
    expect(ganttContainer).toBeInTheDocument();
    expect(ganttContainer).toHaveStyle({ width: '100%', height: '100%' });
  });

  it('初期化時にgantt.initが呼ばれること', async () => {
    render(<DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      expect(gantt.init).toHaveBeenCalled();
    });
  });

  it('configが正しく適用されること', async () => {
    render(<DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      expect(gantt.config.date_format).toBe('%Y-%m-%d');
      expect(gantt.config.scale_mode).toBe('Week');
      expect(gantt.config.readonly).toBe(false);
    });
  });

  it('データが変更されたときにgantt.parseが呼ばれること', async () => {
    const { rerender } = render(
      <DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />
    );

    const newData = {
      tasks: [
        {
          id: 3,
          text: 'タスク3',
          start: '2025-01-20',
          end: '2025-01-25',
          progress: 0.3
        }
      ],
      links: []
    };

    rerender(<DHMLXGanttWrapper data={newData} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      expect(gantt.clearAll).toHaveBeenCalled();
      expect(gantt.parse).toHaveBeenCalled();
    });
  });

  it('イベントハンドラーが登録されること', async () => {
    render(<DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterTaskUpdate', expect.any(Function));
      expect(gantt.attachEvent).toHaveBeenCalledWith('onAfterTaskDrag', expect.any(Function));
    });
  });

  it('コンポーネントがアンマウントされたときにクリーンアップされること', async () => {
    const { unmount } = render(
      <DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />
    );

    await waitFor(() => {
      expect(gantt.init).toHaveBeenCalled();
    });

    unmount();

    expect(gantt.clearAll).toHaveBeenCalled();
  });

  it('SVAR形式からDHTMLX形式へのデータ変換が正しく行われること', async () => {
    render(<DHMLXGanttWrapper data={mockData} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      expect(gantt.parse).toHaveBeenCalled();
      const parseCallArgs = gantt.parse.mock.calls[0][0];
      
      // 変換されたデータの確認
      expect(parseCallArgs.data).toHaveLength(2);
      expect(parseCallArgs.data[0]).toMatchObject({
        id: 1,
        text: 'タスク1',
        start_date: '2025-01-15',
        duration: 5,
        progress: 0.5
      });
      expect(parseCallArgs.links).toEqual(mockData.links);
    });
  });

  it('期間が正しく計算されること', async () => {
    const dataWithoutDuration = {
      tasks: [
        {
          id: 1,
          text: 'タスク',
          start: '2025-01-15',
          end: '2025-01-20'
        }
      ],
      links: []
    };

    render(<DHMLXGanttWrapper data={dataWithoutDuration} config={mockConfig} onUpdate={mockOnUpdate} />);

    await waitFor(() => {
      const parseCallArgs = gantt.parse.mock.calls[0][0];
      expect(parseCallArgs.data[0].duration).toBe(5);
    });
  });
});