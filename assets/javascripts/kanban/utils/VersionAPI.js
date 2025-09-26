// assets/javascripts/kanban/utils/VersionAPI.js
export class VersionAPI {
  static async getProjectVersions(projectId) {
    const response = await fetch(`/projects/${projectId}/versions.json`);
    const data = await response.json();
    return data.versions || [];
  }

  static async createVersion(projectId, versionData) {
    const response = await fetch(`/kanban/projects/${projectId}/versions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ version: versionData })
    });

    if (!response.ok) throw new Error('バージョン作成失敗');
    return await response.json();
  }

  static async assignVersion(projectId, issueId, versionId) {
    const response = await fetch(`/kanban/projects/${projectId}/assign_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_id: issueId,
        version_id: versionId
      })
    });

    if (!response.ok) throw new Error('バージョン割当失敗');
    return await response.json();
  }

  static async bulkAssignVersion(projectId, issueIds, versionId) {
    const response = await fetch(`/kanban/projects/${projectId}/bulk_assign_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        issue_ids: issueIds,
        version_id: versionId
      })
    });

    if (!response.ok) throw new Error('一括バージョン割当失敗');
    return await response.json();
  }

  static async getAssignmentPreview(projectId, issueId, versionId) {
    const response = await fetch(
      `/kanban/projects/${projectId}/version_assignment_preview?issue_id=${issueId}&version_id=${versionId}`
    );
    return await response.json();
  }
}