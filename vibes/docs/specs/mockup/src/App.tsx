import React, { useEffect } from 'react';
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { EpicVersionGrid } from './components/EpicVersion/EpicVersionGrid';
import { Legend } from './components/Legend';
import { mockEpics, mockVersions } from './mockData';
import { useStore } from './store/useStore';
import './styles.scss';

export const App: React.FC = () => {
  // Zustand storeから状態とアクションを取得
  const cells = useStore(state => state.cells);
  const reorderFeatures = useStore(state => state.reorderFeatures);
  const reorderUserStories = useStore(state => state.reorderUserStories);
  const reorderTasks = useStore(state => state.reorderTasks);
  const reorderTests = useStore(state => state.reorderTests);
  const reorderBugs = useStore(state => state.reorderBugs);

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

        // タイプ別に並び替え処理（Zustandのアクションを呼び出し）
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
  }, [reorderFeatures, reorderUserStories, reorderTasks, reorderTests, reorderBugs]);

  return (
    <>
      <h1>🔬 ネストGrid検証 - 4層Grid構造テスト</h1>

      <div className="test-info">
        <strong>検証目的:</strong> Epic×Version Grid の中に FeatureCardGrid → UserStoryGrid → TaskGrid が4層ネストできるかを検証<br />
        <strong>技術:</strong> CSS Grid + Pragmatic Drag and Drop<br />
        <strong>操作:</strong> 各レベルのカード（Feature/UserStory/Task/Test/Bug）をドラッグ&ドロップしてみてください<br />
        <strong>✅ React + TypeScript + Zustand + Pragmatic Drag and Drop で実装</strong>
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
