import React, { useState } from 'react';
import { useStore } from '../../store/useStore';
import { searchIssues } from '../../utils/searchUtils';
import { scrollToIssue, highlightIssue } from '../../utils/domUtils';
import './SearchBar.scss';

/**
 * SearchBar コンポーネント
 *
 * グリッド内のissueを検索し、マッチしたissueまでスクロールして強調表示する
 */
export const SearchBar: React.FC = () => {
  const [query, setQuery] = useState('');
  const [searchResult, setSearchResult] = useState<{
    found: boolean;
    issueId?: string;
    issueType?: string;
    subject?: string;
  } | null>(null);

  const entities = useStore(state => state.entities);
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();

    if (!query.trim()) {
      setSearchResult(null);
      return;
    }

    // 全entitiesから検索
    const result = searchIssues(entities, query);

    if (result) {
      setSearchResult({
        found: true,
        issueId: result.id,
        issueType: result.type,
        subject: result.subject
      });

      // DOM要素までスクロール
      const scrolled = scrollToIssue(result.id, result.type);

      if (scrolled) {
        // ハイライト表示
        highlightIssue(result.id, result.type);

        // DetailPaneに表示
        if (!isDetailPaneVisible) {
          toggleDetailPane();
        }
        setSelectedEntity('issue', result.id);
      } else {
        console.warn(`⚠️ DOM element not found for issue: ${result.id} (${result.type})`);
      }
    } else {
      setSearchResult({ found: false });
    }
  };

  const handleClear = () => {
    setQuery('');
    setSearchResult(null);
  };

  return (
    <div className="search-bar">
      <form onSubmit={handleSearch} className="search-form">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="🔍 タイトルで検索..."
          className="search-input"
        />
        <button type="submit" className="eg-button eg-button--primary" disabled={!query.trim()}>
          検索
        </button>
        {query && (
          <button type="button" onClick={handleClear} className="eg-button eg-button--ghost">
            ✕
          </button>
        )}
      </form>

      {searchResult !== null && (
        <div className={`search-result ${searchResult.found ? 'found' : 'not-found'}`}>
          {searchResult.found ? (
            <span>✅ 見つかりました: {searchResult.subject}</span>
          ) : (
            <span>❌ 該当するissueが見つかりませんでした</span>
          )}
        </div>
      )}
    </div>
  );
};
