import React from 'react';
import { StatusIndicator } from '../common/StatusIndicator';
import { UserStoryGrid } from '../UserStory/UserStoryGrid';
import { UserStoryData } from '../UserStory/UserStory';

export interface FeatureCardData {
  id: string;
  title: string;
  status: 'open' | 'closed';
  stories: UserStoryData[];
}

interface FeatureCardProps {
  feature: FeatureCardData;
}

export const FeatureCard: React.FC<FeatureCardProps> = ({ feature }) => {
  const className = feature.status === 'closed' ? 'feature-card closed' : 'feature-card';

  return (
    <div className={className} data-feature={feature.id}>
      <div className="feature-header">
        <StatusIndicator status={feature.status} />
        {feature.title}
      </div>
      <UserStoryGrid stories={feature.stories} />
    </div>
  );
};
