import React from 'react';
import { StatusIndicator } from './common/StatusIndicator';

export const Legend: React.FC = () => {
  return (
    <div className="legend">
      <h3>Grid階層構造</h3>
      <div className="legend-item">📊 <strong>レベル1:</strong> Epic × Version Grid (最上位グリッド)</div>
      <div className="legend-item">📦 <strong>レベル2:</strong> FeatureCardGrid (各セル内に配置)</div>
      <div className="legend-item">📝 <strong>レベル3:</strong> UserStoryGrid (Feature Card内)</div>
      <div className="legend-item">✅ <strong>レベル4:</strong> TaskGrid / TestGrid / BugGrid (UserStory内)</div>
      <br />
      <div className="legend-item">
        <StatusIndicator status="open" /> 未完了（オープン）
      </div>
      <div className="legend-item">
        <StatusIndicator status="closed" /> 完了（クローズ）
      </div>
    </div>
  );
};
