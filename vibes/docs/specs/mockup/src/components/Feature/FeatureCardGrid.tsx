import React from 'react';
import { FeatureCard } from './FeatureCard';
import { AddButton } from '../common/AddButton';

interface FeatureCardGridProps {
  featureIds: string[];
  epicId: string;
  versionId: string;
}

export const FeatureCardGrid: React.FC<FeatureCardGridProps> = ({ featureIds, epicId, versionId }) => {
  return (
    <div className="feature-card-grid">
      {featureIds.map(featureId => (
        <FeatureCard key={featureId} featureId={featureId} />
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
