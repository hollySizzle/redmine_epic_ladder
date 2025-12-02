import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DetailPaneToggle } from './DetailPaneToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('DetailPaneToggle', () => {
  const mockToggleDetailPane = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - DetailPane Visible', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDetailPaneVisible: true,
          toggleDetailPane: mockToggleDetailPane,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('非表示用のタイトルが表示される', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByTitle('Issue詳細を非表示');
      expect(button).toBeInTheDocument();
    });

    it('非表示用のラベルテキストが表示される', () => {
      render(<DetailPaneToggle />);
      expect(screen.getByText('Issue詳細を非表示')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<DetailPaneToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - DetailPane Hidden', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDetailPaneVisible: false,
          toggleDetailPane: mockToggleDetailPane,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('表示用のタイトルが表示される', () => {
      render(<DetailPaneToggle />);
      const button = screen.getByTitle('Issue詳細を表示');
      expect(button).toBeInTheDocument();
    });

    it('表示用のラベルテキストが表示される', () => {
      render(<DetailPaneToggle />);
      expect(screen.getByText('Issue詳細を表示')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDetailPaneVisible: true,
          toggleDetailPane: mockToggleDetailPane,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleDetailPaneが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<DetailPaneToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleDetailPane).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleDetailPaneが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<DetailPaneToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleDetailPane).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isDetailPaneVisible: false,
          toggleDetailPane: mockToggleDetailPane,
        };
        return selector(state);
      });

      render(<DetailPaneToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
