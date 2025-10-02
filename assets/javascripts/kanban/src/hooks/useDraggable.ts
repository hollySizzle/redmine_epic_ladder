import { useEffect, useRef } from 'react';
import { draggable } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

interface UseDraggableOptions {
  type: string;
  id: string;
  data?: Record<string, any>;
  onDragStart?: () => void;
  onDrop?: () => void;
}

export const useDraggable = ({
  type,
  id,
  data = {},
  onDragStart,
  onDrop
}: UseDraggableOptions) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const cleanup = draggable({
      element,
      getInitialData: () => ({
        type,
        id,
        instanceId: Symbol('nested-grid-test'), // 自己参照を防ぐためのユニークID
        ...data
      }),
      onDragStart: () => {
        element.classList.add('dragging');
        onDragStart?.();
      },
      onDrop: () => {
        element.classList.remove('dragging');
        onDrop?.();
      }
    });

    return cleanup;
    // ベストプラクティス: idとtypeのみを依存配列に含める
  }, [id, type]);

  return ref;
};
