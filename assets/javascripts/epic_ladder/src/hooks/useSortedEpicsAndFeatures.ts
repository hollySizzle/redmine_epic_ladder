import { useMemo } from 'react';
import { useStore } from '../store/useStore';

/**
 * Epic/Featureのソート済み順序を提供するカスタムフック
 *
 * EpicVersionGridとListTabで共通利用するソートロジック
 * - Epic順序: epicSortOptionsに基づいてソート
 * - Feature順序: Epic毎、epicSortOptionsに基づいてソート（Epic&Feature連動）
 */
export const useSortedEpicsAndFeatures = () => {
  const grid = useStore(state => state.grid);
  const epics = useStore(state => state.entities.epics);
  const features = useStore(state => state.entities.features);
  const epicSortOptions = useStore(state => state.epicSortOptions);

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

  return {
    sortedEpicOrder,
    getSortedFeatureIds
  };
};
