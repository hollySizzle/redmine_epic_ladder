import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ColumnSettings from '../../components/ColumnSettings';

describe('ColumnSettings', () => {
  const mockAvailableColumns = [
    { id: 'id', name: 'ID', width: 50 },
    { id: 'text', name: 'タスク名', width: 200 },
    { id: 'tracker_name', name: 'トラッカー', width: 100 },
    { id: 'status_name', name: 'ステータス', width: 100 },
    { id: 'assigned_to_name', name: '担当者', width: 100 },
    { id: 'start_date', name: '開始日', width: 100 },
    { id: 'end_date', name: '終了日', width: 100 },
    { id: 'duration', name: '期間', width: 60 },
    { id: 'progress', name: '進捗', width: 60 }
  ];

  const mockVisibleColumns = [
    { id: 'text', name: 'タスク名', width: 200 },
    { id: 'status_name', name: 'ステータス', width: 100 },
    { id: 'assigned_to_name', name: '担当者', width: 100 }
  ];

  const mockCustomFields = [
    {
      id: 'custom_fields_1',
      name: 'カスタムフィールド1',
      width: 120
    },
    {
      id: 'custom_fields_2',
      name: 'カスタムフィールド2',
      width: 120
    }
  ];

  const defaultProps = {
    availableColumns: mockAvailableColumns,
    visibleColumns: mockVisibleColumns,
    customFields: mockCustomFields,
    onColumnChange: jest.fn(),
    projectId: 'test-project'
  };

  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  describe('F004: カラム設定機能', () => {
    it('カラム設定パネルを正しくレンダリングする', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      expect(screen.getByText('カラム設定')).toBeInTheDocument();
      expect(screen.getByText('表示中のカラム')).toBeInTheDocument();
      expect(screen.getByText('利用可能なカラム')).toBeInTheDocument();
    });

    it('表示中のカラムが正しく表示される', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      expect(screen.getByText('タスク名')).toBeInTheDocument();
      expect(screen.getByText('ステータス')).toBeInTheDocument();
      expect(screen.getByText('担当者')).toBeInTheDocument();
    });

    it('利用可能なカラムが正しく表示される', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // 表示中ではないカラムが利用可能なカラムに表示される
      expect(screen.getByText('ID')).toBeInTheDocument();
      expect(screen.getByText('トラッカー')).toBeInTheDocument();
      expect(screen.getByText('開始日')).toBeInTheDocument();
    });

    it('カスタムフィールドカラムが正しく表示される', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      expect(screen.getByText('カスタムフィールド1')).toBeInTheDocument();
      expect(screen.getByText('カスタムフィールド2')).toBeInTheDocument();
    });

    it('カラムを表示に追加できる', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // 利用可能なカラムから表示に追加
      const idColumn = screen.getByText('ID');
      fireEvent.click(idColumn);
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ id: 'id', name: 'ID' }),
          ...mockVisibleColumns
        ])
      );
    });

    it('カラムを表示から削除できる', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // 表示中のカラムをクリックして削除
      const statusColumn = screen.getByText('ステータス');
      fireEvent.click(statusColumn);
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ id: 'text', name: 'タスク名' }),
          expect.objectContaining({ id: 'assigned_to_name', name: '担当者' })
        ])
      );
    });

    it('カラムの並び替えができる', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // 表示中のカラムをドラッグアンドドロップで並び替え
      const visibleList = screen.getByText('表示中のカラム').parentElement;
      const dragItems = visibleList.querySelectorAll('[draggable="true"]');
      
      if (dragItems.length >= 2) {
        // ドラッグイベントをシミュレート
        fireEvent.dragStart(dragItems[0]);
        fireEvent.dragOver(dragItems[1]);
        fireEvent.drop(dragItems[1]);
        
        expect(defaultProps.onColumnChange).toHaveBeenCalled();
      }
    });

    it('カラム幅を調整できる', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // カラム幅の入力フィールドが表示される
      const widthInputs = screen.getAllByRole('spinbutton');
      expect(widthInputs.length).toBeGreaterThan(0);
      
      // 幅を変更
      fireEvent.change(widthInputs[0], { target: { value: '250' } });
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ width: 250 })
        ])
      );
    });

    it('デフォルト設定にリセットできる', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      const resetButton = screen.getByText('デフォルトにリセット');
      fireEvent.click(resetButton);
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ id: 'text' }),
          expect.objectContaining({ id: 'status_name' }),
          expect.objectContaining({ id: 'assigned_to_name' })
        ])
      );
    });

    it('カラム設定をローカルストレージに保存する', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // カラムを追加
      const idColumn = screen.getByText('ID');
      fireEvent.click(idColumn);
      
      // ローカルストレージに保存される
      const savedColumns = JSON.parse(localStorage.getItem('gantt_columns_test-project'));
      expect(savedColumns).toContain('id');
    });

    it('ローカルストレージからカラム設定を復元する', () => {
      // ローカルストレージに保存された設定をシミュレート
      localStorage.setItem('gantt_columns_test-project', JSON.stringify(['id', 'text', 'tracker_name']));
      
      render(<ColumnSettings {...defaultProps} />);
      
      // 保存された設定が反映される
      expect(screen.getByText('ID')).toBeInTheDocument();
      expect(screen.getByText('トラッカー')).toBeInTheDocument();
    });

    it('カラム幅設定をローカルストレージに保存する', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      // カラム幅を変更
      const widthInputs = screen.getAllByRole('spinbutton');
      fireEvent.change(widthInputs[0], { target: { value: '300' } });
      
      // ローカルストレージに保存される
      const savedWidths = JSON.parse(localStorage.getItem('gantt_column_widths_test-project'));
      expect(savedWidths).toHaveProperty('text', 300);
    });

    it('カラムの最小幅と最大幅を制限する', () => {
      render(<ColumnSettings {...defaultProps} />);
      
      const widthInputs = screen.getAllByRole('spinbutton');
      
      // 最小幅を下回る値を入力
      fireEvent.change(widthInputs[0], { target: { value: '10' } });
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ width: 50 }) // 最小幅に制限される
        ])
      );
      
      // 最大幅を上回る値を入力
      fireEvent.change(widthInputs[0], { target: { value: '600' } });
      
      expect(defaultProps.onColumnChange).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ width: 500 }) // 最大幅に制限される
        ])
      );
    });

    it('カラム設定をプロジェクトごとに分離する', () => {
      // プロジェクトAの設定
      const { rerender } = render(<ColumnSettings {...defaultProps} projectId="project-a" />);
      
      const idColumn = screen.getByText('ID');
      fireEvent.click(idColumn);
      
      // プロジェクトBの設定
      rerender(<ColumnSettings {...defaultProps} projectId="project-b" />);
      
      // プロジェクトAとBで別々に保存される
      const projectAColumns = localStorage.getItem('gantt_columns_project-a');
      const projectBColumns = localStorage.getItem('gantt_columns_project-b');
      
      expect(projectAColumns).toBeTruthy();
      expect(projectBColumns).toBeFalsy();
    });
  });
});