import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { devtools } from 'zustand/middleware';
import type { EpicVersionCellData } from '../components/EpicVersion/EpicVersionGrid';
import { mockCells } from '../mockData';

interface StoreState {
  cells: EpicVersionCellData[];
  reorderFeatures: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderUserStories: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderTasks: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderTests: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderBugs: (sourceId: string, targetId: string, targetData?: any) => void;
}

// 型定義: コンテナとアイテムの検索結果
interface FindResult<Container, Item> {
  container: Container | null;
  item: Item | null;
  index: number;
}

// 共通ヘルパー関数: ネストされた構造から要素を探す
function findItemInContainers<Container, Item>(
  containers: Container[],
  getItems: (container: Container) => Item[],
  predicate: (item: Item) => boolean
): FindResult<Container, Item> {
  for (const container of containers) {
    const items = getItems(container);
    const index = items.findIndex(predicate);
    if (index !== -1) {
      return { container, item: items[index], index };
    }
  }
  return { container: null, item: null, index: -1 };
}

// 共通ヘルパー関数: 同一コンテナ内での並び替え
function reorderInSameContainer<Item>(
  items: Item[],
  sourceIndex: number,
  targetIndex: number
): void {
  const [removed] = items.splice(sourceIndex, 1);
  const newTargetIndex = items.findIndex((_, i) => i === targetIndex);
  items.splice(newTargetIndex, 0, removed);
}

// 共通ヘルパー関数: 異なるコンテナ間での移動
function moveBetweenContainers<Item>(
  sourceItems: Item[],
  targetItems: Item[],
  sourceIndex: number,
  targetIndex: number
): void {
  const [removed] = sourceItems.splice(sourceIndex, 1);
  targetItems.splice(targetIndex + 1, 0, removed);
}

export const useStore = create<StoreState>()(
  devtools(
    immer((set) => ({
      cells: mockCells,

      // Feature カードの並び替え
      reorderFeatures: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceを探す
          const sourceResult = findItemInContainers(
            state.cells,
            (cell) => cell.features,
            (f) => f.id === sourceId
          );

          if (!sourceResult.container || !sourceResult.item) {
            return;
          }

          // 2. Addボタンへのドロップの場合
          if (targetData?.isAddButton) {
            const targetCell = state.cells.find(
              (c) => c.epicId === targetData.epicId && c.versionId === targetData.versionId
            );

            if (!targetCell) {
              return;
            }

            // source cellから削除してtarget cellに追加
            sourceResult.container.features.splice(sourceResult.index, 1);
            targetCell.features.push(sourceResult.item);
            return;
          }

          // 3. targetを探す
          const targetResult = findItemInContainers(
            state.cells,
            (cell) => cell.features,
            (f) => f.id === targetId
          );

          if (!targetResult.container) {
            return;
          }

          // 4. 同じcell内の並び替え
          if (sourceResult.container === targetResult.container) {
            reorderInSameContainer(
              sourceResult.container.features,
              sourceResult.index,
              targetResult.index
            );
          }
          // 5. 異なるcell間の移動
          else {
            moveBetweenContainers(
              sourceResult.container.features,
              targetResult.container.features,
              sourceResult.index,
              targetResult.index
            );
          }
        }, false, 'reorderFeatures'),

      // UserStory の並び替え
      reorderUserStories: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceを探す
          const allFeatures = state.cells.flatMap((c) => c.features);
          const sourceResult = findItemInContainers(
            allFeatures,
            (feature) => feature.stories,
            (s) => s.id === sourceId
          );

          if (!sourceResult.container || !sourceResult.item) {
            return;
          }

          // 2. Addボタンへのドロップ（将来の拡張用）
          if (targetData?.isAddButton) {
            return;
          }

          // 3. targetを探す
          const targetResult = findItemInContainers(
            allFeatures,
            (feature) => feature.stories,
            (s) => s.id === targetId
          );

          if (!targetResult.container) {
            return;
          }

          // 4. 同じfeature内の並び替え
          if (sourceResult.container === targetResult.container) {
            reorderInSameContainer(
              sourceResult.container.stories,
              sourceResult.index,
              targetResult.index
            );
          }
          // 5. 異なるfeature間の移動
          else {
            moveBetweenContainers(
              sourceResult.container.stories,
              targetResult.container.stories,
              sourceResult.index,
              targetResult.index
            );
          }
        }, false, 'reorderUserStories'),

      // Task の並び替え
      reorderTasks: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceを探す
          const allStories = state.cells.flatMap((c) => c.features).flatMap((f) => f.stories);
          const sourceResult = findItemInContainers(
            allStories,
            (story) => story.tasks,
            (t) => t.id === sourceId
          );

          if (!sourceResult.container || !sourceResult.item) {
            return;
          }

          // 2. Addボタンへのドロップ（将来の拡張用）
          if (targetData?.isAddButton) {
            return;
          }

          // 3. targetを探す
          const targetResult = findItemInContainers(
            allStories,
            (story) => story.tasks,
            (t) => t.id === targetId
          );

          if (!targetResult.container) {
            return;
          }

          // 4. 同じstory内の並び替え
          if (sourceResult.container === targetResult.container) {
            reorderInSameContainer(
              sourceResult.container.tasks,
              sourceResult.index,
              targetResult.index
            );
          }
          // 5. 異なるstory間の移動
          else {
            moveBetweenContainers(
              sourceResult.container.tasks,
              targetResult.container.tasks,
              sourceResult.index,
              targetResult.index
            );
          }
        }, false, 'reorderTasks'),

      // Test の並び替え
      reorderTests: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceを探す
          const allStories = state.cells.flatMap((c) => c.features).flatMap((f) => f.stories);
          const sourceResult = findItemInContainers(
            allStories,
            (story) => story.tests,
            (t) => t.id === sourceId
          );

          if (!sourceResult.container || !sourceResult.item) {
            return;
          }

          // 2. Addボタンへのドロップ（将来の拡張用）
          if (targetData?.isAddButton) {
            return;
          }

          // 3. targetを探す
          const targetResult = findItemInContainers(
            allStories,
            (story) => story.tests,
            (t) => t.id === targetId
          );

          if (!targetResult.container) {
            return;
          }

          // 4. 同じstory内の並び替え
          if (sourceResult.container === targetResult.container) {
            reorderInSameContainer(
              sourceResult.container.tests,
              sourceResult.index,
              targetResult.index
            );
          }
          // 5. 異なるstory間の移動
          else {
            moveBetweenContainers(
              sourceResult.container.tests,
              targetResult.container.tests,
              sourceResult.index,
              targetResult.index
            );
          }
        }, false, 'reorderTests'),

      // Bug の並び替え
      reorderBugs: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceを探す
          const allStories = state.cells.flatMap((c) => c.features).flatMap((f) => f.stories);
          const sourceResult = findItemInContainers(
            allStories,
            (story) => story.bugs,
            (b) => b.id === sourceId
          );

          if (!sourceResult.container || !sourceResult.item) {
            return;
          }

          // 2. Addボタンへのドロップ（将来の拡張用）
          if (targetData?.isAddButton) {
            return;
          }

          // 3. targetを探す
          const targetResult = findItemInContainers(
            allStories,
            (story) => story.bugs,
            (b) => b.id === targetId
          );

          if (!targetResult.container) {
            return;
          }

          // 4. 同じstory内の並び替え
          if (sourceResult.container === targetResult.container) {
            reorderInSameContainer(
              sourceResult.container.bugs,
              sourceResult.index,
              targetResult.index
            );
          }
          // 5. 異なるstory間の移動
          else {
            moveBetweenContainers(
              sourceResult.container.bugs,
              targetResult.container.bugs,
              sourceResult.index,
              targetResult.index
            );
          }
        }, false, 'reorderBugs'),
    }))
  )
);
