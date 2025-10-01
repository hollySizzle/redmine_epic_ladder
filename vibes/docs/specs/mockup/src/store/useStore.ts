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

// 共通ヘルパー関数: 配列内でアイテムを並び替え
function reorderInArray<T>(array: T[], sourceIndex: number, targetIndex: number): void {
  const [removed] = array.splice(sourceIndex, 1);
  const newTargetIndex = array.findIndex((_, i) => i === targetIndex - (sourceIndex < targetIndex ? 1 : 0));
  array.splice(newTargetIndex === -1 ? targetIndex : newTargetIndex, 0, removed);
}

// 共通ヘルパー関数: 異なる配列間でアイテムを移動
function moveItemBetweenArrays<T>(sourceArray: T[], targetArray: T[], sourceIndex: number, targetIndex: number): void {
  const [removed] = sourceArray.splice(sourceIndex, 1);
  targetArray.splice(targetIndex + 1, 0, removed);
}

export const useStore = create<StoreState>()(
  devtools(
    immer((set) => ({
      cells: mockCells,

      // Feature カードの並び替え (targetDataを受け取れるようにオーバーロード)
      reorderFeatures: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          console.log('🔍 reorderFeatures START:', { sourceId, targetId, targetData, cellsCount: state.cells.length });

          // 1. source cellを探す
          let sourceCell = null;
          let sourceFeature = null;

          for (const cell of state.cells) {
            const sourceIndex = cell.features.findIndex(f => f.id === sourceId);
            if (sourceIndex !== -1) {
              sourceCell = cell;
              sourceFeature = cell.features[sourceIndex];
              break;
            }
          }

          if (!sourceCell || !sourceFeature) {
            console.warn('⚠️ Source not found');
            return;
          }

          // 2. Addボタンへのドロップの場合
          if (targetData?.isAddButton) {
            const targetEpicId = targetData.epicId;
            const targetVersionId = targetData.versionId;
            const targetCell = state.cells.find(c => c.epicId === targetEpicId && c.versionId === targetVersionId);

            if (!targetCell) {
              console.warn('⚠️ Target cell not found for add button');
              return;
            }

            // source cellから削除
            const sourceIndex = sourceCell.features.findIndex(f => f.id === sourceId);
            const [removed] = sourceCell.features.splice(sourceIndex, 1);

            // target cellの末尾に追加
            targetCell.features.push(removed);
            console.log('✅ Moved feature to empty cell (add button):', {
              sourceId,
              from: `${sourceCell.epicId}×${sourceCell.versionId}`,
              to: `${targetCell.epicId}×${targetCell.versionId}`
            });
            return;
          }

          // 3. target cellを探す (通常のFeatureカード)
          let targetCell = null;
          for (const cell of state.cells) {
            const targetIndex = cell.features.findIndex(f => f.id === targetId);
            if (targetIndex !== -1) {
              targetCell = cell;
              break;
            }
          }

          if (!targetCell) {
            console.warn('⚠️ Target not found');
            return;
          }

          // 4. 同じcell内の並び替え
          if (sourceCell === targetCell) {
            const sourceIndex = sourceCell.features.findIndex(f => f.id === sourceId);
            const targetIndex = sourceCell.features.findIndex(f => f.id === targetId);
            const [removed] = sourceCell.features.splice(sourceIndex, 1);
            const newTargetIndex = sourceCell.features.findIndex(f => f.id === targetId);
            sourceCell.features.splice(newTargetIndex, 0, removed);
            console.log('✅ Reordered features (same cell):', { sourceId, targetId });
          }
          // 5. 異なるcell間の移動
          else {
            // source cellから削除
            const sourceIndex = sourceCell.features.findIndex(f => f.id === sourceId);
            const [removed] = sourceCell.features.splice(sourceIndex, 1);

            // target cellの target の直後に挿入
            const targetIndex = targetCell.features.findIndex(f => f.id === targetId);
            targetCell.features.splice(targetIndex + 1, 0, removed);
            console.log('✅ Moved feature (different cell):', {
              sourceId,
              targetId,
              from: `${sourceCell.epicId}×${sourceCell.versionId}`,
              to: `${targetCell.epicId}×${targetCell.versionId}`
            });
          }
        }, false, 'reorderFeatures'),

      // UserStory の並び替え
      reorderUserStories: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceとtargetが存在するfeatureを探す
          let sourceFeature = null;
          let targetFeature = null;
          let sourceStory = null;

          for (const cell of state.cells) {
            for (const feature of cell.features) {
              const sourceIndex = feature.stories.findIndex(s => s.id === sourceId);
              if (sourceIndex !== -1) {
                sourceFeature = feature;
                sourceStory = feature.stories[sourceIndex];
              }

              const targetIndex = feature.stories.findIndex(s => s.id === targetId);
              if (targetIndex !== -1) {
                targetFeature = feature;
              }
            }
          }

          if (!sourceFeature || !sourceStory) {
            console.warn('⚠️ Source user story not found');
            return;
          }

          // 2. Addボタンへのドロップの場合（将来の拡張用）
          if (targetData?.isAddButton) {
            console.log('🔍 Add button drop for user story - not yet implemented');
            return;
          }

          if (!targetFeature) {
            console.warn('⚠️ Target user story not found');
            return;
          }

          // 3. 同じfeature内の並び替え
          if (sourceFeature === targetFeature) {
            const sourceIndex = sourceFeature.stories.findIndex(s => s.id === sourceId);
            const targetIndex = sourceFeature.stories.findIndex(s => s.id === targetId);
            const [removed] = sourceFeature.stories.splice(sourceIndex, 1);
            const newTargetIndex = sourceFeature.stories.findIndex(s => s.id === targetId);
            sourceFeature.stories.splice(newTargetIndex, 0, removed);
            console.log('✅ Reordered user stories (same feature):', { sourceId, targetId });
          }
          // 4. 異なるfeature間の移動
          else {
            const sourceIndex = sourceFeature.stories.findIndex(s => s.id === sourceId);
            const [removed] = sourceFeature.stories.splice(sourceIndex, 1);
            const targetIndex = targetFeature.stories.findIndex(s => s.id === targetId);
            targetFeature.stories.splice(targetIndex + 1, 0, removed);
            console.log('✅ Moved user story (different feature):', { sourceId, targetId });
          }
        }, false, 'reorderUserStories'),

      // Task の並び替え
      reorderTasks: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceとtargetが存在するstoryを探す
          let sourceStory = null;
          let targetStory = null;
          let sourceTask = null;

          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.tasks.findIndex(t => t.id === sourceId);
                if (sourceIndex !== -1) {
                  sourceStory = story;
                  sourceTask = story.tasks[sourceIndex];
                }

                const targetIndex = story.tasks.findIndex(t => t.id === targetId);
                if (targetIndex !== -1) {
                  targetStory = story;
                }
              }
            }
          }

          if (!sourceStory || !sourceTask) {
            console.warn('⚠️ Source task not found');
            return;
          }

          // 2. Addボタンへのドロップの場合（将来の拡張用）
          if (targetData?.isAddButton) {
            console.log('🔍 Add button drop for task - not yet implemented');
            return;
          }

          if (!targetStory) {
            console.warn('⚠️ Target task not found');
            return;
          }

          // 3. 同じstory内の並び替え
          if (sourceStory === targetStory) {
            const sourceIndex = sourceStory.tasks.findIndex(t => t.id === sourceId);
            const targetIndex = sourceStory.tasks.findIndex(t => t.id === targetId);
            const [removed] = sourceStory.tasks.splice(sourceIndex, 1);
            const newTargetIndex = sourceStory.tasks.findIndex(t => t.id === targetId);
            sourceStory.tasks.splice(newTargetIndex, 0, removed);
            console.log('✅ Reordered tasks (same story):', { sourceId, targetId });
          }
          // 4. 異なるstory間の移動
          else {
            const sourceIndex = sourceStory.tasks.findIndex(t => t.id === sourceId);
            const [removed] = sourceStory.tasks.splice(sourceIndex, 1);
            const targetIndex = targetStory.tasks.findIndex(t => t.id === targetId);
            targetStory.tasks.splice(targetIndex + 1, 0, removed);
            console.log('✅ Moved task (different story):', { sourceId, targetId });
          }
        }, false, 'reorderTasks'),

      // Test の並び替え
      reorderTests: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceとtargetが存在するstoryを探す
          let sourceStory = null;
          let targetStory = null;
          let sourceTest = null;

          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.tests.findIndex(t => t.id === sourceId);
                if (sourceIndex !== -1) {
                  sourceStory = story;
                  sourceTest = story.tests[sourceIndex];
                }

                const targetIndex = story.tests.findIndex(t => t.id === targetId);
                if (targetIndex !== -1) {
                  targetStory = story;
                }
              }
            }
          }

          if (!sourceStory || !sourceTest) {
            console.warn('⚠️ Source test not found');
            return;
          }

          // 2. Addボタンへのドロップの場合（将来の拡張用）
          if (targetData?.isAddButton) {
            console.log('🔍 Add button drop for test - not yet implemented');
            return;
          }

          if (!targetStory) {
            console.warn('⚠️ Target test not found');
            return;
          }

          // 3. 同じstory内の並び替え
          if (sourceStory === targetStory) {
            const sourceIndex = sourceStory.tests.findIndex(t => t.id === sourceId);
            const targetIndex = sourceStory.tests.findIndex(t => t.id === targetId);
            const [removed] = sourceStory.tests.splice(sourceIndex, 1);
            const newTargetIndex = sourceStory.tests.findIndex(t => t.id === targetId);
            sourceStory.tests.splice(newTargetIndex, 0, removed);
            console.log('✅ Reordered tests (same story):', { sourceId, targetId });
          }
          // 4. 異なるstory間の移動
          else {
            const sourceIndex = sourceStory.tests.findIndex(t => t.id === sourceId);
            const [removed] = sourceStory.tests.splice(sourceIndex, 1);
            const targetIndex = targetStory.tests.findIndex(t => t.id === targetId);
            targetStory.tests.splice(targetIndex + 1, 0, removed);
            console.log('✅ Moved test (different story):', { sourceId, targetId });
          }
        }, false, 'reorderTests'),

      // Bug の並び替え
      reorderBugs: (sourceId: string, targetId: string, targetData?: any) =>
        set((state) => {
          // 1. sourceとtargetが存在するstoryを探す
          let sourceStory = null;
          let targetStory = null;
          let sourceBug = null;

          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.bugs.findIndex(b => b.id === sourceId);
                if (sourceIndex !== -1) {
                  sourceStory = story;
                  sourceBug = story.bugs[sourceIndex];
                }

                const targetIndex = story.bugs.findIndex(b => b.id === targetId);
                if (targetIndex !== -1) {
                  targetStory = story;
                }
              }
            }
          }

          if (!sourceStory || !sourceBug) {
            console.warn('⚠️ Source bug not found');
            return;
          }

          // 2. Addボタンへのドロップの場合（将来の拡張用）
          if (targetData?.isAddButton) {
            console.log('🔍 Add button drop for bug - not yet implemented');
            return;
          }

          if (!targetStory) {
            console.warn('⚠️ Target bug not found');
            return;
          }

          // 3. 同じstory内の並び替え
          if (sourceStory === targetStory) {
            const sourceIndex = sourceStory.bugs.findIndex(b => b.id === sourceId);
            const targetIndex = sourceStory.bugs.findIndex(b => b.id === targetId);
            const [removed] = sourceStory.bugs.splice(sourceIndex, 1);
            const newTargetIndex = sourceStory.bugs.findIndex(b => b.id === targetId);
            sourceStory.bugs.splice(newTargetIndex, 0, removed);
            console.log('✅ Reordered bugs (same story):', { sourceId, targetId });
          }
          // 4. 異なるstory間の移動
          else {
            const sourceIndex = sourceStory.bugs.findIndex(b => b.id === sourceId);
            const [removed] = sourceStory.bugs.splice(sourceIndex, 1);
            const targetIndex = targetStory.bugs.findIndex(b => b.id === targetId);
            targetStory.bugs.splice(targetIndex + 1, 0, removed);
            console.log('✅ Moved bug (different story):', { sourceId, targetId });
          }
        }, false, 'reorderBugs'),
    }))
  )
);
