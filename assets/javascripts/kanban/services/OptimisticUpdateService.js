/**
 * OptimisticUpdateService - 設計書準拠の楽観的更新サービス
 * 設計書仕様: 楽観的更新、ロールバック、衝突処理、履歴管理
 */
export class OptimisticUpdateService {
  constructor() {
    // 楽観的更新履歴管理
    this.updateHistory = new Map();
    this.rollbackHistory = new Map();
    this.conflictHistory = new Map();

    // 統計情報
    this.stats = {
      totalUpdates: 0,
      successfulUpdates: 0,
      rolledBackUpdates: 0,
      conflicts: 0,
      averageLatency: 0
    };
  }

  /**
   * 楽観的更新の実行
   */
  async executeOptimisticUpdate(updateType, updateData, callback) {
    const updateId = this.generateUpdateId();
    const timestamp = Date.now();

    // 更新前の状態をスナップショット
    const snapshot = this.createStateSnapshot(updateData);

    try {
      // 1. 楽観的にUIを即座に更新
      const optimisticResult = this.applyOptimisticChange(updateType, updateData);

      // 2. 更新履歴に記録
      this.recordOptimisticUpdate(updateId, {
        type: updateType,
        data: updateData,
        snapshot: snapshot,
        timestamp: timestamp,
        status: 'pending'
      });

      // 3. UIコールバック実行
      if (callback) {
        callback({
          type: 'OPTIMISTIC_UPDATE',
          payload: {
            updateId: updateId,
            updatedData: optimisticResult,
            update: {
              id: updateId,
              type: updateType,
              data: updateData,
              timestamp: timestamp
            }
          }
        });
      }

      // 4. サーバーに実際の更新リクエスト送信
      const serverResult = await this.sendServerUpdate(updateType, updateData, updateId);

      // 5. サーバー更新成功時の処理
      this.handleServerSuccess(updateId, serverResult, callback);

      this.stats.totalUpdates++;
      this.stats.successfulUpdates++;
      this.updateAverageLatency(Date.now() - timestamp);

      return {
        success: true,
        updateId: updateId,
        result: serverResult
      };

    } catch (error) {
      // 6. サーバー更新失敗時のロールバック
      this.handleServerFailure(updateId, error, callback);

      this.stats.totalUpdates++;
      this.stats.rolledBackUpdates++;

      throw {
        success: false,
        updateId: updateId,
        error: error,
        requiresRollback: true
      };
    }
  }

  /**
   * 楽観的変更の適用
   */
  applyOptimisticChange(updateType, updateData) {
    switch (updateType) {
      case 'move_feature':
        return this.applyOptimisticFeatureMove(updateData);
      case 'create_epic':
        return this.applyOptimisticEpicCreate(updateData);
      case 'create_version':
        return this.applyOptimisticVersionCreate(updateData);
      case 'assign_version':
        return this.applyOptimisticVersionAssign(updateData);
      case 'update_issue':
        return this.applyOptimisticIssueUpdate(updateData);
      default:
        throw new Error(`Unknown optimistic update type: ${updateType}`);
    }
  }

  /**
   * Feature移動の楽観的更新
   */
  applyOptimisticFeatureMove(moveData) {
    const { feature_id, source_cell, target_cell, currentGridData } = moveData;

    // グリッドデータのディープコピー
    const updatedData = JSON.parse(JSON.stringify(currentGridData));

    // Feature を移動元から除去
    const sourceFeature = this.removeFeatureFromCell(updatedData, source_cell, feature_id);
    if (!sourceFeature) {
      throw new Error(`Feature ${feature_id} not found in source cell`);
    }

    // Feature の属性を更新（楽観的）
    const updatedFeature = {
      ...sourceFeature,
      issue: {
        ...sourceFeature.issue,
        parent_id: target_cell.epic_id !== 'no-epic' ? target_cell.epic_id : null,
        fixed_version_id: target_cell.version_id !== 'no-version' ? target_cell.version_id : null,
        lock_version: sourceFeature.issue.lock_version + 1, // 楽観ロック
        updated_on: new Date().toISOString()
      }
    };

    // Feature を移動先に追加
    this.addFeatureToCell(updatedData, target_cell, updatedFeature);

    // 統計情報の再計算
    this.recalculateAffectedCellStats(updatedData, [source_cell, target_cell]);

    return updatedData;
  }

  /**
   * Epic作成の楽観的更新
   */
  applyOptimisticEpicCreate(createData) {
    const { epic_data, currentGridData } = createData;
    const updatedData = JSON.parse(JSON.stringify(currentGridData));

    // 楽観的な新Epic ID生成（負数を使用してサーバーIDと区別）
    const optimisticId = -Date.now();

    const newEpic = {
      id: optimisticId,
      subject: epic_data.subject,
      description: epic_data.description,
      tracker: { id: 1, name: 'Epic' }, // Epic トラッカー
      status: { id: 1, name: 'New' },
      assigned_to: epic_data.assigned_to_id ? { id: epic_data.assigned_to_id } : null,
      fixed_version: epic_data.fixed_version_id ? { id: epic_data.fixed_version_id } : null,
      parent: null,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      lock_version: 0,
      is_optimistic: true // 楽観的更新フラグ
    };

    // Epic行をグリッドに追加
    const newEpicRow = {
      issue: newEpic,
      features: [],
      statistics: {
        total_features: 0,
        completed_features: 0,
        completion_rate: 0
      },
      ui_state: { expanded: true }
    };

    updatedData.grid.rows.push(newEpicRow);

    return updatedData;
  }

  /**
   * Version作成の楽観的更新
   */
  applyOptimisticVersionCreate(createData) {
    const { version_data, currentGridData } = createData;
    const updatedData = JSON.parse(JSON.stringify(currentGridData));

    const optimisticId = -Date.now();

    const newVersion = {
      id: optimisticId,
      name: version_data.name,
      description: version_data.description,
      effective_date: version_data.effective_date,
      status: version_data.status || 'open',
      issue_count: 0,
      type: 'version',
      is_optimistic: true
    };

    // No Versionの前に挿入
    const noVersionIndex = updatedData.grid.columns.findIndex(col => col.type === 'no-version');
    if (noVersionIndex !== -1) {
      updatedData.grid.columns.splice(noVersionIndex, 0, newVersion);
    } else {
      updatedData.grid.columns.push(newVersion);
    }

    return updatedData;
  }

  /**
   * Version割当の楽観的更新
   */
  applyOptimisticVersionAssign(assignData) {
    const { issue_id, version_id, currentGridData } = assignData;
    const updatedData = JSON.parse(JSON.stringify(currentGridData));

    // 対象Issueを検索して更新
    const updated = this.findAndUpdateIssue(updatedData, issue_id, (issue) => ({
      ...issue,
      fixed_version_id: version_id,
      lock_version: issue.lock_version + 1,
      updated_on: new Date().toISOString()
    }));

    if (!updated) {
      throw new Error(`Issue ${issue_id} not found for version assignment`);
    }

    return updatedData;
  }

  /**
   * Issue更新の楽観的更新
   */
  applyOptimisticIssueUpdate(updateData) {
    const { issue_id, updates, currentGridData } = updateData;
    const updatedData = JSON.parse(JSON.stringify(currentGridData));

    const updated = this.findAndUpdateIssue(updatedData, issue_id, (issue) => ({
      ...issue,
      ...updates,
      lock_version: issue.lock_version + 1,
      updated_on: new Date().toISOString()
    }));

    if (!updated) {
      throw new Error(`Issue ${issue_id} not found for update`);
    }

    return updatedData;
  }

  /**
   * サーバー更新の送信
   */
  async sendServerUpdate(updateType, updateData, updateId) {
    const { GridV2API } = await import('./GridV2API.js');

    // WebSocket 通知（楽観的更新の伝播）
    this.notifyOptimisticUpdate(updateType, updateData, updateId);

    switch (updateType) {
      case 'move_feature':
        return await GridV2API.moveFeature(updateData.project_id, {
          feature_id: updateData.feature_id,
          source_cell: updateData.source_cell,
          target_cell: updateData.target_cell,
          lock_version: updateData.lock_version
        });

      case 'create_epic':
        return await GridV2API.createEpic(updateData.project_id, updateData.epic_data);

      case 'create_version':
        return await GridV2API.createVersion(updateData.project_id, updateData.version_data);

      case 'assign_version':
        return await GridV2API.assignVersion(updateData.project_id, {
          issue_id: updateData.issue_id,
          version_id: updateData.version_id
        });

      default:
        throw new Error(`Server update not supported for type: ${updateType}`);
    }
  }

  /**
   * サーバー成功時の処理
   */
  handleServerSuccess(updateId, serverResult, callback) {
    const update = this.updateHistory.get(updateId);
    if (update) {
      update.status = 'success';
      update.serverResult = serverResult;
      update.completedAt = Date.now();
    }

    if (callback) {
      callback({
        type: 'MOVE_SUCCESS',
        payload: {
          updateId: updateId,
          updatedData: serverResult.updated_data || serverResult.data,
          serverResult: serverResult
        }
      });
    }
  }

  /**
   * サーバー失敗時のロールバック処理
   */
  handleServerFailure(updateId, error, callback) {
    const update = this.updateHistory.get(updateId);
    if (update) {
      update.status = 'failed';
      update.error = error;
      update.failedAt = Date.now();

      // ロールバック履歴に記録
      this.rollbackHistory.set(updateId, {
        originalUpdate: update,
        rollbackAt: Date.now(),
        reason: error.message || 'Unknown error'
      });
    }

    // 衝突検出
    if (error.status === 409 || error.isOptimisticUpdateConflict?.()) {
      this.handleOptimisticConflict(updateId, error);
    }

    if (callback) {
      callback({
        type: 'MOVE_ROLLBACK',
        payload: {
          updateId: updateId,
          error: error.message || 'Update failed'
        }
      });
    }
  }

  /**
   * 楽観的更新衝突の処理
   */
  handleOptimisticConflict(updateId, conflictError) {
    this.stats.conflicts++;

    const conflictData = {
      updateId: updateId,
      conflictType: conflictError.details?.conflict_type || 'unknown',
      detectedAt: Date.now(),
      serverState: conflictError.details?.actual_state,
      clientState: conflictError.details?.expected_state
    };

    this.conflictHistory.set(updateId, conflictData);

    console.warn('[OptimisticUpdate] Conflict detected:', conflictData);
  }

  /**
   * WebSocket楽観的更新通知
   */
  notifyOptimisticUpdate(updateType, updateData, updateId) {
    // GridWebSocketService への通知
    import('./GridWebSocketService.js').then(({ GridWebSocketService }) => {
      const wsService = GridWebSocketService.getInstance(
        updateData.project_id,
        updateData.user_id
      );

      if (wsService) {
        wsService.notifyOptimisticUpdate(updateType, {
          ...updateData,
          update_id: updateId,
          local_timestamp: Date.now()
        });
      }
    });
  }

  /**
   * ヘルパーメソッド群
   */

  generateUpdateId() {
    return `opt_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
  }

  createStateSnapshot(updateData) {
    return {
      timestamp: Date.now(),
      gridData: updateData.currentGridData,
      userAction: updateData.userAction || 'unknown'
    };
  }

  recordOptimisticUpdate(updateId, updateRecord) {
    this.updateHistory.set(updateId, updateRecord);

    // 履歴サイズ制限（メモリリーク防止）
    if (this.updateHistory.size > 1000) {
      const oldestKey = this.updateHistory.keys().next().value;
      this.updateHistory.delete(oldestKey);
    }
  }

  removeFeatureFromCell(gridData, sourceCell, featureId) {
    let removedFeature = null;

    // Epic行からFeature削除
    gridData.grid.rows.forEach(epicRow => {
      if (this.cellMatches(epicRow, sourceCell.epic_id)) {
        const featureIndex = epicRow.features.findIndex(f => f.issue.id === featureId);
        if (featureIndex !== -1) {
          removedFeature = epicRow.features.splice(featureIndex, 1)[0];
        }
      }
    });

    // 孤児Feature削除
    if (!removedFeature && gridData.orphan_features) {
      const orphanIndex = gridData.orphan_features.findIndex(f => f.issue.id === featureId);
      if (orphanIndex !== -1) {
        removedFeature = gridData.orphan_features.splice(orphanIndex, 1)[0];
      }
    }

    return removedFeature;
  }

  addFeatureToCell(gridData, targetCell, feature) {
    if (targetCell.epic_id === 'no-epic') {
      // 孤児Feature として追加
      gridData.orphan_features = gridData.orphan_features || [];
      gridData.orphan_features.push(feature);
    } else {
      // Epic行に追加
      const targetEpic = gridData.grid.rows.find(row =>
        this.cellMatches(row, targetCell.epic_id)
      );
      if (targetEpic) {
        targetEpic.features = targetEpic.features || [];
        targetEpic.features.push(feature);
      }
    }
  }

  cellMatches(epicRow, epicId) {
    if (epicId === 'no-epic') {
      return !epicRow.issue.id || epicRow.issue.parent_id === null;
    }
    return epicRow.issue.id === epicId;
  }

  findAndUpdateIssue(gridData, issueId, updateFn) {
    // Epic行で検索
    for (const epicRow of gridData.grid.rows) {
      if (epicRow.issue.id === issueId) {
        epicRow.issue = updateFn(epicRow.issue);
        return true;
      }

      // Epic内のFeatureで検索
      if (epicRow.features) {
        for (const feature of epicRow.features) {
          if (feature.issue.id === issueId) {
            feature.issue = updateFn(feature.issue);
            return true;
          }
        }
      }
    }

    // 孤児Featureで検索
    if (gridData.orphan_features) {
      for (const orphanFeature of gridData.orphan_features) {
        if (orphanFeature.issue.id === issueId) {
          orphanFeature.issue = updateFn(orphanFeature.issue);
          return true;
        }
      }
    }

    return false;
  }

  recalculateAffectedCellStats(gridData, cells) {
    cells.forEach(cell => {
      const epicRow = gridData.grid.rows.find(row =>
        this.cellMatches(row, cell.epic_id)
      );

      if (epicRow && epicRow.features) {
        const totalFeatures = epicRow.features.length;
        const completedFeatures = epicRow.features.filter(f =>
          ['Resolved', 'Closed'].includes(f.issue.status.name)
        ).length;

        epicRow.statistics = {
          total_features: totalFeatures,
          completed_features: completedFeatures,
          completion_rate: totalFeatures > 0 ?
            Math.round((completedFeatures / totalFeatures) * 100) : 0
        };
      }
    });
  }

  updateAverageLatency(latency) {
    const alpha = 0.1; // 平滑化係数
    this.stats.averageLatency = this.stats.averageLatency * (1 - alpha) + latency * alpha;
  }

  /**
   * 統計情報とデバッグ情報
   */
  getStatistics() {
    return {
      ...this.stats,
      pendingUpdates: Array.from(this.updateHistory.values()).filter(u => u.status === 'pending').length,
      recentConflicts: Array.from(this.conflictHistory.values()).filter(
        c => Date.now() - c.detectedAt < 60000 // 直近1分間
      ).length,
      rollbackRate: this.stats.totalUpdates > 0 ?
        (this.stats.rolledBackUpdates / this.stats.totalUpdates * 100).toFixed(2) + '%' : '0%'
    };
  }

  getUpdateHistory(limit = 50) {
    return Array.from(this.updateHistory.entries())
      .sort(([,a], [,b]) => b.timestamp - a.timestamp)
      .slice(0, limit)
      .map(([id, update]) => ({ id, ...update }));
  }

  clearHistory() {
    this.updateHistory.clear();
    this.rollbackHistory.clear();
    this.conflictHistory.clear();
  }
}

// シングルトンインスタンス
let optimisticUpdateServiceInstance = null;

export function getOptimisticUpdateService() {
  if (!optimisticUpdateServiceInstance) {
    optimisticUpdateServiceInstance = new OptimisticUpdateService();
  }
  return optimisticUpdateServiceInstance;
}

export default OptimisticUpdateService;