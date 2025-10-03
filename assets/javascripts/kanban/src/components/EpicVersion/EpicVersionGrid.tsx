import React from 'react';
import { FeatureCardGrid } from '../Feature/FeatureCardGrid';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';

export const EpicVersionGrid: React.FC = () => {
  // ストアから直接データを取得
  const grid = useStore(state => state.grid);
  const epics = useStore(state => state.entities.epics);
  const versions = useStore(state => state.entities.versions);
  const createEpic = useStore(state => state.createEpic);
  const createVersion = useStore(state => state.createVersion);

  // versionの数を動的に取得（'none'を除く）
  const versionCount = grid.version_order.filter(vId => vId !== 'none').length;

  // grid-template-columnsを動的に生成
  const gridTemplateColumns = `var(--epic-width) repeat(${versionCount}, var(--version-width))`;

  const handleAddEpic = async () => {
    const subject = prompt('Epic名を入力してください:');
    if (!subject) return;

    try {
      await createEpic({
        subject,
        description: '',
        status: 'open'
      });
    } catch (error) {
      alert(`Epic作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const handleAddVersion = async () => {
    const name = prompt('Version名を入力してください:');
    if (!name) return;

    try {
      await createVersion({
        name,
        description: '',
        status: 'open'
      });
    } catch (error) {
      alert(`Version作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
    <div className="epic-version-wrapper">
      <div className="epic-version-grid" style={{ gridTemplateColumns }}>
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
          onClick={handleAddVersion}
        />
      </div>

      <div className="new-epic-wrapper">
        <AddButton
          type="epic"
          label="+ New Epic"
          dataAddButton="epic"
          className="add-epic-btn"
          onClick={handleAddEpic}
        />
      </div>
    </div>
  );
};
