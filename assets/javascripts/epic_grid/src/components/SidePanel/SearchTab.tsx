import React, { useState, useRef, useEffect } from 'react';
import { useStore } from '../../store/useStore';
import { highlightIssue, scrollToIssue } from '../../utils/domUtils';
import { searchAllIssues } from '../../utils/searchUtils';
import type { SearchResult } from '../../types/normalized-api';

/**
 * SearchTab コンポーネント
 *
 * 検索機能とその結果を表示するタブコンテンツ
 * 複数ヒット時は一覧表示し、クリックでカードへスクロール&ハイライト
 *
 * Phase 1対応:
 * - ID検索（数値のみ入力時、完全一致）
 * - ID完全一致時は自動的にDetailPaneも表示
 */
export const SearchTab: React.FC = () => {
  const [query, setQuery] = useState('');
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [hasSearched, setHasSearched] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const entities = useStore(state => state.entities);
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const activeSideTab = useStore(state => state.activeSideTab);

  // SearchTabがアクティブになったら入力欄にフォーカス
  useEffect(() => {
    if (activeSideTab === 'search' && inputRef.current) {
      // 少し遅延させてフォーカス（アニメーション完了後）
      const timer = setTimeout(() => {
        inputRef.current?.focus();
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [activeSideTab]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();

    if (!query.trim()) {
      setSearchResults([]);
      setHasSearched(false);
      return;
    }

    // 全マッチするissueを検索
    const results = searchAllIssues(entities, query);
    setSearchResults(results);
    setHasSearched(true);
  };

  const handleResultClick = (result: SearchResult) => {
    // DOM要素までスクロール
    const scrolled = scrollToIssue(result.id, result.type);

    if (scrolled) {
      // ハイライト表示
      highlightIssue(result.id, result.type);

      // Phase 1: ID完全一致の場合のみDetailPaneも自動表示
      if (result.isExactIdMatch) {
        if (!isDetailPaneVisible) {
          toggleDetailPane();
        }
        setSelectedEntity('issue', result.id);
      }
    } else {
      console.warn(`⚠️ DOM element not found for issue: ${result.id} (${result.type})`);
    }
  };

  const handleClear = () => {
    setQuery('');
    setSearchResults([]);
    setHasSearched(false);
  };

  const getIssueTypeLabel = (type: string): string => {
    switch (type) {
      case 'epic': return 'Epic';
      case 'feature': return 'Feature';
      case 'user-story': return 'UserStory';
      case 'task': return 'Task';
      case 'test': return 'Test';
      case 'bug': return 'Bug';
      default: return type;
    }
  };

  const getIssueTypeIcon = (type: string): string => {
    switch (type) {
      case 'epic': return '📦';
      case 'feature': return '✨';
      case 'user-story': return '📝';
      case 'task': return '✅';
      case 'test': return '🧪';
      case 'bug': return '🐛';
      default: return '📄';
    }
  };

  return (
    <div className="search-tab">
      <div className="search-tab__input-area">
        <form onSubmit={handleSearch} className='input_form'>
          <input
            ref={inputRef}
            type="text"
            className="search-tab__input"
            placeholder="Epic/Feature/ストーリーを検索..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{ flex: 1 }}
          />
          <button type="submit" className="search-tab__button" disabled={!query.trim()}>
            🔍 検索
          </button>
          {query && (
            <button type="button" onClick={handleClear} className="search-tab__button search-tab__button--clear">
              ✕
            </button>
          )}
        </form>
      </div>

      <div className="search-tab__results">
        {!hasSearched && (
          <div className="search-tab__placeholder">
            <p>💡 ID または タイトル（subject）で検索できます</p>
            <ul className="search-tab__features">
              <li><strong>ID検索</strong>: 数値のみ入力で完全一致検索（例: 123）</li>
              <li><strong>タイトル検索</strong>: 部分一致検索（大文字小文字区別なし）</li>
              <li>Epic/Feature/UserStory/Task/Test/Bug を横断検索</li>
              <li>クリックでカードへジャンプ&ハイライト</li>
              <li>ID完全一致時は詳細パネルも自動表示</li>
            </ul>
          </div>
        )}

        {hasSearched && searchResults.length === 0 && (
          <div className="search-tab__no-results">
            <p>❌ 「{query}」に該当するissueが見つかりませんでした</p>
          </div>
        )}

        {hasSearched && searchResults.length > 0 && (
          <div className="search-tab__results-list">
            <div className="search-tab__results-header">
              <p>✅ {searchResults.length}件見つかりました</p>
            </div>
            <ul className="search-tab__list">
              {searchResults.map((result) => (
                <li
                  key={`${result.type}-${result.id}`}
                  className="search-tab__list-item"
                  onClick={() => handleResultClick(result)}
                >
                  <div className="search-tab__item-icon">
                    {getIssueTypeIcon(result.type)}
                  </div>
                  <div className="search-tab__item-content">
                    <div className="search-tab__item-type">
                      {getIssueTypeLabel(result.type)}
                    </div>
                    <div className="search-tab__item-subject">
                      {result.subject}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
};
