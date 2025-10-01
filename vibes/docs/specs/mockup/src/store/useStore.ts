import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { devtools } from 'zustand/middleware';
import type { EpicVersionCellData } from '../components/EpicVersion/EpicVersionGrid';
import { mockCells } from '../mockData';

interface StoreState {
  cells: EpicVersionCellData[];
  reorderFeatures: (sourceId: string, targetId: string) => void;
  reorderUserStories: (sourceId: string, targetId: string) => void;
  reorderTasks: (sourceId: string, targetId: string) => void;
  reorderTests: (sourceId: string, targetId: string) => void;
  reorderBugs: (sourceId: string, targetId: string) => void;
}

export const useStore = create<StoreState>()(
  devtools(
    immer((set) => ({
      cells: mockCells,

      // Feature カードの並び替え
      reorderFeatures: (sourceId: string, targetId: string) =>
        set((state) => {
          for (const cell of state.cells) {
            const sourceIndex = cell.features.findIndex(f => f.id === sourceId);
            const targetIndex = cell.features.findIndex(f => f.id === targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const [removed] = cell.features.splice(sourceIndex, 1);
              cell.features.splice(targetIndex, 0, removed);
              console.log('✅ Reordered features:', { sourceId, targetId });
              break;
            }
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
                feature.stories.splice(targetIndex, 0, removed);
                console.log('✅ Reordered stories:', { sourceId, targetId });
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
                  story.tasks.splice(targetIndex, 0, removed);
                  console.log('✅ Reordered tasks:', { sourceId, targetId });
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
                  story.tests.splice(targetIndex, 0, removed);
                  console.log('✅ Reordered tests:', { sourceId, targetId });
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
                  story.bugs.splice(targetIndex, 0, removed);
                  console.log('✅ Reordered bugs:', { sourceId, targetId });
                  return;
                }
              }
            }
          }
        }, false, 'reorderBugs'),
    }))
  )
);
