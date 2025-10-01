import { useEffect, useRef } from 'react';
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

interface UseDropTargetOptions {
  type: string;
  id: string;
  data?: Record<string, any>;
  canDrop?: (sourceData: any) => boolean;
  onDragEnter?: () => void;
  onDragLeave?: () => void;
  onDrop?: (sourceData: any) => void;
}

export const useDropTarget = ({
  type,
  id,
  data = {},
  canDrop,
  onDragEnter,
  onDragLeave,
  onDrop
}: UseDropTargetOptions) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const cleanup = dropTargetForElements({
      element,
      getData: () => ({
        type,
        id,
        ...data
      }),
      getIsSticky: () => true,
      canDrop: ({ source }) => {
        if (canDrop) {
          return canDrop(source.data);
        }
        // デフォルト: 同じタイプで、異なるIDの場合のみドロップ可能
        return source.data.type === type && source.data.id !== id;
      },
      onDragEnter: () => {
        element.classList.add('over');
        onDragEnter?.();
      },
      onDragLeave: () => {
        element.classList.remove('over');
        onDragLeave?.();
      },
      onDrop: ({ source }) => {
        element.classList.remove('over');
        onDrop?.(source.data);
      }
    });

    return cleanup;
    // ベストプラクティス: idとtypeのみを依存配列に含める
  }, [id, type]);

  return ref;
};
