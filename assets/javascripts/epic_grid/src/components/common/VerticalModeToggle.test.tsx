import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { VerticalModeToggle } from './VerticalModeToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('VerticalModeToggle', () => {
  const mockToggleVerticalMode = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - Vertical Mode ON', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isVerticalMode: true,
          toggleVerticalMode: mockToggleVerticalMode,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('横書きに切り替えるタイトルが表示される', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByTitle('横書きに切り替え');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「横書き」が表示される', () => {
      render(<VerticalModeToggle />);
      expect(screen.getByText('横書き')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<VerticalModeToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - Vertical Mode OFF', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isVerticalMode: false,
          toggleVerticalMode: mockToggleVerticalMode,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('縦書きに切り替えるタイトルが表示される', () => {
      render(<VerticalModeToggle />);
      const button = screen.getByTitle('縦書きに切り替え');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「縦書き」が表示される', () => {
      render(<VerticalModeToggle />);
      expect(screen.getByText('縦書き')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isVerticalMode: true,
          toggleVerticalMode: mockToggleVerticalMode,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleVerticalModeが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<VerticalModeToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleVerticalMode).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleVerticalModeが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<VerticalModeToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleVerticalMode).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isVerticalMode: false,
          toggleVerticalMode: mockToggleVerticalMode,
        };
        return selector(state);
      });

      render(<VerticalModeToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
