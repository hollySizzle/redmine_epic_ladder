import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AssignedToToggle } from './AssignedToToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('AssignedToToggle', () => {
  const mockToggleAssignedToVisible = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - AssignedTo Visible', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isAssignedToVisible: true,
          toggleAssignedToVisible: mockToggleAssignedToVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<AssignedToToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<AssignedToToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('非表示用のタイトルが表示される', () => {
      render(<AssignedToToggle />);
      const button = screen.getByTitle('担当者名を非表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「担当者名」が表示される', () => {
      render(<AssignedToToggle />);
      expect(screen.getByText('担当者名')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<AssignedToToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - AssignedTo Hidden', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isAssignedToVisible: false,
          toggleAssignedToVisible: mockToggleAssignedToVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<AssignedToToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<AssignedToToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('表示用のタイトルが表示される', () => {
      render(<AssignedToToggle />);
      const button = screen.getByTitle('担当者名を表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「担当者名」が表示される', () => {
      render(<AssignedToToggle />);
      expect(screen.getByText('担当者名')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isAssignedToVisible: true,
          toggleAssignedToVisible: mockToggleAssignedToVisible,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleAssignedToVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<AssignedToToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleAssignedToVisible).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleAssignedToVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<AssignedToToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleAssignedToVisible).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isAssignedToVisible: false,
          toggleAssignedToVisible: mockToggleAssignedToVisible,
        };
        return selector(state);
      });

      render(<AssignedToToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
