/**
 * Feature Card API Client
 * 設計仕様書準拠: @vibes/docs/logics/feature_card/feature_card_server_specification.md
 */

import { ApiClient } from '../utils/ApiClient';

class FeatureCardAPI {
  constructor() {
    this.apiClient = new ApiClient();
  }

  /**
   * Feature Card一覧取得
   * @param {Object} filters - フィルタパラメータ
   * @returns {Promise<Object>} Feature Card一覧データ
   */
  async getFeatureCards(filters = {}) {
    try {
      const params = new URLSearchParams(filters).toString();
      const url = params ? `/kanban/cards?${params}` : '/kanban/cards';

      const response = await this.apiClient.get(url);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch feature cards:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Feature Card詳細取得
   * @param {number} featureId - FeatureのID
   * @returns {Promise<Object>} Feature詳細データ
   */
  async getFeatureCard(featureId) {
    try {
      const response = await this.apiClient.get(`/kanban/cards/${featureId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch feature card:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Feature作成
   * @param {Object} featureData - Feature作成データ
   * @returns {Promise<Object>} 作成されたFeature
   */
  async createFeature(featureData) {
    try {
      const response = await this.apiClient.post('/kanban/cards', {
        feature: featureData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to create feature:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Feature更新
   * @param {number} featureId - FeatureのID
   * @param {Object} featureData - Feature更新データ
   * @returns {Promise<Object>} 更新されたFeature
   */
  async updateFeature(featureId, featureData) {
    try {
      const response = await this.apiClient.put(`/kanban/cards/${featureId}`, {
        feature: featureData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to update feature:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * UserStory作成
   * @param {number} featureId - 親FeatureのID
   * @param {Object} userStoryData - UserStory作成データ
   * @returns {Promise<Object>} 作成されたUserStory
   */
  async createUserStory(featureId, userStoryData) {
    try {
      const response = await this.apiClient.post(`/kanban/cards/${featureId}/user_stories`, {
        user_story: userStoryData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to create user story:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * UserStory更新
   * @param {number} userStoryId - UserStoryのID
   * @param {Object} userStoryData - UserStory更新データ
   * @returns {Promise<Object>} 更新されたUserStory
   */
  async updateUserStory(userStoryId, userStoryData) {
    try {
      const response = await this.apiClient.put(`/kanban/user_stories/${userStoryId}`, {
        user_story: userStoryData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to update user story:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * UserStory削除
   * @param {number} userStoryId - UserStoryのID
   * @returns {Promise<Object>} 削除結果
   */
  async deleteUserStory(userStoryId) {
    try {
      const response = await this.apiClient.delete(`/kanban/user_stories/${userStoryId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to delete user story:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Task作成
   * @param {number} userStoryId - 親UserStoryのID
   * @param {Object} taskData - Task作成データ
   * @returns {Promise<Object>} 作成されたTask
   */
  async createTask(userStoryId, taskData) {
    try {
      const response = await this.apiClient.post(`/kanban/user_stories/${userStoryId}/tasks`, {
        task: taskData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to create task:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Test作成
   * @param {number} userStoryId - 親UserStoryのID
   * @param {Object} testData - Test作成データ
   * @returns {Promise<Object>} 作成されたTest
   */
  async createTest(userStoryId, testData) {
    try {
      const response = await this.apiClient.post(`/kanban/user_stories/${userStoryId}/tests`, {
        test: testData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to create test:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * Bug作成
   * @param {number} userStoryId - 親UserStoryのID
   * @param {Object} bugData - Bug作成データ
   * @returns {Promise<Object>} 作成されたBug
   */
  async createBug(userStoryId, bugData) {
    try {
      const response = await this.apiClient.post(`/kanban/user_stories/${userStoryId}/bugs`, {
        bug: bugData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to create bug:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * アイテム（Task/Test/Bug）更新
   * @param {number} itemId - アイテムのID
   * @param {Object} itemData - アイテム更新データ
   * @param {string} itemType - アイテムタイプ（Task/Test/Bug）
   * @returns {Promise<Object>} 更新されたアイテム
   */
  async updateItem(itemId, itemData, itemType) {
    try {
      const response = await this.apiClient.put(`/kanban/items/${itemId}`, {
        item: itemData,
        item_type: itemType
      });
      return response.data;
    } catch (error) {
      console.error(`Failed to update ${itemType}:`, error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * アイテム（Task/Test/Bug）削除
   * @param {number} itemId - アイテムのID
   * @param {string} itemType - アイテムタイプ（Task/Test/Bug）
   * @returns {Promise<Object>} 削除結果
   */
  async deleteItem(itemId, itemType) {
    try {
      const response = await this.apiClient.delete(`/kanban/items/${itemId}`, {
        item_type: itemType
      });
      return response.data;
    } catch (error) {
      console.error(`Failed to delete ${itemType}:`, error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * UserStory一括更新
   * @param {Array<number>} userStoryIds - UserStoryIDの配列
   * @param {Object} bulkData - 一括更新データ
   * @returns {Promise<Object>} 一括更新結果
   */
  async bulkUpdateUserStories(userStoryIds, bulkData) {
    try {
      const response = await this.apiClient.put('/kanban/user_stories/bulk_update', {
        user_story_ids: userStoryIds,
        bulk_update: bulkData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to bulk update user stories:', error);
      throw this.handleAPIError(error);
    }
  }

  /**
   * APIエラーハンドリング
   * @private
   * @param {Error} error - APIエラー
   * @returns {Error} 処理されたエラー
   */
  handleAPIError(error) {
    if (error.response) {
      // サーバーレスポンスエラー
      const { status, data } = error.response;

      switch (status) {
        case 400:
          return new Error(`バリデーションエラー: ${data.error || '入力内容を確認してください'}`);
        case 401:
          return new Error('認証が必要です。再ログインしてください。');
        case 403:
          return new Error('この操作を実行する権限がありません。');
        case 404:
          return new Error('指定されたリソースが見つかりません。');
        case 422:
          return new Error(`処理エラー: ${data.error || '入力内容に問題があります'}`);
        case 500:
          return new Error('サーバーエラーが発生しました。しばらく待ってから再試行してください。');
        default:
          return new Error(`APIエラー (${status}): ${data.error || '不明なエラーが発生しました'}`);
      }
    } else if (error.request) {
      // ネットワークエラー
      return new Error('ネットワークエラー: サーバーに接続できませんでした。');
    } else {
      // その他のエラー
      return new Error(`予期しないエラー: ${error.message}`);
    }
  }

  /**
   * ローディング状態管理用のラッパー
   * @param {Function} apiCall - API呼び出し関数
   * @param {Function} setLoading - ローディング状態セッター
   * @returns {Promise} API実行結果
   */
  async withLoading(apiCall, setLoading) {
    setLoading(true);
    try {
      const result = await apiCall();
      return result;
    } finally {
      setLoading(false);
    }
  }
}

// シングルトンインスタンス
const featureCardAPI = new FeatureCardAPI();

export { FeatureCardAPI, featureCardAPI };