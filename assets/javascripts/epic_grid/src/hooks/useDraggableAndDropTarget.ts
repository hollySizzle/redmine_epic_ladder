import { useEffect, useRef } from 'react';
import { draggable, dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';

interface UseDraggableAndDropTargetOptions {
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

/**
 * ドラッグ可能でかつドロップターゲットにもなる要素のためのカスタムフック
 * Feature、UserStory、Task、Test、Bug などに使用
 */
export const useDraggableAndDropTarget = ({
  type,
  id,
  data = {},
  canDrop,
  onDragStart,
  onDragEnter,
  onDragLeave,
  onDrop,
  onDragEnd
}: UseDraggableAndDropTargetOptions) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      console.warn('⚠️ useDraggableAndDropTarget: element is null', { type, id });
      return;
    }

    console.log('✅ Setting up drag and drop for:', { type, id, element });

    const cleanup = combine(
      // Draggable設定
      draggable({
        element,
        getInitialData: () => ({
          type,
          id,
          instanceId: Symbol('nested-grid-test'), // 自己参照を防ぐためのユニークID
          ...data
        }),
        onDragStart: () => {
          console.log('🎯 onDragStart:', { type, id });
          element.classList.add('dragging');
          onDragStart?.();
        },
        onDrop: () => {
          console.log('🎯 onDrop (draggable):', { type, id });
          element.classList.remove('dragging');
          onDragEnd?.();
        }
      }),
      // DropTarget設定
      dropTargetForElements({
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
          console.log('🎯 onDragEnter:', { type, id });
          element.classList.add('over');
          onDragEnter?.();
        },
        onDragLeave: () => {
          console.log('🎯 onDragLeave:', { type, id });
          element.classList.remove('over');
          onDragLeave?.();
        },
        onDrop: ({ source }) => {
          console.log('🎯 onDrop (dropTarget):', { source: source.data, target: { type, id } });
          element.classList.remove('over');
          onDrop?.(source.data);
        }
      })
    );

    return cleanup;
    // ベストプラクティス: idとtypeのみを依存配列に含める
    // コールバック関数は常に最新のクロージャでアクセスされる
    // refは安定しているため、不要な再登録を防ぐ
  }, [id, type]);

  return ref;
};
