import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { SortSelector } from './SortSelector';
import { useStore } from '../../store/useStore';

describe('SortSelector - Sort Controls Integration Tests', () => {

  beforeEach(() => {
    // LocalStorageをクリア
    localStorage.clear();

    // ストアをリセット
    useStore.setState({
      epicSortOptions: { sort_by: 'subject', sort_direction: 'asc' },
      versionSortOptions: { sort_by: 'date', sort_direction: 'asc' }
    });
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('Epic&Feature sort selector', () => {

    it('should render with correct default values', () => {
      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const label = screen.getByText('Epic&Feature並び替え');
      expect(label).toBeTruthy();

      const selects = screen.getAllByRole('combobox');
      expect(selects.length).toBe(2); // sort_by and sort_direction

      // デフォルトは subject / asc
      expect(selects[0].value).toBe('subject');
      expect(selects[1].value).toBe('asc');
    });

    it('should update store when sort field changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      await user.selectOptions(sortFieldSelect, 'id');

      // ストアが更新されているか確認
      const state = useStore.getState();
      expect(state.epicSortOptions.sort_by).toBe('id');
      expect(state.epicSortOptions.sort_direction).toBe('asc'); // direction は変わらない
    });

    it('should update store when sort direction changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortDirectionSelect = screen.getAllByRole('combobox')[1];
      await user.selectOptions(sortDirectionSelect, 'desc');

      // ストアが更新されているか確認
      const state = useStore.getState();
      expect(state.epicSortOptions.sort_by).toBe('subject'); // field は変わらない
      expect(state.epicSortOptions.sort_direction).toBe('desc');
    });

    it('should save to localStorage when sort field changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      await user.selectOptions(sortFieldSelect, 'date');

      // LocalStorageに保存されているか確認
      expect(localStorage.getItem('kanban_epic_sort_by')).toBe('date');
      expect(localStorage.getItem('kanban_epic_sort_direction')).toBe('asc');
    });

    it('should save to localStorage when sort direction changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortDirectionSelect = screen.getAllByRole('combobox')[1];
      await user.selectOptions(sortDirectionSelect, 'desc');

      // LocalStorageに保存されているか確認
      expect(localStorage.getItem('kanban_epic_sort_by')).toBe('subject');
      expect(localStorage.getItem('kanban_epic_sort_direction')).toBe('desc');
    });

    it('should display all sort field options', () => {
      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      const options = Array.from(sortFieldSelect.querySelectorAll('option')).map(opt => opt.value);

      expect(options).toEqual(['date', 'id', 'subject']);
    });

    it('should display all sort direction options', () => {
      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortDirectionSelect = screen.getAllByRole('combobox')[1];
      const options = Array.from(sortDirectionSelect.querySelectorAll('option')).map(opt => opt.value);

      expect(options).toEqual(['asc', 'desc']);
    });
  });

  describe('Version sort selector', () => {

    it('should render with correct default values', () => {
      render(<SortSelector type="version" label="Version並び替え" />);

      const label = screen.getByText('Version並び替え');
      expect(label).toBeTruthy();

      const selects = screen.getAllByRole('combobox');
      expect(selects.length).toBe(2);

      // デフォルトは date / asc
      expect(selects[0].value).toBe('date');
      expect(selects[1].value).toBe('asc');
    });

    it('should update store when sort field changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="version" label="Version並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      await user.selectOptions(sortFieldSelect, 'id');

      // ストアが更新されているか確認
      const state = useStore.getState();
      expect(state.versionSortOptions.sort_by).toBe('id');
      expect(state.versionSortOptions.sort_direction).toBe('asc');
    });

    it('should save to localStorage when sort changes', async () => {
      const user = userEvent.setup();

      render(<SortSelector type="version" label="Version並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      await user.selectOptions(sortFieldSelect, 'subject');

      // LocalStorageに保存されているか確認
      expect(localStorage.getItem('kanban_version_sort_by')).toBe('subject');
    });
  });

  describe('LocalStorage persistence', () => {

    it('should load epic sort from localStorage on init', () => {
      // LocalStorageに保存済みの値をセット
      localStorage.setItem('kanban_epic_sort_by', 'id');
      localStorage.setItem('kanban_epic_sort_direction', 'desc');

      // ストアを再初期化（実際のアプリ起動時の動作をシミュレート）
      const sortBy = localStorage.getItem('kanban_epic_sort_by') || 'subject';
      const sortDirection = localStorage.getItem('kanban_epic_sort_direction') || 'asc';

      useStore.setState({
        epicSortOptions: {
          sort_by: sortBy as 'date' | 'id' | 'subject',
          sort_direction: sortDirection as 'asc' | 'desc'
        }
      });

      render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const selects = screen.getAllByRole('combobox');
      expect(selects[0].value).toBe('id');
      expect(selects[1].value).toBe('desc');
    });

    it('should load version sort from localStorage on init', () => {
      // LocalStorageに保存済みの値をセット
      localStorage.setItem('kanban_version_sort_by', 'subject');
      localStorage.setItem('kanban_version_sort_direction', 'desc');

      // ストアを再初期化
      const sortBy = localStorage.getItem('kanban_version_sort_by') || 'date';
      const sortDirection = localStorage.getItem('kanban_version_sort_direction') || 'asc';

      useStore.setState({
        versionSortOptions: {
          sort_by: sortBy as 'date' | 'id' | 'subject',
          sort_direction: sortDirection as 'asc' | 'desc'
        }
      });

      render(<SortSelector type="version" label="Version並び替え" />);

      const selects = screen.getAllByRole('combobox');
      expect(selects[0].value).toBe('subject');
      expect(selects[1].value).toBe('desc');
    });
  });

  describe('Label text', () => {

    it('should display correct field labels for epic', () => {
      const { container } = render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      const options = Array.from(sortFieldSelect.querySelectorAll('option'));

      expect(options[0].textContent).toBe('開始日');
      expect(options[1].textContent).toBe('ID');
      expect(options[2].textContent).toBe('件名');
    });

    it('should display correct field labels for version', () => {
      const { container } = render(<SortSelector type="version" label="Version並び替え" />);

      const sortFieldSelect = screen.getAllByRole('combobox')[0];
      const options = Array.from(sortFieldSelect.querySelectorAll('option'));

      expect(options[0].textContent).toBe('期日');
      expect(options[1].textContent).toBe('ID');
      expect(options[2].textContent).toBe('名前');
    });

    it('should display correct direction labels', () => {
      const { container } = render(<SortSelector type="epic" label="Epic&Feature並び替え" />);

      const sortDirectionSelect = screen.getAllByRole('combobox')[1];
      const options = Array.from(sortDirectionSelect.querySelectorAll('option'));

      expect(options[0].textContent).toBe('昇順');
      expect(options[1].textContent).toBe('降順');
    });
  });
});
