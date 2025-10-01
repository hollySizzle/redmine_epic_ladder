import React from 'react';
import { FeatureCardGrid } from '../Feature/FeatureCardGrid';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

export const EpicVersionGrid: React.FC = () => {
  // ストアから直接データを取得
  const grid = useStore(state => state.grid);
  const epics = useStore(state => state.entities.epics);
  const versions = useStore(state => state.entities.versions);

  return (
    <div className="epic-version-wrapper">
      <div className="epic-version-grid">
        {/* ヘッダー行 */}
        <div className="epic-version-label">Epic \ Version</div>
        {grid.version_order
          .filter(vId => vId !== 'none')
          .map(versionId => {
            const version = versions[versionId];
            return (
              <div key={versionId} className="version-header">
                {version.name}
              </div>
            );
          })}

        {/* Epic行 */}
        {grid.epic_order.map(epicId => {
          const epic = epics[epicId];
          return (
            <React.Fragment key={epicId}>
              <div className="epic-header">{epic.subject}</div>
              {grid.version_order
                .filter(vId => vId !== 'none')
                .map(versionId => {
                  const cellKey = `${epicId}:${versionId}`;
                  const featureIds = grid.index[cellKey] || [];

                  return (
                    <div
                      key={cellKey}
                      className="epic-version-cell"
                      data-epic={epicId}
                      data-version={versionId}
                    >
                      <FeatureCardGrid
                        featureIds={featureIds}
                        epicId={epicId}
                        versionId={versionId}
                      />
                    </div>
                  );
                })}
            </React.Fragment>
          );
        })}
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
