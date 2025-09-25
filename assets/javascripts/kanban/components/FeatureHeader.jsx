import React from 'react';

/**
 * FeatureHeader - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const FeatureHeader = ({ feature, expanded, onToggle }) => {
  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#fff3e0',
      '完了': '#e0e0e0',
      '未着手': '#f5f5f5'
    };
    return colors[status] || '#f5f5f5';
  };

  return (
    <div className="feature-header">
      <h3
        className="feature-title"
        onClick={onToggle}
        style={{ cursor: 'pointer' }}
      >
        {feature.issue.subject}
      </h3>

      <span
        className="feature-status-badge"
        style={{ backgroundColor: getStatusColor(feature.issue.status) }}
      >
        {feature.issue.status}
      </span>
    </div>
  );
};