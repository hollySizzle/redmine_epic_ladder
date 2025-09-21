// API通信ユーティリティクラス
// React-バックエンド間の効率的データ交換を管理
export class ApiClient {
  constructor(projectId) {
    this.projectId = projectId;
    this.baseUrl = `/projects/${projectId}/kanban`;
    this.headers = {
      'Content-Type': 'application/json',
      'X-CSRF-Token': this.getCsrfToken()
    };
  }

  // CSRFトークンの取得
  getCsrfToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }

  // ===== APIIntegration統合エンドポイント =====

  // カンバンデータの取得
  async getKanbanData() {
    const response = await fetch(`${this.baseUrl}/api/kanban_data`);
    if (!response.ok) throw new Error('カンバンデータ取得失敗');
    return await response.json();
  }

  // イシューの状態遷移
  async transitionIssue(issueId, targetColumn) {
    const response = await fetch(`${this.baseUrl}/api/transition_issue`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        issue_id: issueId,
        target_column: targetColumn
      })
    });

    if (!response.ok) throw new Error('状態遷移失敗');
    return await response.json();
  }

  // 接続テスト
  async testConnection() {
    const response = await fetch(`${this.baseUrl}/api/test_connection`);
    if (!response.ok) throw new Error('接続テスト失敗');
    return await response.json();
  }

  // エラーハンドリング
  handleApiError(error, context = '') {
    console.error(`API Error${context ? ` (${context})` : ''}:`, error);
    return '通信エラーが発生しました';
  }
}