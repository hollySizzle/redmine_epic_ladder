import React from 'react';
import { FeatureCardGrid } from '../Feature/FeatureCardGrid';
import { FeatureCardData } from '../Feature/FeatureCard';
import { AddButton } from '../common/AddButton';

export interface EpicData {
  id: string;
  name: string;
}

export interface VersionData {
  id: string;
  name: string;
}

export interface EpicVersionCellData {
  epicId: string;
  versionId: string;
  features: FeatureCardData[];
}

interface EpicVersionGridProps {
  epics: EpicData[];
  versions: VersionData[];
  cells: EpicVersionCellData[];
}

export const EpicVersionGrid: React.FC<EpicVersionGridProps> = ({
  epics,
  versions,
  cells
}) => {
  const getCellData = (epicId: string, versionId: string): FeatureCardData[] => {
    const cell = cells.find(c => c.epicId === epicId && c.versionId === versionId);
    return cell ? cell.features : [];
  };

  return (
    <div className="epic-version-wrapper">
      <div className="epic-version-grid">
        {/* ヘッダー行 */}
        <div className="epic-version-label">Epic \ Version</div>
        {versions.map(version => (
          <div key={version.id} className="version-header">
            {version.name}
          </div>
        ))}

        {/* Epic行 */}
        {epics.map(epic => (
          <React.Fragment key={epic.id}>
            <div className="epic-header">{epic.name}</div>
            {versions.map(version => (
              <div
                key={`${epic.id}-${version.id}`}
                className="epic-version-cell"
                data-epic={epic.id}
                data-version={version.id}
              >
                <FeatureCardGrid features={getCellData(epic.id, version.id)} />
              </div>
            ))}
          </React.Fragment>
        ))}
      </div>

      <div className="new-version-wrapper">
        <AddButton
          type="version"
          label="+ New Version"
          dataAddButton="version"
          className="add-version-btn"
        />
      </div>

      <div className="new-epic-wrapper">
        <AddButton
          type="epic"
          label="+ New Epic"
          dataAddButton="epic"
          className="add-epic-btn"
        />
      </div>
    </div>
  );
};
