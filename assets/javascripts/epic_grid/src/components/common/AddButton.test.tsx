import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AddButton } from './AddButton';

describe('AddButton', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering', () => {
    it('ラベルが表示される', () => {
      render(<AddButton type="epic" label="Add Epic" />);
      expect(screen.getByText('Add Epic')).toBeInTheDocument();
    });

    it('デフォルトクラスが適用される', () => {
      render(<AddButton type="feature" label="Add Feature" />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('add-button');
      expect(button).toHaveClass('add-feature-btn');
    });

    it('カスタムクラスが追加される', () => {
      render(<AddButton type="epic" label="Add" className="custom-class" />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('add-button');
      expect(button).toHaveClass('add-epic-btn');
      expect(button).toHaveClass('custom-class');
    });

    it('data-add-button属性が設定される', () => {
      render(<AddButton type="version" label="Add" dataAddButton="test-id" />);
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('data-add-button', 'test-id');
    });
  });

  describe('Click Handling - with onClick prop', () => {
    it('onClickハンドラーが呼ばれる', () => {
      const mockOnClick = vi.fn();
      render(<AddButton type="epic" label="Add Epic" onClick={mockOnClick} />);

      const button = screen.getByRole('button');
      fireEvent.click(button);

      expect(mockOnClick).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回呼ばれる', () => {
      const mockOnClick = vi.fn();
      render(<AddButton type="feature" label="Add" onClick={mockOnClick} />);

      const button = screen.getByRole('button');
      fireEvent.click(button);
      fireEvent.click(button);
      fireEvent.click(button);

      expect(mockOnClick).toHaveBeenCalledTimes(3);
    });
  });

  describe('Click Handling - without onClick prop', () => {
    it('onClickなしの場合alertが呼ばれる', () => {
      const mockAlert = vi.spyOn(window, 'alert').mockImplementation(() => {});
      render(<AddButton type="user-story" label="Add Story" />);

      const button = screen.getByRole('button');
      fireEvent.click(button);

      expect(mockAlert).toHaveBeenCalledWith('Add Story clicked!');
      mockAlert.mockRestore();
    });
  });

  describe('Type variants', () => {
    it.each([
      ['epic', 'add-epic-btn'],
      ['version', 'add-version-btn'],
      ['feature', 'add-feature-btn'],
      ['user-story', 'add-user-story-btn'],
      ['task', 'add-task-btn'],
      ['test', 'add-test-btn'],
      ['bug', 'add-bug-btn'],
    ] as const)('type="%s"でクラス"%s"が適用される', (type, expectedClass) => {
      render(<AddButton type={type} label="Add" />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass(expectedClass);
    });
  });

  describe('Context props', () => {
    it('epicIdが渡される', () => {
      render(<AddButton type="feature" label="Add" epicId="epic-123" />);
      expect(screen.getByRole('button')).toBeInTheDocument();
    });

    it('versionIdが渡される', () => {
      render(<AddButton type="feature" label="Add" versionId="v1" />);
      expect(screen.getByRole('button')).toBeInTheDocument();
    });

    it('featureIdが渡される', () => {
      render(<AddButton type="user-story" label="Add" featureId="f1" />);
      expect(screen.getByRole('button')).toBeInTheDocument();
    });

    it('全てのIDが渡される', () => {
      render(
        <AddButton
          type="task"
          label="Add Task"
          epicId="e1"
          versionId="v1"
          featureId="f1"
        />
      );
      expect(screen.getByRole('button')).toBeInTheDocument();
    });
  });

  describe('onDrop callback', () => {
    it('onDropが渡されても正常にレンダリングされる', () => {
      const mockOnDrop = vi.fn();
      render(<AddButton type="feature" label="Add" onDrop={mockOnDrop} />);
      expect(screen.getByRole('button')).toBeInTheDocument();
    });
  });
});
