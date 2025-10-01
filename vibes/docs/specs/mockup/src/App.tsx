import React, { useState, useEffect } from 'react';
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { EpicVersionGrid } from './components/EpicVersion/EpicVersionGrid';
import { Legend } from './components/Legend';
import { mockEpics, mockVersions, mockCells } from './mockData';
import type { EpicVersionCellData } from './components/EpicVersion/EpicVersionGrid';
import './styles.scss';

export const App: React.FC = () => {
  const [cells, setCells] = useState<EpicVersionCellData[]>(mockCells);

  // グローバルなドロップイベント監視
  useEffect(() => {
    return monitorForElements({
      onDrop: ({ source, location }) => {
        console.log('🌍 Global drop detected:', { source: source.data, location });

        const sourceType = source.data.type as string;
        const sourceId = source.data.id as string;

        // dropTargetが存在する場合のみ処理
        const dropTargets = location.current.dropTargets;
        if (dropTargets.length === 0) return;

        // 最も内側のdropTargetを取得
        const targetData = dropTargets[0].data;
        const targetType = targetData.type as string;
        const targetId = targetData.id as string;

        console.log('🎯 Reordering:', { sourceType, sourceId, targetType, targetId });

        // 同じタイプ同士のみ並び替え可能
        if (sourceType !== targetType) {
          console.warn('⚠️ Cannot reorder different types');
          return;
        }

        // タイプ別に並び替え処理
        if (sourceType === 'feature-card') {
          reorderFeatures(sourceId, targetId);
        } else if (sourceType === 'user-story') {
          reorderUserStories(sourceId, targetId);
        } else if (sourceType === 'task') {
          reorderTasks(sourceId, targetId);
        } else if (sourceType === 'test') {
          reorderTests(sourceId, targetId);
        } else if (sourceType === 'bug') {
          reorderBugs(sourceId, targetId);
        }
      }
    });
  }, [cells]);

  // Feature カードの並び替え
  const reorderFeatures = (sourceId: string, targetId: string) => {
    setCells(prevCells => {
      return prevCells.map(cell => {
        const sourceIndex = cell.features.findIndex(f => f.id === sourceId);
        const targetIndex = cell.features.findIndex(f => f.id === targetId);

        // 同じセル内のFeatureが見つかった場合のみ並び替え
        if (sourceIndex !== -1 && targetIndex !== -1) {
          const newFeatures = [...cell.features];
          const [removed] = newFeatures.splice(sourceIndex, 1);
          newFeatures.splice(targetIndex, 0, removed);
          return { ...cell, features: newFeatures };
        }
        return cell;
      });
    });
  };

  // UserStory の並び替え
  const reorderUserStories = (sourceId: string, targetId: string) => {
    setCells(prevCells => {
      return prevCells.map(cell => ({
        ...cell,
        features: cell.features.map(feature => {
          const sourceIndex = feature.stories.findIndex(s => s.id === sourceId);
          const targetIndex = feature.stories.findIndex(s => s.id === targetId);

          if (sourceIndex !== -1 && targetIndex !== -1) {
            const newStories = [...feature.stories];
            const [removed] = newStories.splice(sourceIndex, 1);
            newStories.splice(targetIndex, 0, removed);
            return { ...feature, stories: newStories };
          }
          return feature;
        })
      }));
    });
  };

  // Task の並び替え
  const reorderTasks = (sourceId: string, targetId: string) => {
    setCells(prevCells => {
      return prevCells.map(cell => ({
        ...cell,
        features: cell.features.map(feature => ({
          ...feature,
          stories: feature.stories.map(story => {
            const sourceIndex = story.tasks.findIndex(t => t.id === sourceId);
            const targetIndex = story.tasks.findIndex(t => t.id === targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newTasks = [...story.tasks];
              const [removed] = newTasks.splice(sourceIndex, 1);
              newTasks.splice(targetIndex, 0, removed);
              return { ...story, tasks: newTasks };
            }
            return story;
          })
        }))
      }));
    });
  };

  // Test の並び替え
  const reorderTests = (sourceId: string, targetId: string) => {
    setCells(prevCells => {
      return prevCells.map(cell => ({
        ...cell,
        features: cell.features.map(feature => ({
          ...feature,
          stories: feature.stories.map(story => {
            const sourceIndex = story.tests.findIndex(t => t.id === sourceId);
            const targetIndex = story.tests.findIndex(t => t.id === targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newTests = [...story.tests];
              const [removed] = newTests.splice(sourceIndex, 1);
              newTests.splice(targetIndex, 0, removed);
              return { ...story, tests: newTests };
            }
            return story;
          })
        }))
      }));
    });
  };

  // Bug の並び替え
  const reorderBugs = (sourceId: string, targetId: string) => {
    setCells(prevCells => {
      return prevCells.map(cell => ({
        ...cell,
        features: cell.features.map(feature => ({
          ...feature,
          stories: feature.stories.map(story => {
            const sourceIndex = story.bugs.findIndex(b => b.id === sourceId);
            const targetIndex = story.bugs.findIndex(b => b.id === targetId);

            if (sourceIndex !== -1 && targetIndex !== -1) {
              const newBugs = [...story.bugs];
              const [removed] = newBugs.splice(sourceIndex, 1);
              newBugs.splice(targetIndex, 0, removed);
              return { ...story, bugs: newBugs };
            }
            return story;
          })
        }))
      }));
    });
  };

  return (
    <>
      <h1>🔬 ネストGrid検証 - 4層Grid構造テスト</h1>

      <div className="test-info">
        <strong>検証目的:</strong> Epic×Version Grid の中に FeatureCardGrid → UserStoryGrid → TaskGrid が4層ネストできるかを検証<br />
        <strong>技術:</strong> CSS Grid + Pragmatic Drag and Drop<br />
        <strong>操作:</strong> 各レベルのカード（Feature/UserStory/Task/Test/Bug）をドラッグ&ドロップしてみてください<br />
        <strong>✅ React + TypeScript + Custom Hooks + 状態管理 で実装</strong>
      </div>

      <EpicVersionGrid
        epics={mockEpics}
        versions={mockVersions}
        cells={cells}
      />

      <Legend />
    </>
  );
};
