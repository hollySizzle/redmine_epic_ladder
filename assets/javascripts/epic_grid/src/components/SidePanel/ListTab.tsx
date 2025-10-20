import React from 'react';
import { useStore } from '../../store/useStore';
import { highlightIssue, scrollToIssue, expandParentUserStory, enableFocusMode } from '../../utils/domUtils';

/**
 * ListTab コンポーネント
 *
 * Epic/Feature一覧を階層的に表示するタブコンテンツ
 * <details>/<summary>でEpicを折りたたみ可能な「箱」として表現
 *
 * - Epicタイトルクリック: グリッドにスクロール
 * - マーカー(📦)クリック: 折りたたみトグル
 * - デフォルト: 全Epic展開状態
 */
export const ListTab: React.FC = () => {
  const entities = useStore(state => state.entities);
  const epicOrder = useStore(state => state.grid.epic_order);

  // Epic配下のFeatureをグループ化
  const buildHierarchy = () => {
    return epicOrder.map(epicId => {
      const epic = entities.epics[epicId];
      if (!epic) return null;

      const features = epic.feature_ids
        .map(featureId => entities.features[featureId])
        .filter(Boolean);

      return { epic, features };
    }).filter(Boolean);
  };

  const hierarchy = buildHierarchy();

  const handleEpicClick = (epicId: string, e: React.MouseEvent) => {
    // <summary>のデフォルト動作（折りたたみ）を防ぐ
    e.preventDefault();
    e.stopPropagation();

    console.log('📊 [ListTab] Epic title clicked:', epicId);

    // 親階層を自動展開（Epic自身は不要だが統一のため呼び出し）
    expandParentUserStory(epicId, 'epic');

    // DOM要素までスクロール
    const scrolled = scrollToIssue(epicId, 'epic');

    if (scrolled) {
      // フォーカスモード有効化
      enableFocusMode(epicId, 'epic');
      // ハイライト表示
      highlightIssue(epicId, 'epic');
    } else {
      console.warn(`⚠️ Epic DOM element not found: ${epicId}`);
    }
  };

  const handleFeatureClick = (featureId: string, e: React.MouseEvent) => {
    e.stopPropagation(); // 親のdetailsクリックを防ぐ

    console.log('📊 [ListTab] Feature clicked:', featureId);

    // 親階層を自動展開（Feature自身は不要だが統一のため呼び出し）
    expandParentUserStory(featureId, 'feature');

    // DOM要素までスクロール
    const scrolled = scrollToIssue(featureId, 'feature');

    if (scrolled) {
      // フォーカスモード有効化
      enableFocusMode(featureId, 'feature');
      // ハイライト表示
      highlightIssue(featureId, 'feature');
    } else {
      console.warn(`⚠️ Feature DOM element not found: ${featureId}`);
    }
  };

  return (
    <div className="list-tab">
      <div className="list-tab__header">
        <h3 className="list-tab__title">Epic / Feature 一覧</h3>
        <p className="list-tab__subtitle">
          {hierarchy.length}個のEpic
        </p>
      </div>

      <div className="list-tab__content">
        {hierarchy.length === 0 ? (
          <div className="list-tab__empty">
            <p>📭 Epicがありません</p>
          </div>
        ) : (
          <div className="list-tab__tree">
            {hierarchy.map((item) => {
              if (!item) return null;
              const { epic, features } = item;

              return (
                <details key={epic.id} open className="list-tab__epic-details">
                  <summary className="list-tab__epic-summary">
                    <div className="list-tab__epic-marker">📦</div>
                    <div
                      className="list-tab__epic-content"
                      onClick={(e) => handleEpicClick(epic.id, e)}
                    >
                      <div className="list-tab__epic-subject">
                        {epic.subject}
                      </div>
                      <div className="list-tab__epic-stats">
                        {epic.statistics.total_features}件のFeature
                        {' '}・{' '}
                        {Math.round(epic.statistics.completion_percentage)}%完了
                      </div>
                    </div>
                  </summary>

                  {/* Features */}
                  {features.length > 0 && (
                    <ul className="list-tab__features">
                      {features.map((feature) => (
                        <li
                          key={feature.id}
                          className="list-tab__feature-item"
                          onClick={(e) => handleFeatureClick(feature.id, e)}
                        >
                          <div className="list-tab__feature-icon">✨</div>
                          <div className="list-tab__feature-content">
                            <div className="list-tab__feature-subject">
                              {feature.subject}
                            </div>
                            <div className="list-tab__feature-stats">
                              {feature.statistics.total_user_stories}件のストーリー
                              {' '}・{' '}
                              {Math.round(feature.statistics.completion_percentage)}%完了
                            </div>
                          </div>
                        </li>
                      ))}
                    </ul>
                  )}
                </details>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
