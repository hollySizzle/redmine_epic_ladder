import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { UserStoryGrid } from '../UserStory/UserStoryGrid';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useStore } from '../../store/useStore';

interface FeatureCardProps {
  featureId: string;
}

export const FeatureCard: React.FC<FeatureCardProps> = ({ featureId }) => {
  // ストアから直接Featureを取得
  const feature = useStore(state => state.entities.features[featureId]);

  if (!feature) return null;

  const className = feature.status === 'closed' ? 'feature-card closed' : 'feature-card';

  const ref = useDraggableAndDropTarget({
    type: 'feature-card',
    id: feature.id,
    onDrop: (sourceData) => {
      console.log('Feature dropped:', sourceData.id, '→', feature.id);
    }
  });

  return (
    <div ref={ref} className={className} data-feature={feature.id}>
      <div className="feature-header">
        <StatusIndicator status={feature.status} />
        {feature.title}
      </div>
      <UserStoryGrid storyIds={feature.user_story_ids} />
    </div>
  );
};
