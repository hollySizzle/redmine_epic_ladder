/**
 * realTimeUpdateHelpers - リアルタイム更新のヘルパー関数
 * 設計書仕様: データマージ、衝突処理、楽観的更新
 */

/**
 * リモートグリッド更新の適用
 */
export function applyRemoteGridUpdate(currentData, updateData) {
  if (!currentData) return currentData;

  const updatedData = JSON.parse(JSON.stringify(currentData)); // Deep copy

  // Issue更新の適用
  if (updateData.updated_issues && updateData.updated_issues.length > 0) {
    updateData.updated_issues.forEach(updatedIssue => {
      applyIssueUpdate(updatedData, updatedIssue);
    });
  }

  // Issue削除の適用
  if (updateData.deleted_issues && updateData.deleted_issues.length > 0) {
    updateData.deleted_issues.forEach(deletedIssueId => {
      removeIssueFromGrid(updatedData, deletedIssueId);
    });
  }

  // グリッド構造変更の適用
  if (updateData.grid_changes && updateData.grid_changes.length > 0) {
    updateData.grid_changes.forEach(change => {
      applyGridStructureChange(updatedData, change);
    });
  }

  return updatedData;
}

/**
 * リモートFeature移動の適用
 */
export function applyRemoteFeatureMove(currentData, moveData) {
  if (!currentData) return currentData;

  const updatedData = JSON.parse(JSON.stringify(currentData));

  // 移動対象のFeatureを更新
  applyIssueUpdate(updatedData, moveData.updated_issue);

  // 影響を受けるセルの統計情報更新
  if (moveData.affected_cells) {
    moveData.affected_cells.forEach(cellUpdate => {
      updateCellStatistics(updatedData, cellUpdate);
    });
  }

  return updatedData;
}

/**
 * リモートEpicの追加
 */
export function addRemoteEpic(currentData, epicData) {
  if (!currentData?.grid?.rows) return currentData;

  const updatedData = JSON.parse(JSON.stringify(currentData));

  const newEpicRow = {
    issue: epicData,
    features: [],
    statistics: {
      total_features: 0,
      completed_features: 0,
      completion_rate: 0
    },
    ui_state: {
      expanded: true
    }
  };

  updatedData.grid.rows.push(newEpicRow);

  return updatedData;
}

/**
 * リモートVersionの追加
 */
export function addRemoteVersion(currentData, versionData) {
  if (!currentData?.grid?.columns) return currentData;

  const updatedData = JSON.parse(JSON.stringify(currentData));

  const newVersionColumn = {
    id: versionData.id,
    name: versionData.name,
    description: versionData.description,
    effective_date: versionData.effective_date,
    status: versionData.status,
    issue_count: versionData.issue_count || 0,
    type: 'version'
  };

  // No Versionの前に挿入
  const noVersionIndex = updatedData.grid.columns.findIndex(col => col.type === 'no-version');
  if (noVersionIndex !== -1) {
    updatedData.grid.columns.splice(noVersionIndex, 0, newVersionColumn);
  } else {
    updatedData.grid.columns.push(newVersionColumn);
  }

  return updatedData;
}

/**
 * ポーリング更新の適用
 */
export function applyPollingUpdate(currentData, updateData) {
  if (!updateData.updates || updateData.updates.length === 0) {
    return currentData;
  }

  let updatedData = JSON.parse(JSON.stringify(currentData));

  updateData.updates.forEach(update => {
    switch (update.type) {
      case 'issue_updated':
        applyIssueUpdate(updatedData, update.data);
        break;
      case 'issue_deleted':
        removeIssueFromGrid(updatedData, update.data.issue_id);
        break;
      case 'epic_created':
        updatedData = addRemoteEpic(updatedData, update.data);
        break;
      case 'version_created':
        updatedData = addRemoteVersion(updatedData, update.data);
        break;
      default:
        console.warn('Unknown update type:', update.type);
    }
  });

  return updatedData;
}

/**
 * Issue更新の適用
 */
function applyIssueUpdate(gridData, updatedIssue) {
  // Epic行での更新
  if (updatedIssue.tracker.name === 'Epic') {
    const epicRow = gridData.grid.rows.find(row => row.issue.id === updatedIssue.id);
    if (epicRow) {
      epicRow.issue = updatedIssue;
    }
    return;
  }

  // Feature更新
  if (updatedIssue.tracker.name === 'Feature') {
    // 全Epic行からFeatureを検索して更新
    gridData.grid.rows.forEach(epicRow => {
      if (epicRow.features) {
        const featureIndex = epicRow.features.findIndex(
          feature => feature.issue.id === updatedIssue.id
        );
        if (featureIndex !== -1) {
          epicRow.features[featureIndex].issue = updatedIssue;

          // 統計情報の再計算
          recalculateEpicStatistics(epicRow);
        }
      }
    });

    // 孤児Feature更新
    if (gridData.orphan_features) {
      const orphanIndex = gridData.orphan_features.findIndex(
        feature => feature.issue.id === updatedIssue.id
      );
      if (orphanIndex !== -1) {
        gridData.orphan_features[orphanIndex].issue = updatedIssue;
      }
    }
  }
}

/**
 * Issueの削除
 */
function removeIssueFromGrid(gridData, issueId) {
  // Epic削除
  const epicIndex = gridData.grid.rows.findIndex(row => row.issue.id === issueId);
  if (epicIndex !== -1) {
    gridData.grid.rows.splice(epicIndex, 1);
    return;
  }

  // Feature削除
  gridData.grid.rows.forEach(epicRow => {
    if (epicRow.features) {
      const featureIndex = epicRow.features.findIndex(
        feature => feature.issue.id === issueId
      );
      if (featureIndex !== -1) {
        epicRow.features.splice(featureIndex, 1);
        recalculateEpicStatistics(epicRow);
      }
    }
  });

  // 孤児Feature削除
  if (gridData.orphan_features) {
    const orphanIndex = gridData.orphan_features.findIndex(
      feature => feature.issue.id === issueId
    );
    if (orphanIndex !== -1) {
      gridData.orphan_features.splice(orphanIndex, 1);
    }
  }
}

/**
 * グリッド構造変更の適用
 */
function applyGridStructureChange(gridData, change) {
  switch (change.type) {
    case 'version_added':
      if (!gridData.grid.versions.find(v => v.id === change.data.id)) {
        gridData.grid.versions.push(change.data);
      }
      break;
    case 'version_removed':
      gridData.grid.versions = gridData.grid.versions.filter(
        v => v.id !== change.data.version_id
      );
      break;
    case 'epic_reorder':
      // Epic順序の変更
      if (change.data.new_order) {
        const reorderedRows = [];
        change.data.new_order.forEach(epicId => {
          const row = gridData.grid.rows.find(r => r.issue.id === epicId);
          if (row) {
            reorderedRows.push(row);
          }
        });
        gridData.grid.rows = reorderedRows;
      }
      break;
    default:
      console.warn('Unknown grid structure change:', change.type);
  }
}

/**
 * セル統計情報の更新
 */
function updateCellStatistics(gridData, cellUpdate) {
  const { epic_id, version_id, statistics } = cellUpdate;

  // 対応するEpic行を検索
  const epicRow = gridData.grid.rows.find(row =>
    row.issue.id === epic_id || (epic_id === 'no-epic' && row.issue.id === null)
  );

  if (epicRow && statistics) {
    // セル統計情報の更新（必要に応じて実装）
    epicRow.statistics = {
      ...epicRow.statistics,
      ...statistics
    };
  }
}

/**
 * Epic統計情報の再計算
 */
function recalculateEpicStatistics(epicRow) {
  if (!epicRow.features) {
    epicRow.statistics = {
      total_features: 0,
      completed_features: 0,
      completion_rate: 0
    };
    return;
  }

  const totalFeatures = epicRow.features.length;
  const completedFeatures = epicRow.features.filter(feature =>
    ['Resolved', 'Closed'].includes(feature.issue.status.name)
  ).length;

  epicRow.statistics = {
    total_features: totalFeatures,
    completed_features: completedFeatures,
    completion_rate: totalFeatures > 0 ?
      Math.round((completedFeatures / totalFeatures) * 100) : 0
  };
}

/**
 * 楽観的更新のロールバック
 */
export function rollbackOptimisticUpdate(currentData, updateId) {
  // 楽観的更新の情報からロールバック処理を実行
  // 実装簡略化のため、データを再読み込みする方針
  console.warn(`Rolling back optimistic update ${updateId} - data refresh required`);
  return currentData;
}

/**
 * 既存のリアルタイム更新（レガシー）
 */
export function applyRealTimeUpdate(currentData, updateData) {
  // 既存のポーリングベース更新処理
  return applyPollingUpdate(currentData, updateData);
}

/**
 * データ整合性チェック
 */
export function validateGridDataConsistency(gridData) {
  const issues = [];

  if (!gridData?.grid?.rows) {
    issues.push('Missing grid rows');
    return issues;
  }

  if (!gridData?.grid?.columns) {
    issues.push('Missing grid columns');
    return issues;
  }

  // Epic行の整合性チェック
  gridData.grid.rows.forEach((row, index) => {
    if (!row.issue) {
      issues.push(`Epic row ${index} missing issue data`);
    }

    if (!Array.isArray(row.features)) {
      issues.push(`Epic row ${index} features is not array`);
    }

    // Feature重複チェック
    const featureIds = new Set();
    row.features?.forEach(feature => {
      if (featureIds.has(feature.issue.id)) {
        issues.push(`Duplicate feature ${feature.issue.id} in Epic ${row.issue.id}`);
      }
      featureIds.add(feature.issue.id);
    });
  });

  return issues;
}

export default {
  applyRemoteGridUpdate,
  applyRemoteFeatureMove,
  addRemoteEpic,
  addRemoteVersion,
  applyPollingUpdate,
  rollbackOptimisticUpdate,
  applyRealTimeUpdate,
  validateGridDataConsistency
};