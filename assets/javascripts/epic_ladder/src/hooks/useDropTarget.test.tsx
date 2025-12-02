import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { useDropTarget } from './useDropTarget';
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

// モック
vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter');

// テスト用コンポーネント
interface TestComponentProps {
  type: string;
  id: string;
  data?: Record<string, any>;
  canDrop?: (sourceData: any) => boolean;
  onDragEnter?: () => void;
  onDragLeave?: () => void;
  onDrop?: (sourceData: any) => void;
}

const TestComponent: React.FC<TestComponentProps> = ({
  type,
  id,
  data,
  canDrop,
  onDragEnter,
  onDragLeave,
  onDrop
}) => {
  const ref = useDropTarget({ type, id, data, canDrop, onDragEnter, onDragLeave, onDrop });
  return <div ref={ref} data-testid="drop-target">{id}</div>;
};

describe('useDropTarget', () => {
  let mockCleanup: ReturnType<typeof vi.fn>;
  let mockDropTargetConfig: any;

  beforeEach(() => {
    mockCleanup = vi.fn();
    mockDropTargetConfig = null;

    // dropTargetForElements関数のモック
    vi.mocked(dropTargetForElements).mockImplementation((config) => {
      mockDropTargetConfig = config;
      return mockCleanup;
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('基本動作', () => {
    it('コンポーネントがマウントされるとdropTargetForElementsが呼ばれる', () => {
      render(<TestComponent type="epic" id="e1" />);

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
      expect(mockDropTargetConfig).not.toBeNull();
    });

    it('drop target要素がDOMに存在する', () => {
      render(<TestComponent type="epic" id="e1" />);

      const element = screen.getByTestId('drop-target');
      expect(element).toBeInTheDocument();
      expect(element.textContent).toBe('e1');
    });

    it('アンマウント時にcleanup関数が呼ばれる', () => {
      const { unmount } = render(<TestComponent type="epic" id="e1" />);

      expect(mockCleanup).not.toHaveBeenCalled();

      unmount();

      expect(mockCleanup).toHaveBeenCalledTimes(1);
    });
  });

  describe('getData', () => {
    it('getDataが正しいデータを返す', () => {
      render(<TestComponent type="epic" id="e1" data={{ versionId: 'v1' }} />);

      expect(mockDropTargetConfig).not.toBeNull();
      const data = mockDropTargetConfig.getData();

      expect(data.type).toBe('epic');
      expect(data.id).toBe('e1');
      expect(data.versionId).toBe('v1');
    });

    it('dataが未指定の場合もgetDataが動作する', () => {
      render(<TestComponent type="epic" id="e1" />);

      const data = mockDropTargetConfig.getData();

      expect(data.type).toBe('epic');
      expect(data.id).toBe('e1');
      expect(data.versionId).toBeUndefined();
    });
  });

  describe('getIsSticky', () => {
    it('getIsStickyが常にtrueを返す', () => {
      render(<TestComponent type="epic" id="e1" />);

      expect(mockDropTargetConfig.getIsSticky()).toBe(true);
    });
  });

  describe('canDrop', () => {
    it('canDropが未指定の場合、同じtypeで異なるidならtrue', () => {
      render(<TestComponent type="epic" id="e1" />);

      const sourceData = { type: 'epic', id: 'e2' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(true);
    });

    it('canDropが未指定の場合、同じidならfalse', () => {
      render(<TestComponent type="epic" id="e1" />);

      const sourceData = { type: 'epic', id: 'e1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(false);
    });

    it('canDropが未指定の場合、異なるtypeならfalse', () => {
      render(<TestComponent type="epic" id="e1" />);

      const sourceData = { type: 'feature', id: 'f1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(false);
    });

    it('canDropが指定されている場合、カスタムロジックが使用される', () => {
      const customCanDrop = vi.fn((sourceData) => {
        return sourceData.type === 'feature';
      });

      render(<TestComponent type="epic" id="e1" canDrop={customCanDrop} />);

      const sourceData = { type: 'feature', id: 'f1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(customCanDrop).toHaveBeenCalledWith(sourceData);
      expect(result).toBe(true);
    });

    it('canDropがfalseを返す場合', () => {
      const customCanDrop = vi.fn(() => false);

      render(<TestComponent type="epic" id="e1" canDrop={customCanDrop} />);

      const sourceData = { type: 'feature', id: 'f1' };
      const result = mockDropTargetConfig.canDrop({ source: { data: sourceData } });

      expect(result).toBe(false);
    });
  });

  describe('onDragEnter', () => {
    it('onDragEnterが呼ばれるとoverクラスが追加される', () => {
      const mockOnDragEnter = vi.fn();
      render(<TestComponent type="epic" id="e1" onDragEnter={mockOnDragEnter} />);

      const element = screen.getByTestId('drop-target');

      mockDropTargetConfig.onDragEnter();

      expect(element.classList.contains('over')).toBe(true);
      expect(mockOnDragEnter).toHaveBeenCalledTimes(1);
    });

    it('onDragEnterコールバックが未指定でもエラーにならない', () => {
      render(<TestComponent type="epic" id="e1" />);

      const element = screen.getByTestId('drop-target');

      expect(() => {
        mockDropTargetConfig.onDragEnter();
      }).not.toThrow();

      expect(element.classList.contains('over')).toBe(true);
    });
  });

  describe('onDragLeave', () => {
    it('onDragLeaveが呼ばれるとoverクラスが削除される', () => {
      const mockOnDragLeave = vi.fn();
      render(<TestComponent type="epic" id="e1" onDragLeave={mockOnDragLeave} />);

      const element = screen.getByTestId('drop-target');

      // まずoverクラスを追加
      mockDropTargetConfig.onDragEnter();
      expect(element.classList.contains('over')).toBe(true);

      // onDragLeaveを実行
      mockDropTargetConfig.onDragLeave();

      expect(element.classList.contains('over')).toBe(false);
      expect(mockOnDragLeave).toHaveBeenCalledTimes(1);
    });

    it('onDragLeaveコールバックが未指定でもエラーにならない', () => {
      render(<TestComponent type="epic" id="e1" />);

      const element = screen.getByTestId('drop-target');

      mockDropTargetConfig.onDragEnter();

      expect(() => {
        mockDropTargetConfig.onDragLeave();
      }).not.toThrow();

      expect(element.classList.contains('over')).toBe(false);
    });
  });

  describe('onDrop', () => {
    it('onDropが呼ばれるとoverクラスが削除されてコールバックが実行される', () => {
      const mockOnDrop = vi.fn();
      render(<TestComponent type="epic" id="e1" onDrop={mockOnDrop} />);

      const element = screen.getByTestId('drop-target');

      // まずoverクラスを追加
      mockDropTargetConfig.onDragEnter();
      expect(element.classList.contains('over')).toBe(true);

      // onDropを実行
      const sourceData = { type: 'epic', id: 'e2', versionId: 'v1' };
      mockDropTargetConfig.onDrop({ source: { data: sourceData } });

      expect(element.classList.contains('over')).toBe(false);
      expect(mockOnDrop).toHaveBeenCalledWith(sourceData);
      expect(mockOnDrop).toHaveBeenCalledTimes(1);
    });

    it('onDropコールバックが未指定でもエラーにならない', () => {
      render(<TestComponent type="epic" id="e1" />);

      const element = screen.getByTestId('drop-target');

      mockDropTargetConfig.onDragEnter();

      expect(() => {
        mockDropTargetConfig.onDrop({ source: { data: { type: 'epic', id: 'e2' } } });
      }).not.toThrow();

      expect(element.classList.contains('over')).toBe(false);
    });
  });

  describe('再初期化', () => {
    it('idが変更されると再初期化される', () => {
      const { rerender } = render(<TestComponent type="epic" id="e1" />);

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
      expect(mockCleanup).not.toHaveBeenCalled();

      // idを変更
      rerender(<TestComponent type="epic" id="e2" />);

      // cleanupが呼ばれて、再度dropTargetForElementsが呼ばれる
      expect(mockCleanup).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(2);

      // 新しいidがgetDataに反映される
      const newData = mockDropTargetConfig.getData();
      expect(newData.id).toBe('e2');
    });

    it('typeが変更されると再初期化される', () => {
      const { rerender } = render(<TestComponent type="epic" id="e1" />);

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // typeを変更
      rerender(<TestComponent type="feature" id="e1" />);

      // cleanupが呼ばれて、再度dropTargetForElementsが呼ばれる
      expect(mockCleanup).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(2);

      // 新しいtypeがgetDataに反映される
      const newData = mockDropTargetConfig.getData();
      expect(newData.type).toBe('feature');
    });

    it('id と type が同時に変更されると再初期化される', () => {
      const { rerender } = render(<TestComponent type="epic" id="e1" />);

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // id と type を同時に変更
      rerender(<TestComponent type="feature" id="f1" />);

      expect(mockCleanup).toHaveBeenCalledTimes(1);
      expect(dropTargetForElements).toHaveBeenCalledTimes(2);

      const newData = mockDropTargetConfig.getData();
      expect(newData.type).toBe('feature');
      expect(newData.id).toBe('f1');
    });

    it('dataのみが変更されても再初期化されない (依存配列に含まれない)', () => {
      const { rerender } = render(
        <TestComponent type="epic" id="e1" data={{ version: 'v1' }} />
      );

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // dataのみ変更
      rerender(<TestComponent type="epic" id="e1" data={{ version: 'v2' }} />);

      // cleanupも再実行もされない (dataは依存配列に含まれないため)
      expect(mockCleanup).not.toHaveBeenCalled();
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
    });

    it('コールバックのみが変更されても再初期化されない', () => {
      const callback1 = vi.fn();
      const callback2 = vi.fn();

      const { rerender } = render(<TestComponent type="epic" id="e1" onDrop={callback1} />);

      expect(dropTargetForElements).toHaveBeenCalledTimes(1);

      // コールバックのみ変更
      rerender(<TestComponent type="epic" id="e1" onDrop={callback2} />);

      // 再初期化されない
      expect(mockCleanup).not.toHaveBeenCalled();
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
    });
  });

  describe('element設定', () => {
    it('dropTargetForElements関数に渡されるelementが正しいDOM要素', () => {
      render(<TestComponent type="epic" id="e1" />);

      expect(mockDropTargetConfig.element).toBeInstanceOf(HTMLDivElement);
      expect(mockDropTargetConfig.element.dataset.testid).toBe('drop-target');
    });
  });
});
