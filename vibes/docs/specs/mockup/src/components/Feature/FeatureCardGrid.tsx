import React from 'react';
import { FeatureCard, FeatureCardData } from './FeatureCard';
import { AddButton } from '../common/AddButton';

interface FeatureCardGridProps {
  features: FeatureCardData[];
  epicId: string;
  versionId: string;
}

export const FeatureCardGrid: React.FC<FeatureCardGridProps> = ({ features, epicId, versionId }) => {
  return (
    <div className="feature-card-grid">
      {features.map(feature => (
        <FeatureCard key={feature.id} feature={feature} />
      ))}
      <AddButton
        type="feature"
        label="+ Add Feature"
        dataAddButton="feature"
        className="feature-card"
        epicId={epicId}
        versionId={versionId}
      />
    </div>
  );
};
