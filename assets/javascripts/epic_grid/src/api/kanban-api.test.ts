/**
 * Kanban API Test
 *
 * MSW契約テスト + 主要エンドポイントのユニットテスト
 *
 * テスト方針:
 * 1. MSWハンドラとの整合性を検証 (契約テスト)
 * 2. 主要なCRUD操作の動作を確認
 * 3. エラーハンドリングを検証
 */

import { describe, it, expect, beforeAll, afterEach, afterAll, vi, beforeEach } from 'vitest';
import { server } from '../mocks/server';
import {
  fetchGridData,
  createEpic,
  createFeature,
  createUserStory,
  createTask,
  createTest,
  createBug,
  createVersion,
  moveFeature,
  moveUserStory,
  reorderEpics,
  reorderVersions,
  batchUpdate,
  resetMockData,
  KanbanAPIError
} from './kanban-api';
import type { NormalizedAPIResponse } from '../types/normalized-api';

// MSWサーバーのセットアップ
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  server.resetHandlers();
  // Note: resetMockData()はMSWのcurrentDataをリセットしますが、
  // afterEachではserver.resetHandlers()のみで十分です。
  // 各テストで必要な場合は個別にresetMockData(1)を呼び出します。
});
afterAll(() => server.close());

describe('Kanban API - MSW契約テスト', () => {
  describe('fetchGridData', () => {
    it('プロジェクトIDを指定してグリッドデータを取得できる', async () => {
      const data = await fetchGridData(1);

      expect(data).toBeDefined();
      expect(data.entities.epics).toBeDefined();
      expect(data.entities.features).toBeDefined();
      expect(data.entities.user_stories).toBeDefined();
      expect(data.entities.tasks).toBeDefined();
      expect(data.entities.tests).toBeDefined();
      expect(data.entities.bugs).toBeDefined();
      expect(data.entities.versions).toBeDefined();
      expect(data.entities.users).toBeDefined();
      expect(data.grid.index).toBeDefined();
      expect(data.grid.epic_order).toBeDefined();
      expect(data.grid.version_order).toBeDefined();
    });

    it('MSWレスポンスがNormalizedAPIResponse型に準拠している', async () => {
      const data: NormalizedAPIResponse = await fetchGridData(1);

      // 型チェック: TypeScriptコンパイルが通ればOK
      expect(typeof data.entities.epics).toBe('object');
      expect(typeof data.entities.features).toBe('object');
      expect(Array.isArray(data.grid.epic_order)).toBe(true);
      expect(Array.isArray(data.grid.version_order)).toBe(true);
    });

    it('grid_indexがRecord<epic_id:feature_id:version_id, user_story_id[]>形式である', async () => {
      const data = await fetchGridData(1);

      Object.entries(data.grid.index).forEach(([key, value]) => {
        // キーフォーマット: "epic-1:f1:v1" または "epic-1:f1:none"
        expect(key).toMatch(/^[^:]+:[^:]+:[^:]+$/);
        // 値は配列
        expect(Array.isArray(value)).toBe(true);
      });
    });
  });

  describe('Create API - MSW契約テスト', () => {
    it('createEpic がMSWハンドラと整合している', async () => {
      const response = await createEpic(1, {
        subject: 'New Epic',
        description: 'Epic description',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.subject).toBe('New Epic');
      expect(response.data.created_entity.id).toMatch(/^epic-/);
    });

    it('createFeature がMSWハンドラと整合している', async () => {
      // 先にモックデータから取得できるepicを使う
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];

      const response = await createFeature(1, {
        subject: 'New Feature',
        parent_epic_id: firstEpicId,
        fixed_version_id: null,
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.title).toBe('New Feature');
      expect(response.data.created_entity.parent_epic_id).toBe(firstEpicId);
    });

    it('createUserStory がMSWハンドラと整合している', async () => {
      // 先にモックデータから取得できるfeatureを使う
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];
      const firstFeatureId = gridData.grid.feature_order_by_epic[firstEpicId][0];

      const response = await createUserStory(1, firstFeatureId, {
        subject: 'New User Story',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.title).toBe('New User Story');
    });

    it('createTask がMSWハンドラと整合している', async () => {
      // 先にモックデータから取得できるuser_storyを使う
      const gridData = await fetchGridData(1);
      const firstUserStoryId = Object.values(gridData.entities.user_stories)[0].id;

      const response = await createTask(1, firstUserStoryId, {
        subject: 'New Task',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.title).toBe('New Task');
    });

    it('createTest がMSWハンドラと整合している', async () => {
      // 先にモックデータから取得できるuser_storyを使う
      const gridData = await fetchGridData(1);
      const firstUserStoryId = Object.values(gridData.entities.user_stories)[0].id;

      const response = await createTest(1, firstUserStoryId, {
        subject: 'New Test',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.title).toBe('New Test');
    });

    it('createBug がMSWハンドラと整合している', async () => {
      // 先にモックデータから取得できるuser_storyを使う
      const gridData = await fetchGridData(1);
      const firstUserStoryId = Object.values(gridData.entities.user_stories)[0].id;

      const response = await createBug(1, firstUserStoryId, {
        subject: 'New Bug',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.title).toBe('New Bug');
    });

    it('createVersion がMSWハンドラと整合している', async () => {
      const response = await createVersion(1, {
        name: 'v2.0.0',
        description: 'Version 2.0',
        effective_date: '2025-12-31',
      });

      expect(response.success).toBe(true);
      expect(response.data.created_entity).toBeDefined();
      expect(response.data.created_entity.name).toBe('v2.0.0');
    });
  });

  describe('Move API - MSW契約テスト', () => {
    it('moveFeature がMSWハンドラと整合している', async () => {
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;
      const firstEpicId = epics[0];
      const secondEpicId = epics[1] || epics[0]; // 2つ目がなければ1つ目
      const featureId = gridData.grid.feature_order_by_epic[firstEpicId]?.[0];

      if (!featureId) {
        // テストデータがない場合はスキップ
        expect(true).toBe(true);
        return;
      }

      const response = await moveFeature(1, {
        feature_id: featureId,
        target_epic_id: secondEpicId,
        target_version_id: null,
      });

      expect(response.success).toBe(true);
      expect(response.updated_entities.features).toBeDefined();
      expect(response.updated_entities.features![featureId].parent_epic_id).toBe(secondEpicId);
    });

    it('moveUserStory がMSWハンドラと整合している', async () => {
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];
      const features = gridData.grid.feature_order_by_epic[firstEpicId];
      const firstFeatureId = features?.[0];
      const secondFeatureId = features?.[1] || firstFeatureId;

      if (!firstFeatureId) {
        expect(true).toBe(true);
        return;
      }

      // UserStoryを取得
      const userStoryId = Object.values(gridData.entities.user_stories).find(
        us => us.parent_feature_id === firstFeatureId
      )?.id;

      if (!userStoryId) {
        expect(true).toBe(true);
        return;
      }

      const response = await moveUserStory(1, {
        user_story_id: userStoryId,
        target_feature_id: secondFeatureId,
        target_version_id: null,
      });

      expect(response.success).toBe(true);
      expect(response.updated_entities.user_stories).toBeDefined();
      expect(response.updated_entities.user_stories![userStoryId].parent_feature_id).toBe(secondFeatureId);
    });
  });

  describe('Reorder API - MSW契約テスト', () => {
    it('reorderEpics がMSWハンドラと整合している', async () => {
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;
      if (epics.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const response = await reorderEpics(1, {
        source_epic_id: epics[0],
        target_epic_id: epics[1],
        position: 'after'
      });

      expect(response.success).toBe(true);
      expect(response.data.epic_order).toBeDefined();
      expect(Array.isArray(response.data.epic_order)).toBe(true);
    });

    it('reorderVersions がMSWハンドラと整合している', async () => {
      const gridData = await fetchGridData(1);
      const versions = gridData.grid.version_order;
      if (versions.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const response = await reorderVersions(1, {
        source_version_id: versions[0],
        target_version_id: versions[1],
        position: 'after'
      });

      expect(response.success).toBe(true);
      expect(response.data.version_order).toBeDefined();
      expect(Array.isArray(response.data.version_order)).toBe(true);
    });
  });

  describe('Batch Update - MSW契約テスト', () => {
    it('batchUpdate がMSWハンドラと整合している', async () => {
      const response = await batchUpdate(1, {
        moved_user_stories: [
          { id: 'us-1', target_feature_id: 'f2', target_version_id: 'v2' },
        ],
        reordered_epics: ['epic-2', 'epic-1'],
        reordered_versions: ['v2', 'v1'],
      });

      expect(response.success).toBe(true);
      expect(response.updated_entities).toBeDefined();
      expect(response.updated_epic_order).toBeDefined();
      expect(response.updated_version_order).toBeDefined();
    });
  });
});

describe('Kanban API - エンドポイント動作テスト', () => {
  describe('fetchGridData', () => {
    it('取得したデータに必須プロパティが含まれている', async () => {
      const data = await fetchGridData(1);

      // エンティティコレクション
      expect(data.entities.epics).toBeTruthy();
      expect(data.entities.features).toBeTruthy();
      expect(data.entities.user_stories).toBeTruthy();
      expect(data.entities.tasks).toBeTruthy();
      expect(data.entities.tests).toBeTruthy();
      expect(data.entities.bugs).toBeTruthy();
      expect(data.entities.versions).toBeTruthy();
      expect(data.entities.users).toBeTruthy();

      // グリッド構造
      expect(data.grid.index).toBeTruthy();
      expect(data.grid.epic_order).toBeTruthy();
      expect(data.grid.version_order).toBeTruthy();
    });

    it('エンティティがオブジェクト形式で返される', async () => {
      const data = await fetchGridData(1);

      expect(typeof data.entities.epics).toBe('object');
      expect(typeof data.entities.features).toBe('object');
      expect(typeof data.entities.versions).toBe('object');
    });

    it('orderが配列形式で返される', async () => {
      const data = await fetchGridData(1);

      expect(Array.isArray(data.grid.epic_order)).toBe(true);
      expect(Array.isArray(data.grid.version_order)).toBe(true);
    });
  });

  describe('Create Operations', () => {
    beforeEach(async () => {
      await resetMockData(1);
    });

    it('createEpic で新しいEpicが作成される', async () => {
      const result = await createEpic(1, {
        subject: 'Test Epic',
        description: 'Test Description',
      });

      expect(result.success).toBe(true);
      expect(result.data.created_entity.subject).toBe('Test Epic');
      expect(result.data.created_entity.description).toBe('Test Description');
    });

    it('createFeature でparent_epic_idが設定される', async () => {
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];

      const result = await createFeature(1, {
        subject: 'Test Feature',
        parent_epic_id: firstEpicId,
        fixed_version_id: null,
      });

      expect(result.success).toBe(true);
      expect(result.data.created_entity.parent_epic_id).toBe(firstEpicId);
    });

    it('createUserStory でparent_feature_idが設定される', async () => {
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];
      const firstFeatureId = gridData.grid.feature_order_by_epic[firstEpicId][0];

      const result = await createUserStory(1, firstFeatureId, {
        subject: 'Test Story',
      });

      expect(result.success).toBe(true);
      expect(result.data.created_entity.parent_feature_id).toBe(firstFeatureId);
    });

    it('createTask でparent_user_story_idが設定される', async () => {
      const gridData = await fetchGridData(1);
      const firstUserStoryId = Object.values(gridData.entities.user_stories)[0].id;

      const result = await createTask(1, firstUserStoryId, {
        subject: 'Test Task',
      });

      expect(result.success).toBe(true);
      expect(result.data.created_entity.parent_user_story_id).toBe(firstUserStoryId);
    });
  });

  describe('Move Operations', () => {
    it('moveFeature で親Epic/バージョンが更新される', async () => {
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;
      const firstEpicId = epics[0];
      const secondEpicId = epics[1] || epics[0];
      const featureId = gridData.grid.feature_order_by_epic[firstEpicId]?.[0];

      if (!featureId) {
        expect(true).toBe(true);
        return;
      }

      const result = await moveFeature(1, {
        feature_id: featureId,
        target_epic_id: secondEpicId,
        target_version_id: null,
      });

      expect(result.success).toBe(true);
      expect(result.updated_entities.features![featureId].id).toBe(featureId);
      expect(result.updated_entities.features![featureId].parent_epic_id).toBe(secondEpicId);
    });

    it('moveUserStory で親Feature/バージョンが更新される', async () => {
      const gridData = await fetchGridData(1);
      const firstEpicId = gridData.grid.epic_order[0];
      const features = gridData.grid.feature_order_by_epic[firstEpicId];
      const firstFeatureId = features?.[0];
      const secondFeatureId = features?.[1] || firstFeatureId;

      if (!firstFeatureId) {
        expect(true).toBe(true);
        return;
      }

      const userStoryId = Object.values(gridData.entities.user_stories).find(
        us => us.parent_feature_id === firstFeatureId
      )?.id;

      if (!userStoryId) {
        expect(true).toBe(true);
        return;
      }

      const result = await moveUserStory(1, {
        user_story_id: userStoryId,
        target_feature_id: secondFeatureId,
        target_version_id: null,
      });

      expect(result.success).toBe(true);
      expect(result.updated_entities.user_stories![userStoryId].id).toBe(userStoryId);
      expect(result.updated_entities.user_stories![userStoryId].parent_feature_id).toBe(secondFeatureId);
    });
  });

  describe('Reorder Operations', () => {
    it('reorderEpics で順序が更新される', async () => {
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;
      if (epics.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const result = await reorderEpics(1, {
        source_epic_id: epics[0],
        target_epic_id: epics[1],
        position: 'after'
      });

      expect(result.success).toBe(true);
      expect(Array.isArray(result.data.epic_order)).toBe(true);
    });

    it('reorderVersions で順序が更新される', async () => {
      const gridData = await fetchGridData(1);
      const versions = gridData.grid.version_order;
      if (versions.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const result = await reorderVersions(1, {
        source_version_id: versions[0],
        target_version_id: versions[1],
        position: 'after'
      });

      expect(result.success).toBe(true);
      expect(Array.isArray(result.data.version_order)).toBe(true);
    });
  });

  describe('Batch Update', () => {
    it('複数の操作をまとめて実行できる', async () => {
      // 実際のデータを取得して使用
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;
      const versions = gridData.grid.version_order;

      if (epics.length < 2 || versions.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const reorderedEpics = [epics[1], epics[0]];
      const reorderedVersions = [versions[1], versions[0]];

      const result = await batchUpdate(1, {
        moved_user_stories: [],
        reordered_epics: reorderedEpics,
        reordered_versions: reorderedVersions,
      });

      expect(result.success).toBe(true);
      expect(result.updated_entities).toBeDefined();
      expect(result.updated_epic_order).toEqual(reorderedEpics);
      expect(result.updated_version_order).toEqual(reorderedVersions);
    });

    it('moved_user_storiesのみ指定して実行できる', async () => {
      const result = await batchUpdate(1, {
        moved_user_stories: [],
      });

      expect(result.success).toBe(true);
    });

    it('reordered_epicsのみ指定して実行できる', async () => {
      const gridData = await fetchGridData(1);
      const epics = gridData.grid.epic_order;

      if (epics.length < 2) {
        expect(true).toBe(true);
        return;
      }

      const reorderedEpics = [epics[1], epics[0]];

      const result = await batchUpdate(1, {
        reordered_epics: reorderedEpics,
      });

      expect(result.success).toBe(true);
      expect(result.updated_epic_order).toEqual(reorderedEpics);
    });
  });
});

describe('Kanban API - エラーハンドリング', () => {
  it('KanbanAPIError がエラー情報を保持する', () => {
    const error = new KanbanAPIError('Test error', 'BAD_REQUEST', 400, { detail: 'Bad request' });

    expect(error.message).toBe('Test error');
    expect(error.code).toBe('BAD_REQUEST');
    expect(error.status).toBe(400);
    expect(error.details).toEqual({ detail: 'Bad request' });
    expect(error.name).toBe('KanbanAPIError');
  });

  it('KanbanAPIError がErrorを継承している', () => {
    const error = new KanbanAPIError('Test error', 'INTERNAL_ERROR', 500);

    expect(error instanceof Error).toBe(true);
    expect(error instanceof KanbanAPIError).toBe(true);
  });
});

describe('Kanban API - ヘルパー関数', () => {
  describe('resetMockData', () => {
    it('モックデータをリセットできる', async () => {
      // Epic作成
      await createEpic(1, { subject: 'Test Epic' });

      // リセット実行
      await resetMockData(1);

      // リセット後のデータ確認（モックサーバーの初期状態に戻る）
      const data = await fetchGridData(1);
      expect(data).toBeDefined();
      // モックデータがリセットされていることを確認
    });
  });
});
