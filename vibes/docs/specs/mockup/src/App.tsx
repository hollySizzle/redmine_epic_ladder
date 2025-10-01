import React from 'react';
import { EpicVersionGrid } from './components/EpicVersion/EpicVersionGrid';
import { Legend } from './components/Legend';
import { mockEpics, mockVersions, mockCells } from './mockData';
import './styles.scss';

export const App: React.FC = () => {
  return (
    <>
      <h1>🔬 ネストGrid検証 - 4層Grid構造テスト</h1>

      <div className="test-info">
        <strong>検証目的:</strong> Epic×Version Grid の中に FeatureCardGrid → UserStoryGrid → TaskGrid が4層ネストできるかを検証<br />
        <strong>技術:</strong> CSS Grid + Pragmatic Drag and Drop<br />
        <strong>操作:</strong> 各レベルのカード（Feature/UserStory/Task/Test/Bug）をドラッグ&ドロップしてみてください<br />
        <strong>✅ React + TypeScript で実装</strong>
      </div>

      <EpicVersionGrid
        epics={mockEpics}
        versions={mockVersions}
        cells={mockCells}
      />

      <Legend />
    </>
  );
};
