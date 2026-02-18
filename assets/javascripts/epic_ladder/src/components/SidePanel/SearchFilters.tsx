/**
 * SearchFilters コンポーネント（Phase 2実装予定）
 *
 * 検索対象（subject/description/all）やステータスフィルターを提供
 *
 * Phase 2で実装予定:
 * - 検索対象トグル（Subject/Description/All）
 *
 * Phase 3で実装予定:
 * - ステータスドロップダウンフィルター
 * - 優先度フィルター
 * - 担当者フィルター
 */

import React from 'react';
import type { SearchTarget } from '../../types/normalized-api';

interface SearchFiltersProps {
  searchTarget: SearchTarget;
  onSearchTargetChange: (target: SearchTarget) => void;
  // Phase 3用（将来）
  statusIds?: number[];
  onStatusIdsChange?: (statusIds: number[]) => void;
}

/**
 * 【Phase 2実装予定】検索フィルターコンポーネント
 *
 * 現在はスケルトン実装のみ。Phase 2で以下を実装:
 * - Subject/Description/All のトグルボタン
 * - 折りたたみ可能なUI
 */
export const SearchFilters: React.FC<SearchFiltersProps> = ({
  searchTarget,
  onSearchTargetChange,
  statusIds,
  onStatusIdsChange,
}) => {
  // TODO: Phase 2で実装
  // 現状は何も表示しない
  return null;

  /* Phase 2実装イメージ:
  return (
    <div className="search-filters">
      <details className="search-filters__details">
        <summary className="search-filters__summary">
          🔧 フィルター設定
        </summary>

        <div className="search-filters__content">
          <div className="search-filters__section">
            <label className="search-filters__label">検索対象</label>
            <div className="search-filters__toggle-group">
              <button
                className={`search-filters__toggle ${searchTarget === 'subject' ? 'active' : ''}`}
                onClick={() => onSearchTargetChange('subject')}
              >
                件名
              </button>
              <button
                className={`search-filters__toggle ${searchTarget === 'description' ? 'active' : ''}`}
                onClick={() => onSearchTargetChange('description')}
              >
                説明
              </button>
              <button
                className={`search-filters__toggle ${searchTarget === 'all' ? 'active' : ''}`}
                onClick={() => onSearchTargetChange('all')}
              >
                すべて
              </button>
            </div>
          </div>

          {/* Phase 3: ステータスフィルター * /}
          <div className="search-filters__section">
            <label className="search-filters__label">ステータス</label>
            <select
              className="search-filters__select"
              multiple
              value={statusIds?.map(String) ?? []}
              onChange={(e) => {
                const selected = Array.from(e.target.selectedOptions, opt => parseInt(opt.value, 10));
                onStatusIdsChange?.(selected);
              }}
            >
              <option value="">すべて</option>
              <option value="1">New</option>
              <option value="2">In Progress</option>
              <option value="3">Resolved</option>
              <option value="4">Feedback</option>
              <option value="5">Closed</option>
            </select>
          </div>
        </div>
      </details>
    </div>
  );
  */
};
