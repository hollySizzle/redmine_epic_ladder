import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TabBar, Tab, TabId } from './TabBar';

const mockTabs: Tab[] = [
  { id: 'search', label: '検索', icon: '🔍' },
  { id: 'list', label: '一覧', icon: '📋' },
  { id: 'about', label: 'About', icon: 'ℹ️' },
];

describe('TabBar', () => {
  it('すべてのタブが表示される', () => {
    const mockOnTabChange = vi.fn();
    render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    expect(screen.getByText('検索')).toBeInTheDocument();
    expect(screen.getByText('一覧')).toBeInTheDocument();
    expect(screen.getByText('About')).toBeInTheDocument();
  });

  it('タブのアイコンが表示される', () => {
    const mockOnTabChange = vi.fn();
    render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    expect(screen.getByText('🔍')).toBeInTheDocument();
    expect(screen.getByText('📋')).toBeInTheDocument();
    expect(screen.getByText('ℹ️')).toBeInTheDocument();
  });

  it('アクティブなタブにアクティブクラスが適用される', () => {
    const mockOnTabChange = vi.fn();
    const { container } = render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    const buttons = container.querySelectorAll('.tab-bar__tab');
    expect(buttons[0]).toHaveClass('tab-bar__tab--active');
    expect(buttons[1]).not.toHaveClass('tab-bar__tab--active');
    expect(buttons[2]).not.toHaveClass('tab-bar__tab--active');
  });

  it('タブクリックでonTabChangeが呼ばれる', () => {
    const mockOnTabChange = vi.fn();
    render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    fireEvent.click(screen.getByText('一覧'));
    expect(mockOnTabChange).toHaveBeenCalledWith('list');

    fireEvent.click(screen.getByText('About'));
    expect(mockOnTabChange).toHaveBeenCalledWith('about');
  });

  it('onClose未指定時はクローズボタンが表示されない', () => {
    const mockOnTabChange = vi.fn();
    const { container } = render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    expect(container.querySelector('.tab-bar__close-button')).not.toBeInTheDocument();
  });

  it('onClose指定時はクローズボタンが表示される', () => {
    const mockOnTabChange = vi.fn();
    const mockOnClose = vi.fn();
    render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} onClose={mockOnClose} />);

    expect(screen.getByTitle('サイドメニューを閉じる')).toBeInTheDocument();
    expect(screen.getByLabelText('サイドメニューを閉じる')).toBeInTheDocument();
  });

  it('クローズボタンクリックでonCloseが呼ばれる', () => {
    const mockOnTabChange = vi.fn();
    const mockOnClose = vi.fn();
    render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} onClose={mockOnClose} />);

    fireEvent.click(screen.getByTitle('サイドメニューを閉じる'));
    expect(mockOnClose).toHaveBeenCalledTimes(1);
  });

  it('aria属性が正しく設定される', () => {
    const mockOnTabChange = vi.fn();
    const { container } = render(<TabBar tabs={mockTabs} activeTab="list" onTabChange={mockOnTabChange} />);

    const buttons = container.querySelectorAll('[role="tab"]');
    expect(buttons).toHaveLength(3);

    expect(buttons[0]).toHaveAttribute('aria-selected', 'false');
    expect(buttons[1]).toHaveAttribute('aria-selected', 'true');
    expect(buttons[2]).toHaveAttribute('aria-selected', 'false');
  });

  it('正しいクラス名が適用されている', () => {
    const mockOnTabChange = vi.fn();
    const { container } = render(<TabBar tabs={mockTabs} activeTab="search" onTabChange={mockOnTabChange} />);

    expect(container.querySelector('.tab-bar')).toBeInTheDocument();
    expect(container.querySelector('.tab-bar__tabs')).toBeInTheDocument();
    expect(container.querySelector('.tab-bar__tab')).toBeInTheDocument();
    expect(container.querySelector('.tab-bar__icon')).toBeInTheDocument();
    expect(container.querySelector('.tab-bar__label')).toBeInTheDocument();
  });
});
