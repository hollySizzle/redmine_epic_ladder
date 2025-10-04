import { describe, it, expect, beforeEach } from 'vitest';
import { server } from '../server';
import { http, HttpResponse } from 'msw';
import type {
  NormalizedAPIResponse,
  MoveFeatureRequest,
  MoveFeatureResponse,
  CreateEpicRequest,
  CreateEpicResponse,
  CreateVersionRequest,
  CreateVersionResponse
} from '../../types/normalized-api';

describe('MSW Handlers', () => {
  const baseUrl = 'http://localhost:3000';
  const projectId = '1';

  beforeEach(async () => {
    // 各テストの前にモックデータをリセット
    await fetch(`${baseUrl}/api/epic_grid/projects/${projectId}/grid/reset`, {
      method: 'POST'
    });
  });

  describe('GET /api/epic_grid/projects/:projectId/grid', () => {
    it('グリッドデータを取得できる', async () => {
      const response = await fetch(`${baseUrl}/api/epic_grid/projects/${projectId}/grid`);
      const data: NormalizedAPIResponse = await response.json();

      expect(response.status).toBe(200);
      expect(data.entities).toBeDefined();
      expect(data.entities.epics).toBeDefined();
      expect(data.entities.features).toBeDefined();
      expect(data.grid).toBeDefined();
      expect(data.grid.index).toBeDefined();
    });

    it('include_closed=false でclosedステータスが除外される', async () => {
      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid?include_closed=false`
      );
      const data: NormalizedAPIResponse = await response.json();

      const features = Object.values(data.entities.features);
      const hasClosedFeatures = features.some(f => f.status === 'closed');

      expect(hasClosedFeatures).toBe(false);
    });

    it('include_closed=true でclosedステータスが含まれる', async () => {
      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid?include_closed=true`
      );
      const data: NormalizedAPIResponse = await response.json();

      expect(response.status).toBe(200);
      expect(data.entities.features).toBeDefined();
    });
  });

  describe('POST /api/epic_grid/projects/:projectId/grid/move_feature', () => {
    beforeEach(async () => {
      // モックデータをリセット
      await fetch(`${baseUrl}/api/epic_grid/projects/${projectId}/grid/reset`, {
        method: 'POST'
      });
    });

    it('Featureを別のセルに移動できる', async () => {
      const moveRequest: MoveFeatureRequest = {
        feature_id: 'f1',
        target_epic_id: 'epic2',
        target_version_id: 'v2'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/move_feature`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(moveRequest)
        }
      );

      const data: MoveFeatureResponse = await response.json();

      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.updated_entities.features).toBeDefined();
      expect(data.updated_entities.features!['f1']).toBeDefined();
      expect(data.updated_entities.features!['f1'].parent_epic_id).toBe('epic2');
      expect(data.updated_entities.features!['f1'].fixed_version_id).toBe('v2');
    });

    it('移動後のグリッドインデックスが更新される', async () => {
      const moveRequest: MoveFeatureRequest = {
        feature_id: 'f1',
        target_epic_id: 'epic2',
        target_version_id: 'v2'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/move_feature`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(moveRequest)
        }
      );

      const data: MoveFeatureResponse = await response.json();

      expect(data.updated_grid_index).toBeDefined();
      expect(data.updated_grid_index['epic2:v2']).toContain('f1');
    });

    it('存在しないFeature IDでエラーが返される', async () => {
      const moveRequest: MoveFeatureRequest = {
        feature_id: 'invalid_id',
        target_epic_id: 'epic1',
        target_version_id: 'v1'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/move_feature`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(moveRequest)
        }
      );

      expect(response.status).toBe(404);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error).toBeDefined();
    });

    it('存在しないEpic IDでエラーが返される', async () => {
      const moveRequest: MoveFeatureRequest = {
        feature_id: 'f1',
        target_epic_id: 'invalid_epic',
        target_version_id: 'v1'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/move_feature`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(moveRequest)
        }
      );

      expect(response.status).toBe(404);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('not_found');
    });

    it('Version伝播により子要素も更新される', async () => {
      const moveRequest: MoveFeatureRequest = {
        feature_id: 'f1',
        target_epic_id: 'epic1',
        target_version_id: 'v3'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/move_feature`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(moveRequest)
        }
      );

      const data: MoveFeatureResponse = await response.json();

      expect(data.propagation_result).toBeDefined();
      expect(data.propagation_result!.affected_issue_ids.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/epic_grid/projects/:projectId/grid/updates', () => {
    it('差分更新データを取得できる', async () => {
      const since = new Date(Date.now() - 1000 * 60 * 5).toISOString(); // 5分前
      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/updates?since=${since}`
      );
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.has_changes).toBeDefined();
      expect(data.current_timestamp).toBeDefined();
    });
  });

  describe('POST /api/epic_grid/projects/:projectId/grid/reset', () => {
    it('モックデータをリセットできる', async () => {
      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/grid/reset`,
        { method: 'POST' }
      );
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
    });
  });

  describe('POST /api/epic_grid/projects/:projectId/epics', () => {
    it('Epicを作成できる', async () => {
      const createRequest: CreateEpicRequest = {
        subject: 'ユーザー管理機能',
        description: 'ユーザー登録・編集・削除機能の実装',
        status: 'open'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateEpicResponse = await response.json();

      expect(response.status).toBe(201);
      expect(data.success).toBe(true);
      expect(data.data.created_entity).toBeDefined();
      expect(data.data.created_entity.subject).toBe('ユーザー管理機能');
      expect(data.data.created_entity.description).toBe('ユーザー登録・編集・削除機能の実装');
      expect(data.data.created_entity.status).toBe('open');
    });

    it('作成後にepic_orderが更新される', async () => {
      const createRequest: CreateEpicRequest = {
        subject: '決済機能'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateEpicResponse = await response.json();

      expect(data.data.grid_updates.epic_order).toBeDefined();
      expect(data.data.grid_updates.epic_order).toContain(data.data.created_entity.id);
    });

    it('subject空文字でバリデーションエラーが返される', async () => {
      const createRequest = {
        subject: '',
        description: 'Invalid epic'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('validation_error');
      expect(data.error.message).toContain('required');
    });

    it('subject空白文字のみでバリデーションエラーが返される', async () => {
      const createRequest = {
        subject: '   ',
        description: 'Invalid epic'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('validation_error');
    });

    it('最小限のパラメータ（subjectのみ）でEpic作成できる', async () => {
      const createRequest: CreateEpicRequest = {
        subject: 'シンプルなEpic'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateEpicResponse = await response.json();

      expect(response.status).toBe(201);
      expect(data.success).toBe(true);
      expect(data.data.created_entity.subject).toBe('シンプルなEpic');
      expect(data.data.created_entity.status).toBe('open'); // デフォルト値
    });

    it('作成されたEpicがepicsエンティティに含まれる', async () => {
      const createRequest: CreateEpicRequest = {
        subject: 'インフラ整備',
        description: 'CI/CD環境構築',
        status: 'in_progress'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/epics`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateEpicResponse = await response.json();
      const createdId = data.data.created_entity.id;

      expect(data.data.updated_entities.epics).toBeDefined();
      expect(data.data.updated_entities.epics![createdId]).toBeDefined();
      expect(data.data.updated_entities.epics![createdId].subject).toBe('インフラ整備');
      expect(data.data.updated_entities.epics![createdId].status).toBe('in_progress');
    });
  });

  describe('POST /api/epic_grid/projects/:projectId/versions', () => {

    it('Versionを作成できる', async () => {
      const createRequest: CreateVersionRequest = {
        name: 'v2.1.0',
        description: 'Q2 Release',
        due_date: '2025-06-30',
        status: 'open'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateVersionResponse = await response.json();

      expect(response.status).toBe(201);
      expect(data.success).toBe(true);
      expect(data.data.created_entity).toBeDefined();
      expect(data.data.created_entity.name).toBe('v2.1.0');
      expect(data.data.created_entity.description).toBe('Q2 Release');
      expect(data.data.created_entity.effective_date).toBe('2025-06-30');
      expect(data.data.created_entity.status).toBe('open');
    });

    it('作成後にversion_orderが更新される', async () => {
      const createRequest: CreateVersionRequest = {
        name: 'v3.0.0',
        description: 'Major Release'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateVersionResponse = await response.json();

      expect(data.data.grid_updates.version_order).toBeDefined();
      expect(data.data.grid_updates.version_order).toContain(data.data.created_entity.id);
    });

    it('name空文字でバリデーションエラーが返される', async () => {
      const createRequest = {
        name: '',
        description: 'Invalid version'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('validation_error');
      expect(data.error.message).toContain('required');
    });

    it('name空白文字のみでバリデーションエラーが返される', async () => {
      const createRequest = {
        name: '   ',
        description: 'Invalid version'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('validation_error');
    });

    it('最小限のパラメータ（nameのみ）でVersion作成できる', async () => {
      const createRequest: CreateVersionRequest = {
        name: 'v1.5.0'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateVersionResponse = await response.json();

      expect(response.status).toBe(201);
      expect(data.success).toBe(true);
      expect(data.data.created_entity.name).toBe('v1.5.0');
      expect(data.data.created_entity.status).toBe('open'); // デフォルト値
    });

    it('作成されたVersionがversionsエンティティに含まれる', async () => {
      const createRequest: CreateVersionRequest = {
        name: 'v4.0.0-beta',
        description: 'Beta Release',
        status: 'locked'
      };

      const response = await fetch(
        `${baseUrl}/api/epic_grid/projects/${projectId}/versions`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createRequest)
        }
      );

      const data: CreateVersionResponse = await response.json();
      const createdId = data.data.created_entity.id;

      expect(data.data.updated_entities.versions).toBeDefined();
      expect(data.data.updated_entities.versions![createdId]).toBeDefined();
      expect(data.data.updated_entities.versions![createdId].name).toBe('v4.0.0-beta');
      expect(data.data.updated_entities.versions![createdId].status).toBe('locked');
    });
  });
});
