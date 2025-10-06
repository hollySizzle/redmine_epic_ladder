import React, { useState } from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { UserStoryGridForCard } from '../UserStory/UserStoryGridForCard';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface FeatureCardProps {
  featureId: string;
}

export const FeatureCard: React.FC<FeatureCardProps> = ({ featureId }) => {
  // ストアから直接Featureを取得
  const feature = useStore(state => state.entities.features[featureId]);
  const setSelectedIssueId = useStore(state => state.setSelectedIssueId);

  // 個別折り畳み状態（保存しない）
  const [isLocalCollapsed, setIsLocalCollapsed] = useState(false);

  if (!feature) return null;

  const className = feature.status === 'closed' ? 'feature-card closed' : 'feature-card';

  const ref = useDraggableAndDropTarget({
    type: 'feature-card',
    id: feature.id,
    onDrop: (sourceData) => {
      console.log('Feature dropped:', sourceData.id, '→', feature.id);
    }
  });

  const handleHeaderClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIssueId(feature.id);
  };

  const handleToggleCollapse = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsLocalCollapsed(!isLocalCollapsed);
  };

  return (
    <div ref={ref} className={className} data-feature={feature.id}>
      <div className="feature-header" onClick={handleHeaderClick}>
        <button
          className="feature-collapse-toggle"
          onClick={handleToggleCollapse}
          title={isLocalCollapsed ? 'UserStory配下を展開' : 'UserStory配下を折り畳み'}
        >
          {isLocalCollapsed ? '▶' : '▼'}
        </button>
        <StatusIndicator status={feature.status} />
        {feature.title}
      </div>
      <UserStoryGridForCard
        featureId={feature.id}
        storyIds={feature.user_story_ids}
        isLocalCollapsed={isLocalCollapsed}
      />
    </div>
  );
};
