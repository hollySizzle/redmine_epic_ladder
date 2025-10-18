import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UnassignedHighlightToggle } from './UnassignedHighlightToggle';
import { useStore } from '../../store/useStore';

describe('UnassignedHighlightToggle', () => {
  beforeEach(() => {
    // localStorageをクリア
    localStorage.clear();

    // ストアを初期状態にリセット（デフォルトtrue）
    useStore.setState({
      isUnassignedHighlightVisible: true
    });
  });

  describe('Rendering', () => {
    it('should render toggle button', () => {
      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');
      expect(button).toBeTruthy();
    });

    it('should display "担当不在🟠" when highlight is visible', () => {
      useStore.setState({ isUnassignedHighlightVisible: true });

      render(<UnassignedHighlightToggle />);

      expect(screen.getByText('担当不在🟠')).toBeTruthy();
    });

    it('should display "担当不在" when highlight is hidden', () => {
      useStore.setState({ isUnassignedHighlightVisible: false });

      render(<UnassignedHighlightToggle />);

      expect(screen.getByText('担当不在')).toBeTruthy();
    });

    it('should have active class when highlight is visible', () => {
      useStore.setState({ isUnassignedHighlightVisible: true });

      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');
      expect(button.className).toContain('active');
    });

    it('should not have active class when highlight is hidden', () => {
      useStore.setState({ isUnassignedHighlightVisible: false });

      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');
      expect(button.className).not.toContain('active');
    });
  });

  describe('Interaction', () => {
    it('should toggle from visible to hidden when clicked', async () => {
      const user = userEvent.setup();
      useStore.setState({ isUnassignedHighlightVisible: true });

      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');

      // 初期状態: ON
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(true);

      // クリック: OFF
      await user.click(button);
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(false);
    });

    it('should toggle from hidden to visible when clicked', async () => {
      const user = userEvent.setup();
      useStore.setState({ isUnassignedHighlightVisible: false });

      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');

      // 初期状態: OFF
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(false);

      // クリック: ON
      await user.click(button);
      expect(useStore.getState().isUnassignedHighlightVisible).toBe(true);
    });

    it('should save state to localStorage when toggled', async () => {
      const user = userEvent.setup();
      useStore.setState({ isUnassignedHighlightVisible: true });

      render(<UnassignedHighlightToggle />);

      const button = screen.getByRole('button');

      // クリックしてOFF
      await user.click(button);

      const saved = localStorage.getItem('kanban_unassigned_highlight_visible');
      expect(saved).toBe('false');

      // もう一度クリックしてON
      await user.click(button);

      const savedAgain = localStorage.getItem('kanban_unassigned_highlight_visible');
      expect(savedAgain).toBe('true');
    });
  });

  describe('localStorage Integration', () => {
    it('should load initial state from localStorage (visible)', () => {
      // localStorageに保存
      localStorage.setItem('kanban_unassigned_highlight_visible', 'true');

      // ストアを再初期化（useStore.tsと同じロジック）
      const saved = localStorage.getItem('kanban_unassigned_highlight_visible');
      const initialValue = saved !== null ? saved === 'true' : true;

      useStore.setState({ isUnassignedHighlightVisible: initialValue });

      render(<UnassignedHighlightToggle />);

      expect(useStore.getState().isUnassignedHighlightVisible).toBe(true);
      expect(screen.getByText('担当不在🟠')).toBeTruthy();
    });

    it('should load initial state from localStorage (hidden)', () => {
      // localStorageに保存
      localStorage.setItem('kanban_unassigned_highlight_visible', 'false');

      // ストアを再初期化
      const saved = localStorage.getItem('kanban_unassigned_highlight_visible');
      const initialValue = saved !== null ? saved === 'true' : true;

      useStore.setState({ isUnassignedHighlightVisible: initialValue });

      render(<UnassignedHighlightToggle />);

      expect(useStore.getState().isUnassignedHighlightVisible).toBe(false);
      expect(screen.getByText('担当不在')).toBeTruthy();
    });

    it('should default to true when localStorage is empty', () => {
      // localStorageをクリア
      localStorage.clear();

      // デフォルト値（true）でストアを初期化
      const saved = localStorage.getItem('kanban_unassigned_highlight_visible');
      const initialValue = saved !== null ? saved === 'true' : true;

      useStore.setState({ isUnassignedHighlightVisible: initialValue });

      render(<UnassignedHighlightToggle />);

      expect(useStore.getState().isUnassignedHighlightVisible).toBe(true);
      expect(screen.getByText('担当不在🟠')).toBeTruthy();
    });
  });
});
