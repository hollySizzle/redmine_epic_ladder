import { useState, useMemo, useCallback } from 'react';
import { useDraggable } from '@dnd-kit/core';

/**
 * FeatureCard - 設計書準拠のFeatureカードコンポーネント
 * 設計書仕様: 階層表示（Feature → UserStory → Task/Test/Bug）、D&D対応（設計書55-116行目準拠）
 *
 * @param {Object} feature - Feature情報（issue, user_stories等含む）
 * @param {Object} cellCoordinates - セル座標情報（D&D用）
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {boolean} expanded - 展開状態
 * @param {boolean} isDragging - ドラッグ中フラグ
 * @param {number} featureIndex - Feature インデックス
 */
export const FeatureCard = ({
  feature,
  cellCoordinates,
  compactMode = false,
  expanded = false,
  isDragging = false,
  featureIndex
}) => {
  // 展開状態管理（設計書185-192行目準拠）
  const [expansionState, setExpansionState] = useState({
    featureExpanded: expanded,
    userStoriesExpanded: new Map()
  });

  // 編集状態管理
  const [editingState, setEditingState] = useState({
    isEditing: false,
    editingUserStory: null,
    editingItem: null
  });

  // エラー状態管理
  const [error, setError] = useState(null);

  // @dnd-kit ドラッグ可能設定
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    isDragging: dragKitIsDragging
  } = useDraggable({
    id: `feature-${feature.issue.id}`,
    data: {
      type: 'feature-card',
      feature: feature,
      currentCell: cellCoordinates
    }
  });

  // ドラッグスタイル計算
  const dragStyle = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    zIndex: isDragging || dragKitIsDragging ? 1000 : 'auto',
    opacity: isDragging || dragKitIsDragging ? 0.8 : 1
  } : {};

  // Feature基本情報（メモ化）
  const featureInfo = useMemo(() => {
    const issue = feature.issue || {};
    return {
      id: issue.id,
      subject: issue.subject || 'Untitled Feature',
      status: issue.status || 'New',
      priority: issue.priority || 'Normal',
      assigned_to: issue.assigned_to?.name || 'Unassigned',
      description: issue.description || '',
      estimated_hours: issue.estimated_hours || 0,
      done_ratio: issue.done_ratio || 0
    };
  }, [feature.issue]);

  // UserStories 情報（メモ化）
  const userStories = useMemo(() => {
    return feature.user_stories || [];
  }, [feature.user_stories]);

  // 統計情報計算（メモ化）
  const featureStatistics = useMemo(() => {
    const totalUserStories = userStories.length;
    const completedUserStories = userStories.filter(us =>
      ['Resolved', 'Closed'].includes(us.issue?.status)
    ).length;

    let totalTasks = 0;
    let completedTasks = 0;

    userStories.forEach(userStory => {
      const tasks = userStory.tasks || [];
      const tests = userStory.tests || [];
      const bugs = userStory.bugs || [];

      totalTasks += tasks.length + tests.length + bugs.length;
      completedTasks += [
        ...tasks.filter(t => ['Resolved', 'Closed'].includes(t.issue?.status)),
        ...tests.filter(t => ['Resolved', 'Closed'].includes(t.issue?.status)),
        ...bugs.filter(b => ['Resolved', 'Closed'].includes(b.issue?.status))
      ].length;
    });

    return {
      totalUserStories,
      completedUserStories,
      totalTasks,
      completedTasks,
      userStoryCompletionRate: totalUserStories > 0 ?
        Math.round((completedUserStories / totalUserStories) * 100) : 0,
      taskCompletionRate: totalTasks > 0 ?
        Math.round((completedTasks / totalTasks) * 100) : 0
    };
  }, [userStories]);

  // Feature展開/折り畳みトグル
  const toggleFeatureExpansion = useCallback(() => {
    setExpansionState(prev => ({
      ...prev,
      featureExpanded: !prev.featureExpanded
    }));
  }, []);

  // UserStory展開/折り畳みトグル（設計書190行目準拠）
  const toggleUserStoryExpansion = useCallback((userStoryId) => {
    setExpansionState(prev => {
      const newExpanded = new Map(prev.userStoriesExpanded);
      newExpanded.set(userStoryId, !newExpanded.get(userStoryId));
      return {
        ...prev,
        userStoriesExpanded: newExpanded
      };
    });
  }, []);

  // CRUD操作処理（設計書202-208行目準拠）
  const handleCreateUserStory = useCallback(async (featureId, data) => {
    try {
      // TODO: API呼び出し実装
      console.log('[FeatureCard] Creating UserStory:', { featureId, data });
    } catch (error) {
      setError(`UserStory作成エラー: ${error.message}`);
    }
  }, []);

  const handleUpdateUserStory = useCallback(async (id, data) => {
    try {
      // TODO: API呼び出し実装
      console.log('[FeatureCard] Updating UserStory:', { id, data });
    } catch (error) {
      setError(`UserStory更新エラー: ${error.message}`);
    }
  }, []);

  const handleDeleteUserStory = useCallback(async (id) => {
    try {
      // TODO: API呼び出し実装
      console.log('[FeatureCard] Deleting UserStory:', { id });
    } catch (error) {
      setError(`UserStory削除エラー: ${error.message}`);
    }
  }, []);

  return (
    <div
      ref={setNodeRef}
      className={`feature-card ${compactMode ? 'compact' : ''} ${isDragging || dragKitIsDragging ? 'dragging' : ''}`}
      data-feature-id={featureInfo.id}
      data-feature-index={featureIndex}
      style={dragStyle}
      {...attributes}
      {...listeners}
    >
      {/* Feature Header（設計書58-61行目準拠） */}
      <div className="feature-header">
        <div className="feature-title-section">
          <button
            className="feature-expand-toggle"
            onClick={toggleFeatureExpansion}
            title={expansionState.featureExpanded ? 'Featureを折りたたむ' : 'Featureを展開'}
          >
            <span className={`expand-icon ${expansionState.featureExpanded ? 'expanded' : ''}`}>
              ▼
            </span>
          </button>

          <div className="feature-title">
            <h4 title={featureInfo.description}>
              {featureInfo.subject}
            </h4>
            <div className="feature-metadata">
              <span className="feature-id">#{featureInfo.id}</span>
              <span className={`feature-status ${featureInfo.status.toLowerCase()}`}>
                {featureInfo.status}
              </span>
              {!compactMode && (
                <span className="feature-assigned">{featureInfo.assigned_to}</span>
              )}
            </div>
          </div>
        </div>

        {/* Feature統計情報 */}
        <div className="feature-statistics">
          <div className="stat-item">
            <span className="stat-value">{featureStatistics.totalUserStories}</span>
            <span className="stat-label">Stories</span>
          </div>
          {!compactMode && (
            <div className="stat-item">
              <span className="stat-value">{featureStatistics.userStoryCompletionRate}%</span>
              <span className="stat-label">Done</span>
            </div>
          )}
        </div>
      </div>

      {/* UserStory一覧（設計書62-83行目準拠・展開時のみ表示） */}
      {expansionState.featureExpanded && (
        <div className="user-story-list">
          {userStories.map((userStory) => {
            const isUserStoryExpanded = expansionState.userStoriesExpanded.get(userStory.issue.id);

            return (
              <div
                key={userStory.issue.id}
                className={`user-story-item ${isUserStoryExpanded ? 'expanded' : 'collapsed'}`}
              >
                {/* UserStory Header（設計書70-73行目準拠） */}
                <div className="user-story-header">
                  <button
                    className="user-story-expand-toggle"
                    onClick={() => toggleUserStoryExpansion(userStory.issue.id)}
                    title={isUserStoryExpanded ? 'UserStoryを折りたたむ' : 'UserStoryを展開'}
                  >
                    <span className={`expand-icon ${isUserStoryExpanded ? 'expanded' : ''}`}>
                      ▼
                    </span>
                  </button>

                  <div className="user-story-title">
                    <h5>{userStory.issue.subject || 'Untitled UserStory'}</h5>
                    <div className="user-story-metadata">
                      <span className="user-story-id">#{userStory.issue.id}</span>
                      <span className={`user-story-status ${userStory.issue.status?.toLowerCase()}`}>
                        {userStory.issue.status}
                      </span>
                    </div>
                  </div>

                  {!compactMode && (
                    <button
                      className="user-story-delete-button"
                      onClick={() => handleDeleteUserStory(userStory.issue.id)}
                      title="UserStoryを削除"
                    >
                      ×
                    </button>
                  )}
                </div>

                {/* Task/Test/Bug コンテナ群（設計書75-83行目準拠・UserStory展開時のみ表示） */}
                {isUserStoryExpanded && (
                  <div className="item-containers">
                    {/* Task Container（設計書75行目準拠） */}
                    <div className="task-container">
                      <div className="container-header">
                        <h6>Tasks ({userStory.tasks?.length || 0})</h6>
                      </div>
                      <div className="container-items">
                        {(userStory.tasks || []).map(task => (
                          <div key={task.issue.id} className="base-item-card task-card">
                            <span className="item-title">{task.issue.subject}</span>
                            <span className={`item-status ${task.issue.status?.toLowerCase()}`}>
                              {task.issue.status}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Test Container（設計書76行目準拠） */}
                    <div className="test-container">
                      <div className="container-header">
                        <h6>Tests ({userStory.tests?.length || 0})</h6>
                      </div>
                      <div className="container-items">
                        {(userStory.tests || []).map(test => (
                          <div key={test.issue.id} className="base-item-card test-card">
                            <span className="item-title">{test.issue.subject}</span>
                            <span className={`item-status ${test.issue.status?.toLowerCase()}`}>
                              {test.issue.status}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Bug Container（設計書77行目準拠） */}
                    <div className="bug-container">
                      <div className="container-header">
                        <h6>Bugs ({userStory.bugs?.length || 0})</h6>
                      </div>
                      <div className="container-items">
                        {(userStory.bugs || []).map(bug => (
                          <div key={bug.issue.id} className="base-item-card bug-card">
                            <span className="item-title">{bug.issue.subject}</span>
                            <span className={`item-status ${bug.issue.status?.toLowerCase()}`}>
                              {bug.issue.status}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}

          {/* Add UserStory Button（設計書63行目準拠） */}
          {!compactMode && (
            <div className="add-user-story-section">
              <button
                className="add-user-story-button"
                onClick={() => handleCreateUserStory(featureInfo.id, { subject: 'New UserStory' })}
                title="新しいUserStoryを追加"
              >
                <span className="plus-icon">+</span>
                <span className="button-text">Add UserStory</span>
              </button>
            </div>
          )}
        </div>
      )}

      {/* 折りたたみ時のサマリー表示 */}
      {!expansionState.featureExpanded && (
        <div className="feature-collapsed-summary">
          <div className="summary-stats">
            {featureStatistics.totalUserStories} UserStories
            {featureStatistics.totalTasks > 0 && (
              <span> • {featureStatistics.totalTasks} Tasks</span>
            )}
            <span> • {featureStatistics.taskCompletionRate}% Complete</span>
          </div>
        </div>
      )}

      {/* エラー表示 */}
      {error && (
        <div className="feature-card-error">
          <div className="error-message">{error}</div>
          <button
            className="error-dismiss"
            onClick={() => setError(null)}
          >
            ×
          </button>
        </div>
      )}

      {/* ドラッグインジケーター */}
      {(isDragging || dragKitIsDragging) && (
        <div className="drag-indicator">
          <div className="drag-handle">
            <span>移動中...</span>
          </div>
        </div>
      )}
    </div>
  );
};

export default FeatureCard;