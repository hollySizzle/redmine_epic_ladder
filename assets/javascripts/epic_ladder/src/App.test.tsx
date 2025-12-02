import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { App } from './App';
import { useStore } from './store/useStore';

// Mock子コンポーネント
vi.mock('./components/EpicVersion/EpicVersionGrid', () => ({
  EpicVersionGrid: () => <div data-testid="epic-version-grid">EpicVersionGrid</div>
}));

vi.mock('./components/FilterPanel', () => ({
  FilterPanel: () => <div data-testid="filter-panel">FilterPanel</div>
}));

vi.mock('./components/IssueDetail/DetailPane', () => ({
  DetailPane: () => <div data-testid="detail-pane">DetailPane</div>
}));

vi.mock('./components/Layout/TripleSplitLayout', () => ({
  TripleSplitLayout: ({ centerPane, leftPane, rightPane, isLeftPaneVisible, isRightPaneVisible }: any) => (
    <div data-testid="triple-split-layout">
      {isLeftPaneVisible && <div data-testid="left-pane">{leftPane}</div>}
      <div data-testid="center-pane">{centerPane}</div>
      {isRightPaneVisible && <div data-testid="right-pane">{rightPane}</div>}
    </div>
  )
}));

vi.mock('./components/SidePanel/SidePanel', () => ({
  SidePanel: () => <div data-testid="side-panel">SidePanel</div>
}));

vi.mock('./components/Legend', () => ({
  Legend: () => <div data-testid="legend">Legend</div>
}));

vi.mock('./components/common/SearchBar', () => ({
  SearchBar: () => <div data-testid="search-bar">SearchBar</div>
}));

vi.mock('./components/common/SettingsDropdown', () => ({
  SettingsDropdown: () => <div data-testid="settings-dropdown">SettingsDropdown</div>
}));

vi.mock('./components/common/UnassignedHighlightToggle', () => ({
  UnassignedHighlightToggle: () => <div data-testid="unassigned-highlight-toggle">UnassignedHighlightToggle</div>
}));

vi.mock('./components/common/UserStoryChildrenToggle', () => ({
  UserStoryChildrenToggle: () => <div data-testid="user-story-children-toggle">UserStoryChildrenToggle</div>
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
  monitorForElements: vi.fn(() => vi.fn())
}));

describe('App', () => {
  const mockFetchGridData = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();

    // デフォルトのstore状態をモック
    useStore.setState({
      fetchGridData: mockFetchGridData,
      isLoading: false,
      error: null,
      projectId: '1',
      selectedEntity: null,
      isDetailPaneVisible: false,
      isSideMenuVisible: false,
      toggleSideMenu: vi.fn(),
      isVerticalMode: false,
      isDirty: false,
      pendingChanges: {
        movedUserStories: [],
        reorderedEpics: null,
        reorderedVersions: null,
      },
      savePendingChanges: vi.fn(),
      discardPendingChanges: vi.fn(),
      reorderFeatures: vi.fn(),
      reorderUserStories: vi.fn(),
      moveUserStoryToCell: vi.fn(),
      reorderTasks: vi.fn(),
      reorderTests: vi.fn(),
      reorderBugs: vi.fn(),
      reorderEpics: vi.fn(),
      reorderVersions: vi.fn(),
    });

    // Mock getElementById
    const mockElement = document.createElement('div');
    mockElement.setAttribute('data-project-id', '123');
    vi.spyOn(document, 'getElementById').mockReturnValue(mockElement);
  });

  describe('Loading State', () => {
    it('should render loading state when isLoading is true', () => {
      useStore.setState({ isLoading: true });

      render(<App />);

      expect(screen.getByText('Loading grid data...')).toBeInTheDocument();
    });
  });

  describe('Error State', () => {
    it('should render error state when error exists', () => {
      useStore.setState({ error: 'Network error' });

      render(<App />);

      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
    });
  });

  describe('Normal Rendering', () => {
    it('should render main components', () => {
      render(<App />);

      expect(screen.getByTestId('epic-version-grid')).toBeInTheDocument();
      expect(screen.getByTestId('filter-panel')).toBeInTheDocument();
      expect(screen.getByTestId('search-bar')).toBeInTheDocument();
      expect(screen.getByTestId('legend')).toBeInTheDocument();
    });

    it('should render menu toggle button', () => {
      render(<App />);

      expect(screen.getByTitle('サイドメニューを開く')).toBeInTheDocument();
    });

    it('should render fullscreen mode when no panes visible', () => {
      useStore.setState({
        isSideMenuVisible: false,
        isDetailPaneVisible: false,
      });

      const { container } = render(<App />);

      expect(container.querySelector('.kanban-fullscreen')).toBeInTheDocument();
      expect(screen.queryByTestId('triple-split-layout')).not.toBeInTheDocument();
    });

    it('should render triple split layout when side menu visible', () => {
      useStore.setState({ isSideMenuVisible: true });

      render(<App />);

      expect(screen.getByTestId('triple-split-layout')).toBeInTheDocument();
      expect(screen.getByTestId('side-panel')).toBeInTheDocument();
    });

    it('should render triple split layout when detail pane visible', () => {
      useStore.setState({ isDetailPaneVisible: true });

      render(<App />);

      expect(screen.getByTestId('triple-split-layout')).toBeInTheDocument();
      expect(screen.getByTestId('detail-pane')).toBeInTheDocument();
    });
  });

  describe('Data Fetching', () => {
    it('should fetch grid data on mount', async () => {
      render(<App />);

      await waitFor(() => {
        expect(mockFetchGridData).toHaveBeenCalledWith('123');
      });
    });

    it('should use default project id if data-project-id not found', async () => {
      vi.spyOn(document, 'getElementById').mockReturnValue(document.createElement('div'));

      render(<App />);

      await waitFor(() => {
        expect(mockFetchGridData).toHaveBeenCalledWith('1');
      });
    });
  });

  describe('Dirty State', () => {
    it('should show save/discard buttons when dirty', () => {
      useStore.setState({
        isDirty: true,
        pendingChanges: {
          movedUserStories: [{ id: '1' }],
          reorderedEpics: null,
          reorderedVersions: null,
        },
      });

      render(<App />);

      expect(screen.getByText(/💾 保存/)).toBeInTheDocument();
      expect(screen.getByText('✖ 破棄')).toBeInTheDocument();
    });

    it('should show changes count in save button', () => {
      useStore.setState({
        isDirty: true,
        pendingChanges: {
          movedUserStories: [{ id: '1' }, { id: '2' }],
          reorderedEpics: { order: [] },
          reorderedVersions: null,
        },
      });

      render(<App />);

      expect(screen.getByText('💾 保存 (3件)')).toBeInTheDocument();
    });

    it('should not show save/discard buttons when not dirty', () => {
      useStore.setState({ isDirty: false });

      render(<App />);

      expect(screen.queryByText(/💾 保存/)).not.toBeInTheDocument();
      expect(screen.queryByText('✖ 破棄')).not.toBeInTheDocument();
    });
  });

  describe('Save/Discard Actions', () => {
    beforeEach(() => {
      useStore.setState({
        isDirty: true,
        pendingChanges: {
          movedUserStories: [{ id: '1' }],
          reorderedEpics: null,
          reorderedVersions: null
        },
        savePendingChanges: vi.fn(),
        discardPendingChanges: vi.fn(),
        fetchGridData: mockFetchGridData,
        isLoading: false,
        error: null,
        projectId: '123'
      });
    });

    it('should call savePendingChanges when save button clicked', async () => {
      const mockSave = vi.fn().mockResolvedValue(undefined);
      const mockAlert = vi.spyOn(window, 'alert').mockImplementation(() => {});
      useStore.setState({ savePendingChanges: mockSave });

      render(<App />);

      const saveButton = screen.getByText(/💾 保存/);
      saveButton.click();

      await waitFor(() => {
        expect(mockSave).toHaveBeenCalled();
      });

      expect(mockAlert).toHaveBeenCalledWith('✅ 変更を保存しました');
      mockAlert.mockRestore();
    });

    it('should show error alert when save fails', async () => {
      const mockSave = vi.fn().mockRejectedValue(new Error('Save failed'));
      const mockAlert = vi.spyOn(window, 'alert').mockImplementation(() => {});
      useStore.setState({ savePendingChanges: mockSave });

      render(<App />);

      const saveButton = screen.getByText(/💾 保存/);
      saveButton.click();

      await waitFor(() => {
        expect(mockAlert).toHaveBeenCalledWith('❌ 保存に失敗しました: Save failed');
      });

      mockAlert.mockRestore();
    });

    it('should call discardPendingChanges when discard button clicked and confirmed', () => {
      const mockDiscard = vi.fn();
      const mockConfirm = vi.spyOn(window, 'confirm').mockReturnValue(true);
      useStore.setState({ discardPendingChanges: mockDiscard });

      render(<App />);

      const discardButton = screen.getByText('✖ 破棄');
      discardButton.click();

      expect(mockConfirm).toHaveBeenCalledWith('未保存の変更を破棄してもよろしいですか？');
      expect(mockDiscard).toHaveBeenCalled();
      mockConfirm.mockRestore();
    });

    it('should not call discardPendingChanges when discard cancelled', () => {
      const mockDiscard = vi.fn();
      const mockConfirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
      useStore.setState({ discardPendingChanges: mockDiscard });

      render(<App />);

      const discardButton = screen.getByText('✖ 破棄');
      discardButton.click();

      expect(mockConfirm).toHaveBeenCalled();
      expect(mockDiscard).not.toHaveBeenCalled();
      mockConfirm.mockRestore();
    });

    it('should disable save button while saving', async () => {
      const mockSave = vi.fn().mockImplementation(() => new Promise(resolve => setTimeout(resolve, 100)));
      useStore.setState({ savePendingChanges: mockSave });
      vi.spyOn(window, 'alert').mockImplementation(() => {});

      render(<App />);

      const saveButton = screen.getByText(/💾 保存/) as HTMLButtonElement;
      expect(saveButton.disabled).toBe(false);

      saveButton.click();

      await waitFor(() => {
        expect(saveButton.disabled).toBe(true);
      });
    });
  });

  describe('BeforeUnload Event', () => {
    it('should register beforeunload listener', () => {
      const addEventListenerSpy = vi.spyOn(window, 'addEventListener');

      useStore.setState({
        isDirty: false,
        fetchGridData: mockFetchGridData,
        isLoading: false,
        error: null,
        projectId: '123',
        pendingChanges: {
          movedUserStories: [],
          reorderedEpics: null,
          reorderedVersions: null
        }
      });

      const { unmount } = render(<App />);

      expect(addEventListenerSpy).toHaveBeenCalledWith('beforeunload', expect.any(Function));

      unmount();
      addEventListenerSpy.mockRestore();
    });

    it('should remove beforeunload listener on unmount', () => {
      const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener');

      useStore.setState({
        isDirty: false,
        fetchGridData: mockFetchGridData,
        isLoading: false,
        error: null,
        projectId: '123',
        pendingChanges: {
          movedUserStories: [],
          reorderedEpics: null,
          reorderedVersions: null
        }
      });

      const { unmount } = render(<App />);

      unmount();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('beforeunload', expect.any(Function));
      removeEventListenerSpy.mockRestore();
    });
  });

  describe('Menu Toggle', () => {
    it('should call toggleSideMenu when menu button clicked', () => {
      const mockToggle = vi.fn();
      useStore.setState({
        toggleSideMenu: mockToggle,
        fetchGridData: mockFetchGridData,
        isLoading: false,
        error: null,
        projectId: '123',
        isSideMenuVisible: false,
        isDetailPaneVisible: false,
        pendingChanges: {
          movedUserStories: [],
          reorderedEpics: null,
          reorderedVersions: null
        }
      });

      render(<App />);

      const menuButton = screen.getByRole('button', { name: /メニュー|サイドメニュー/ });
      menuButton.click();

      expect(mockToggle).toHaveBeenCalled();
    });
  });
});
