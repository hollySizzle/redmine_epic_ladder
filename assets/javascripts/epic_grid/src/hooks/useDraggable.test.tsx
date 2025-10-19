import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { useDraggable } from './useDraggable';
import { draggable } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

// モック
vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter');

// テスト用コンポーネント
interface TestComponentProps {
  type: string;
  id: string;
  data?: Record<string, any>;
  onDragStart?: () => void;
  onDrop?: () => void;
}

const TestComponent: React.FC<TestComponentProps> = ({ type, id, data, onDragStart, onDrop }) => {
  const ref = useDraggable({ type, id, data, onDragStart, onDrop });
  return <div ref={ref} data-testid="draggable-element">{id}</div>;
};

describe('useDraggable (Integration Test)', () => {
  let mockCleanup: ReturnType<typeof vi.fn>;
  let mockDraggableConfig: any;

  beforeEach(() => {
    mockCleanup = vi.fn();
    mockDraggableConfig = null;

    // draggable関数のモック
    vi.mocked(draggable).mockImplementation((config) => {
      mockDraggableConfig = config;
      return mockCleanup;
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('コンポーネントがマウントされるとdraggableが呼ばれる', () => {
    render(<TestComponent type="feature" id="f1" />);

    expect(draggable).toHaveBeenCalledTimes(1);
    expect(mockDraggableConfig).not.toBeNull();
  });

  it('draggable要素がDOMに存在する', () => {
    render(<TestComponent type="feature" id="f1" />);

    const element = screen.getByTestId('draggable-element');
    expect(element).toBeInTheDocument();
    expect(element.textContent).toBe('f1');
  });

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
    // dataプロパティ以外のカスタムデータは存在しない
    expect(initialData.parentId).toBeUndefined();
  });

  it('onDragStartが呼ばれるとdraggingクラスが追加される', () => {
    const mockOnDragStart = vi.fn();
    render(<TestComponent type="feature" id="f1" onDragStart={mockOnDragStart} />);

    const element = screen.getByTestId('draggable-element');

    // onDragStartを実行
    mockDraggableConfig.onDragStart();

    expect(element.classList.contains('dragging')).toBe(true);
    expect(mockOnDragStart).toHaveBeenCalledTimes(1);
  });

  it('onDropが呼ばれるとdraggingクラスが削除される', () => {
    const mockOnDrop = vi.fn();
    render(<TestComponent type="feature" id="f1" onDrop={mockOnDrop} />);

    const element = screen.getByTestId('draggable-element');

    // 最初にdraggingクラスを追加
    mockDraggableConfig.onDragStart();
    expect(element.classList.contains('dragging')).toBe(true);

    // onDropを実行
    mockDraggableConfig.onDrop();

    expect(element.classList.contains('dragging')).toBe(false);
    expect(mockOnDrop).toHaveBeenCalledTimes(1);
  });

  it('onDragStart/onDropがオプショナルでもエラーにならない', () => {
    render(<TestComponent type="feature" id="f1" />);

    const element = screen.getByTestId('draggable-element');

    // onDragStart/onDropを実行してもエラーにならない
    expect(() => {
      mockDraggableConfig.onDragStart();
      mockDraggableConfig.onDrop();
    }).not.toThrow();

    // クラスの追加・削除は正常に動作する
    mockDraggableConfig.onDragStart();
    expect(element.classList.contains('dragging')).toBe(true);

    mockDraggableConfig.onDrop();
    expect(element.classList.contains('dragging')).toBe(false);
  });

  it('アンマウント時にcleanup関数が呼ばれる', () => {
    const { unmount } = render(<TestComponent type="feature" id="f1" />);

    expect(mockCleanup).not.toHaveBeenCalled();

    unmount();

    expect(mockCleanup).toHaveBeenCalledTimes(1);
  });

  it('idが変更されると再初期化される', () => {
    const { rerender } = render(<TestComponent type="feature" id="f1" />);

    expect(draggable).toHaveBeenCalledTimes(1);
    expect(mockCleanup).not.toHaveBeenCalled();

    // idを変更
    rerender(<TestComponent type="feature" id="f2" />);

    // cleanupが呼ばれて、再度draggableが呼ばれる
    expect(mockCleanup).toHaveBeenCalledTimes(1);
    expect(draggable).toHaveBeenCalledTimes(2);

    // 新しいidがgetInitialDataに反映される
    const newInitialData = mockDraggableConfig.getInitialData();
    expect(newInitialData.id).toBe('f2');
  });

  it('typeが変更されると再初期化される', () => {
    const { rerender } = render(<TestComponent type="feature" id="f1" />);

    expect(draggable).toHaveBeenCalledTimes(1);

    // typeを変更
    rerender(<TestComponent type="epic" id="f1" />);

    // cleanupが呼ばれて、再度draggableが呼ばれる
    expect(mockCleanup).toHaveBeenCalledTimes(1);
    expect(draggable).toHaveBeenCalledTimes(2);

    // 新しいtypeがgetInitialDataに反映される
    const newInitialData = mockDraggableConfig.getInitialData();
    expect(newInitialData.type).toBe('epic');
  });

  it('id と type が同時に変更されると再初期化される', () => {
    const { rerender } = render(<TestComponent type="feature" id="f1" />);

    expect(draggable).toHaveBeenCalledTimes(1);

    // id と type を同時に変更
    rerender(<TestComponent type="epic" id="e1" />);

    expect(mockCleanup).toHaveBeenCalledTimes(1);
    expect(draggable).toHaveBeenCalledTimes(2);

    const newInitialData = mockDraggableConfig.getInitialData();
    expect(newInitialData.type).toBe('epic');
    expect(newInitialData.id).toBe('e1');
  });

  it('dataのみが変更されても再初期化されない (依存配列に含まれない)', () => {
    const { rerender } = render(
      <TestComponent type="feature" id="f1" data={{ version: 'v1' }} />
    );

    expect(draggable).toHaveBeenCalledTimes(1);

    // dataのみ変更
    rerender(<TestComponent type="feature" id="f1" data={{ version: 'v2' }} />);

    // cleanupも再実行もされない (dataは依存配列に含まれないため)
    expect(mockCleanup).not.toHaveBeenCalled();
    expect(draggable).toHaveBeenCalledTimes(1);
  });

  it('draggable関数に渡されるelementが正しいDOM要素', () => {
    render(<TestComponent type="feature" id="f1" />);

    expect(mockDraggableConfig.element).toBeInstanceOf(HTMLDivElement);
    expect(mockDraggableConfig.element.dataset.testid).toBe('draggable-element');
  });
});
