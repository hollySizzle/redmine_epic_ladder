import React from 'react';
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { VersionStatsToggle } from './VersionStatsToggle';
import { useStore } from '../../store/useStore';

describe('VersionStatsToggle', () => {
  beforeEach(() => {
    // localStorageをクリア
    localStorage.clear();
    // ストアをリセット（デフォルトはfalse）
    useStore.setState({
      isVersionStatsVisible: false,
    });
  });

  describe('Rendering', () => {
    it('should render toggle button', () => {
      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('should have active class when visible', () => {
      useStore.setState({ isVersionStatsVisible: true });
      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveClass('eg-button--active');
    });

    it('should not have active class when hidden (default)', () => {
      // デフォルトはfalseなのでそのまま
      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');
      expect(button).not.toHaveClass('eg-button--active');
    });
  });

  describe('Toggle Behavior', () => {
    it('should toggle visibility on click', async () => {
      const user = userEvent.setup();
      // デフォルトはfalse

      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');

      // 初期状態: OFF
      expect(useStore.getState().isVersionStatsVisible).toBe(false);

      // クリックで ON
      await user.click(button);
      expect(useStore.getState().isVersionStatsVisible).toBe(true);

      // 再クリックで OFF
      await user.click(button);
      expect(useStore.getState().isVersionStatsVisible).toBe(false);
    });

    it('should persist state to localStorage', async () => {
      const user = userEvent.setup();
      // デフォルトはfalse

      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');

      // クリックで ON
      await user.click(button);
      expect(localStorage.getItem('kanban_version_stats_visible')).toBe('true');

      // 再クリックで OFF
      await user.click(button);
      expect(localStorage.getItem('kanban_version_stats_visible')).toBe('false');
    });
  });

  describe('Title Attribute', () => {
    it('should show hide message when visible', () => {
      useStore.setState({ isVersionStatsVisible: true });
      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('title', 'バージョン統計を非表示');
    });

    it('should show display message when hidden', () => {
      useStore.setState({ isVersionStatsVisible: false });
      render(<VersionStatsToggle />);
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('title', 'バージョン統計を表示');
    });
  });
});
