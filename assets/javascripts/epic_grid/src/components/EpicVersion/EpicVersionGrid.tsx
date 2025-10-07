import React, { useState } from 'react';
import { UserStoryGridForCell } from '../UserStory/UserStoryGridForCell';
import { AddButton } from '../common/AddButton';
import { VersionFormModal, VersionFormData } from '../common/VersionFormModal';
import { IssueFormModal, IssueFormData } from '../common/IssueFormModal';
import { useStore } from '../../store/useStore';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useDropTarget } from '../../hooks/useDropTarget';
import { formatDate } from '../../utils/dateFormat';
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
      {feature.subject}
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
      <UserStoryGridForCell
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

  // モーダル開閉状態
  const [isVersionModalOpen, setIsVersionModalOpen] = useState(false);
  const [isEpicModalOpen, setIsEpicModalOpen] = useState(false);
  const [isFeatureModalOpen, setIsFeatureModalOpen] = useState(false);
  const [selectedEpicId, setSelectedEpicId] = useState<string | null>(null);

  // versionの数を動的に取得
  const versionCount = grid.version_order.length;

  // grid-template-columnsを動的に生成 (Epic列 + Feature列 + Version列×N)
  const gridTemplateColumns = `var(--epic-width) var(--feature-width) repeat(${versionCount}, var(--version-width))`;

  const handleAddEpic = () => {
    setIsEpicModalOpen(true);
  };

  const handleEpicSubmit = async (data: IssueFormData) => {
    try {
      await createEpic({
        subject: data.subject,
        description: data.description,
        status: 'open'
      });
    } catch (error) {
      alert(`Epic作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  const handleAddVersion = () => {
    setIsVersionModalOpen(true);
  };

  const handleVersionSubmit = async (data: VersionFormData) => {
    try {
      await createVersion({
        name: data.name,
        description: '',
        status: 'open',
        effective_date: data.effective_date || undefined
      });
    } catch (error) {
      alert(`Version作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
    }
  };

  const handleAddFeature = (epicId: string) => {
    setSelectedEpicId(epicId);
    setIsFeatureModalOpen(true);
  };

  const handleFeatureSubmit = async (data: IssueFormData) => {
    if (!selectedEpicId) {
      console.error('[DEBUG] selectedEpicId is null!');
      alert('エラー: Epic IDが設定されていません');
      return;
    }

    console.log('[DEBUG] Creating Feature with epicId:', selectedEpicId);

    try {
      await createFeature({
        subject: data.subject,
        description: data.description,
        parent_epic_id: selectedEpicId,
        fixed_version_id: null,
      });
      console.log('[DEBUG] Feature created successfully');
    } catch (error) {
      console.error('[DEBUG] Feature creation error:', error);
      alert(`Feature作成に失敗しました: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw error; // モーダルでエラー処理するため再スロー
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
          const effectiveDate = version ? formatDate(version.effective_date) : null;
          return (
            <div key={versionId} className="version-header">
              <div className="version-name">{versionName}</div>
              {effectiveDate && (
                <div className="version-date">{effectiveDate}</div>
              )}
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
                <div className="epic-cell" data-epic={epicId}>
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
                  <div className="epic-cell" data-epic={epicId} style={{ gridRow: `span ${validFeatures.length}` }}>
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

      <VersionFormModal
        isOpen={isVersionModalOpen}
        onClose={() => setIsVersionModalOpen(false)}
        onSubmit={handleVersionSubmit}
      />

      <IssueFormModal
        isOpen={isEpicModalOpen}
        onClose={() => setIsEpicModalOpen(false)}
        onSubmit={handleEpicSubmit}
        title="新しいEpicを追加"
        subjectLabel="Epic名"
        subjectPlaceholder="例: ユーザー管理機能"
      />

      <IssueFormModal
        isOpen={isFeatureModalOpen}
        onClose={() => setIsFeatureModalOpen(false)}
        onSubmit={handleFeatureSubmit}
        title="新しいFeatureを追加"
        subjectLabel="Feature名"
        subjectPlaceholder="例: ログイン機能"
      />
    </div>
  );
};
