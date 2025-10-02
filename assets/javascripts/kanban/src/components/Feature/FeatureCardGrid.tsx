import React from 'react';
import { FeatureCard } from './FeatureCard';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

interface FeatureCardGridProps {
  featureIds: string[];
  epicId: string;
  versionId: string;
}

export const FeatureCardGrid: React.FC<FeatureCardGridProps> = ({ featureIds, epicId, versionId }) => {
  const createFeature = useStore((state) => state.createFeature);

  const handleAddFeature = async () => {
    const subject = prompt('Feature名を入力してください:');
    if (!subject) return;

    try {
      await createFeature({
        subject,
        description: '',
        parent_epic_id: epicId,
        fixed_version_id: versionId === 'none' ? null : versionId
      });
    } catch (error) {
      alert(`Feature作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

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
        onClick={handleAddFeature}
      />
    </div>
  );
};
