import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ListTab } from './ListTab';
import { useStore } from '../../store/useStore';
import * as domUtils from '../../utils/domUtils';

// モック
vi.mock('../../store/useStore');
vi.mock('../../utils/domUtils');

describe('ListTab', () => {
  const mockEntities = {
    epics: {
      'epic-1': {
        id: 'epic-1',
        subject: 'ユーザー認証機能',
        feature_ids: ['feature-1', 'feature-2'],
        statistics: {
          total_features: 2,
          completed_features: 1,
          total_user_stories: 5,
          total_child_items: 10,
          completion_percentage: 50
        }
      },
      'epic-2': {
        id: 'epic-2',
        subject: '管理画面',
        feature_ids: ['feature-3'],
        statistics: {
          total_features: 1,
          completed_features: 0,
          total_user_stories: 3,
          total_child_items: 6,
          completion_percentage: 0
        }
      }
    },
    features: {
      'feature-1': {
        id: 'feature-1',
        subject: 'ログイン画面',
        parent_epic_id: 'epic-1',
        statistics: {
          total_user_stories: 3,
          completed_user_stories: 2,
          completion_percentage: 66.7
        }
      },
      'feature-2': {
        id: 'feature-2',
        subject: 'ログインAPI',
        parent_epic_id: 'epic-1',
        statistics: {
          total_user_stories: 2,
          completed_user_stories: 1,
          completion_percentage: 50
        }
      },
      'feature-3': {
        id: 'feature-3',
        subject: 'ユーザー管理',
        parent_epic_id: 'epic-2',
        statistics: {
          total_user_stories: 3,
          completed_user_stories: 0,
          completion_percentage: 0
        }
      }
    },
    versions: {},
    user_stories: {},
    tasks: {},
    tests: {},
    bugs: {},
    users: {}
  };

  const mockGrid = {
    epic_order: ['epic-1', 'epic-2'],
    version_order: [],
    feature_order_by_epic: {
      'epic-1': ['feature-1', 'feature-2'],
      'epic-2': ['feature-3']
    },
    index: {}
  };

  beforeEach(() => {
    vi.clearAllMocks();

    // Zustand ストアのモック
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        entities: mockEntities,
        grid: mockGrid,
        isStatsVisible: true,
        epicSortOptions: {
          sort_by: 'subject',
          sort_direction: 'asc'
        }
      };
      return selector(state);
    });

    // domUtils のモック
    vi.mocked(domUtils.scrollToIssue).mockReturnValue(true);
    vi.mocked(domUtils.highlightIssue).mockImplementation(() => {});
    vi.mocked(domUtils.enableFocusMode).mockImplementation(() => {});
    vi.mocked(domUtils.expandParentUserStory).mockImplementation(() => {});
  });

  it('タイトルが表示される', () => {
    render(<ListTab />);
    expect(screen.getByText('Epic / Feature 一覧')).toBeInTheDocument();
  });

  it('Epicの数が表示される', () => {
    render(<ListTab />);
    expect(screen.getByText('2個のEpic')).toBeInTheDocument();
  });

  it('Epic階層ツリーが<details>/<summary>で表示される', () => {
    const { container } = render(<ListTab />);

    // <details>要素が存在
    const detailsElements = container.querySelectorAll('.list-tab__epic-details');
    expect(detailsElements.length).toBe(2);

    // Epic1
    expect(screen.getByText('ユーザー認証機能')).toBeInTheDocument();
    expect(screen.getByText('2件のFeature ・ 50%完了')).toBeInTheDocument();

    // Epic2
    expect(screen.getByText('管理画面')).toBeInTheDocument();
    expect(screen.getByText('1件のFeature ・ 0%完了')).toBeInTheDocument();
  });

  it('デフォルトで全Epicが展開状態（open属性）', () => {
    const { container } = render(<ListTab />);

    const detailsElements = container.querySelectorAll('.list-tab__epic-details');
    detailsElements.forEach((details) => {
      expect(details).toHaveAttribute('open');
    });
  });

  it('Feature一覧が階層的に表示される', () => {
    render(<ListTab />);

    // Epic1のFeature
    expect(screen.getByText('ログイン画面')).toBeInTheDocument();
    expect(screen.getByText('3件のストーリー ・ 67%完了')).toBeInTheDocument();
    expect(screen.getByText('ログインAPI')).toBeInTheDocument();
    expect(screen.getByText('2件のストーリー ・ 50%完了')).toBeInTheDocument();

    // Epic2のFeature
    expect(screen.getByText('ユーザー管理')).toBeInTheDocument();
    expect(screen.getByText('3件のストーリー ・ 0%完了')).toBeInTheDocument();
  });

  it('Epicタイトルクリック時にスクロール＆ハイライトが実行される（折りたたみはしない）', () => {
    render(<ListTab />);

    const epicContentElement = screen.getByText('ユーザー認証機能').closest('.list-tab__epic-content');
    expect(epicContentElement).not.toBeNull();

    fireEvent.click(epicContentElement!);

    expect(domUtils.expandParentUserStory).toHaveBeenCalledWith('epic-1', 'epic');
    expect(domUtils.scrollToIssue).toHaveBeenCalledWith('epic-1', 'epic');
    expect(domUtils.enableFocusMode).toHaveBeenCalledWith('epic-1', 'epic');
    expect(domUtils.highlightIssue).toHaveBeenCalledWith('epic-1', 'epic');
  });

  it('Featureクリック時にスクロール＆ハイライトが実行される', () => {
    render(<ListTab />);

    const featureElement = screen.getByText('ログイン画面').closest('.list-tab__feature-item');
    expect(featureElement).not.toBeNull();

    fireEvent.click(featureElement!);

    expect(domUtils.expandParentUserStory).toHaveBeenCalledWith('feature-1', 'feature');
    expect(domUtils.scrollToIssue).toHaveBeenCalledWith('feature-1', 'feature');
    expect(domUtils.enableFocusMode).toHaveBeenCalledWith('feature-1', 'feature');
    expect(domUtils.highlightIssue).toHaveBeenCalledWith('feature-1', 'feature');
  });

  it('Epicがない場合は空メッセージが表示される', () => {
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        entities: {
          epics: {},
          features: {},
          versions: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {},
        },
        grid: {
          epic_order: [],
          feature_order_by_epic: {}
        },
        isStatsVisible: true,
        epicSortOptions: {
          sort_by: 'subject',
          sort_direction: 'asc'
        }
      };
      return selector(state);
    });

    render(<ListTab />);
    expect(screen.getByText('📭 Epicがありません')).toBeInTheDocument();
  });

  it('Featureがない場合でもEpicが表示される', () => {
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        entities: {
          epics: {
            'epic-no-features': {
              id: 'epic-no-features',
              subject: 'Featureなし Epic',
              feature_ids: [],
              statistics: {
                total_features: 0,
                completed_features: 0,
                total_user_stories: 0,
                total_child_items: 0,
                completion_percentage: 0
              }
            }
          },
          features: {},
          versions: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: {
          epic_order: ['epic-no-features'],
          version_order: [],
          feature_order_by_epic: {
            'epic-no-features': []
          },
          index: {}
        },
        isStatsVisible: true,
        epicSortOptions: {
          sort_by: 'subject',
          sort_direction: 'asc'
        }
      };
      return selector(state);
    });

    render(<ListTab />);
    expect(screen.getByText('Featureなし Epic')).toBeInTheDocument();
  });

  it('正しいクラス名とHTML構造が適用されている', () => {
    const { container } = render(<ListTab />);

    expect(container.querySelector('.list-tab')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__header')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__title')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__subtitle')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__content')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__tree')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__epic-details')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__epic-summary')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__epic-marker')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__epic-content')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__features')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__feature-item')).toBeInTheDocument();
  });

  it('スクロール失敗時は警告ログが出力される', () => {
    const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.mocked(domUtils.scrollToIssue).mockReturnValue(false);

    render(<ListTab />);

    const epicContentElement = screen.getByText('ユーザー認証機能').closest('.list-tab__epic-content');
    fireEvent.click(epicContentElement!);

    expect(consoleWarnSpy).toHaveBeenCalledWith('⚠️ Epic DOM element not found: epic-1');
    expect(domUtils.enableFocusMode).not.toHaveBeenCalled();
    expect(domUtils.highlightIssue).not.toHaveBeenCalled();

    consoleWarnSpy.mockRestore();
  });

  it('マーカー(📦)が表示される', () => {
    const { container } = render(<ListTab />);

    const markers = container.querySelectorAll('.list-tab__epic-marker');
    expect(markers.length).toBe(2);

    markers.forEach((marker) => {
      expect(marker.textContent).toBe('📦');
    });
  });

  describe('検索機能', () => {
    it('検索入力欄が表示される', () => {
      render(<ListTab />);
      const searchInput = screen.getByPlaceholderText('Epic / Feature を検索...');
      expect(searchInput).toBeInTheDocument();
    });

    it('検索クエリでEpicをフィルタリングできる', () => {
      render(<ListTab />);
      const searchInput = screen.getByPlaceholderText('Epic / Feature を検索...');

      // 「認証」で検索
      fireEvent.change(searchInput, { target: { value: '認証' } });

      // Epic1のみ表示される
      expect(screen.getByText('ユーザー認証機能')).toBeInTheDocument();
      expect(screen.queryByText('管理画面')).not.toBeInTheDocument();
    });

    it('検索クエリでFeatureをフィルタリングできる', () => {
      render(<ListTab />);
      const searchInput = screen.getByPlaceholderText('Epic / Feature を検索...');

      // 「ログイン」で検索
      fireEvent.change(searchInput, { target: { value: 'ログイン' } });

      // Epic1は表示される（配下にマッチするFeatureがある）
      expect(screen.getByText('ユーザー認証機能')).toBeInTheDocument();
      // Epic2は表示されない
      expect(screen.queryByText('管理画面')).not.toBeInTheDocument();
      // マッチするFeatureのみ表示
      expect(screen.getByText('ログイン画面')).toBeInTheDocument();
      expect(screen.getByText('ログインAPI')).toBeInTheDocument();
    });

    it('クリアボタンをクリックすると検索がリセットされる', () => {
      render(<ListTab />);
      const searchInput = screen.getByPlaceholderText('Epic / Feature を検索...');

      // 検索実行
      fireEvent.change(searchInput, { target: { value: '認証' } });
      expect(searchInput).toHaveValue('認証');

      // クリアボタンをクリック
      const clearButton = screen.getByTitle('検索をクリア');
      fireEvent.click(clearButton);

      // 検索がクリアされる
      expect(searchInput).toHaveValue('');
      // すべてのEpicが再表示される
      expect(screen.getByText('ユーザー認証機能')).toBeInTheDocument();
      expect(screen.getByText('管理画面')).toBeInTheDocument();
    });

    it('検索結果が0件の場合は空メッセージが表示される', () => {
      render(<ListTab />);
      const searchInput = screen.getByPlaceholderText('Epic / Feature を検索...');

      // マッチしない検索
      fireEvent.change(searchInput, { target: { value: 'xxxxx' } });

      expect(screen.getByText('📭 Epicがありません')).toBeInTheDocument();
    });
  });
});
