import React from 'react';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TripleSplitLayout } from './TripleSplitLayout';

describe('TripleSplitLayout', () => {
  beforeEach(() => {
    // LocalStorageをクリア
    localStorage.clear();
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('Basic Rendering', () => {
    it('全ペインが表示される', () => {
      render(
        <TripleSplitLayout
          leftPane={<div>Left Content</div>}
          centerPane={<div>Center Content</div>}
          rightPane={<div>Right Content</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      expect(screen.getByText('Left Content')).toBeInTheDocument();
      expect(screen.getByText('Center Content')).toBeInTheDocument();
      expect(screen.getByText('Right Content')).toBeInTheDocument();
    });

    it('中央ペインのみ表示', () => {
      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center Only</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={false}
          isRightPaneVisible={false}
        />
      );

      expect(screen.queryByText('Left')).not.toBeInTheDocument();
      expect(screen.getByText('Center Only')).toBeInTheDocument();
      expect(screen.queryByText('Right')).not.toBeInTheDocument();
    });

    it('左ペインが非表示のとき、左スプリッターも非表示', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={false}
          isRightPaneVisible={true}
        />
      );

      const leftSplitter = container.querySelector('.triple-split-layout__splitter--left');
      expect(leftSplitter).not.toBeInTheDocument();
    });

    it('右ペインが非表示のとき、右スプリッターも非表示', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={false}
        />
      );

      const rightSplitter = container.querySelector('.triple-split-layout__splitter--right');
      expect(rightSplitter).not.toBeInTheDocument();
    });
  });

  describe('Splitter Rendering', () => {
    it('左スプリッターにrole="separator"が設定される', () => {
      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={false}
        />
      );

      const separator = screen.getByRole('separator', { name: /左ペインのリサイズ/ });
      expect(separator).toBeInTheDocument();
    });

    it('右スプリッターにrole="separator"が設定される', () => {
      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={false}
          isRightPaneVisible={true}
        />
      );

      const separator = screen.getByRole('separator', { name: /右ペインのリサイズ/ });
      expect(separator).toBeInTheDocument();
    });

    it('両スプリッターが表示されるとき、2つのseparatorがある', () => {
      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const separators = screen.getAllByRole('separator');
      expect(separators).toHaveLength(2);
    });
  });

  describe('LocalStorage Restoration', () => {
    it('保存された幅が復元される', () => {
      localStorage.setItem('epic_ladder_triple_split_widths', JSON.stringify({
        left: 300,
        right: 500
      }));

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const leftPane = container.querySelector('.triple-split-layout__left') as HTMLElement;
      const rightPane = container.querySelector('.triple-split-layout__right') as HTMLElement;

      expect(leftPane.style.width).toBe('300px');
      expect(rightPane.style.width).toBe('500px');
    });

    it('不正なJSON形式の場合はデフォルト幅が使用される', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      localStorage.setItem('epic_ladder_triple_split_widths', 'invalid json');

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const leftPane = container.querySelector('.triple-split-layout__left') as HTMLElement;
      const rightPane = container.querySelector('.triple-split-layout__right') as HTMLElement;

      // デフォルト値: 230px, 450px
      expect(leftPane.style.width).toBe('230px');
      expect(rightPane.style.width).toBe('450px');
      expect(consoleWarnSpy).toHaveBeenCalled();

      consoleWarnSpy.mockRestore();
    });

    it('最小値以下の値はクランプされる', () => {
      localStorage.setItem('epic_ladder_triple_split_widths', JSON.stringify({
        left: 50,  // MIN_LEFT_WIDTH (150) 以下
        right: 100 // MIN_RIGHT_WIDTH (200) 以下
      }));

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const leftPane = container.querySelector('.triple-split-layout__left') as HTMLElement;
      const rightPane = container.querySelector('.triple-split-layout__right') as HTMLElement;

      expect(leftPane.style.width).toBe('150px'); // クランプされる
      expect(rightPane.style.width).toBe('200px'); // MIN_RIGHT_WIDTH = 200 にクランプされる
    });

    it('最大値以上の値はクランプされる', () => {
      localStorage.setItem('epic_ladder_triple_split_widths', JSON.stringify({
        left: 500,  // MAX_LEFT_WIDTH (400) 以上
        right: 900  // MAX_RIGHT_WIDTH (800) 以上
      }));

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const leftPane = container.querySelector('.triple-split-layout__left') as HTMLElement;
      const rightPane = container.querySelector('.triple-split-layout__right') as HTMLElement;

      expect(leftPane.style.width).toBe('400px'); // クランプされる
      expect(rightPane.style.width).toBe('800px'); // MAX_RIGHT_WIDTH = 800 にクランプされる
    });
  });

  describe('Double Click Reset', () => {
    it('左スプリッターダブルクリックでデフォルト幅に戻る', () => {
      localStorage.setItem('epic_ladder_triple_split_widths', JSON.stringify({
        left: 300,
        right: 450
      }));

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const leftSplitter = screen.getByRole('separator', { name: /左ペインのリサイズ/ });
      fireEvent.doubleClick(leftSplitter);

      const leftPane = container.querySelector('.triple-split-layout__left') as HTMLElement;
      expect(leftPane.style.width).toBe('230px'); // DEFAULT_LEFT_WIDTH
    });

    it('右スプリッターダブルクリックでデフォルト幅に戻る', () => {
      localStorage.setItem('epic_ladder_triple_split_widths', JSON.stringify({
        left: 230,
        right: 500
      }));

      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const rightSplitter = screen.getByRole('separator', { name: /右ペインのリサイズ/ });
      fireEvent.doubleClick(rightSplitter);

      const rightPane = container.querySelector('.triple-split-layout__right') as HTMLElement;
      expect(rightPane.style.width).toBe('450px'); // DEFAULT_RIGHT_WIDTH
    });
  });

  describe('Width Change Callbacks', () => {
    it('左スプリッターダブルクリックでonLeftPaneWidthChangeが呼ばれる', () => {
      const mockCallback = vi.fn();

      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
          onLeftPaneWidthChange={mockCallback}
        />
      );

      const leftSplitter = screen.getByRole('separator', { name: /左ペインのリサイズ/ });
      fireEvent.doubleClick(leftSplitter);

      expect(mockCallback).toHaveBeenCalledWith(230);
    });

    it('右スプリッターダブルクリックでonRightPaneWidthChangeが呼ばれる', () => {
      const mockCallback = vi.fn();

      render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
          onRightPaneWidthChange={mockCallback}
        />
      );

      const rightSplitter = screen.getByRole('separator', { name: /右ペインのリサイズ/ });
      fireEvent.doubleClick(rightSplitter);

      expect(mockCallback).toHaveBeenCalledWith(450);
    });

    it('コールバックなしでもエラーにならない', () => {
      expect(() => {
        render(
          <TripleSplitLayout
            leftPane={<div>Left</div>}
            centerPane={<div>Center</div>}
            rightPane={<div>Right</div>}
            isLeftPaneVisible={true}
            isRightPaneVisible={true}
          />
        );

        const leftSplitter = screen.getByRole('separator', { name: /左ペインのリサイズ/ });
        fireEvent.doubleClick(leftSplitter);
      }).not.toThrow();
    });
  });

  describe('CSS Classes', () => {
    it('基本クラスが適用される', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={true}
        />
      );

      const layout = container.querySelector('.triple-split-layout');
      expect(layout).toBeInTheDocument();
    });

    it('左ペインにクラスが適用される', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={true}
          isRightPaneVisible={false}
        />
      );

      const leftPane = container.querySelector('.triple-split-layout__left');
      expect(leftPane).toBeInTheDocument();
    });

    it('中央ペインにクラスが適用される', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={false}
          isRightPaneVisible={false}
        />
      );

      const centerPane = container.querySelector('.triple-split-layout__center');
      expect(centerPane).toBeInTheDocument();
    });

    it('右ペインにクラスが適用される', () => {
      const { container } = render(
        <TripleSplitLayout
          leftPane={<div>Left</div>}
          centerPane={<div>Center</div>}
          rightPane={<div>Right</div>}
          isLeftPaneVisible={false}
          isRightPaneVisible={true}
        />
      );

      const rightPane = container.querySelector('.triple-split-layout__right');
      expect(rightPane).toBeInTheDocument();
    });
  });
});
