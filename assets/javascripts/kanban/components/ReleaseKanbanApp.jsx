import React, { useState, useEffect } from 'react';
import { KanbanBoard } from './KanbanBoard';
import { VersionBar } from './VersionBar';
import { BatchActionPanel } from './BatchActionPanel';
import { ApiClient } from '../utils/ApiClient';

// リリースカンバンのメインアプリケーションコンポーネント
// 7つのコンポーネントを統合した全体統括
export const ReleaseKanbanApp = ({ projectId, currentUser, initialData }) => {
  const [kanbanData, setKanbanData] = useState(initialData || null);
  const [selectedCards, setSelectedCards] = useState([]);
  const [selectedVersion, setSelectedVersion] = useState(null);
  const [loading, setLoading] = useState(!initialData);
  const [error, setError] = useState(null);
  const [apiClient] = useState(() => new ApiClient(projectId));

  // 初期化処理
  useEffect(() => {
    if (!initialData) {
      loadInitialData();
    }
  }, [projectId]);

  const loadInitialData = async () => {
    try {
      setLoading(true);
      setError(null);

      // 接続テストを実行
      await testApiConnection();

      // カンバンデータを読み込み
      const data = await apiClient.getKanbanData();
      setKanbanData(data);

      console.log('ReleaseKanban初期化完了:', {
        project: data.project?.name,
        issues: data.issues?.length,
        columns: data.columns?.length
      });
    } catch (err) {
      console.warn('API未実装、モックモードで動作:', err);
      setError('APIサーバーに接続できません（モックモードで動作中）');

      // モックデータで動作継続
      setKanbanData(generateMockKanbanData());
    } finally {
      setLoading(false);
    }
  };

  const testApiConnection = async () => {
    try {
      const result = await apiClient.testConnection();
      console.log('API接続テスト成功:', result);
      return result;
    } catch (error) {
      console.warn('API接続テスト失敗:', error);
      throw error;
    }
  };

  const generateMockKanbanData = () => ({
    project: {
      id: projectId,
      name: 'サンプルプロジェクト',
      identifier: 'sample-project'
    },
    columns: [
      { id: 'backlog', title: 'バックログ', statuses: ['New', 'Open'] },
      { id: 'ready', title: '準備完了', statuses: ['Ready'] },
      { id: 'in_progress', title: '進行中', statuses: ['In Progress', 'Assigned'] },
      { id: 'review', title: 'レビュー', statuses: ['Review', 'Ready for Test'] },
      { id: 'testing', title: 'テスト中', statuses: ['Testing', 'QA'] },
      { id: 'done', title: '完了', statuses: ['Resolved', 'Closed'] }
    ],
    issues: [
      {
        id: 1,
        subject: 'ユーザー認証機能の実装',
        tracker: 'UserStory',
        status: 'In Progress',
        assigned_to: currentUser.name,
        epic: 'ユーザー管理Epic',
        column: 'in_progress',
        hierarchy_level: 3,
        fixed_version: 'v1.0'
      },
      {
        id: 2,
        subject: 'ログイン画面の作成',
        tracker: 'Task',
        status: 'In Progress',
        assigned_to: currentUser.name,
        epic: 'ユーザー管理Epic',
        column: 'in_progress',
        hierarchy_level: 4,
        parent_id: 1,
        fixed_version: 'v1.0'
      },
      {
        id: 3,
        subject: 'ログイン機能のテスト',
        tracker: 'Test',
        status: 'New',
        assigned_to: 'テスター',
        epic: 'ユーザー管理Epic',
        column: 'backlog',
        hierarchy_level: 4,
        parent_id: 1,
        fixed_version: 'v1.0'
      }
    ],
    statistics: {
      by_tracker: { UserStory: 1, Task: 1, Test: 1 },
      by_status: { 'In Progress': 2, New: 1 },
      by_assignee: { [currentUser.name]: 2, 'テスター': 1 }
    },
    metadata: {
      last_updated: new Date().toISOString(),
      total_issues: 3
    }
  });

  // カード選択の処理
  const handleCardSelect = (cardId) => {
    setSelectedCards(prev => {
      if (prev.includes(cardId)) {
        return prev.filter(id => id !== cardId);
      } else {
        return [...prev, cardId];
      }
    });
  };

  // 全選択/全解除
  const handleSelectAll = () => {
    if (selectedCards.length === kanbanData.issues?.length) {
      setSelectedCards([]);
    } else {
      setSelectedCards(kanbanData.issues?.map(issue => issue.id) || []);
    }
  };

  // バージョン変更の処理
  const handleVersionChange = (version) => {
    setSelectedVersion(version);
    // TODO: 選択されたバージョンでフィルタリングなどの処理
  };

  // データリフレッシュ
  const handleRefresh = async () => {
    await loadInitialData();
    setSelectedCards([]);
  };

  // 一括操作の処理
  const handleBatchAction = async (action, options = {}) => {
    if (selectedCards.length === 0) {
      alert('カードを選択してください');
      return;
    }

    try {
      console.log('一括操作実行:', { action, selectedCards, options });

      switch (action) {
        case 'assign_version':
          await handleBatchVersionAssign(options.versionId);
          break;
        case 'generate_tests':
          await handleBatchTestGeneration();
          break;
        case 'validate_release':
          await handleBatchReleaseValidation();
          break;
        default:
          console.warn('未知の一括操作:', action);
      }

      // 操作後にデータを更新
      await handleRefresh();
    } catch (error) {
      console.error('一括操作エラー:', error);
      alert('操作に失敗しました: ' + error.message);
    }
  };

  const handleBatchVersionAssign = async (versionId) => {
    // TODO: VersionManagementコンポーネントの一括バージョン割当API
    console.log('一括バージョン割当:', { selectedCards, versionId });
    alert('バージョン割当機能は実装中です');
  };

  const handleBatchTestGeneration = async () => {
    // TODO: AutoGenerationコンポーネントの一括Test生成API
    console.log('一括Test生成:', selectedCards);
    alert('Test自動生成機能は実装中です');
  };

  const handleBatchReleaseValidation = async () => {
    // TODO: ValidationGuardコンポーネントの一括検証API
    console.log('一括リリース検証:', selectedCards);
    alert('リリース検証機能は実装中です');
  };

  if (loading) {
    return (
      <div className="release-kanban-loading">
        <div className="loading-spinner"></div>
        <p>Release Kanban を読み込み中...</p>
      </div>
    );
  }

  return (
    <div className="release-kanban-app">
      <div className="kanban-header-controls">
        <h1>Release Kanban - {kanbanData?.project?.name}</h1>

        {error && (
          <div className="error-banner">
            <span>{error}</span>
            <button onClick={handleRefresh}>再試行</button>
          </div>
        )}

        <div className="header-actions">
          <button onClick={handleRefresh} className="refresh-btn">
            更新
          </button>
          <button onClick={handleSelectAll} className="select-all-btn">
            {selectedCards.length === kanbanData.issues?.length ? '全解除' : '全選択'}
          </button>
          <span className="selection-count">
            {selectedCards.length} / {kanbanData.issues?.length || 0} 選択中
          </span>
        </div>
      </div>

      {/* バージョンバー */}
      <VersionBar
        projectId={projectId}
        selectedVersion={selectedVersion}
        onVersionChange={handleVersionChange}
      />

      {/* 一括操作パネル */}
      {selectedCards.length > 0 && (
        <BatchActionPanel
          selectedCards={selectedCards}
          onBatchAction={handleBatchAction}
          projectId={projectId}
        />
      )}

      {/* メインカンバンボード */}
      <KanbanBoard
        projectId={projectId}
        kanbanData={kanbanData}
        selectedCards={selectedCards}
        onCardSelect={handleCardSelect}
        currentUser={currentUser}
      />

      {/* 統計情報 */}
      {kanbanData?.statistics && (
        <div className="kanban-statistics">
          <h3>統計情報</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <label>トラッカー別:</label>
              <span>{Object.entries(kanbanData.statistics.by_tracker).map(([tracker, count]) => `${tracker}: ${count}`).join(', ')}</span>
            </div>
            <div className="stat-item">
              <label>ステータス別:</label>
              <span>{Object.entries(kanbanData.statistics.by_status).map(([status, count]) => `${status}: ${count}`).join(', ')}</span>
            </div>
            <div className="stat-item">
              <label>最終更新:</label>
              <span>{new Date(kanbanData.metadata.last_updated).toLocaleString()}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};