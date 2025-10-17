import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { FilterPanel } from './FilterPanel';
import { useStore } from '../store/useStore';
import type { Epic, Feature, Version } from '../types/normalized-api';

describe('FilterPanel', () => {
  beforeEach(() => {
    // 各テスト前にストアをリセット
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
      grid: { index: {}, epic_order: [], version_order: [] },
      metadata: {
        available_statuses: [],
        available_trackers: []
      },
      filters: {},
      excludeClosedVersions: false,
      isLoading: false,
      error: null,
      projectId: 'project1'
    });
  });

  describe('Rendering', () => {
    it('should render filter toggle button', () => {
      render(<FilterPanel />);
      expect(screen.getByText(/フィルタ/)).toBeTruthy();
    });

    it('should show filter panel when toggle button is clicked', async () => {
      const user = userEvent.setup();
      render(<FilterPanel />);

      const toggleButton = screen.getByText(/フィルタ/);
      await user.click(toggleButton);

      expect(screen.getByText('バージョン')).toBeTruthy();
      expect(screen.getByText('Epic')).toBeTruthy();
      expect(screen.getByText('Feature')).toBeTruthy();
    });
  });

  describe('Natural Sort for Versions', () => {
    it('should sort versions in natural order by name', async () => {
      const user = userEvent.setup();

      // 自然順ソートをテストするデータ（意図的に順序をシャッフル）
      const versions: Record<string, Version> = {
        'v10': { id: 'v10', name: '10.0.0', status: 'open', project_id: 'p1' },
        'v2': { id: 'v2', name: '2.0.0', status: 'open', project_id: 'p1' },
        'v1': { id: 'v1', name: '1.0.0', status: 'open', project_id: 'p1' },
        'v20': { id: 'v20', name: '20.0.0', status: 'open', project_id: 'p1' }
      };

      useStore.setState({
        entities: {
          epics: {},
          versions,
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: {},
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ/));

      // バージョンセクションを取得
      const versionSection = screen.getByText('バージョン').parentElement;
      expect(versionSection).toBeTruthy();

      // バージョンのラベルを取得して順序を確認
      const versionLabels = Array.from(
        versionSection!.querySelectorAll('.filter-checkbox span')
      ).map(el => el.textContent);

      // 期待される自然順: 1.0.0, 2.0.0, 10.0.0, 20.0.0
      expect(versionLabels).toEqual(['1.0.0', '2.0.0', '10.0.0', '20.0.0']);
    });

    it('should sort versions with prefix numbers correctly', async () => {
      const user = userEvent.setup();

      const versions: Record<string, Version> = {
        'v1': { id: 'v1', name: '1_初期機能', status: 'open', project_id: 'p1' },
        'v10': { id: 'v10', name: '10_追加機能', status: 'open', project_id: 'p1' },
        'v2': { id: 'v2', name: '2_基本機能', status: 'open', project_id: 'p1' }
      };

      useStore.setState({
        entities: {
          epics: {},
          versions,
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: {},
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ/));

      const versionSection = screen.getByText('バージョン').parentElement;
      const versionLabels = Array.from(
        versionSection!.querySelectorAll('.filter-checkbox span')
      ).map(el => el.textContent);

      // 期待される自然順: 1_初期機能, 2_基本機能, 10_追加機能
      expect(versionLabels).toEqual(['1_初期機能', '2_基本機能', '10_追加機能']);
    });
  });

  describe('Natural Sort for Epics', () => {
    it('should sort epics in natural order by subject', async () => {
      const user = userEvent.setup();

      const epics: Record<string, Epic> = {
        'e10': { id: 'e10', subject: '10_認証システム', project_id: 'p1' },
        'e2': { id: 'e2', subject: '2_ユーザ管理', project_id: 'p1' },
        'e1': { id: 'e1', subject: '1_基本設定', project_id: 'p1' },
        'e100': { id: 'e100', subject: '100_運用保守', project_id: 'p1' }
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
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: {},
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ/));

      const epicSection = screen.getByText('Epic').parentElement;
      const epicLabels = Array.from(
        epicSection!.querySelectorAll('.filter-checkbox span')
      ).map(el => el.textContent);

      // 期待される自然順: 1_基本設定, 2_ユーザ管理, 10_認証システム, 100_運用保守
      expect(epicLabels).toEqual([
        '1_基本設定',
        '2_ユーザ管理',
        '10_認証システム',
        '100_運用保守'
      ]);
    });
  });

  describe('Natural Sort for Features', () => {
    it('should sort features in natural order by title', async () => {
      const user = userEvent.setup();

      const features: Record<string, Feature> = {
        'f10': { id: 'f10', title: '10_詳細画面', parent_epic_id: 'e1', project_id: 'p1' },
        'f2': { id: 'f2', title: '2_一覧画面', parent_epic_id: 'e1', project_id: 'p1' },
        'f1': { id: 'f1', title: '1_登録画面', parent_epic_id: 'e1', project_id: 'p1' },
        'f20': { id: 'f20', title: '20_削除機能', parent_epic_id: 'e1', project_id: 'p1' }
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
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: {},
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ/));

      const featureSection = screen.getByText('Feature').parentElement;
      const featureLabels = Array.from(
        featureSection!.querySelectorAll('.filter-checkbox span')
      ).map(el => el.textContent);

      // 期待される自然順: 1_登録画面, 2_一覧画面, 10_詳細画面, 20_削除機能
      expect(featureLabels).toEqual([
        '1_登録画面',
        '2_一覧画面',
        '10_詳細画面',
        '20_削除機能'
      ]);
    });
  });

  describe('Filter Application', () => {
    it('should apply version filter when checkbox is selected and Apply is clicked', async () => {
      const user = userEvent.setup();
      const setFiltersMock = useStore.getState().setFilters;

      const versions: Record<string, Version> = {
        'v1': { id: 'v1', name: 'v1.0.0', status: 'open', project_id: 'p1' },
        'v2': { id: 'v2', name: 'v2.0.0', status: 'open', project_id: 'p1' }
      };

      useStore.setState({
        entities: {
          epics: {},
          versions,
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: {},
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ/));

      // v1.0.0を選択
      const v1Checkbox = screen.getByLabelText('v1.0.0');
      await user.click(v1Checkbox);

      // 適用ボタンをクリック
      await user.click(screen.getByText('適用'));

      // フィルタが適用されていることを確認
      const currentFilters = useStore.getState().filters;
      expect(currentFilters.fixed_version_id_in).toEqual(['v1']);
    });

    it('should clear all filters when Clear button is clicked', async () => {
      const user = userEvent.setup();

      useStore.setState({
        entities: {
          epics: {},
          versions: {
            'v1': { id: 'v1', name: 'v1.0.0', status: 'open', project_id: 'p1' }
          },
          features: {},
          user_stories: {},
          tasks: {},
          tests: {},
          bugs: {},
          users: {}
        },
        grid: { index: {}, epic_order: [], version_order: [] },
        metadata: {
          available_statuses: [],
          available_trackers: []
        },
        filters: { fixed_version_id_in: ['v1'] }, // 初期状態でフィルタ適用済み
        excludeClosedVersions: false,
        isLoading: false,
        error: null,
        projectId: 'project1'
      });

      render(<FilterPanel />);
      await user.click(screen.getByText(/フィルタ \(1\)/)); // フィルタカウント表示を確認

      await user.click(screen.getByText('クリア'));

      // フィルタがクリアされていることを確認
      const currentFilters = useStore.getState().filters;
      expect(currentFilters).toEqual({});
    });
  });
});
