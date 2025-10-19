import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { SearchBar } from './SearchBar';
import { useStore } from '../../store/useStore';

describe('SearchBar', () => {
  const mockToggleSideMenu = vi.fn();
  const mockSetActiveSideTab = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();

    // ストアをリセット
    useStore.setState({
      isSideMenuVisible: false,
      activeSideTab: 'list',
      toggleSideMenu: mockToggleSideMenu,
      setActiveSideTab: mockSetActiveSideTab,
    });
  });

  describe('Rendering', () => {
    it('should render search button with icon and text', () => {
      render(<SearchBar />);

      const button = screen.getByRole('button', { name: /検索/ });
      expect(button).toBeTruthy();
      expect(button.textContent).toContain('🔍 検索');
      expect(button.title).toBe('検索タブを開く');
    });

    it('should have correct button classes', () => {
      render(<SearchBar />);

      const button = screen.getByRole('button', { name: /検索/ });
      expect(button.className).toContain('eg-button');
      expect(button.className).toContain('eg-button--lg');
    });
  });

  describe('Click Behavior', () => {
    it('should open side menu and activate search tab when clicked (menu closed)', async () => {
      const user = userEvent.setup();

      useStore.setState({
        isSideMenuVisible: false,
        toggleSideMenu: mockToggleSideMenu,
        setActiveSideTab: mockSetActiveSideTab,
      });

      render(<SearchBar />);

      const button = screen.getByRole('button', { name: /検索/ });
      await user.click(button);

      expect(mockToggleSideMenu).toHaveBeenCalledTimes(1);
      expect(mockSetActiveSideTab).toHaveBeenCalledWith('search');
    });

    it('should only activate search tab when clicked (menu already open)', async () => {
      const user = userEvent.setup();

      useStore.setState({
        isSideMenuVisible: true,
        toggleSideMenu: mockToggleSideMenu,
        setActiveSideTab: mockSetActiveSideTab,
      });

      render(<SearchBar />);

      const button = screen.getByRole('button', { name: /検索/ });
      await user.click(button);

      expect(mockToggleSideMenu).not.toHaveBeenCalled();
      expect(mockSetActiveSideTab).toHaveBeenCalledWith('search');
    });

    it('should activate search tab even if already active', async () => {
      const user = userEvent.setup();

      useStore.setState({
        isSideMenuVisible: true,
        activeSideTab: 'search',
        toggleSideMenu: mockToggleSideMenu,
        setActiveSideTab: mockSetActiveSideTab,
      });

      render(<SearchBar />);

      const button = screen.getByRole('button', { name: /検索/ });
      await user.click(button);

      // タブが既にアクティブでもsetActiveSideTabは呼ばれる（フォーカス再設定のため）
      expect(mockSetActiveSideTab).toHaveBeenCalledWith('search');
    });
  });
});
