import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { SearchTab } from './SearchTab';
import { useStore } from '../../store/useStore';
import * as searchUtils from '../../utils/searchUtils';
import * as domUtils from '../../utils/domUtils';

// モック
vi.mock('../../store/useStore');
vi.mock('../../utils/searchUtils');
vi.mock('../../utils/domUtils');

describe('SearchTab', () => {
  const mockSetSelectedEntity = vi.fn();
  const mockToggleDetailPane = vi.fn();

  const mockEntities = {
    epics: {
      'epic-1': { id: 'epic-1', subject: 'ユーザー認証機能' },
    },
    features: {
      'feature-1': { id: 'feature-1', title: 'ログイン画面' },
      'feature-2': { id: 'feature-2', title: 'ログインAPI' },
    },
    user_stories: {},
    tasks: {},
    tests: {},
    bugs: {},
  };

  beforeEach(() => {
    vi.clearAllMocks();

    // Zustand ストアのモック
    vi.mocked(useStore).mockImplementation((selector: any) => {
      const state = {
        entities: mockEntities,
        setSelectedEntity: mockSetSelectedEntity,
        toggleDetailPane: mockToggleDetailPane,
        isDetailPaneVisible: false,
      };
      return selector(state);
    });

    // domUtils のモック
    vi.mocked(domUtils.scrollToIssue).mockReturnValue(true);
    vi.mocked(domUtils.highlightIssue).mockImplementation(() => {});
  });

  it('初期表示時はプレースホルダーが表示される', () => {
    render(<SearchTab />);
    expect(screen.getByText(/タイトル（subject）で検索できます/)).toBeInTheDocument();
  });

  it('検索ボタンはクエリが空の場合は無効化される', () => {
    render(<SearchTab />);
    const searchButton = screen.getByRole('button', { name: /検索/ });
    expect(searchButton).toBeDisabled();
  });

  it('クエリを入力すると検索ボタンが有効化される', () => {
    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    expect(searchButton).not.toBeDisabled();
  });

  it('検索実行時に searchAllIssues が呼ばれる', () => {
    const mockResults = [
      { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面' },
      { id: 'feature-2', type: 'feature' as const, subject: 'ログインAPI' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    expect(searchUtils.searchAllIssues).toHaveBeenCalledWith(mockEntities, 'ログイン');
  });

  it('検索結果が複数ある場合、一覧表示される', () => {
    const mockResults = [
      { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面' },
      { id: 'feature-2', type: 'feature' as const, subject: 'ログインAPI' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    expect(screen.getByText(/2件見つかりました/)).toBeInTheDocument();
    expect(screen.getByText('ログイン画面')).toBeInTheDocument();
    expect(screen.getByText('ログインAPI')).toBeInTheDocument();
  });

  it('検索結果が0件の場合、メッセージが表示される', () => {
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue([]);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: '存在しないキーワード' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    expect(screen.getByText(/該当するissueが見つかりませんでした/)).toBeInTheDocument();
  });

  it('検索結果をクリックするとスクロール&ハイライト処理が呼ばれる', () => {
    const mockResults = [
      { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    const resultItem = screen.getByText('ログイン画面');
    fireEvent.click(resultItem);

    expect(domUtils.scrollToIssue).toHaveBeenCalledWith('feature-1', 'feature');
    expect(domUtils.highlightIssue).toHaveBeenCalledWith('feature-1', 'feature');
  });

  it('検索結果クリック時にスクロール&ハイライトが実行される', () => {
    const mockResults = [
      { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);
    vi.mocked(domUtils.scrollToIssue).mockReturnValue(true);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    const resultItem = screen.getByText('ログイン画面');
    fireEvent.click(resultItem);

    // Phase 1変更: 通常のsubject検索ではDetailPaneは自動表示されない
    expect(domUtils.scrollToIssue).toHaveBeenCalledWith('feature-1', 'feature');
    expect(domUtils.highlightIssue).toHaveBeenCalledWith('feature-1', 'feature');
    expect(mockToggleDetailPane).not.toHaveBeenCalled();
    expect(mockSetSelectedEntity).not.toHaveBeenCalled();
  });

  it('クリアボタンをクリックすると検索状態がリセットされる', () => {
    const mockResults = [
      { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'ログイン' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    expect(screen.getByText(/1件見つかりました/)).toBeInTheDocument();

    const clearButton = screen.getByRole('button', { name: /✕/ });
    fireEvent.click(clearButton);

    expect(screen.queryByText(/1件見つかりました/)).not.toBeInTheDocument();
    expect(screen.getByText(/タイトル（subject）で検索できます/)).toBeInTheDocument();
  });

  it('各エンティティタイプに対応するアイコンが表示される', () => {
    const mockResults = [
      { id: 'epic-1', type: 'epic' as const, subject: 'Epic件名' },
      { id: 'feature-1', type: 'feature' as const, subject: 'Feature件名' },
      { id: 'story-1', type: 'user-story' as const, subject: 'UserStory件名' },
      { id: 'task-1', type: 'task' as const, subject: 'Task件名' },
      { id: 'test-1', type: 'test' as const, subject: 'Test件名' },
      { id: 'bug-1', type: 'bug' as const, subject: 'Bug件名' },
    ];
    vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResults);

    render(<SearchTab />);
    const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
    fireEvent.change(input, { target: { value: 'test' } });

    const searchButton = screen.getByRole('button', { name: /検索/ });
    fireEvent.click(searchButton);

    // アイコンが表示されているかは絵文字が含まれているかで確認
    expect(screen.getByText('📦')).toBeInTheDocument(); // Epic
    expect(screen.getByText('✨')).toBeInTheDocument(); // Feature
    expect(screen.getByText('📝')).toBeInTheDocument(); // UserStory
    expect(screen.getByText('✅')).toBeInTheDocument(); // Task
    expect(screen.getByText('🧪')).toBeInTheDocument(); // Test
    expect(screen.getByText('🐛')).toBeInTheDocument(); // Bug
  });

  describe('Phase 1: ID検索機能', () => {
    it('数値のみ入力時はID完全一致検索が実行される', () => {
      const mockResult = [
        { id: '101', type: 'epic' as const, subject: 'ID検索テスト用Epic', isExactIdMatch: true },
      ];
      vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResult);

      render(<SearchTab />);
      const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
      fireEvent.change(input, { target: { value: '101' } });

      const searchButton = screen.getByRole('button', { name: /検索/ });
      fireEvent.click(searchButton);

      expect(searchUtils.searchAllIssues).toHaveBeenCalledWith(mockEntities, '101');
      expect(screen.getByText(/1件見つかりました/)).toBeInTheDocument();
      expect(screen.getByText('ID検索テスト用Epic')).toBeInTheDocument();
    });

    it('ID完全一致時はDetailPane自動表示フラグがtrue', () => {
      const mockResult = [
        { id: '101', type: 'epic' as const, subject: 'ID検索テスト用Epic', isExactIdMatch: true },
      ];
      vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResult);
      vi.mocked(domUtils.scrollToIssue).mockReturnValue(true);

      render(<SearchTab />);
      const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
      fireEvent.change(input, { target: { value: '101' } });

      const searchButton = screen.getByRole('button', { name: /検索/ });
      fireEvent.click(searchButton);

      // 結果をクリック
      const resultItem = screen.getByText('ID検索テスト用Epic');
      fireEvent.click(resultItem);

      // DetailPane自動表示が呼ばれることを確認
      expect(mockToggleDetailPane).toHaveBeenCalled();
      expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', '101');
    });

    it('通常のsubject検索時はDetailPane自動表示されない', () => {
      const mockResult = [
        { id: 'feature-1', type: 'feature' as const, subject: 'ログイン画面', isExactIdMatch: false },
      ];
      vi.mocked(searchUtils.searchAllIssues).mockReturnValue(mockResult);
      vi.mocked(domUtils.scrollToIssue).mockReturnValue(true);

      render(<SearchTab />);
      const input = screen.getByPlaceholderText(/Epic\/Feature\/ストーリーを検索.../);
      fireEvent.change(input, { target: { value: 'ログイン' } });

      const searchButton = screen.getByRole('button', { name: /検索/ });
      fireEvent.click(searchButton);

      // 結果をクリック
      const resultItem = screen.getByText('ログイン画面');
      fireEvent.click(resultItem);

      // DetailPane自動表示は呼ばれない
      expect(mockToggleDetailPane).not.toHaveBeenCalled();
      expect(mockSetSelectedEntity).not.toHaveBeenCalled();
    });
  });
});
