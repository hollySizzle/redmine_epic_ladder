import React from 'react';
import { render, screen } from '@testing-library/react';
import TestDHMLXGantt from '../../components/TestDHMLXGantt';

// DHMLXGanttWrapperコンポーネントのモック
jest.mock('../../components/DHMLXGanttWrapper', () => {
  return function MockDHMLXGanttWrapper({ data, config, onUpdate }) {
    return (
      <div data-testid="dhtmlx-gantt-wrapper">
        <div>タスク数: {data.tasks.length}</div>
        <div>リンク数: {data.links.length}</div>
        <div>スケールモード: {config.scale_mode}</div>
      </div>
    );
  };
});

describe('TestDHMLXGantt', () => {
  it('コンポーネントが正しくレンダリングされること', () => {
    render(<TestDHMLXGantt />);
    
    // タイトルが表示されていることを確認
    expect(screen.getByText('DHTMLX Gantt テスト')).toBeInTheDocument();
  });

  it('テストデータが正しく渡されること', () => {
    render(<TestDHMLXGantt />);
    
    // モックコンポーネントに正しいデータが渡されていることを確認
    expect(screen.getByText('タスク数: 6')).toBeInTheDocument();
    expect(screen.getByText('リンク数: 2')).toBeInTheDocument();
  });

  it('設定が正しく渡されること', () => {
    render(<TestDHMLXGantt />);
    
    // スケールモードが正しく設定されていることを確認
    expect(screen.getByText('スケールモード: Week')).toBeInTheDocument();
  });

  it('テスト内容のリストが表示されること', () => {
    render(<TestDHMLXGantt />);
    
    // テスト内容が表示されていることを確認
    expect(screen.getByText('テスト内容:')).toBeInTheDocument();
    expect(screen.getByText('基本的なタスク表示')).toBeInTheDocument();
    expect(screen.getByText('親子関係の表示')).toBeInTheDocument();
    expect(screen.getByText('依存関係（リンク）の表示')).toBeInTheDocument();
    expect(screen.getByText('ドラッグ＆ドロップ操作')).toBeInTheDocument();
    expect(screen.getByText('進捗率の表示')).toBeInTheDocument();
  });
});