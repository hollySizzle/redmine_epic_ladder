import React from 'react';
import { UserStoryGrid } from '../UserStory/UserStoryGrid';
import { AddButton } from '../common/AddButton';
import { useStore } from '../../store/useStore';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useDropTarget } from '../../hooks/useDropTarget';
import type { Feature } from '../../types/normalized-api';

// Feature列のD&D対応コンポーネント
const DraggableFeatureCell: React.FC<{ feature: Feature }> = ({ feature }) => {
  const ref = useDraggableAndDropTarget({
    type: 'feature-card',
    id: feature.id,
    onDrop: (sourceData) => {
      console.log('Feature dropped:', sourceData.id, '→', feature.id);
    }
  });

  return (
    <div ref={ref} className="feature-cell draggable" data-feature={feature.id}>
      {feature.title}
    </div>
  );
};

// UserStoryセル: drop targetとして機能（ローカル操作に変更）
const UserStoryCell: React.FC<{
  epicId: string;
  featureId: string;
  versionId: string;
  storyIds: string[];
}> = ({ epicId, featureId, versionId, storyIds }) => {
  const moveUserStoryToCell = useStore(state => state.moveUserStoryToCell);

  const ref = useDropTarget({
    type: 'user-story',
    id: `cell-${epicId}-${featureId}-${versionId}`,
    data: { epicId, featureId, versionId, cellType: 'us-cell' },
    canDrop: (sourceData) => sourceData.type === 'user-story',
    onDrop: (sourceData) => {
      console.log('UserStory dropped on cell:', sourceData.id, '→', { epicId, featureId, versionId });

      // ローカル操作に変更（API呼び出しは保存ボタン押下時）
      moveUserStoryToCell(
        sourceData.id,
        epicId,
        featureId,
        versionId
      );
    }
  });

  return (
    <div
      ref={ref}
      className="us-cell"
      data-epic={epicId}
      data-feature={featureId}
      data-version={versionId}
    >
      <UserStoryGrid
        epicId={epicId}
        featureId={featureId}
        versionId={versionId}
        storyIds={storyIds}
      />
    </div>
  );
};

export const EpicVersionGrid: React.FC = () => {
  // ストアから直接データを取得
  const grid = useStore(state => state.grid);
  const epics = useStore(state => state.entities.epics);
  const features = useStore(state => state.entities.features);
  const versions = useStore(state => state.entities.versions);
  const createEpic = useStore(state => state.createEpic);
  const createVersion = useStore(state => state.createVersion);
  const createFeature = useStore(state => state.createFeature);
  

  // versionの数を動的に取得
  const versionCount = grid.version_order.length;

  // grid-template-columnsを動的に生成 (Epic列 + Feature列 + Version列×N)
  const gridTemplateColumns = `var(--epic-width) var(--feature-width) repeat(${versionCount}, var(--version-width))`;

  const handleAddEpic = async () => {
    console.log('[DEBUG] handleAddEpic called');
    console.log('[DEBUG] About to call prompt()...');
    const subject = prompt('Epic名を入力してください:');
    console.log('[DEBUG] prompt() returned:', subject);
    if (!subject) {
      console.log('[DEBUG] prompt() cancelled or empty, returning');
      return;
    }

    try {
      console.log('[DEBUG] Creating epic with subject:', subject);
      await createEpic({
        subject,
        description: '',
        status: 'open'
      });
      console.log('[DEBUG] Epic created successfully');
    } catch (error) {
      console.error('[DEBUG] Epic creation failed:', error);
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

  const handleAddFeature = async (epicId: string) => {
    const subject = prompt('Feature名を入力してください:');
    if (!subject) return;

    try {
      await createFeature({
        subject,
        description: '',
        parent_epic_id: epicId,
        fixed_version_id: null,
      });
    } catch (error) {
      alert(`Feature作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
    <div className="epic-version-wrapper">
      <div className="epic-feature-version-grid" style={{ gridTemplateColumns }}>
        {/* ヘッダー行 */}
        <div className="header-label">Epic</div>
        <div className="header-label">Feature</div>
        {grid.version_order.map(versionId => {
          const version = versions[versionId];
          // 'none' の場合はバージョン未設定として表示
          const versionName = version ? version.name : '(未設定)';
          return (
            <div key={versionId} className="version-header">
              {versionName}
            </div>
          );
        })}

        {/* Epic × Feature × Version の3次元グリッド */}
        {grid.epic_order.map(epicId => {
          const epic = epics[epicId];
          const epicFeatures = grid.feature_order_by_epic[epicId] || [];

          // 実際に存在するFeatureだけをフィルタ
          const validFeatures = epicFeatures.filter(fId => features[fId]);

          // Featureが0個の場合でもEpic列を表示
          if (validFeatures.length === 0) {
            return (
              <React.Fragment key={epicId}>
                <div className="epic-cell">
                  <div className="epic-name">{epic.subject}</div>
                  <AddButton
                    type="feature"
                    label="+ Add Feature"
                    dataAddButton="feature"
                    className="add-feature-btn"
                    onClick={() => handleAddFeature(epicId)}
                    epicId={epicId}
                  />
                </div>
                <div className="feature-cell empty-cell"></div>
                {grid.version_order.map(versionId => (
                  <div key={`${epicId}-empty-${versionId}`} className="us-cell empty-cell"></div>
                ))}
              </React.Fragment>
            );
          }

          return validFeatures.map((featureId, featureIndex) => {
            const feature = features[featureId];

            return (
              <React.Fragment key={`${epicId}-${featureId}`}>
                {/* Epic列 (1Epic分を縦に結合したイメージ) */}
                {featureIndex === 0 ? (
                  <div className="epic-cell" style={{ gridRow: `span ${validFeatures.length}` }}>
                    <div className="epic-name">{epic.subject}</div>
                    <AddButton
                      type="feature"
                      label="+ Add Feature"
                      dataAddButton="feature"
                      className="add-feature-btn"
                      onClick={() => handleAddFeature(epicId)}
                      epicId={epicId}
                    />
                  </div>
                ) : null}

                {/* Feature列 (D&D対応) */}
                <DraggableFeatureCell feature={feature} />

                {/* Version列 (UserStory一覧) */}
                {grid.version_order.map(versionId => {
                  const cellKey = `${epicId}:${featureId}:${versionId}`;
                  const userStoryIds = grid.index[cellKey] || [];

                  return (
                    <UserStoryCell
                      key={cellKey}
                      epicId={epicId}
                      featureId={featureId}
                      versionId={versionId}
                      storyIds={userStoryIds}
                    />
                  );
                })}
              </React.Fragment>
            );
          });
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
