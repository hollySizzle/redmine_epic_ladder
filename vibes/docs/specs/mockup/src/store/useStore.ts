import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { devtools } from 'zustand/middleware';
import type { EpicVersionCellData } from '../components/EpicVersion/EpicVersionGrid';
import { mockCells } from '../mockData';

interface StoreState {
  cells: EpicVersionCellData[];
  reorderFeatures: (sourceId: string, targetId: string, targetData?: any) => void;
  reorderUserStories: (sourceId: string, targetId: string) => void;
  reorderTasks: (sourceId: string, targetId: string) => void;
  reorderTests: (sourceId: string, targetId: string) => void;
  reorderBugs: (sourceId: string, targetId: string) => void;
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
      reorderUserStories: (sourceId: string, targetId: string) =>
        set((state) => {
          for (const cell of state.cells) {
            for (const feature of cell.features) {
              const sourceIndex = feature.stories.findIndex(s => s.id === sourceId);
              const targetIndex = feature.stories.findIndex(s => s.id === targetId);

              if (sourceIndex !== -1 && targetIndex !== -1) {
                const [removed] = feature.stories.splice(sourceIndex, 1);
                const newTargetIndex = feature.stories.findIndex(s => s.id === targetId);
                feature.stories.splice(newTargetIndex, 0, removed);
                console.log('✅ Reordered stories:', { sourceId, targetId, sourceIndex, targetIndex, newTargetIndex });
                return;
              }
            }
          }
        }, false, 'reorderUserStories'),

      // Task の並び替え
      reorderTasks: (sourceId: string, targetId: string) =>
        set((state) => {
          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.tasks.findIndex(t => t.id === sourceId);
                const targetIndex = story.tasks.findIndex(t => t.id === targetId);

                if (sourceIndex !== -1 && targetIndex !== -1) {
                  const [removed] = story.tasks.splice(sourceIndex, 1);
                  const newTargetIndex = story.tasks.findIndex(t => t.id === targetId);
                  story.tasks.splice(newTargetIndex, 0, removed);
                  console.log('✅ Reordered tasks:', { sourceId, targetId, sourceIndex, targetIndex, newTargetIndex });
                  return;
                }
              }
            }
          }
        }, false, 'reorderTasks'),

      // Test の並び替え
      reorderTests: (sourceId: string, targetId: string) =>
        set((state) => {
          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.tests.findIndex(t => t.id === sourceId);
                const targetIndex = story.tests.findIndex(t => t.id === targetId);

                if (sourceIndex !== -1 && targetIndex !== -1) {
                  const [removed] = story.tests.splice(sourceIndex, 1);
                  const newTargetIndex = story.tests.findIndex(t => t.id === targetId);
                  story.tests.splice(newTargetIndex, 0, removed);
                  console.log('✅ Reordered tests:', { sourceId, targetId, sourceIndex, targetIndex, newTargetIndex });
                  return;
                }
              }
            }
          }
        }, false, 'reorderTests'),

      // Bug の並び替え
      reorderBugs: (sourceId: string, targetId: string) =>
        set((state) => {
          for (const cell of state.cells) {
            for (const feature of cell.features) {
              for (const story of feature.stories) {
                const sourceIndex = story.bugs.findIndex(b => b.id === sourceId);
                const targetIndex = story.bugs.findIndex(b => b.id === targetId);

                if (sourceIndex !== -1 && targetIndex !== -1) {
                  const [removed] = story.bugs.splice(sourceIndex, 1);
                  const newTargetIndex = story.bugs.findIndex(b => b.id === targetId);
                  story.bugs.splice(newTargetIndex, 0, removed);
                  console.log('✅ Reordered bugs:', { sourceId, targetId, sourceIndex, targetIndex, newTargetIndex });
                  return;
                }
              }
            }
          }
        }, false, 'reorderBugs'),
    }))
  )
);
