// assets/javascripts/kanban/services/KanbanAPIService.js
export class KanbanAPIService {
  constructor(projectId, apiBaseUrl) {
    this.projectId = projectId;
    this.baseUrl = apiBaseUrl || `/kanban/projects/${projectId}`;
  }

  async getKanbanData(filters = {}) {
    const queryString = new URLSearchParams(filters).toString();
    const response = await this.fetch(`cards${queryString ? `?${queryString}` : ''}`);
    return await response.json();
  }

  async moveCard(cardId, columnId) {
    return await this.post('move_card', { card_id: cardId, column_id: columnId });
  }

  async assignVersion(issueId, versionId) {
    return await this.post('assign_version', { issue_id: issueId, version_id: versionId });
  }

  async generateTest(userStoryId, options = {}) {
    return await this.post('generate_test', { user_story_id: userStoryId, ...options });
  }

  async getReleaseValidation(issueId) {
    const response = await this.fetch(`release_validation?issue_id=${issueId}`);
    return await response.json();
  }

  async fetch(path, options = {}) {
    const url = path.startsWith('http') ? path : `${this.baseUrl}/${path}`;
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...options.headers
      },
      ...options
    });

    if (!response.ok) {
      await this.handleErrorResponse(response);
    }
    return response;
  }

  async post(path, data) {
    const response = await this.fetch(path, {
      method: 'POST',
      headers: { 'X-CSRF-Token': this.getCSRFToken() },
      body: JSON.stringify(data)
    });
    return await response.json();
  }

  async handleErrorResponse(response) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    try {
      const errorData = await response.json();
      if (errorData.error) {
        errorMessage = errorData.error;
      }
    } catch (e) {
      // JSON パースエラーは無視
    }
    throw new Error(errorMessage);
  }

  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }
}