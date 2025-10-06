import React, { useEffect } from 'react';
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { EpicVersionGrid } from './components/EpicVersion/EpicVersionGrid';
import { Legend } from './components/Legend';
import { SplitLayout } from './components/IssueDetail/SplitLayout';
import { IssueDetailPane } from './components/IssueDetail/IssueDetailPane';
import { DetailPaneToggle } from './components/common/DetailPaneToggle';
import { VerticalModeToggle } from './components/common/VerticalModeToggle';
import { useStore } from './store/useStore';
import './styles.scss';

export const App: React.FC = () => {
  // Zustand storeから状態とアクションを取得
  const fetchGridData = useStore(state => state.fetchGridData);
  const isLoading = useStore(state => state.isLoading);
  const error = useStore(state => state.error);
  const projectId = useStore(state => state.projectId);
  const selectedIssueId = useStore(state => state.selectedIssueId);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const isVerticalMode = useStore(state => state.isVerticalMode);
  const reorderFeatures = useStore(state => state.reorderFeatures);
  const reorderUserStories = useStore(state => state.reorderUserStories);
  const moveUserStoryToCell = useStore(state => state.moveUserStoryToCell);
  const reorderTasks = useStore(state => state.reorderTasks);
  const reorderTests = useStore(state => state.reorderTests);
  const reorderBugs = useStore(state => state.reorderBugs);
  const reorderEpics = useStore(state => state.reorderEpics);
  const reorderVersions = useStore(state => state.reorderVersions);

  // 初期データ取得
  useEffect(() => {
    // data-project-id属性からプロジェクトIDを取得
    const rootElement = document.getElementById('kanban-root');
    const dataProjectId = rootElement?.getAttribute('data-project-id') || '1';
    console.log('📊 Loading grid for project ID:', dataProjectId);
    fetchGridData(dataProjectId);
  }, [fetchGridData]);

  // 縦書きモード時にkanban-rootにvertical-modeクラスを追加
  useEffect(() => {
    const rootElement = document.getElementById('kanban-root');
    if (!rootElement) return;

    if (isVerticalMode) {
      rootElement.classList.add('vertical-mode');
    } else {
      rootElement.classList.remove('vertical-mode');
    }
  }, [isVerticalMode]);

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

        // AddButtonへのドロップ処理（真下に配置）
        if (targetData.isAddButton) {
          console.log('📦 Drop on AddButton:', targetData);

          // UserStoryのAddButton/Cellへのドロップは EpicVersionGrid.tsx の onDrop で処理される
          if (sourceType === 'user-story' && targetType === 'user-story') {
            console.log('ℹ️ UserStory drop on AddButton will be handled by EpicVersionGrid onDrop');
            return;
          }
          return;
        }

        // セルへのドロップ処理（移動）
        if (targetId.startsWith('cell-')) {
          console.log('📦 Drop on cell:', targetData);

          // UserStoryのCellへのドロップは EpicVersionGrid.tsx の onDrop で処理される
          if (sourceType === 'user-story' && targetData.cellType === 'us-cell') {
            console.log('ℹ️ UserStory drop on cell will be handled by EpicVersionGrid onDrop');
            return;
          }
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
        } else if (sourceType === 'epic') {
          console.log('🔍 Calling reorderEpics...');
          reorderEpics(sourceId, targetId, targetData);
          console.log('🔍 reorderEpics called');
        } else if (sourceType === 'version') {
          console.log('🔍 Calling reorderVersions...');
          reorderVersions(sourceId, targetId, targetData);
          console.log('🔍 reorderVersions called');
        }
      }
    });
  }, [reorderFeatures, reorderUserStories, reorderTasks, reorderTests, reorderBugs, reorderEpics, reorderVersions]);

  if (isLoading) {
    return <div className="loading">Loading grid data...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  // カンバングリッド部分
  const kanbanContent = (
    <>
      <div className="kanban-header">
        <h1>🔬 ネストGrid検証 - 4層Grid構造テスト (正規化API対応)</h1>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <VerticalModeToggle />
          <DetailPaneToggle />
        </div>
      </div>

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

  return (
    <div className="app-container">
      {isDetailPaneVisible ? (
        <SplitLayout
          leftPane={kanbanContent}
          rightPane={
            <IssueDetailPane
              issueId={selectedIssueId}
              projectId={projectId}
            />
          }
        />
      ) : (
        <div className="kanban-fullscreen">
          {kanbanContent}
        </div>
      )}
    </div>
  );
};
