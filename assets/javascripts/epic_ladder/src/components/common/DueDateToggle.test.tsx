import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DueDateToggle } from './DueDateToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('DueDateToggle', () => {
  const mockToggleDueDateVisible = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - DueDate Visible', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDueDateVisible: true,
          toggleDueDateVisible: mockToggleDueDateVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<DueDateToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<DueDateToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('非表示用のタイトルが表示される', () => {
      render(<DueDateToggle />);
      const button = screen.getByTitle('期日を非表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「期日」が表示される', () => {
      render(<DueDateToggle />);
      expect(screen.getByText('期日')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<DueDateToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - DueDate Hidden', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDueDateVisible: false,
          toggleDueDateVisible: mockToggleDueDateVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<DueDateToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<DueDateToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('表示用のタイトルが表示される', () => {
      render(<DueDateToggle />);
      const button = screen.getByTitle('期日を表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「期日」が表示される', () => {
      render(<DueDateToggle />);
      expect(screen.getByText('期日')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDueDateVisible: true,
          toggleDueDateVisible: mockToggleDueDateVisible,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleDueDateVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<DueDateToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleDueDateVisible).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleDueDateVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<DueDateToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleDueDateVisible).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDueDateVisible: false,
          toggleDueDateVisible: mockToggleDueDateVisible,
        };
        return selector(state);
      });

      render(<DueDateToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
