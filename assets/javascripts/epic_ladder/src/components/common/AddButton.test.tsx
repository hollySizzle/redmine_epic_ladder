import React from 'react';
import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AddButton } from './AddButton';
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

// モック
vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter');

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

  describe('Drop Target機能', () => {
    let mockCleanup: ReturnType<typeof vi.fn>;
    let mockDropTargetConfig: any;

    beforeEach(() => {
      mockCleanup = vi.fn();
      mockDropTargetConfig = null;

      vi.mocked(dropTargetForElements).mockImplementation((config) => {
        mockDropTargetConfig = config;
        return mockCleanup;
      });
    });

    afterEach(() => {
      vi.clearAllMocks();
    });

    it('dropTargetForElementsが呼ばれる', () => {
      render(<AddButton type="feature" label="Add" />);
      expect(dropTargetForElements).toHaveBeenCalledTimes(1);
    });

    it('getDataが正しいデータを返す', () => {
      render(
        <AddButton
          type="feature"
          label="Add Feature"
          epicId="e1"
          versionId="v1"
          featureId="f1"
        />
      );

      const data = mockDropTargetConfig.getData();
      expect(data.type).toBe('feature');
      expect(data.epicId).toBe('e1');
      expect(data.versionId).toBe('v1');
      expect(data.featureId).toBe('f1');
      expect(data.isAddButton).toBe(true);
      expect(data.id).toBe('add-button-feature-e1-v1-f1');
    });

    it('ID未指定時のgetData', () => {
      render(<AddButton type="epic" label="Add Epic" />);

      const data = mockDropTargetConfig.getData();
      expect(data.type).toBe('epic');
      expect(data.id).toBe('add-button-epic-none-none-none');
    });

    it('canDropで同じtypeのみtrueを返す', () => {
      render(<AddButton type="feature" label="Add" />);

      const resultSameType = mockDropTargetConfig.canDrop({
        source: { data: { type: 'feature', id: 'f1' } }
      });
      expect(resultSameType).toBe(true);

      const resultDifferentType = mockDropTargetConfig.canDrop({
        source: { data: { type: 'epic', id: 'e1' } }
      });
      expect(resultDifferentType).toBe(false);
    });

    it('onDropコールバックが呼ばれる', () => {
      const mockOnDrop = vi.fn();
      render(<AddButton type="feature" label="Add" onDrop={mockOnDrop} />);

      const sourceData = { type: 'feature', id: 'f1', title: 'Feature 1' };
      mockDropTargetConfig.onDrop({ source: { data: sourceData } });

      expect(mockOnDrop).toHaveBeenCalledWith(sourceData);
      expect(mockOnDrop).toHaveBeenCalledTimes(1);
    });

    it('onDropが未指定でもエラーにならない', () => {
      render(<AddButton type="feature" label="Add" />);

      expect(() => {
        mockDropTargetConfig.onDrop({ source: { data: { type: 'feature', id: 'f1' } } });
      }).not.toThrow();
    });

    it('アンマウント時にcleanupが呼ばれる', () => {
      const { unmount } = render(<AddButton type="feature" label="Add" />);

      expect(mockCleanup).not.toHaveBeenCalled();
      unmount();
      expect(mockCleanup).toHaveBeenCalledTimes(1);
    });
  });
});
