import React, { useEffect } from 'react';
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { EpicVersionGrid } from './components/EpicVersion/EpicVersionGrid';
import { Legend } from './components/Legend';
import { useStore } from './store/useStore';
import './styles.scss';

export const App: React.FC = () => {
  // Zustand storeから状態とアクションを取得
  const fetchGridData = useStore(state => state.fetchGridData);
  const isLoading = useStore(state => state.isLoading);
  const error = useStore(state => state.error);
  const reorderFeatures = useStore(state => state.reorderFeatures);
  const reorderUserStories = useStore(state => state.reorderUserStories);
  const reorderTasks = useStore(state => state.reorderTasks);
  const reorderTests = useStore(state => state.reorderTests);
  const reorderBugs = useStore(state => state.reorderBugs);

  // 初期データ取得
  useEffect(() => {
    fetchGridData('1'); // projectId = 1
  }, [fetchGridData]);

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

        console.log('🎯 Reordering:', { sourceType, sourceId, targetType, targetId, targetData });

        // 同じタイプ同士のみ並び替え可能
        if (sourceType !== targetType) {
          console.warn('⚠️ Cannot reorder different types');
          return;
        }

        // タイプ別に並び替え処理（Zustandのアクションを呼び出し）
        console.log('🔍 About to call reorder function:', { sourceType, sourceId, targetId });
        if (sourceType === 'feature-card') {
          console.log('🔍 Calling reorderFeatures...');
          reorderFeatures(sourceId, targetId, targetData);
          console.log('🔍 reorderFeatures called');
        } else if (sourceType === 'user-story') {
          console.log('🔍 Calling reorderUserStories...');
          reorderUserStories(sourceId, targetId, targetData);
          console.log('🔍 reorderUserStories called');
        } else if (sourceType === 'task') {
          console.log('🔍 Calling reorderTasks...');
          reorderTasks(sourceId, targetId, targetData);
          console.log('🔍 reorderTasks called');
        } else if (sourceType === 'test') {
          console.log('🔍 Calling reorderTests...');
          reorderTests(sourceId, targetId, targetData);
          console.log('🔍 reorderTests called');
        } else if (sourceType === 'bug') {
          console.log('🔍 Calling reorderBugs...');
          reorderBugs(sourceId, targetId, targetData);
          console.log('🔍 reorderBugs called');
        }
      }
    });
  }, [reorderFeatures, reorderUserStories, reorderTasks, reorderTests, reorderBugs]);

  if (isLoading) {
    return <div className="loading">Loading grid data...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  return (
    <>
      <h1>🔬 ネストGrid検証 - 4層Grid構造テスト (正規化API対応)</h1>

      <div className="test-info">
        <strong>検証目的:</strong> Epic×Version Grid の中に FeatureCardGrid → UserStoryGrid → TaskGrid が4層ネストできるかを検証<br />
        <strong>技術:</strong> CSS Grid + Pragmatic Drag and Drop + Normalized API + MSW<br />
        <strong>操作:</strong> 各レベルのカード（Feature/UserStory/Task/Test/Bug）をドラッグ&ドロップしてみてください<br />
        <strong>✅ React + TypeScript + Zustand + Pragmatic Drag and Drop + MSW で実装</strong>
      </div>

      <EpicVersionGrid />

      <Legend />
    </>
  );
};
