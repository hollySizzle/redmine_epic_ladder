import React from 'react';

/**
 * AboutTab コンポーネント
 *
 * プラグインのバージョン情報・ヘルプを表示するタブコンテンツ
 */
export const AboutTab: React.FC = () => {
  return (
    <div className="about-tab">
      <div className="about-tab__section">
        <h3 className="about-tab__title">Epic Grid Plugin</h3>
        <p className="about-tab__version">Version 1.0.0</p>
      </div>

      <div className="about-tab__section">
        <h4 className="about-tab__subtitle">概要</h4>
        <p className="about-tab__description">
          RedmineのEpic/Feature/UserStoryを<br />
          カンバンボード形式で管理するプラグインです。
        </p>
      </div>

      <div className="about-tab__section">
        <h4 className="about-tab__subtitle">主な機能</h4>
        <ul className="about-tab__feature-list">
          <li>Epic × Version のグリッドビュー</li>
          <li>ドラッグ&ドロップによる移動</li>
          <li>階層的なチケット管理</li>
          <li>リアルタイムフィルタリング</li>
          <li>詳細ペイン表示</li>
        </ul>
      </div>

      <div className="about-tab__section about-tab__section--footer">
        <p className="about-tab__copyright">
          © 2025 Redmine Epic Grid Plugin
        </p>
      </div>
    </div>
  );
};
