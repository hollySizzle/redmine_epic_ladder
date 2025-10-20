import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { SidePanel } from './SidePanel';
import { useStore } from '../../store/useStore';

vi.mock('../../store/useStore');

describe('SidePanel', () => {
  const mockToggleSideMenu = vi.fn();
  const mockSetActiveSideTab = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        toggleSideMenu: mockToggleSideMenu,
        activeSideTab: 'search' as const,
        setActiveSideTab: mockSetActiveSideTab,
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: {
          index: {},
          epic_order: [],
          feature_order_by_epic: {},
          version_order: []
        }
      };
      return selector(state);
    });
  });

  it('TabBarとタブコンテンツが表示される', () => {
    render(<SidePanel />);

    // TabBarのタブが表示される
    expect(screen.getByText('検索')).toBeInTheDocument();
    expect(screen.getByText('一覧')).toBeInTheDocument();
    expect(screen.getByText('About')).toBeInTheDocument();

    // デフォルトで検索タブのコンテンツが表示される
    expect(screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索/)).toBeInTheDocument();
  });

  it('activeSideTabが"list"の場合、ListTabが表示される', () => {
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        toggleSideMenu: mockToggleSideMenu,
        activeSideTab: 'list' as const,
        setActiveSideTab: mockSetActiveSideTab,
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: {
          index: {},
          epic_order: [],
          feature_order_by_epic: {},
          version_order: []
        },
        epicSortOptions: {
          sort_by: 'subject',
          sort_direction: 'asc'
        }
      };
      return selector(state);
    });

    render(<SidePanel />);

    expect(screen.getByText('Epic / Feature 一覧')).toBeInTheDocument();
    // ListTabは空のEpicリストを表示
    expect(screen.getByText('📭 Epicがありません')).toBeInTheDocument();
  });

  it('activeSideTabが"about"の場合、AboutTabが表示される', () => {
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        toggleSideMenu: mockToggleSideMenu,
        activeSideTab: 'about' as const,
        setActiveSideTab: mockSetActiveSideTab,
      };
      return selector(state);
    });

    render(<SidePanel />);

    expect(screen.getByText('Epic Grid Plugin')).toBeInTheDocument();
    expect(screen.getByText('Version 1.0.0')).toBeInTheDocument();
  });

  it('タブクリックでsetActiveSideTabが呼ばれる', () => {
    render(<SidePanel />);

    fireEvent.click(screen.getByText('一覧'));
    expect(mockSetActiveSideTab).toHaveBeenCalledWith('list');

    fireEvent.click(screen.getByText('About'));
    expect(mockSetActiveSideTab).toHaveBeenCalledWith('about');
  });

  it('クローズボタンクリックでtoggleSideMenuが呼ばれる', () => {
    render(<SidePanel />);

    fireEvent.click(screen.getByTitle('サイドメニューを閉じる'));
    expect(mockToggleSideMenu).toHaveBeenCalledTimes(1);
  });

  it('正しいクラス名が適用されている', () => {
    const { container } = render(<SidePanel />);

    expect(container.querySelector('.side-panel')).toBeInTheDocument();
    expect(container.querySelector('.side-panel__content')).toBeInTheDocument();
  });

  it('不正なactiveSideTab値の場合、デフォルトでListTabが表示される', () => {
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        toggleSideMenu: mockToggleSideMenu,
        activeSideTab: 'invalid' as any,
        setActiveSideTab: mockSetActiveSideTab,
        entities: {
          epics: {},
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: {
          index: {},
          epic_order: [],
          feature_order_by_epic: {},
          version_order: []
        },
        epicSortOptions: {
          sort_by: 'subject',
          sort_direction: 'asc'
        }
      };
      return selector(state);
    });

    render(<SidePanel />);

    // default caseでListTabが表示される
    expect(screen.getByText('Epic / Feature 一覧')).toBeInTheDocument();
    expect(screen.getByText('📭 Epicがありません')).toBeInTheDocument();
  });
});
