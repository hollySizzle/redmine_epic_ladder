import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { StatsToggle } from './StatsToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('StatsToggle', () => {
  const mockToggleStatsVisible = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - Stats Visible', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isStatsVisible: true,
          toggleStatsVisible: mockToggleStatsVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<StatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<StatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('非表示用のタイトルが表示される', () => {
      render(<StatsToggle />);
      const button = screen.getByTitle('統計情報を非表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「統計情報」が表示される', () => {
      render(<StatsToggle />);
      expect(screen.getByText('統計情報')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<StatsToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - Stats Hidden', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isStatsVisible: false,
          toggleStatsVisible: mockToggleStatsVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<StatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<StatsToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('表示用のタイトルが表示される', () => {
      render(<StatsToggle />);
      const button = screen.getByTitle('統計情報を表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「統計情報」が表示される', () => {
      render(<StatsToggle />);
      expect(screen.getByText('統計情報')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isStatsVisible: true,
          toggleStatsVisible: mockToggleStatsVisible,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleStatsVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<StatsToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleStatsVisible).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleStatsVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<StatsToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleStatsVisible).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isStatsVisible: false,
          toggleStatsVisible: mockToggleStatsVisible,
        };
        return selector(state);
      });

      render(<StatsToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
