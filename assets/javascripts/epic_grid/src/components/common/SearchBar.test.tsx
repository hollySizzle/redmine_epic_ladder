import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { SearchBar } from './SearchBar';
import { useStore } from '../../store/useStore';
import type { Epic, Feature, UserStory, Task, Test, Bug } from '../../types/normalized-api';

describe('SearchBar', () => {
  beforeEach(() => {
    // ストアをリセット
    useStore.setState({
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
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      selectedEntity: null,
      isDetailPaneVisible: false
    });
  });

  describe('Rendering', () => {
    it('should render search input and button', () => {
      render(<SearchBar />);

      expect(screen.getByPlaceholderText(/タイトルで検索/)).toBeTruthy();
      expect(screen.getByText('検索')).toBeTruthy();
    });

    it('should disable search button when query is empty', () => {
      render(<SearchBar />);

      const searchButton = screen.getByText('検索') as HTMLButtonElement;
      expect(searchButton.disabled).toBe(true);
    });

    it('should enable search button when query is entered', async () => {
      const user = userEvent.setup();
      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'test');

      const searchButton = screen.getByText('検索') as HTMLButtonElement;
      expect(searchButton.disabled).toBe(false);
    });

    it('should show clear button when query is entered', async () => {
      const user = userEvent.setup();
      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'test');

      expect(screen.getByText('✕')).toBeTruthy();
    });
  });

  describe('Search Functionality', () => {
    it('should find epic by subject (case insensitive)', async () => {
      const user = userEvent.setup();

      const epics: Record<string, Epic> = {
        'e1': {
          id: 'e1',
          subject: 'Test Epic',
          status: 'open',
          fixed_version_id: null,
          feature_ids: [],
          statistics: {
            total_features: 0,
            completed_features: 0,
            total_user_stories: 0,
            total_child_items: 0,
            completion_percentage: 0
          },
          created_on: '2025-01-01T00:00:00Z',
          updated_on: '2025-01-01T00:00:00Z',
          tracker_id: 1
        }
      };

      useStore.setState({
        entities: {
          epics,
          versions: {},
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        }
      });

      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'test epic');
      await user.click(screen.getByText('検索'));

      expect(screen.getByText(/見つかりました: Test Epic/)).toBeTruthy();
    });

    it('should find feature by title', async () => {
      const user = userEvent.setup();

      const features: Record<string, Feature> = {
        'f1': {
          id: 'f1',
          title: 'Login Feature',
          status: 'open',
          parent_epic_id: 'e1',
          user_story_ids: [],
          fixed_version_id: null,
          version_source: 'none',
          statistics: {
            total_user_stories: 0,
            completed_user_stories: 0,
            total_child_items: 0,
            child_items_by_type: { tasks: 0, tests: 0, bugs: 0 },
            completion_percentage: 0
          },
          created_on: '2025-01-01T00:00:00Z',
          updated_on: '2025-01-01T00:00:00Z',
          tracker_id: 2
        }
      };

      useStore.setState({
        entities: {
          epics: {},
          versions: {},
          features,
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        }
      });

      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'login');
      await user.click(screen.getByText('検索'));

      expect(screen.getByText(/見つかりました: Login Feature/)).toBeTruthy();
    });

    it('should show not found message when no match', async () => {
      const user = userEvent.setup();

      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'nonexistent');
      await user.click(screen.getByText('検索'));

      expect(screen.getByText(/該当するissueが見つかりませんでした/)).toBeTruthy();
    });

    it('should clear search results when clear button is clicked', async () => {
      const user = userEvent.setup();

      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'test');
      await user.click(screen.getByText('検索'));

      // Clear button click
      await user.click(screen.getByText('✕'));

      expect((searchInput as HTMLInputElement).value).toBe('');
      expect(screen.queryByText(/見つかりました/)).toBeFalsy();
      expect(screen.queryByText(/該当するissue/)).toBeFalsy();
    });
  });

  describe('Search Priority', () => {
    it('should find epic first when multiple types match', async () => {
      const user = userEvent.setup();

      const epics: Record<string, Epic> = {
        'e1': {
          id: 'e1',
          subject: 'Authentication',
          status: 'open',
          fixed_version_id: null,
          feature_ids: [],
          statistics: {
            total_features: 0,
            completed_features: 0,
            total_user_stories: 0,
            total_child_items: 0,
            completion_percentage: 0
          },
          created_on: '2025-01-01T00:00:00Z',
          updated_on: '2025-01-01T00:00:00Z',
          tracker_id: 1
        }
      };

      const features: Record<string, Feature> = {
        'f1': {
          id: 'f1',
          title: 'Authentication Module',
          status: 'open',
          parent_epic_id: 'e1',
          user_story_ids: [],
          fixed_version_id: null,
          version_source: 'none',
          statistics: {
            total_user_stories: 0,
            completed_user_stories: 0,
            total_child_items: 0,
            child_items_by_type: { tasks: 0, tests: 0, bugs: 0 },
            completion_percentage: 0
          },
          created_on: '2025-01-01T00:00:00Z',
          updated_on: '2025-01-01T00:00:00Z',
          tracker_id: 2
        }
      };

      useStore.setState({
        entities: {
          epics,
          versions: {},
          features,
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        }
      });

      render(<SearchBar />);

      const searchInput = screen.getByPlaceholderText(/タイトルで検索/);
      await user.type(searchInput, 'auth');
      await user.click(screen.getByText('検索'));

      // Should find Epic first (priority order: Epic > Feature > UserStory > Task > Test > Bug)
      expect(screen.getByText(/見つかりました: Authentication$/)).toBeTruthy();
    });
  });
});
