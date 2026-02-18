import React from 'react';
import { useStore } from '../../store/useStore';
import type { SortField, SortDirection } from '../../types/normalized-api';

interface SortSelectorProps {
  type: 'epic' | 'version';
  label: string;
}

/**
 * Epic/Versionのソート選択コンポーネント
 * - ソートフィールド（date/id/subject）
 * - ソート方向（asc/desc）
 */
export const SortSelector: React.FC<SortSelectorProps> = ({ type, label }) => {
  const epicSortOptions = useStore(state => state.epicSortOptions);
  const versionSortOptions = useStore(state => state.versionSortOptions);
  const setEpicSort = useStore(state => state.setEpicSort);
  const setVersionSort = useStore(state => state.setVersionSort);

  const sortOptions = type === 'epic' ? epicSortOptions : versionSortOptions;
  const setSort = type === 'epic' ? setEpicSort : setVersionSort;

  const handleSortByChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const sortBy = e.target.value as SortField;
    setSort(sortBy, sortOptions.sort_direction);
  };

  const handleSortDirectionChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const sortDirection = e.target.value as SortDirection;
    setSort(sortOptions.sort_by, sortDirection);
  };

  // ソートフィールドのラベル
  const sortFieldLabels: Record<SortField, string> = {
    date: type === 'epic' ? '開始日' : '期日',
    id: 'ID',
    subject: type === 'epic' ? '件名' : '名前'
  };

  // ソート方向のラベル
  const sortDirectionLabels: Record<SortDirection, string> = {
    asc: '昇順',
    desc: '降順'
  };

  return (
    <div className="sort-selector">
      <label className="sort-selector__label">{label}</label>
      <div className="sort-selector__controls">
        <select
          className="sort-selector__field"
          value={sortOptions.sort_by}
          onChange={handleSortByChange}
          title="ソート項目を選択"
        >
          {Object.entries(sortFieldLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <select
          className="sort-selector__direction"
          value={sortOptions.sort_direction}
          onChange={handleSortDirectionChange}
          title="ソート方向を選択"
        >
          {Object.entries(sortDirectionLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
};
