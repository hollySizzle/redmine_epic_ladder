import React, { useMemo, useState } from 'react';
import { useDraggableAndDropTarget } from '../../hooks/useDraggableAndDropTarget';
import { useDropTarget } from '../../hooks/useDropTarget';
import { useStore } from '../../store/useStore';
import type { Feature } from '../../types/normalized-api';
import { formatDateWithDayOfWeek } from '../../utils/dateFormat';
import { UserStoryGridForCell } from '../UserStory/UserStoryGridForCell';
import { AddButton } from '../common/AddButton';
import { IssueFormData, IssueFormModal } from '../common/IssueFormModal';
import { VersionFormData, VersionFormModal } from '../common/VersionFormModal';

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
  const users = useStore(state => Object.values(state.entities.users || {}));
  const setSelectedEntity = useStore(state => state.setSelectedEntity);
  const toggleDetailPane = useStore(state => state.toggleDetailPane);
  const isDetailPaneVisible = useStore(state => state.isDetailPaneVisible);
  const epicSortOptions = useStore(state => state.epicSortOptions);
  const versionSortOptions = useStore(state => state.versionSortOptions);
  const filters = useStore(state => state.filters);
  const hideEmptyEpicsVersions = useStore(state => state.hideEmptyEpicsVersions);

  // Epic順序をソート設定に基づいて動的にソート
  const sortedEpicOrder = useMemo(() => {
    const epicIds = [...grid.epic_order];
    const { sort_by, sort_direction } = epicSortOptions;

    // subject ソートの場合はサーバー側の順序をそのまま使用（自然順ソート済み）
    if (sort_by === 'subject') {
      return sort_direction === 'asc' ? epicIds : [...epicIds].reverse();
    }

    // id, date の場合はフロントエンドでソート
    return epicIds.sort((aId, bId) => {
      const epicA = epics[aId];
      const epicB = epics[bId];
      if (!epicA || !epicB) return 0;

      let comparison = 0;

      if (sort_by === 'date') {
        // start_date がnullの場合は先頭に配置
        const dateA = epicA.statistics?.completion_percentage || 0; // TODO: Epic型にstart_dateを追加
        const dateB = epicB.statistics?.completion_percentage || 0;
        comparison = dateA - dateB;
      } else if (sort_by === 'id') {
        comparison = parseInt(aId) - parseInt(bId);
      }

      return sort_direction === 'asc' ? comparison : -comparison;
    });
  }, [grid.epic_order, epics, epicSortOptions]);

  // Feature順序をソート設定に基づいて動的にソート（Epic&Feature並び替え）
  const getSortedFeatureIds = useMemo(() => {
    return (epicId: string): string[] => {
      const featureIds = grid.feature_order_by_epic[epicId] || [];
      const { sort_by, sort_direction } = epicSortOptions;

      // subject ソートの場合はサーバー側の順序をそのまま使用（自然順ソート済み）
      if (sort_by === 'subject') {
        return sort_direction === 'asc' ? featureIds : [...featureIds].reverse();
      }

      // id, date の場合はフロントエンドでソート
      const sorted = [...featureIds].sort((aId, bId) => {
        const featureA = features[aId];
        const featureB = features[bId];
        if (!featureA || !featureB) return 0;

        let comparison = 0;

        if (sort_by === 'date') {
          // start_date がnullの場合は先頭に配置
          const dateA = featureA.statistics?.completion_percentage || 0; // TODO: Feature型にstart_dateを追加
          const dateB = featureB.statistics?.completion_percentage || 0;
          comparison = dateA - dateB;
        } else if (sort_by === 'id') {
          comparison = parseInt(aId) - parseInt(bId);
        }

        return sort_direction === 'asc' ? comparison : -comparison;
      });
      return sorted;
    };
  }, [grid.feature_order_by_epic, features, epicSortOptions]);

  // Version順序をソート設定に基づいて動的にソート
  const sortedVersionOrder = useMemo(() => {
    const versionIds = [...grid.version_order];
    // 'none'は常に最後に配置
    const noneIndex = versionIds.indexOf('none');
    if (noneIndex !== -1) {
      versionIds.splice(noneIndex, 1);
    }

    const sorted = versionIds.sort((aId, bId) => {
      const versionA = versions[aId];
      const versionB = versions[bId];
      if (!versionA || !versionB) return 0;

      const { sort_by, sort_direction } = versionSortOptions;
      let comparison = 0;

      if (sort_by === 'date') {
        // effective_date がnullの場合は先頭に配置
        const dateA = versionA.effective_date ? new Date(versionA.effective_date).getTime() : 0;
        const dateB = versionB.effective_date ? new Date(versionB.effective_date).getTime() : 0;
        comparison = dateA - dateB;
      } else if (sort_by === 'id') {
        comparison = parseInt(aId) - parseInt(bId);
      } else if (sort_by === 'subject') {
        comparison = versionA.name.localeCompare(versionB.name);
      }

      return sort_direction === 'asc' ? comparison : -comparison;
    });

    // 'none'を最後に追加
    if (noneIndex !== -1) {
      sorted.push('none');
    }

    return sorted;
  }, [grid.version_order, versions, versionSortOptions]);

  // フィルタが設定されているかチェック
  const hasActiveFilters = useMemo(() => {
    return !!(
      filters.fixed_version_id_in?.length ||
      filters.assigned_to_id_in?.length ||
      filters.tracker_id_in?.length ||
      filters.status_id_in?.length ||
      filters.parent_id_in?.length ||
      filters.fixed_version_effective_date_gteq ||
      filters.fixed_version_effective_date_lteq
    );
  }, [filters]);

  // Epicにヒットするデータがあるかチェック
  const hasEpicData = useMemo(() => {
    if (!hideEmptyEpicsVersions || !hasActiveFilters) {
      return new Set(sortedEpicOrder); // 全Epic表示
    }

    const epicIdsWithData = new Set<string>();

    sortedEpicOrder.forEach(epicId => {
      const epicFeatures = getSortedFeatureIds(epicId);
      // Featureが1つでも存在すればそのEpicは表示
      if (epicFeatures.some(fId => features[fId])) {
        epicIdsWithData.add(epicId);
      }
    });

    return epicIdsWithData;
  }, [hideEmptyEpicsVersions, hasActiveFilters, sortedEpicOrder, getSortedFeatureIds, features]);

  // Versionにヒットするデータがあるかチェック
  const hasVersionData = useMemo(() => {
    if (!hideEmptyEpicsVersions || !hasActiveFilters) {
      return new Set(sortedVersionOrder); // 全Version表示
    }

    const versionIdsWithData = new Set<string>();

    sortedVersionOrder.forEach(versionId => {
      // grid.indexから該当Versionを含むセルを検索
      const hasData = Object.keys(grid.index).some(cellKey => {
        const [, , vId] = cellKey.split(':');
        const storyIds = grid.index[cellKey] || [];
        return vId === versionId && storyIds.length > 0;
      });

      if (hasData) {
        versionIdsWithData.add(versionId);
      }
    });

    return versionIdsWithData;
  }, [hideEmptyEpicsVersions, hasActiveFilters, sortedVersionOrder, grid.index]);

  // フィルタ適用後のEpic/Version順序
  const filteredEpicOrder = useMemo(() => {
    return sortedEpicOrder.filter(epicId => hasEpicData.has(epicId));
  }, [sortedEpicOrder, hasEpicData]);

  const filteredVersionOrder = useMemo(() => {
    return sortedVersionOrder.filter(versionId => hasVersionData.has(versionId));
  }, [sortedVersionOrder, hasVersionData]);

  // モーダル開閉状態
  const [isVersionModalOpen, setIsVersionModalOpen] = useState(false);
  const [isEpicModalOpen, setIsEpicModalOpen] = useState(false);
  const [isFeatureModalOpen, setIsFeatureModalOpen] = useState(false);
  const [selectedEpicId, setSelectedEpicId] = useState<string | null>(null);

  // versionの数を動的に取得（フィルタ適用後）
  const versionCount = filteredVersionOrder.length;

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
        assigned_to_id: data.assigned_to_id
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
        {filteredVersionOrder.map(versionId => {
          const version = versions[versionId];
          // 'none' の場合はバージョン未設定として表示
          const versionName = version ? version.name : '(未設定)';
          const effectiveDate = version ? formatDateWithDayOfWeek(version.effective_date) : null;

          const handleVersionClick = () => {
            // 詳細ペインが非表示の場合は開く
            if (!isDetailPaneVisible) {
              toggleDetailPane();
            }
            // versionIdが'none'の場合はクリック無効
            if (versionId !== 'none' && version) {
              setSelectedEntity('version', versionId);
            }
          };

          return (
            <div
              key={versionId}
              className={`version-header ${versionId !== 'none' && version ? 'clickable' : ''}`}
              onClick={handleVersionClick}
              style={{ cursor: versionId !== 'none' && version ? 'pointer' : 'default' }}
            >
              <div className="version-name">{versionName}</div>
              {effectiveDate && (
                <div className="version-date">{effectiveDate}</div>
              )}
            </div>
          );
        })}

        {/* Epic × Feature × Version の3次元グリッド */}
        {filteredEpicOrder.map(epicId => {
          const epic = epics[epicId];
          const epicFeatures = getSortedFeatureIds(epicId);

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
                {filteredVersionOrder.map(versionId => (
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
                {filteredVersionOrder.map(versionId => {
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

      {/* <div className='scroll_information'>
        <p>Shift + Scroll で横移動</p>
      </div> */}

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
        showAssignee={true}
        users={users}
      />
    </div>
  );
};
