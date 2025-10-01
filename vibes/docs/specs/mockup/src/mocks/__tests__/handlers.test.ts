import { describe, it, expect, beforeEach } from 'vitest';
import { server } from '../server';
import { http, HttpResponse } from 'msw';
import type { NormalizedAPIResponse, MoveFeatureRequest, MoveFeatureResponse } from '../../types/normalized-api';

describe('MSW Handlers', () => {
  const baseUrl = 'http://localhost:3000';
  const projectId = '1';

  describe('GET /api/kanban/projects/:projectId/grid', () => {
    it('グリッドデータを取得できる', async () => {
      const response = await fetch(`${baseUrl}/api/kanban/projects/${projectId}/grid`);
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid?include_closed=false`
      );
      const data: NormalizedAPIResponse = await response.json();

      const features = Object.values(data.entities.features);
      const hasClosedFeatures = features.some(f => f.status === 'closed');

      expect(hasClosedFeatures).toBe(false);
    });

    it('include_closed=true でclosedステータスが含まれる', async () => {
      const response = await fetch(
        `${baseUrl}/api/kanban/projects/${projectId}/grid?include_closed=true`
      );
      const data: NormalizedAPIResponse = await response.json();

      expect(response.status).toBe(200);
      expect(data.entities.features).toBeDefined();
    });
  });

  describe('POST /api/kanban/projects/:projectId/grid/move_feature', () => {
    beforeEach(async () => {
      // モックデータをリセット
      await fetch(`${baseUrl}/api/kanban/projects/${projectId}/grid/reset`, {
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid/move_feature`,
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid/move_feature`,
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid/move_feature`,
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid/move_feature`,
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
        `${baseUrl}/api/kanban/projects/${projectId}/grid/move_feature`,
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

  describe('GET /api/kanban/projects/:projectId/grid/updates', () => {
    it('差分更新データを取得できる', async () => {
      const since = new Date(Date.now() - 1000 * 60 * 5).toISOString(); // 5分前
      const response = await fetch(
        `${baseUrl}/api/kanban/projects/${projectId}/grid/updates?since=${since}`
      );
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.has_changes).toBeDefined();
      expect(data.current_timestamp).toBeDefined();
    });
  });

  describe('POST /api/kanban/projects/:projectId/grid/reset', () => {
    it('モックデータをリセットできる', async () => {
      const response = await fetch(
        `${baseUrl}/api/kanban/projects/${projectId}/grid/reset`,
        { method: 'POST' }
      );
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
    });
  });
});
