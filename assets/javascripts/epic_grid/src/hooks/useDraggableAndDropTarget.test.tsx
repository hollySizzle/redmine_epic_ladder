import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { useDraggableAndDropTarget } from './useDraggableAndDropTarget';
import { draggable, dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';

// モック
vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter');
vi.mock('@atlaskit/pragmatic-drag-and-drop/combine');

// テスト用コンポーネント
interface TestComponentProps {
  type: string;
  id: string;
  data?: Record<string, any>;
  canDrop?: (sourceData: any) => boolean;
  onDragStart?: () => void;
  onDragEnter?: () => void;
  onDragLeave?: () => void;
  onDrop?: (sourceData: any) => void;
  onDragEnd?: () => void;
}

const TestComponent: React.FC<TestComponentProps> = ({
  type,
  id,
  data,
  canDrop,
  onDragStart,
  onDragEnter,
  onDragLeave,
  onDrop,
  onDragEnd
}) => {
  const ref = useDraggableAndDropTarget({
    type,
    id,
    data,
    canDrop,
    onDragStart,
    onDragEnter,
    onDragLeave,
    onDrop,
    onDragEnd
  });
  return <div ref={ref} data-testid="draggable-drop-target">{id}</div>;
};

describe('useDraggableAndDropTarget', () => {
  let mockCleanup: ReturnType<typeof vi.fn>;
  let mockDraggableConfig: any;
  let mockDropTargetConfig: any;
  let consoleLogSpy: ReturnType<typeof vi.spyOn>;
  let consoleWarnSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    mockCleanup = vi.fn();
    mockDraggableConfig = null;
    mockDropTargetConfig = null;

    // console.log と console.warn のスパイ
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

    // draggable関数のモック
    vi.mocked(draggable).mockImplementation((config) => {
      mockDraggableConfig = config;
      return vi.fn();
    });

    // dropTargetForElements関数のモック
    vi.mocked(dropTargetForElements).mockImplementation((config) => {
      mockDropTargetConfig = config;
      return vi.fn();
    });

    // combine関数のモック
    vi.mocked(combine).mockImplementation((...cleanups) => {
      return mockCleanup;
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    consoleLogSpy.mockRestore();
    consoleWarnSpy.mockRestore();
  });

  describe('基本動作', () => {
    it('コンポーネントがマウントされるとdraggableとdropTargetForElementsが呼ばれる', () => {
      render(<TestComponent type="feature" id="f1" />);

      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
      expect(combine).toHaveBeenCalledTimes(1);
    });

    it('要素がDOMに存在する', () => {
      render(<TestComponent type="feature" id="f1" />);

      const element = screen.getByTestId('draggable-drop-target');
      expect(element).toBeInTheDocument();
      expect(element.textContent).toBe('f1');
    });

    it('setup時にログが出力される', () => {
      render(<TestComponent type="feature" id="f1" />);

      expect(consoleLogSpy).toHaveBeenCalledWith(
        '✅ Setting up drag and drop for:',
        expect.objectContaining({
          type: 'feature',
          id: 'f1',
          element: expect.any(HTMLDivElement)
        })
      );
    });

    it('アンマウント時にcleanup関数が呼ばれる', () => {
      const { unmount } = render(<TestComponent type="feature" id="f1" />);

      expect(mockCleanup).not.toHaveBeenCalled();

      unmount();

      expect(mockCleanup).toHaveBeenCalledTimes(1);
    });
  });

  describe('Draggable機能', () => {
    it('getInitialDataが正しいデータを返す', () => {
      render(
        <TestComponent
          type="feature"
          id="f1"
          data={{ parentId: 'epic-1', versionId: 'v1' }}
        />
      );

      expect(mockDraggableConfig).not.toBeNull();
      const initialData = mockDraggableConfig.getInitialData();

      expect(initialData.type).toBe('feature');
      expect(initialData.id).toBe('f1');
      expect(initialData.parentId).toBe('epic-1');
      expect(initialData.versionId).toBe('v1');
      expect(initialData.instanceId).toBeDefined();
      expect(typeof initialData.instanceId).toBe('symbol');
    });

    it('dataが未指定の場合もgetInitialDataが動作する', () => {
      render(<TestComponent type="feature" id="f1" />);

      const initialData = mockDraggableConfig.getInitialData();

      expect(initialData.type).toBe('feature');
      expect(initialData.id).toBe('f1');
      expect(initialData.instanceId).toBeDefined();
      expect(initialData.parentId).toBeUndefined();
    });

    it('onDragStartが呼ばれるとdraggingクラスが追加される', () => {
      const mockOnDragStart = vi.fn();
      render(<TestComponent type="feature" id="f1" onDragStart={mockOnDragStart} />);

      const element = screen.getByTestId('draggable-drop-target');

      mockDraggableConfig.onDragStart();

      expect(element.classList.contains('dragging')).toBe(true);
      expect(mockOnDragStart).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith('🎯 onDragStart:', { type: 'feature', id: 'f1' });
    });

    it('onDrop(draggable)が呼ばれるとdraggingクラスが削除される', () => {
      const mockOnDragEnd = vi.fn();
      render(<TestComponent type="feature" id="f1" onDragEnd={mockOnDragEnd} />);

      const element = screen.getByTestId('draggable-drop-target');

      // 最初にdraggingクラスを追加
      mockDraggableConfig.onDragStart();
      expect(element.classList.contains('dragging')).toBe(true);

      // onDropを実行
      mockDraggableConfig.onDrop();

      expect(element.classList.contains('dragging')).toBe(false);
      expect(mockOnDragEnd).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith('🎯 onDrop (draggable):', { type: 'feature', id: 'f1' });
    });

    it('onDragStart/onDragEndがオプショナルでもエラーにならない', () => {
      render(<TestComponent type="feature" id="f1" />);

      const element = screen.getByTestId('draggable-drop-target');

      expect(() => {
        mockDraggableConfig.onDragStart();
        mockDraggableConfig.onDrop();
      }).not.toThrow();

      mockDraggableConfig.onDragStart();
      expect(element.classList.contains('dragging')).toBe(true);

      mockDraggableConfig.onDrop();
      expect(element.classList.contains('dragging')).toBe(false);
    });
  });

  describe('DropTarget機能', () => {
    it('getDataが正しいデータを返す', () => {
      render(<TestComponent type="feature" id="f1" data={{ versionId: 'v1' }} />);

      expect(mockDropTargetConfig).not.toBeNull();
      const data = mockDropTargetConfig.getData();

      expect(data.type).toBe('feature');
      expect(data.id).toBe('f1');
      expect(data.versionId).toBe('v1');
    });

    it('getIsStickyが常にtrueを返す', () => {
      render(<TestComponent type="feature" id="f1" />);

      expect(mockDropTargetConfig.getIsSticky()).toBe(true);
    });

    it('canDropが未指定の場合、同じtypeで異なるidならtrue', () => {
      render(<TestComponent type="feature" id="f1" />);

      const sourceData = { type: 'feature', id: 'f2' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(true);
    });

    it('canDropが未指定の場合、同じidならfalse', () => {
      render(<TestComponent type="feature" id="f1" />);

      const sourceData = { type: 'feature', id: 'f1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(false);
    });

    it('canDropが未指定の場合、異なるtypeならfalse', () => {
      render(<TestComponent type="feature" id="f1" />);

      const sourceData = { type: 'epic', id: 'e1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(false);
    });

    it('canDropが指定されている場合、カスタムロジックが使用される', () => {
      const customCanDrop = vi.fn((sourceData) => {
        return sourceData.type === 'user_story';
      });

      render(<TestComponent type="feature" id="f1" canDrop={customCanDrop} />);

      const sourceData = { type: 'user_story', id: 'us1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(customCanDrop).toHaveBeenCalledWith(sourceData);
      expect(result).toBe(true);
    });

    it('onDragEnterが呼ばれるとoverクラスが追加される', () => {
      const mockOnDragEnter = vi.fn();
      render(<TestComponent type="feature" id="f1" onDragEnter={mockOnDragEnter} />);

      const element = screen.getByTestId('draggable-drop-target');

      mockDropTargetConfig.onDragEnter();

      expect(element.classList.contains('over')).toBe(true);
      expect(mockOnDragEnter).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith('🎯 onDragEnter:', { type: 'feature', id: 'f1' });
    });

    it('onDragLeaveが呼ばれるとoverクラスが削除される', () => {
      const mockOnDragLeave = vi.fn();
      render(<TestComponent type="feature" id="f1" onDragLeave={mockOnDragLeave} />);

      const element = screen.getByTestId('draggable-drop-target');

      // まずoverクラスを追加
      mockDropTargetConfig.onDragEnter();
      expect(element.classList.contains('over')).toBe(true);

      // onDragLeaveを実行
      mockDropTargetConfig.onDragLeave();

      expect(element.classList.contains('over')).toBe(false);
      expect(mockOnDragLeave).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith('🎯 onDragLeave:', { type: 'feature', id: 'f1' });
    });

    it('onDrop(dropTarget)が呼ばれるとoverクラスが削除されてコールバックが実行される', () => {
      const mockOnDrop = vi.fn();
      render(<TestComponent type="feature" id="f1" onDrop={mockOnDrop} />);

      const element = screen.getByTestId('draggable-drop-target');

      // まずoverクラスを追加
      mockDropTargetConfig.onDragEnter();
      expect(element.classList.contains('over')).toBe(true);

      // onDropを実行
      const sourceData = { type: 'feature', id: 'f2', versionId: 'v1' };
      mockDropTargetConfig.onDrop({ source: { data: sourceData } });

      expect(element.classList.contains('over')).toBe(false);
      expect(mockOnDrop).toHaveBeenCalledWith(sourceData);
      expect(mockOnDrop).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        '🎯 onDrop (dropTarget):',
        expect.objectContaining({
          source: sourceData,
          target: { type: 'feature', id: 'f1' }
        })
      );
    });

    it('onDragEnter/onDragLeave/onDropがオプショナルでもエラーにならない', () => {
      render(<TestComponent type="feature" id="f1" />);

      const element = screen.getByTestId('draggable-drop-target');

      expect(() => {
        mockDropTargetConfig.onDragEnter();
        mockDropTargetConfig.onDragLeave();
        mockDropTargetConfig.onDrop({ source: { data: { type: 'feature', id: 'f2' } } });
      }).not.toThrow();

      mockDropTargetConfig.onDragEnter();
      expect(element.classList.contains('over')).toBe(true);

      mockDropTargetConfig.onDrop({ source: { data: { type: 'feature', id: 'f2' } } });
      expect(element.classList.contains('over')).toBe(false);
    });
  });

  describe('再初期化', () => {
    it('idが変更されると再初期化される', () => {
      const { rerender } = render(<TestComponent type="feature" id="f1" />);

      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
      expect(mockCleanup).not.toHaveBeenCalled();

      // idを変更
      rerender(<TestComponent type="feature" id="f2" />);

      // cleanupが呼ばれて、再度初期化される
      expect(mockCleanup).toHaveBeenCalledTimes(1);
      expect(draggable).toHaveBeenCalledTimes(2);
      expect(dropTargetForElements).toHaveBeenCalledTimes(2);

      // 新しいidがgetInitialDataとgetDataに反映される
      const newInitialData = mockDraggableConfig.getInitialData();
      const newData = mockDropTargetConfig.getData();
      expect(newInitialData.id).toBe('f2');
      expect(newData.id).toBe('f2');
    });

    it('typeが変更されると再初期化される', () => {
      const { rerender } = render(<TestComponent type="feature" id="f1" />);

      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // typeを変更
      rerender(<TestComponent type="user_story" id="f1" />);

      expect(mockCleanup).toHaveBeenCalledTimes(1);
      expect(draggable).toHaveBeenCalledTimes(2);
      expect(dropTargetForElements).toHaveBeenCalledTimes(2);

      const newInitialData = mockDraggableConfig.getInitialData();
      const newData = mockDropTargetConfig.getData();
      expect(newInitialData.type).toBe('user_story');
      expect(newData.type).toBe('user_story');
    });

    it('dataのみが変更されても再初期化されない', () => {
      const { rerender } = render(
        <TestComponent type="feature" id="f1" data={{ version: 'v1' }} />
      );

      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // dataのみ変更
      rerender(<TestComponent type="feature" id="f1" data={{ version: 'v2' }} />);

      // 再初期化されない
      expect(mockCleanup).not.toHaveBeenCalled();
      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
    });

    it('コールバックのみが変更されても再初期化されない', () => {
      const callback1 = vi.fn();
      const callback2 = vi.fn();

      const { rerender } = render(<TestComponent type="feature" id="f1" onDrop={callback1} />);

      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // コールバックのみ変更
      rerender(<TestComponent type="feature" id="f1" onDrop={callback2} />);

      // 再初期化されない
      expect(mockCleanup).not.toHaveBeenCalled();
      expect(draggable).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
    });
  });

  describe('element設定', () => {
    it('draggableとdropTargetに渡されるelementが同じDOM要素', () => {
      render(<TestComponent type="feature" id="f1" />);

      expect(mockDraggableConfig.element).toBeInstanceOf(HTMLDivElement);
      expect(mockDropTargetConfig.element).toBeInstanceOf(HTMLDivElement);
      expect(mockDraggableConfig.element).toBe(mockDropTargetConfig.element);
      expect(mockDraggableConfig.element.dataset.testid).toBe('draggable-drop-target');
    });
  });
});
