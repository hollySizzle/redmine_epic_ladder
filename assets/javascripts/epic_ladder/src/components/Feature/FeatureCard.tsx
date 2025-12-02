import React from 'react';
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
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);

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
    if (!isDetailPaneVisible) {
      toggleDetailPane();
    }
    setSelectedEntity('issue', feature.id);
  };

  return (
    <div ref={ref} className={className} data-feature={feature.id}>
      <div className="feature-header" onClick={handleHeaderClick}>
        <StatusIndicator status={feature.status} />
        {feature.title}
      </div>
      <UserStoryGridForCard
        featureId={feature.id}
        storyIds={feature.user_story_ids}
      />
    </div>
  );
};
