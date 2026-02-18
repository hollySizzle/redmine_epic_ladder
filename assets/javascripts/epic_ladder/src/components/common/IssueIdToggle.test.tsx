import React from 'react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { IssueIdToggle } from './IssueIdToggle';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('IssueIdToggle', () => {
  const mockToggleIssueIdVisible = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering - IssueId Visible', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isIssueIdVisible: true,
          toggleIssueIdVisible: mockToggleIssueIdVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<IssueIdToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用される', () => {
      render(<IssueIdToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('非表示用のタイトルが表示される', () => {
      render(<IssueIdToggle />);
      const button = screen.getByTitle('チケットIDを非表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「チケットID」が表示される', () => {
      render(<IssueIdToggle />);
      expect(screen.getByText('チケットID')).toBeInTheDocument();
    });

    it('SVGアイコンが表示される', () => {
      const { container } = render(<IssueIdToggle />);
      const svg = container.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('Rendering - IssueId Hidden', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isIssueIdVisible: false,
          toggleIssueIdVisible: mockToggleIssueIdVisible,
        };
        return selector(state);
      });
    });

    it('ボタンが表示される', () => {
      render(<IssueIdToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('activeクラスが適用されない', () => {
      render(<IssueIdToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });

    it('表示用のタイトルが表示される', () => {
      render(<IssueIdToggle />);
      const button = screen.getByTitle('チケットIDを表示');
      expect(button).toBeInTheDocument();
    });

    it('ラベルテキスト「チケットID」が表示される', () => {
      render(<IssueIdToggle />);
      expect(screen.getByText('チケットID')).toBeInTheDocument();
    });
  });

  describe('Interaction', () => {
    beforeEach(() => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isIssueIdVisible: true,
          toggleIssueIdVisible: mockToggleIssueIdVisible,
        };
        return selector(state);
      });
    });

    it('クリックでtoggleIssueIdVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<IssueIdToggle />);

      const button = screen.getByRole('button');
      await user.click(button);

      expect(mockToggleIssueIdVisible).toHaveBeenCalledTimes(1);
    });

    it('複数回クリックで複数回toggleIssueIdVisibleが呼ばれる', async () => {
      const user = userEvent.setup();
      render(<IssueIdToggle />);

      const button = screen.getByRole('button');
      await user.click(button);
      await user.click(button);
      await user.click(button);

      expect(mockToggleIssueIdVisible).toHaveBeenCalledTimes(3);
    });
  });

  describe('CSS Classes', () => {
    it('共通のCSSクラスが適用される', () => {
      vi.mocked(useStore).mockImplementation((selector: any) => {
        const state = {
          isIssueIdVisible: false,
          toggleIssueIdVisible: mockToggleIssueIdVisible,
        };
        return selector(state);
      });

      render(<IssueIdToggle />);
      const button = screen.getByRole('button');

      expect(button).toHaveClass('eg-button');
      expect(button).toHaveClass('eg-button--toggle');
    });
  });
});
